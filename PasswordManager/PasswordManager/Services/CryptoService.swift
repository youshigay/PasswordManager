//
//  CryptoService.swift
//  PasswordManager
//
//  Created by michaels on 2026/3/24.
//

import Foundation
import CryptoKit
import CommonCrypto

enum CryptoError: Error {
    case encryptionFailed
    case decryptionFailed
    case invalidData
    case keyDerivationFailed
}

class CryptoService {
    static let shared = CryptoService()
    private init() {}

    // MARK: - Key Derivation (PBKDF2)

    func deriveKey(from password: String, salt: Data) throws -> SymmetricKey {
        guard let passwordData = password.data(using: .utf8) else {
            throw CryptoError.keyDerivationFailed
        }

        let derivedKeyData = try PBKDF2.derive(
            password: passwordData,
            salt: salt,
            iterations: Constants.Security.pbkdf2Iterations,
            keyLength: Constants.Security.keyLength
        )

        return SymmetricKey(data: derivedKeyData)
    }

    func generateSalt() -> Data {
        var salt = Data(count: Constants.Security.saltLength)
        _ = salt.withUnsafeMutableBytes { saltBytes in
            guard let baseAddress = saltBytes.baseAddress else { return }
            _ = SecRandomCopyBytes(kSecRandomDefault, Constants.Security.saltLength, baseAddress)
        }
        return salt
    }

    // MARK: - DEK Generation

    func generateDEK() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }

    func encodeDEK(_ key: SymmetricKey) -> Data {
        return key.withUnsafeBytes { Data($0) }
    }

    func decodeDEK(_ data: Data) -> SymmetricKey {
        return SymmetricKey(data: data)
    }

    // MARK: - AES-GCM Encryption

    func encrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw CryptoError.encryptionFailed
        }
        return combined
    }

    func decrypt(_ combinedData: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
        return try AES.GCM.open(sealedBox, using: key)
    }

    // MARK: - DEK Encryption with Master Key

    func encryptDEK(_ dek: SymmetricKey, using masterKey: SymmetricKey) throws -> Data {
        let dekData = encodeDEK(dek)
        return try encrypt(dekData, using: masterKey)
    }

    func decryptDEK(_ encryptedDEK: Data, using masterKey: SymmetricKey) throws -> SymmetricKey {
        let dekData = try decrypt(encryptedDEK, using: masterKey)
        return decodeDEK(dekData)
    }

    // MARK: - Vault Encryption

    func encryptVault(_ vault: Vault, using dek: SymmetricKey) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(vault)
        return try encrypt(jsonData, using: dek)
    }

    func decryptVault(_ data: Data, using dek: SymmetricKey) throws -> Vault {
        let jsonData = try decrypt(data, using: dek)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Vault.self, from: jsonData)
    }
}

// MARK: - PBKDF2 Implementation

private enum PBKDF2 {
    static func derive(password: Data, salt: Data, iterations: Int, keyLength: Int) throws -> Data {
        var derivedKey = Data(count: keyLength)
        let derivationStatus = derivedKey.withUnsafeMutableBytes { derivedKeyBytes in
            salt.withUnsafeBytes { saltBytes in
                password.withUnsafeBytes { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        password.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedKeyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        keyLength
                    )
                }
            }
        }

        guard derivationStatus == kCCSuccess else {
            throw CryptoError.keyDerivationFailed
        }

        return derivedKey
    }
}
