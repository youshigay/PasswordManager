//
//  BiometricService.swift
//  PasswordManager
//
//  Created by michaels on 2026/3/24.
//

import Foundation
import LocalAuthentication

enum BiometricType {
    case none
    case touchID
    case faceID
}

enum BiometricError: Error, LocalizedError {
    case notAvailable
    case authenticationFailed
    case userCancel
    case userFallback

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "生物识别不可用"
        case .authenticationFailed:
            return "认证失败"
        case .userCancel:
            return "用户取消"
        case .userFallback:
            return "用户选择其他方式"
        }
    }
}

class BiometricService {
    static let shared = BiometricService()
    private init() {}

    // MARK: - Biometric Type Detection

    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        default:
            return .none
        }
    }

    var isBiometricAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    var biometricTypeName: String {
        switch biometricType {
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        case .none:
            return "生物识别"
        }
    }

    // MARK: - Authentication

    func authenticate(reason: String = "解锁密码管理器") async throws -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "使用主密码"
        context.localizedFallbackTitle = "使用主密码"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw BiometricError.notAvailable
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch let error as LAError {
            switch error.code {
            case .userCancel:
                throw BiometricError.userCancel
            case .userFallback:
                throw BiometricError.userFallback
            case .authenticationFailed:
                throw BiometricError.authenticationFailed
            default:
                throw BiometricError.authenticationFailed
            }
        }
    }
}
