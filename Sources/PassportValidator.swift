import Foundation
import CryptoKit

public class PassportValidator {
    public init() {}
    
    public func validateSignature(
        documentData: Data,
        signature: Data,
        publicKey: Data
    ) throws -> Bool {
        let digest = SHA256.hash(data: documentData)
        let key = try P256.Signing.PublicKey(rawRepresentation: publicKey)
        let sig = try P256.Signing.ECDSASignature(rawRepresentation: signature)
        return key.isValidSignature(sig, for: Data(digest))
    }
}
