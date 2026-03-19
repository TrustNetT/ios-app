import Foundation
import Vision
import CryptoKit

// MARK: - Biometric Hasher
/// Privacy-preserving facial geometry hashing
/// Extracts facial landmarks from ID photo, computes SHA-256 hash
/// Never stores raw biometric data
public class BiometricHasher {
    
    // MARK: - Public Interface
    
    /// Extract facial geometry from ID photo and compute hash
    /// - Parameter imageData: JPEG/PNG image data from government ID
    /// - Returns: BiometricHash with SHA-256 hash of facial geometry
    public func hashBiometric(from imageData: Data) throws -> BiometricHash {
        // Validate image format
        guard let uiImage = UIImage(data: imageData) else {
            throw BiometricHasherError.invalidImageFormat("Cannot decode image data")
        }
        
        guard let cgImage = uiImage.cgImage else {
            throw BiometricHasherError.invalidImageFormat("Cannot convert to CGImage")
        }
        
        // Detect face landmarks
        let landmarks = try detectFaceLandmarks(cgImage: cgImage)
        
        // Extract normalized facial geometry
        let geometry = try extractFacialGeometry(landmarks: landmarks)
        
        // Compute SHA-256 hash
        let hash = computeGeometryHash(geometry: geometry)
        
        return BiometricHash(hash: hash, timestamp: Date())
    }
    
    // MARK: - Face Landmark Detection
    
    private func detectFaceLandmarks(cgImage: CGImage) throws -> [String: CGPoint] {
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        var detectedLandmarks: [String: CGPoint] = [:]
        
        try handler.perform([request])
        
        guard let results = request.results as? [VNFaceObservation], !results.isEmpty else {
            throw BiometricHasherError.noFaceDetected("No face found in image")
        }
        
        guard let face = results.first else {
            throw BiometricHasherError.multipleFacesDetected("Image contains multiple faces")
        }
        
        guard let landmarks = face.landmarks else {
            throw BiometricHasherError.landmarkDetectionFailed("Cannot extract face landmarks")
        }
        
        // Extract key facial landmarks for geometry
        extractKeyLandmarks(from: landmarks, into: &detectedLandmarks)
        
        return detectedLandmarks
    }
    
    private func extractKeyLandmarks(
        from landmarks: VNFaceLandmarks2D,
        into result: inout [String: CGPoint]
    ) {
        // Eyes
        if let leftEye = landmarks.leftEye?.normalizedPoints.first {
            result["leftEyeCenter"] = leftEye
        }
        if let rightEye = landmarks.rightEye?.normalizedPoints.first {
            result["rightEyeCenter"] = rightEye
        }
        
        // Nose
        if let nose = landmarks.nose?.normalizedPoints.first {
            result["noseTip"] = nose
        }
        
        // Mouth
        if let mouth = landmarks.outerLips?.normalizedPoints.first {
            result["mouthCenter"] = mouth
        }
        
        // Face contour (use midpoints for key positions)
        if let faceContour = landmarks.faceContour?.normalizedPoints {
            if faceContour.count >= 17 {
                result["leftCheekbone"] = faceContour[7]  // Left side middle
                result["rightCheekbone"] = faceContour[faceContour.count - 8]  // Right side middle
            }
        }
    }
    
    // MARK: - Facial Geometry Extraction
    
    private func extractFacialGeometry(landmarks: [String: CGPoint]) throws -> FacialGeometry {
        // Validate minimum required landmarks
        let required = ["leftEyeCenter", "rightEyeCenter", "noseTip"]
        for key in required {
            guard landmarks[key] != nil else {
                throw BiometricHasherError.insufficientLandmarks("Missing \(key)")
            }
        }
        
        let leftEye = landmarks["leftEyeCenter"]!
        let rightEye = landmarks["rightEyeCenter"]!
        let nose = landmarks["noseTip"]!
        let mouth = landmarks["mouthCenter"] ?? CGPoint(x: 0.5, y: 0.5)
        let leftCheek = landmarks["leftCheekbone"] ?? CGPoint(x: 0.25, y: 0.4)
        let rightCheek = landmarks["rightCheekbone"] ?? CGPoint(x: 0.75, y: 0.4)
        
        // Compute geometric relationships (distance-invariant)
        let interEyeDistance = distance(leftEye, rightEye)
        let eyeToNoseDistance = distance((leftEye + rightEye) / 2, nose)
        let noseToMouthDistance = distance(nose, mouth)
        let leftEyeToLeftCheekDistance = distance(leftEye, leftCheek)
        let rightEyeToRightCheekDistance = distance(rightEye, rightCheek)
        
        // Normalize by inter-eye distance for scale invariance
        let scale = max(interEyeDistance, 0.001)  // Avoid division by zero
        
        return FacialGeometry(
            interEyeDistance: interEyeDistance,
            eyeToNoseRatio: eyeToNoseDistance / scale,
            noseToMouthRatio: noseToMouthDistance / scale,
            leftEyeToLeftCheekRatio: leftEyeToLeftCheekDistance / scale,
            rightEyeToRightCheekRatio: rightEyeToRightCheekDistance / scale,
            eyeAspectRatio: computeEyeAspectRatio(leftEye: leftEye, rightEye: rightEye, nose: nose),
            faceWidth: abs(rightEyeToRightCheekDistance - leftEyeToLeftCheekDistance)
        )
    }
    
    private func computeEyeAspectRatio(leftEye: CGPoint, rightEye: CGPoint, nose: CGPoint) -> Float {
        let eyeWidth = distance(leftEye, rightEye)
        let eyeHeight = abs(nose.y - ((leftEye.y + rightEye.y) / 2))
        return Float(eyeHeight / max(eyeWidth, 0.001))
    }
    
    // MARK: - Hash Computation
    
    private func computeGeometryHash(geometry: FacialGeometry) -> String {
        // Serialize geometry to deterministic byte representation
        var hasher = SHA256()
        
        // Hash each geometric measurement with fixed precision
        // Use 6 decimal places for consistency
        let measurements = [
            String(format: "%.6f", geometry.interEyeDistance),
            String(format: "%.6f", geometry.eyeToNoseRatio),
            String(format: "%.6f", geometry.noseToMouthRatio),
            String(format: "%.6f", geometry.leftEyeToLeftCheekRatio),
            String(format: "%.6f", geometry.rightEyeToRightCheekRatio),
            String(format: "%.6f", geometry.eyeAspectRatio),
            String(format: "%.6f", geometry.faceWidth)
        ]
        
        let geometryString = measurements.joined(separator: "|")
        
        if let data = geometryString.data(using: .utf8) {
            hasher.update(data: data)
        }
        
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Helper Functions
    
    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> Double {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return sqrt(dx * dx + dy * dy)
    }
}

// MARK: - Data Types

/// Extracted facial geometry measurements
struct FacialGeometry {
    let interEyeDistance: Double
    let eyeToNoseRatio: Double
    let noseToMouthRatio: Double
    let leftEyeToLeftCheekRatio: Double
    let rightEyeToRightCheekRatio: Double
    let eyeAspectRatio: Float
    let faceWidth: Double
}

// MARK: - Error Types

enum BiometricHasherError: LocalizedError {
    case invalidImageFormat(String)
    case noFaceDetected(String)
    case multipleFacesDetected(String)
    case landmarkDetectionFailed(String)
    case insufficientLandmarks(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidImageFormat(let details):
            return "Invalid image format: \(details)"
        case .noFaceDetected(let details):
            return "No face detected: \(details)"
        case .multipleFacesDetected(let details):
            return "Multiple faces detected: \(details)"
        case .landmarkDetectionFailed(let details):
            return "Failed to detect landmarks: \(details)"
        case .insufficientLandmarks(let details):
            return "Insufficient face landmarks: \(details)"
        }
    }
}

// MARK: - Helper Extensions

private extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func / (lhs: CGPoint, rhs: Double) -> CGPoint {
        return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }
}
