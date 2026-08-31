//  User.swift
//  SpectraCrop
//
//  Created by SpectraCrop Development Team
//  Copyright © 2026 SpectraCrop. All rights reserved.
//

import Foundation

// MARK: - User Model

struct User: Identifiable, Codable {
    let id: UUID
    var username: String
    var sessionId: String
    var createdAt: Date
    var lastLoginAt: Date?
    
    // MARK: - Initializers
    
    init(id: UUID = UUID(),
         username: String,
         sessionId: String,
         createdAt: Date = Date(),
         lastLoginAt: Date? = nil) {
        self.id = id
        self.username = username
        self.sessionId = sessionId
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
    }
    
    // MARK: - CodingKeys
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case sessionId
        case createdAt
        case lastLoginAt
    }
}

// MARK: - User DTO for API responses

struct UserDTO: Codable {
    let id: String?
    let username: String
    let sessionId: String
    
    // Convert to User model
    func toUser() -> User {
        return User(
            id: UUID(uuidString: id ?? UUID().uuidString) ?? UUID(),
            username: username,
            sessionId: sessionId
        )
    }
}

// MARK: - Login Request

struct LoginRequest: Codable {
    let username: String
    let password: String
}

// MARK: - Register Request

struct RegisterRequest: Codable {
    let username: String
    let password: String
}

// MARK: - ReLogin Request

struct ReLoginRequest: Codable {
    let sessionId: String
}
