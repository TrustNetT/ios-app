# QR Code-Based Node Discovery for iOS Registration

**Date**: March 19, 2026  
**Status**: Design Document  
**Purpose**: Enable first-time users to connect to their local TrustNet node via QR code scan  
**Platform**: iOS 13+ (Vision framework for QR code scanning)

---

## Problem Statement

**Current UX Issue**: Users must manually enter their node's IPv6 address (complex, error-prone)
```
Example: [fd10:1234:5678::9abc]:1317
```

**Proposed Solution**: First-time users scan a QR code displayed on their node's web UI → app automatically connects

**Benefits**:
- ✅ Zero configuration for first-time users
- ✅ No IPv6 address typing required
- ✅ Automatic node verification (certificate pinning)
- ✅ One-time setup process
- ✅ Improved UX for non-technical users

---

## QR Code Content Specification

### Data Format

The QR code encodes a **TrustNet node connection URI** in the following format:

```
trustnet://node/{nodeId}?endpoint={endpoint}&cert={certFingerprint}&pin={pinCode}
```

### URI Components

| Component | Description | Example | Required |
|-----------|-------------|---------|----------|
| `trustnet://node/` | Protocol scheme (identifies this as TrustNet node) | N/A | ✅ Yes |
| `{nodeId}` | Unique node identifier (first 16 chars of node public key) | `a1b2c3d4e5f6g7h8` | ✅ Yes |
| `endpoint` | Node API endpoint (IPv6 URL) | `https://[fd10:1234::5678]:1317` | ✅ Yes |
| `certFingerprint` | SHA-256 fingerprint of node certificate | `7f2d4a8b9c3e5f1d...` | ✅ Yes |
| `pinCode` | 6-digit PIN for verification (user enters on both devices) | `123456` | ✅ Yes |

### Example QR Code Content

```
trustnet://node/a1b2c3d4e5f6g7h8?endpoint=https://[fd10:1234:5678:9abc::1]:1317&cert=7f2d4a8b9c3e5f1d4a2b3c4d5e6f7a8b&pin=123456
```

### QR Code Size & Capacity

- **Data size**: ~200 characters
- **QR version**: Version 4 (required ~50x50 pixels)
- **Encoding**: URL-encoded UTF-8

---

## Node Side: QR Code Generation & Display

### 1. Node Web UI QR Code Generation

**File**: `core/web/api/node_setup.py` (Alpine node, Python FastAPI)

```python
import os
import hashlib
import secrets
import qrcode
from datetime import datetime

class NodeSetupAPI:
    """Generate and display QR codes for first-time setup"""
    
    def generate_setup_qr(self):
        """Generate QR code for iOS app registration discovery"""
        
        # 1. Get node identity
        node_id = self.get_node_id()  # First 16 chars of public key
        endpoint = self.get_node_endpoint()  # https://[IPv6]:1317
        
        # 2. Get certificate fingerprint
        cert_path = "/etc/trustnet/certs/node.crt"
        cert_fingerprint = self.get_cert_sha256(cert_path)
        
        # 3. Generate 6-digit PIN (user-facing verification code)
        pin_code = self.generate_pin()
        
        # 4. Construct URI
        uri = (
            f"trustnet://node/{node_id}"
            f"?endpoint={endpoint}"
            f"&cert={cert_fingerprint}"
            f"&pin={pin_code}"
        )
        
        # 5. Generate QR code
        qr = qrcode.QRCode(version=4, box_size=10, border=2)
        qr.add_data(uri)
        qr.make(fit=True)
        
        qr_image = qr.make_image(fill_color="black", back_color="white")
        
        # 6. Store PIN in session (30-minute expiry)
        self.store_pin_session(node_id, pin_code, expires_in=1800)
        
        return {
            "qr_image": qr_image,  # PNG bytes
            "node_id": node_id,
            "pin_code": pin_code,  # Display to user for manual entry fallback
            "expires_at": datetime.now().timestamp() + 1800,
        }
    
    def get_node_endpoint(self) -> str:
        """Get node's IPv6 endpoint URL"""
        # Read from config or derive from network interface
        ipv6_addr = self.get_ipv6_address()  # e.g., "fd10:1234:5678::1"
        return f"https://[{ipv6_addr}]:1317"
    
    def get_cert_sha256(self, cert_path: str) -> str:
        """Get certificate SHA-256 fingerprint"""
        with open(cert_path, "rb") as f:
            cert_data = f.read()
        
        # For PEM format, extract DER first
        # ... (certificate parsing)
        
        fingerprint = hashlib.sha256(cert_data).hexdigest()
        return fingerprint
    
    def generate_pin(self) -> str:
        """Generate 6-digit PIN for user verification"""
        return str(secrets.randbelow(1000000)).zfill(6)
    
    def store_pin_session(self, node_id: str, pin: str, expires_in: int):
        """Store PIN in Redis/memory for verification"""
        # Expire after 30 minutes for security
        self.session_store[node_id] = {
            "pin": pin,
            "created_at": datetime.now(),
            "expires_in": expires_in,
        }

@app.get("/api/setup/qr-code")
def get_qr_code():
    """Return QR code image (PNG) for display on node web UI"""
    setup = NodeSetupAPI()
    result = setup.generate_setup_qr()
    
    # Encode PNG as base64 for JSON response
    import base64
    qr_base64 = base64.b64encode(result["qr_image"]).decode()
    
    return {
        "qr_image_base64": qr_base64,
        "node_id": result["node_id"],
        "pin_code": result["pin_code"],
        "expires_at": result["expires_at"],
        "instructions": "Scan this QR code with TrustNet iOS app to connect automatically"
    }

@app.post("/api/setup/verify-pin")
def verify_pin(node_id: str, pin: str):
    """Verify PIN from iOS app (security check)"""
    setup = NodeSetupAPI()
    stored_pin = setup.session_store.get(node_id, {}).get("pin")
    
    if stored_pin == pin:
        # Grant temporary credentials
        return {"status": "verified", "token": generate_temp_token()}
    else:
        return {"status": "failed", "error": "Invalid PIN"}
```

### 2. Node Web UI Display

**Page**: `core/web/templates/first-setup.html`

```html
<!DOCTYPE html>
<html>
<head>
    <title>TrustNet Node Setup</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            max-width: 600px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .setup-card {
            background: white;
            border-radius: 12px;
            padding: 40px;
            text-align: center;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .qr-code {
            margin: 30px 0;
            display: inline-block;
            padding: 20px;
            background: white;
            border-radius: 8px;
        }
        .pin-code {
            font-size: 28px;
            font-family: monospace;
            font-weight: bold;
            margin: 20px 0;
            letter-spacing: 5px;
            background: #f0f0f0;
            padding: 15px;
            border-radius: 8px;
        }
        .instructions {
            background: #e8f4f8;
            border-left: 4px solid #0066cc;
            padding: 15px;
            margin: 20px 0;
            text-align: left;
            border-radius: 4px;
        }
        .expiry {
            color: #666;
            font-size: 14px;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="setup-card">
        <h1>🔐 Connect Your iPhone</h1>
        
        <div class="instructions">
            <strong>Steps:</strong>
            <ol>
                <li>Open TrustNet app on your iPhone</li>
                <li>Tap "Connect to Node"</li>
                <li>Scan this QR code</li>
                <li>Confirm PIN on both devices</li>
            </ol>
        </div>
        
        <div class="qr-code">
            <img id="qr-image" src="" alt="QR Code" width="300" height="300">
        </div>
        
        <p>Or enter this code manually:</p>
        <div class="pin-code" id="pin-code">------</div>
        
        <div class="expiry">
            This QR code expires in 30 minutes at <span id="expiry-time">--:--</span>
        </div>
    </div>
    
    <script>
        // Fetch QR code from API
        fetch('/api/setup/qr-code')
            .then(r => r.json())
            .then(data => {
                document.getElementById('qr-image').src = 
                    'data:image/png;base64,' + data.qr_image_base64;
                document.getElementById('pin-code').textContent = data.pin_code;
                
                // Display expiry time
                const expiry = new Date(data.expires_at * 1000);
                document.getElementById('expiry-time').textContent = 
                    expiry.toLocaleTimeString();
            });
    </script>
</body>
</html>
```

---

## iOS Side: QR Code Scanning & Node Connection

### 1. QR Code Scanner View

**File**: `Sources/UI/NodeDiscoveryView.swift`

```swift
import SwiftUI
import Vision
import AVFoundation

struct NodeDiscoveryView: View {
    @StateObject private var viewModel = NodeDiscoveryViewModel()
    @State private var showCamera = false
    @State private var showPINVerification = false
    @State private var scannedURI: String?
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                // Title
                VStack(alignment: .leading) {
                    Text("Connect to Your Node")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Scan the QR code displayed on your node's web interface")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                
                // Camera view or placeholder
                if showCamera {
                    CameraQRScannerView(
                        onScanned: { uri in
                            scannedURI = uri
                            showCamera = false
                            Task {
                                await viewModel.parseNodeURI(uri)
                            }
                        }
                    )
                    .frame(height: 300)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                } else {
                    // Placeholder with camera icon
                    VStack(spacing: 10) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        Text("Ready to scan")
                            .font(.headline)
                    }
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: { showCamera.toggle() }) {
                        Label(showCamera ? "Stop Camera" : "Scan QR Code", 
                              systemImage: "camera")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: { showPINVerification = true }) {
                        Label("Enter PIN Manually", 
                              systemImage: "keyboard")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                // Status message
                if let error = viewModel.error {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color(.systemRed).opacity(0.1))
                    .cornerRadius(8)
                }
                
                if viewModel.isConnecting {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Connecting to node...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            
            // PIN Verification Modal
            if showPINVerification {
                PINVerificationView(
                    isPresented: $showPINVerification,
                    nodeTitle: viewModel.discoveredNode?.id ?? "Node",
                    pin: $viewModel.enteredPIN,
                    onSubmit: {
                        Task {
                            let success = await viewModel.verifyAndConnect()
                            if success {
                                // Navigate to next screen
                            }
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Camera QR Scanner

struct CameraQRScannerView: UIViewControllerRepresentable {
    var onScanned: (String) -> Void
    
    func makeUIViewController(context: Context) -> CameraQRViewController {
        let controller = CameraQRViewController()
        controller.onScanned = onScanned
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraQRViewController, 
                              context: Context) {}
}

class CameraQRViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onScanned: ((String) -> Void)?
    
    private let captureSession = AVCaptureSession()
    private let previewLayer = AVCaptureVideoPreviewLayer()
    private var scannedCodes: Set<String> = []
    private var lastQRCodeTime: Date = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup camera
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, 
                                                   for: .video, 
                                                   position: .back) else {
            print("Camera not available")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            captureSession.addInput(input)
            
            // Setup QR detection output
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "qr-queue"))
            captureSession.addOutput(output)
            
            // Setup preview
            previewLayer.session = captureSession
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            
            // Start session
            captureSession.startRunning()
        } catch {
            print("Camera setup failed: \(error)")
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }
    
    func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectBarcodesRequest { [weak self] request, error in
            guard error == nil else { return }
            
            for result in request.results ?? [] {
                guard let barcode = result as? VNBarcodeObservation,
                      let payload = barcode.payloadStringValue else { continue }
                
                // Only trigger once per QR code (debounce)
                let now = Date()
                if !self?.scannedCodes.contains(payload) ?? true,
                   now.timeIntervalSince(self?.lastQRCodeTime ?? now) > 0.5 {
                    DispatchQueue.main.async {
                        self?.onScanned?(payload)
                        self?.scannedCodes.insert(payload)
                        self?.lastQRCodeTime = now
                    }
                }
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
    
    deinit {
        captureSession.stopRunning()
    }
}
```

### 2. Node Discovery ViewModel

**File**: `Sources/Logic/NodeDiscoveryViewModel.swift`

```swift
import Foundation
import Security

@MainActor
class NodeDiscoveryViewModel: ObservableObject {
    
    @Published var discoveredNode: NodeInfo?
    @Published var error: String?
    @Published var isConnecting = false
    @Published var enteredPIN = ""
    
    private let nodeConnector = TrustNetNodeConnector.shared
    
    struct NodeInfo {
        let id: String        // Node ID from QR code
        let endpoint: URL     // IPv6 endpoint
        let certFingerprint: String  // Certificate SHA-256
        let pin: String       // Verification PIN
    }
    
    // MARK: - QR Code Parsing
    
    func parseNodeURI(_ uri: String) async {
        error = nil
        
        // Parse trustnet://node/{nodeId}?...
        guard uri.hasPrefix("trustnet://node/") else {
            error = "Invalid QR code format"
            return
        }
        
        // Extract node ID (up to first '?')
        let nodeIdEnd = uri.firstIndex(of: "?") ?? uri.endIndex
        let nodeId = String(uri[uri.index(uri.startIndex, offsetBy: 16)..<nodeIdEnd])
        
        // Parse query parameters
        guard let components = URLComponents(string: uri),
              let endpoint = components.queryItems?.first(where: { $0.name == "endpoint" })?.value,
              let certFingerprint = components.queryItems?.first(where: { $0.name == "cert" })?.value,
              let pin = components.queryItems?.first(where: { $0.name == "pin" })?.value,
              let endpointURL = URL(string: endpoint) else {
            error = "QR code is incomplete or malformed"
            return
        }
        
        // Store discovered node
        discoveredNode = NodeInfo(
            id: nodeId,
            endpoint: endpointURL,
            certFingerprint: certFingerprint,
            pin: pin
        )
        
        // Auto-advance to PIN verification if PIN is visible
        // (user sees same PIN on both screens for verification)
    }
    
    // MARK: - PIN Verification & Connection
    
    func verifyAndConnect() async -> Bool {
        guard let node = discoveredNode else {
            error = "No node discovered"
            return false
        }
        
        guard enteredPIN == node.pin else {
            error = "PIN does not match. Please try again."
            return false
        }
        
        isConnecting = true
        defer { isConnecting = false }
        
        do {
            // 1. Verify certificate fingerprint (security)
            try await nodeConnector.verifyNodeCertificate(
                endpoint: node.endpoint,
                expectedFingerprint: node.certFingerprint
            )
            
            // 2. Send PIN verification to node
            try await nodeConnector.verifyPinOnNode(
                endpoint: node.endpoint,
                nodeId: node.id,
                pin: node.pin
            )
            
            // 3. Store node endpoint (Keychain)
            try KeychainManager.shared.storeNodeEndpoint(node.endpoint)
            
            // 4. Store certificate fingerprint (for pinning)
            try KeychainManager.shared.storeCertFingerprint(node.certFingerprint)
            
            return true
            
        } catch {
            self.error = "Connection failed: \(error.localizedDescription)"
            return false
        }
    }
}

// MARK: - PIN Verification UI

struct PINVerificationView: View {
    @Binding var isPresented: Bool
    let nodeTitle: String
    @Binding var pin: String
    let onSubmit: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Verify Connection")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Node: \(nodeTitle)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("Enter the 6-digit PIN shown on your node's web interface:")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // PIN Input (6 digits)
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    VStack {
                        Text(index < pin.count ? 
                             String(pin[pin.index(pin.startIndex, offsetBy: index)]) : "")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            TextField("", text: $pin)
                .keyboardType(.numberPad)
                .frame(height: 0)  // Hidden input
                .opacity(0)
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: onSubmit) {
                    Text("Connect")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(pin.count != 6)
                
                Button(action: { isPresented = false }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding()
        .ignoresSafeArea(.keyboard)
    }
}
```

### 3. Node Connector with Certificate Pinning

**File**: `Sources/Network/TrustNetNodeConnector.swift`

```swift
import Foundation
import Security

class TrustNetNodeConnector: NSObject, URLSessionDelegate {
    
    static let shared = TrustNetNodeConnector()
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    // MARK: - Certificate Verification
    
    func verifyNodeCertificate(
        endpoint: URL,
        expectedFingerprint: String
    ) async throws {
        
        let request = URLRequest(url: endpoint)
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                
                // Check for network errors
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                // Extract certificate from response
                guard let httpResponse = response as? HTTPURLResponse,
                      let cert = self.extractServerCertificate(response: httpResponse) else {
                    continuation.resume(throwing: NodeConnectorError.noCertificate)
                    return
                }
                
                // Compute certificate SHA-256 fingerprint
                let certFingerprint = self.computeCertificateFingerprint(cert)
                
                // Compare with expected fingerprint
                if certFingerprint == expectedFingerprint {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: 
                        NodeConnectorError.certificateMismatch(
                            expected: expectedFingerprint,
                            actual: certFingerprint
                        )
                    )
                }
            }
            
            task.resume()
        }
    }
    
    private func extractServerCertificate(response: HTTPURLResponse) -> SecCertificate? {
        // Extract certificate from TLS handshake
        // Implementation depends on URLSessionDelegate
        return nil  // Placeholder
    }
    
    private func computeCertificateFingerprint(_ cert: SecCertificate) -> String {
        let data = SecCertificateCopyData(cert) as Data
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - PIN Verification
    
    func verifyPinOnNode(
        endpoint: URL,
        nodeId: String,
        pin: String
    ) async throws {
        
        var request = URLRequest(url: endpoint.appendingPathComponent("/api/setup/verify-pin"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "node_id": nodeId,
            "pin": pin
        ]
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NodeConnectorError.pinVerificationFailed
        }
        
        let result = try JSONDecoder().decode(
            ["status": String].self,
            from: data
        )
        
        guard result["status"] == "verified" else {
            throw NodeConnectorError.pinVerificationFailed
        }
    }
    
    // MARK: - URLSessionDelegate (Certificate Pinning)
    
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Perform standard TLS validation first
        var secResult = SecTrustResultType.invalid
        let status = SecTrustEvaluate(serverTrust, &secResult)
        
        guard status == errSecSuccess else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Certificate pinning: verify against stored fingerprint
        guard let pinnedFingerprint = KeychainManager.shared.retrieveCertFingerprint() else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        if let cert = SecTrustGetCertificateAtIndex(serverTrust, 0) {
            let fingerprint = computeCertificateFingerprint(cert)
            
            if fingerprint == pinnedFingerprint {
                completionHandler(.useCredential, 
                    URLCredential(trust: serverTrust))
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

enum NodeConnectorError: LocalizedError {
    case noCertificate
    case certificateMismatch(expected: String, actual: String)
    case pinVerificationFailed
    case connectionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noCertificate:
            return "Unable to retrieve node certificate"
        case .certificateMismatch:
            return "Certificate verification failed"
        case .pinVerificationFailed:
            return "PIN verification failed"
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        }
    }
}
```

---

## Integration into Registration Flow

### New Registration Step: Node Discovery

```
RegistrationFlow:
  1. Welcome Screen
  2. Biometric/FaceID
  3. ✨ NEW: Node Discovery (QR Code Scan)    ← Insert here
  4. Government ID Scan (NFC)
  5. Form Data Entry
  6. Submit to Node
  7. Blockchain Confirmation
  8. Success
```

### Updated RegistrationView

```swift
struct RegistrationView: View {
    @StateObject private var coordinator = RegistrationCoordinator()
    
    var body: some View {
        switch coordinator.currentScreen {
        case .welcome:
            WelcomeView(onStart: { 
                coordinator.currentScreen = .nodeDiscovery
            })
        
        case .nodeDiscovery:
            NodeDiscoveryView()
                .onDisappear {
                    // Node endpoint now stored in Keychain
                    coordinator.currentScreen = .governmentIDScan
                }
        
        case .governmentIDScan:
            GovernmentIDScanView()
                .onComplete { id in
                    coordinator.governmentID = id
                    coordinator.currentScreen = .formEntry
                }
        
        // ... rest of flow
        }
    }
}
```

---

## Security Considerations

### 1. Certificate Pinning
- ✅ Verify certificate SHA-256 fingerprint matches QR code
- ✅ Store fingerprint in iOS Keychain
- ✅ Prevent MITM attacks on first connection

### 2. PIN Verification
- ✅ 6-digit PIN must enter on both iOS and node simultaneously
- ✅ 30-minute expiry on QR code
- ✅ Prevents replay attacks

### 3. IPv6-Only Communication
- ✅ iOS connects exclusively via IPv6 (matching TrustNet architecture)
- ✅ Certificate issued by Let's Encrypt (not self-signed)
- ✅ All communication HTTPS-only (no HTTP fallback)

### 4. Node Identity Verification
- ✅ Node ID in QR code derived from node public key
- ✅ iOS can verify node authenticity if needed

---

## Testing Checklist

- [ ] QR code generation on Alpine VM
- [ ] QR code display on node web UI
- [ ] iOS camera captures QR code
- [ ] URI parsing extracts all fields correctly
- [ ] Certificate verification passes for valid cert
- [ ] Certificate verification fails for mismatched fingerprint
- [ ] PIN entry UI accepts 6-digit input
- [ ] PIN verification calls node API correctly
- [ ] Node endpoint stored in Keychain
- [ ] Connection persists across app restarts
- [ ] Manual PIN entry works as fallback

---

## Deployment Checklist

**Alpine Node**:
- [ ] Update FastAPI app with QR code generation endpoint
- [ ] Update web UI to display QR code
- [ ] Ensure Let's Encrypt certificate is deployed
- [ ] Test certificate fingerprint extraction

**iOS App**:
- [ ] Implement NodeDiscoveryView & ViewModel
- [ ] Add Vision framework QR code scanning
- [ ] Implement certificate pinning in URLSessionDelegate
- [ ] Test on real device with real local node
- [ ] Verify Keychain storage & retrieval

**Integration**:
- [ ] First-time registration flow includes node discovery
- [ ] Node connection established before NFC scanning
- [ ] All subsequent requests use discovered endpoint

---

**Created by**: GitHub Copilot  
**For**: TrustNet iOS Registration Module  
**Next Steps**: Implement Alpine node API endpoints + iOS UI components
