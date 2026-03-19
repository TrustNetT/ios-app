import Foundation
import CoreNFC
import UIKit

/// Reads government ID data from NFC chip and orchestrates complete registration flow
/// Integrates all Phase 1 components: ICAO validator, biometric hasher, key generator, keychain
public class GovernmentIDScanner: NSObject, NFCTagReaderSessionDelegate {
    
    private var nfcSession: NFCTagReaderSession?
    private var completionHandler: ((Result<RegistrationData, GovernmentIDScannerError>) -> Void)?
    
    // Phase 1 dependencies
    private let validator = ICAO9303Validator()
    private let biometricHasher = BiometricHasher()
    private let keyGenerator = KeyGenerator()
    private let keychainManager = KeychainManager()
    
    /// Start scanning government ID via NFC
    /// - Parameter completion: Called with RegistrationData on success or error on failure
    public func beginScan(completion: @escaping (Result<RegistrationData, GovernmentIDScannerError>) -> Void) {
        self.completionHandler = completion
        
        // Verify NFC is available
        guard NFCTagReaderSession.readingAvailable else {
            completion(.failure(.nfcNotAvailable))
            return
        }
        
        // Create NFC session
        nfcSession = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)
        nfcSession?.alertMessage = "Hold your government ID near the top of your iPhone"
        nfcSession?.begin()
    }
    
    /// Cancel an active NFC scan
    public func cancelScan() {
        nfcSession?.invalidate()
        nfcSession = nil
    }
    
    // MARK: - NFCTagReaderSessionDelegate
    
    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        // Session started, waiting for user to scan
    }
    
    public func tagReaderSession(
        _ session: NFCTagReaderSession,
        didInvalidateWithError error: Error
    ) {
        nfcSession = nil
        
        if let nfcError = error as? NFCReaderError {
            let scanError: GovernmentIDScannerError = nfcError.code == .readerSessionInvalidationErrorSessionTimeout ?
                .nfcTimeout : .nfcReadingFailed
            completionHandler?(.failure(scanError))
        } else {
            completionHandler?(.failure(.nfcReadingFailed))
        }
    }
    
    public func tagReaderSession(
        _ session: NFCTagReaderSession,
        didDetect tags: [NFCTag]
    ) {
        // Process first tag
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "No tag detected")
            return
        }
        
        // Connect to tag
        session.connect(to: tag) { [weak self] error in
            if let error = error {
                session.invalidate(errorMessage: "Failed to connect to ID")
                self?.completionHandler?(.failure(.nfcReadingFailed))
                return
            }
            
            // Process the ID data
            self?.processNFCTag(tag, session: session)
        }
    }
    
    // MARK: - NFC Processing
    
    private func processNFCTag(_ tag: NFCTag, session: NFCTagReaderSession) {
        do {
            // Extract ICAO 9303 data from NFC chip
            let governmentID = try extractGovernmentID(from: tag)
            
            // Validate government signature using Phase 1A
            let signatureValid = try validator.validate(
                data: governmentID.documentNumber.data(using: .utf8) ?? Data(),
                signature: governmentID.governmentSignature,
                countryCode: governmentID.countryCode
            )
            
            guard signatureValid else {
                throw GovernmentIDScannerError.invalidSignature
            }
            
            // Extract and hash biometric using Phase 1B
            let biometricHash = try biometricHasher.hashBiometric(from: governmentID.idPhoto)
            
            // Generate keypair and UserID using Phase 1C
            let (privateKey, publicKey, userID) = try keyGenerator.generateKeypair(
                for: governmentID,
                with: biometricHash
            )
            
            // Store private key securely using Phase 1D
            try keychainManager.storePrivateKey(
                privateKey.rawRepresentation,
                for: userID,
                requireBiometric: false // User can enable in settings
            )
            
            // Create registration data
            let publicKeyPEM = try keyGenerator.publicKeyToPEM(publicKey)
            let registrationData = RegistrationData(
                userID: userID,
                governmentID: governmentID,
                biometricHash: biometricHash,
                publicKeyPEM: publicKeyPEM,
                timestamp: Date()
            )
            
            session.alertMessage = "Registration data captured successfully"
            session.invalidate()
            
            completionHandler?(.success(registrationData))
            
        } catch let error as GovernmentIDScannerError {
            session.invalidate(errorMessage: error.errorDescription ?? "Scan failed")
            completionHandler?(.failure(error))
        } catch let error as ICAO9303Error {
            session.invalidate(errorMessage: "Invalid government ID signature")
            completionHandler?(.failure(.invalidSignature))
        } catch let error as BiometricHasherError {
            session.invalidate(errorMessage: "Could not process face photo")
            completionHandler?(.failure(.biometricProcessingFailed))
        } catch let error as KeyGeneratorError {
            session.invalidate(errorMessage: "Failed to generate keys")
            completionHandler?(.failure(.keyGenerationFailed))
        } catch let error as KeychainError {
            session.invalidate(errorMessage: "Failed to store keys securely")
            completionHandler?(.failure(.keychainStorageError))
        } catch {
            session.invalidate(errorMessage: "Unexpected error during scan")
            completionHandler?(.failure(.unknownError))
        }
    }
    
    // MARK: - ICAO 9303 Data Extraction
    
    /// Extract government ID data from NFC tag (ICAO 9303 format)
    /// ICAO 9303 is international standard for machine-readable travel documents (MRTDs)
    /// Structure: Data groups (DG1-DG16) with biometric and signature data
    private func extractGovernmentID(from tag: NFCTag) throws -> GovernmentID {
        // In real implementation, this would:
        // 1. Select MRZ data file (0x1F20 for passports)
        // 2. Read Document Group 1 (DG1) - personal data
        // 3. Read Document Group 2 (DG2) - face photo
        // 4. Read Security Object (DG13) - signature
        // 5. Read AP DO (0x06) - access control
        
        // For Phase 2, we'll extract from the ISO14443 data structure
        // Pseudocode for real implementation:
        guard case let .iso7816(iso7816Tag) = tag else {
            throw GovernmentIDScannerError.nfcReadingFailed
        }
        
        // Read certificate (contains public key for signature validation)
        let certificateData = try readNFCDataGroup(iso7816Tag, groupID: 14)
        
        // Read DG1 (document information)
        let dg1Data = try readNFCDataGroup(iso7816Tag, groupID: 1)
        
        // Parse MRZ (Machine Readable Zone) from DG1
        let mrz = try parseMRZ(from: dg1Data)
        
        // Read DG2 (face photo)
        let photoData = try readNFCDataGroup(iso7816Tag, groupID: 2)
        let facePhoto = UIImage(data: photoData)?
            .jpegData(compressionQuality: 0.95) ?? photoData
        
        // Read signature (typically in SOD - Security Object Data)
        let signatureData = try readNFCDataGroup(iso7816Tag, groupID: 13)
        
        return GovernmentID(
            fullName: mrz.fullName,
            dateOfBirth: mrz.dateOfBirth,
            documentNumber: mrz.documentNumber,
            countryCode: mrz.countryCode,
            biometricTemplate: facePhoto,
            governmentSignature: signatureData,
            isValid: true,
            idPhoto: facePhoto
        )
    }
    
    /// Read data group from NFC tag
    private func readNFCDataGroup(
        _ tag: NFCISO7816Tag,
        groupID: UInt8
    ) throws -> Data {
        // APDU command to select file and read data
        // SELECT FILE: INS=A4, P1=02 (file selection), P2=0C (return FCI template)
        // READ BINARY: INS=B0
        
        // Command to select Data Group
        let selectAPDU = NFCISO7816APDU(
            instructionClass: 0x00,
            instructionCode: 0xA4,  // SELECT FILE
            p1Parameter: 0x02,      // Select by file identifier
            p2Parameter: 0x0C,      // Return FCI template
            data: Data([0x01, 0x01, groupID]),  // DGx identifier
            expectedResponseLength: 256
        )
        
        var readData = Data()
        var offset = 0
        let maxRead = 256
        
        // Read all bytes from selected file
        while true {
            let readAPDU = NFCISO7816APDU(
                instructionClass: 0x00,
                instructionCode: 0xB0,  // READ BINARY
                p1Parameter: UInt8((offset >> 8) & 0xFF),
                p2Parameter: UInt8(offset & 0xFF),
                expectedResponseLength: maxRead
            )
            
            let response = try tag.sendCommand(apdu: readAPDU)
            
            // Check for EOF or error
            guard response.count >= 2 else { break }
            
            let statusByte1 = response[response.count - 2]
            let statusByte2 = response[response.count - 1]
            
            // If status is 0x9000 (success) or 0x6100 (more data available)
            if statusByte1 == 0x90 || statusByte1 == 0x61 {
                readData.append(contentsOf: response.dropLast(2))
                offset += response.count - 2
                
                if statusByte1 == 0x90 { break }  // 0x9000 = success, no more data
            } else {
                break
            }
        }
        
        return readData
    }
    
    /// Parse Machine Readable Zone (MRZ) from DG1 data
    private func parseMRZ(from data: Data) throws -> MRZData {
        // MRZ is encoded in specific TLV (Tag-Length-Value) format
        // Extract and parse structured data
        
        let decoder = TLVDecoder(data: data)
        
        guard let fullName = try decoder.decode(tag: 0x5F34) as? String,
              let documentNumber = try decoder.decode(tag: 0x44) as? String,
              let countryCode = try decoder.decode(tag: 0x5F28) as? String,
              let dateOfBirthStr = try decoder.decode(tag: 0x5F35) as? String
        else {
            throw GovernmentIDScannerError.invalidGovernmentID
        }
        
        // Parse date (YYMMDD format)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd"
        guard let dateOfBirth = dateFormatter.date(from: dateOfBirthStr) else {
            throw GovernmentIDScannerError.invalidGovernmentID
        }
        
        return MRZData(
            fullName: fullName,
            documentNumber: documentNumber,
            countryCode: countryCode,
            dateOfBirth: dateOfBirth
        )
    }
    
    // MARK: - Helpers
    
    private struct MRZData {
        let fullName: String
        let documentNumber: String
        let countryCode: String
        let dateOfBirth: Date
    }
}

/// Complete registration data ready for blockchain submission
public struct RegistrationData: Codable {
    public let userID: String                  // TrustNet identifier (TN_...)
    public let governmentID: GovernmentID      // Full government ID info
    public let biometricHash: BiometricHash    // Facial geometry hash
    public let publicKeyPEM: String            // Public key for blockchain
    public let timestamp: Date                 // Registration time
    
    public init(
        userID: String,
        governmentID: GovernmentID,
        biometricHash: BiometricHash,
        publicKeyPEM: String,
        timestamp: Date
    ) {
        self.userID = userID
        self.governmentID = governmentID
        self.biometricHash = biometricHash
        self.publicKeyPEM = publicKeyPEM
        self.timestamp = timestamp
    }
    
    /// Prepare for blockchain submission (signing with private key)
    public func sign(using keychainManager: KeychainManager) throws -> SignedRegistration {
        let privateKeyData = try keychainManager.retrievePrivateKey(for: userID)
        let privateKey = try P256.Signing.PrivateKey(rawRepresentation: privateKeyData)
        
        // Sign the registration data
        let jsonData = try JSONEncoder().encode(self)
        let signature = try privateKey.signature(for: jsonData)
        
        return SignedRegistration(
            registrationData: self,
            signature: signature.rawRepresentation.base64EncodedString()
        )
    }
}

/// Registration signed with private key, ready for blockchain
public struct SignedRegistration: Codable {
    public let registrationData: RegistrationData
    public let signature: String  // Base64-encoded signature
}

// MARK: - Error Types

public enum GovernmentIDScannerError: LocalizedError {
    case nfcNotAvailable
    case nfcReadingFailed
    case nfcTimeout
    case invalidGovernmentID
    case invalidSignature
    case biometricProcessingFailed
    case keyGenerationFailed
    case keychainStorageError
    case keyRetrievalFailed
    case documentAlreadyRegistered
    case userCancelled
    case unknownError
    
    public var errorDescription: String? {
        switch self {
        case .nfcNotAvailable:
            return "NFC is not available on this device"
        case .nfcReadingFailed:
            return "Failed to read government ID"
        case .nfcTimeout:
            return "Government ID scanning timed out"
        case .invalidGovernmentID:
            return "Government ID data is invalid"
        case .invalidSignature:
            return "Government ID signature validation failed"
        case .biometricProcessingFailed:
            return "Could not process facial biometric"
        case .keyGenerationFailed:
            return "Failed to generate cryptographic keys"
        case .keychainStorageError:
            return "Failed to store keys securely"
        case .keyRetrievalFailed:
            return "Failed to retrieve keys for signing"
        case .documentAlreadyRegistered:
            return "This government ID has already been registered"
        case .userCancelled:
            return "User cancelled NFC scan"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .nfcNotAvailable:
            return "This device does not support NFC. Use an iPhone 14 or later (XS, 11+)."
        case .nfcReadingFailed:
            return "Hold your government ID flat near the top of your iPhone and try again."
        case .nfcTimeout:
            return "Hold the ID still for longer. Try again with a steadier hand."
        case .invalidGovernmentID:
            return "Check that your government ID is valid and the NFC chip is not damaged."
        case .invalidSignature:
            return "Government ID signature verification failed. Contact support."
        case .biometricProcessingFailed:
            return "The face photo could not be processed. Try scanning again."
        case .keyGenerationFailed:
            return "Cryptographic key generation failed. Try again."
        case .keychainStorageError:
            return "Could not store keys securely. Unlock device and try again."
        case .keyRetrievalFailed:
            return "Could not access stored keys. Your device may be locked."
        case .documentAlreadyRegistered:
            return "This government ID has already been registered. Use a different ID."
        case .userCancelled:
            return "Try scanning your government ID again."
        case .unknownError:
            return "An unexpected error occurred. Please try again."
        }
    }
}

// MARK: - TLV Decoder Helper

private class TLVDecoder {
    private let data: Data
    private var offset: Int = 0
    
    init(data: Data) {
        self.data = data
    }
    
    func decode(tag: UInt8) throws -> Any? {
        var currentOffset = 0
        while currentOffset < data.count {
            let currentTag = data[currentOffset]
            currentOffset += 1
            
            guard currentOffset < data.count else { return nil }
            let length = Int(data[currentOffset])
            currentOffset += 1
            
            if currentTag == tag {
                let valueData = data.subdata(in: currentOffset..<currentOffset + length)
                if let stringValue = String(data: valueData, encoding: .utf8) {
                    return stringValue
                }
                return valueData
            }
            
            currentOffset += length
        }
        return nil
    }
}
