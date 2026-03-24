//
//  PasswordManagerTests.swift
//  PasswordManagerTests
//
//  Created by michaels on 2026/3/24.
//

import Testing
import CryptoKit
@testable import PasswordManager

struct CryptoServiceTests {

    // MARK: - Key Derivation Tests

    @Test func testKeyDerivation() async throws {
        let cryptoService = CryptoService.shared
        let password = "testPassword123"
        let salt = cryptoService.generateSalt()

        let key = try cryptoService.deriveKey(from: password, salt: salt)

        // Same password + salt should produce same key
        let key2 = try cryptoService.deriveKey(from: password, salt: salt)
        #expect(key == key2)
    }

    @Test func testDifferentSaltsProduceDifferentKeys() async throws {
        let cryptoService = CryptoService.shared
        let password = "testPassword123"

        let salt1 = cryptoService.generateSalt()
        let salt2 = cryptoService.generateSalt()

        let key1 = try cryptoService.deriveKey(from: password, salt: salt1)
        let key2 = try cryptoService.deriveKey(from: password, salt: salt2)

        #expect(key1 != key2)
    }

    // MARK: - DEK Tests

    @Test func testDEKEncodingDecoding() async throws {
        let cryptoService = CryptoService.shared

        let dek = cryptoService.generateDEK()
        let encodedData = cryptoService.encodeDEK(dek)
        let decodedKey = cryptoService.decodeDEK(encodedData)

        #expect(decodedKey == dek)
    }

    // MARK: - Encryption/Decryption Tests

    @Test func testEncryptDecrypt() async throws {
        let cryptoService = CryptoService.shared
        let key = cryptoService.generateDEK()

        let originalData = "Hello, World!".data(using: .utf8)!
        let encryptedData = try cryptoService.encrypt(originalData, using: key)
        let decryptedData = try cryptoService.decrypt(encryptedData, using: key)

        #expect(originalData == decryptedData)
    }

    @Test func testDifferentKeysCannotDecrypt() async throws {
        let cryptoService = CryptoService.shared
        let key1 = cryptoService.generateDEK()
        let key2 = cryptoService.generateDEK()

        let originalData = "Secret message".data(using: .utf8)!
        let encryptedData = try cryptoService.encrypt(originalData, using: key1)

        // Attempting to decrypt with wrong key should fail
        var decryptError: Error?
        do {
            _ = try cryptoService.decrypt(encryptedData, using: key2)
        } catch {
            decryptError = error
        }
        #expect(decryptError != nil)
    }

    @Test func testEncryptedDataIsDifferent() async throws {
        let cryptoService = CryptoService.shared
        let key = cryptoService.generateDEK()

        let originalData = "Same data".data(using: .utf8)!
        let encrypted1 = try cryptoService.encrypt(originalData, using: key)
        let encrypted2 = try cryptoService.encrypt(originalData, using: key)

        // Each encryption should produce different ciphertext (due to random nonce)
        #expect(encrypted1 != encrypted2)
    }

    // MARK: - DEK Encryption with Master Key

    @Test func testEncryptDecryptDEK() async throws {
        let cryptoService = CryptoService.shared

        let masterKey = cryptoService.generateDEK()
        let dek = cryptoService.generateDEK()

        let encryptedDEK = try cryptoService.encryptDEK(dek, using: masterKey)
        let decryptedDEK = try cryptoService.decryptDEK(encryptedDEK, using: masterKey)

        #expect(decryptedDEK == dek)
    }
}

struct VaultTests {

    @Test func testAddEntry() async throws {
        var vault = Vault()

        let entry = PasswordEntry(
            name: "Test Site",
            username: "user@example.com",
            password: "password123"
        )

        vault.add(entry)

        #expect(vault.entries.count == 1)
        #expect(vault.entries.first?.name == "Test Site")
    }

    @Test func testUpdateEntry() async throws {
        var vault = Vault()

        let entry = PasswordEntry(
            name: "Test Site",
            username: "user@example.com",
            password: "password123"
        )

        vault.add(entry)

        var updatedEntry = entry
        updatedEntry.update(password: "newPassword456")

        vault.update(updatedEntry)

        #expect(vault.entries.count == 1)
        #expect(vault.entries.first?.password == "newPassword456")
    }

    @Test func testDeleteEntry() async throws {
        var vault = Vault()

        let entry = PasswordEntry(
            name: "Test Site",
            username: "user@example.com",
            password: "password123"
        )

        vault.add(entry)
        #expect(vault.entries.count == 1)

        vault.delete(entry)
        #expect(vault.entries.isEmpty)
    }

    @Test func testSearchByName() async throws {
        var vault = Vault()

        vault.add(PasswordEntry(name: "Google", username: "user1", password: "pass1"))
        vault.add(PasswordEntry(name: "GitHub", username: "user2", password: "pass2"))
        vault.add(PasswordEntry(name: "Gmail", username: "user3", password: "pass3"))

        let results = vault.search("G")

        #expect(results.count == 3) // Google, GitHub, Gmail
    }

    @Test func testSearchByUsername() async throws {
        var vault = Vault()

        vault.add(PasswordEntry(name: "Site1", username: "alice@mail.com", password: "pass1"))
        vault.add(PasswordEntry(name: "Site2", username: "bob@mail.com", password: "pass2"))

        let results = vault.search("alice")

        #expect(results.count == 1)
        #expect(results.first?.username == "alice@mail.com")
    }

    @Test func testSearchCaseInsensitive() async throws {
        var vault = Vault()

        vault.add(PasswordEntry(name: "Google", username: "user", password: "pass"))

        let results = vault.search("GOOGLE")

        #expect(results.count == 1)
    }

    @Test func testFindDuplicate() async throws {
        var vault = Vault()

        let entry = PasswordEntry(
            name: "Test Site",
            username: "user@example.com",
            password: "password123"
        )

        vault.add(entry)

        let duplicate = vault.findDuplicate(name: "Test Site", username: "user@example.com")
        #expect(duplicate != nil)

        let notDuplicate = vault.findDuplicate(name: "Other Site", username: "user@example.com")
        #expect(notDuplicate == nil)
    }
}

struct PasswordEntryTests {

    @Test func testPasswordEntryInit() async throws {
        let entry = PasswordEntry(
            name: "Test",
            username: "user@test.com",
            password: "secret",
            url: "https://test.com",
            notes: "Test notes",
            icon: "🔐"
        )

        #expect(entry.name == "Test")
        #expect(entry.username == "user@test.com")
        #expect(entry.password == "secret")
        #expect(entry.url == "https://test.com")
        #expect(entry.notes == "Test notes")
        #expect(entry.icon == "🔐")
        #expect(entry.isFavorite == false)
    }

    @Test func testUniqueKey() async throws {
        let entry1 = PasswordEntry(name: "Test", username: "user@test.com", password: "pass1")
        let entry2 = PasswordEntry(name: "TEST", username: "USER@TEST.COM", password: "pass2")

        // Same name and username (case-insensitive) should produce same key
        #expect(entry1.uniqueKey == entry2.uniqueKey)
    }

    @Test func testUpdateMethod() async throws {
        var entry = PasswordEntry(
            name: "Original",
            username: "original@test.com",
            password: "originalPass"
        )

        entry.update(
            name: "Updated",
            password: "newPass",
            notes: "Added notes"
        )

        #expect(entry.name == "Updated")
        #expect(entry.username == "original@test.com") // unchanged
        #expect(entry.password == "newPass")
        #expect(entry.notes == "Added notes")
    }
}
