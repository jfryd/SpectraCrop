//  APIClient.swift
//  SpectraCrop
//
//  Created by SpectraCrop Development Team
//  Copyright © 2026 SpectraCrop. All rights reserved.
//

import Foundation
import Security

// MARK: - APIClient Protocol

protocol APIClientProtocol {
    func login(username: String, password: String) async throws -> User
    func register(username: String, password: String) async throws -> User
    func relogin(sessionId: String) async throws -> User
    func logout() async throws
    func deleteAccount() async throws
    func uploadReadings(_ readings: [Reading]) async throws -> String
    func downloadReadings(skip: Int, limit: Int, minimumModified: Date?) async throws -> PageDTO<ReadingDTO>
}

// MARK: - APIClient Implementation

final class APIClient: APIClientProtocol {
    
    // MARK: - Singleton
    
    static let shared = APIClient()
    
    private init() {}
    
    // MARK: - Configuration
    
    private let baseURL = URL(string: "https://siriu5.dk/api/")!
    private let session = URLSession.shared
    private let timeout: TimeInterval = 30
    
    // MARK: - Headers
    
    private var commonHeaders: [String: String] {
        var headers = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        // Add device ID
        if let deviceId = DeviceInfo.deviceId {
            headers["x-DeviceId"] = deviceId
        }
        
        // Add session ID if logged in
        if let sessionId = AuthManager.shared.currentUser?.sessionId {
            headers["x-SessionId"] = sessionId
        }
        
        return headers
    }
    
    // MARK: - Request Builder
    
    private func buildRequest(for endpoint: String, method: String, body: Data? = nil) throws -> URLRequest {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = method
        request.allHTTPHeaderFields = commonHeaders
        
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
    
    // MARK: - Request Execution
    
    private func executeRequest<T: Decodable>(_ request: URLRequest, responseType: T.Type) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            
            // Check for HTTP errors
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError(code: -1, message: "Invalid response")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let error = try decodeError(data: data, statusCode: httpResponse.statusCode)
                throw error
            }
            
            // Decode response
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .millisecondsSince1970
            let result = try decoder.decode(T.self, from: data)
            
            return result
            
        } catch let urlError as URLError {
            throw APIError(code: urlError.errorCode, message: urlError.localizedDescription)
        } catch {
            throw APIError(code: -1, message: error.localizedDescription)
        }
    }
    
    private func decodeError(data: Data, statusCode: Int) -> APIError {
        do {
            let decoder = JSONDecoder()
            let errorResponse = try decoder.decode(APIError.self, from: data)
            return errorResponse
        } catch {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            return APIError(code: statusCode, message: message)
        }
    }
    
    // MARK: - Authentication
    
    func login(username: String, password: String) async throws -> User {
        let requestBody = LoginRequest(username: username, password: password)
        let data = try JSONEncoder().encode(requestBody)
        let request = try buildRequest(for: "authenticate/user", method: "POST", body: data)
        
        let userDTO: UserDTO = try await executeRequest(request, responseType: UserDTO.self)
        return userDTO.toUser()
    }
    
    func register(username: String, password: String) async throws -> User {
        let requestBody = RegisterRequest(username: username, password: password)
        let data = try JSONEncoder().encode(requestBody)
        let request = try buildRequest(for: "authenticate/register", method: "POST", body: data)
        
        let userDTO: UserDTO = try await executeRequest(request, responseType: UserDTO.self)
        return userDTO.toUser()
    }
    
    func relogin(sessionId: String) async throws -> User {
        let requestBody = ReLoginRequest(sessionId: sessionId)
        let data = try JSONEncoder().encode(requestBody)
        let request = try buildRequest(for: "authenticate/relogin", method: "POST", body: data)
        
        let userDTO: UserDTO = try await executeRequest(request, responseType: UserDTO.self)
        return userDTO.toUser()
    }
    
    func logout() async throws {
        let request = try buildRequest(for: "authenticate/logout", method: "GET")
        _ = try await executeRequest(request, responseType: UserDTO.self)
    }
    
    func deleteAccount() async throws {
        let request = try buildRequest(for: "authenticate/delete", method: "GET")
        _ = try await executeRequest(request, responseType: UserDTO.self)
    }
    
    // MARK: - Readings
    
    func uploadReadings(_ readings: [Reading]) async throws -> String {
        let readingDTOs = readings.map { ReadingDTO(from: $0) }
        let requestBody = SyncReadingsRequest(readings: readingDTOs)
        let data = try JSONEncoder().encode(requestBody)
        let request = try buildRequest(for: "readings/upload", method: "POST", body: data)
        
        let response: String = try await executeRequest(request, responseType: String.self)
        return response
    }
    
    func downloadReadings(skip: Int, limit: Int, minimumModified: Date? = nil) async throws -> PageDTO<ReadingDTO> {
        let requestBody = DownloadReadingsRequest(
            skip: skip,
            limit: limit,
            minimumModified: minimumModified?.millisecondsSince1970
        )
        let data = try JSONEncoder().encode(requestBody)
        let request = try buildRequest(for: "readings/download", method: "POST", body: data)
        
        let pageDTO: PageDTO<ReadingDTO> = try await executeRequest(request, responseType: PageDTO<ReadingDTO>.self)
        return pageDTO
    }
}

// MARK: - Mock APIClient for Testing

#if DEBUG
class MockAPIClient: APIClientProtocol {
    func login(username: String, password: String) async throws -> User {
        return User(id: UUID(), username: username, sessionId: UUID().uuidString)
    }
    
    func register(username: String, password: String) async throws -> User {
        return User(id: UUID(), username: username, sessionId: UUID().uuidString)
    }
    
    func relogin(sessionId: String) async throws -> User {
        return User(id: UUID(), username: "test", sessionId: sessionId)
    }
    
    func logout() async throws {}
    
    func deleteAccount() async throws {}
    
    func uploadReadings(_ readings: [Reading]) async throws -> String {
        return "success"
    }
    
    func downloadReadings(skip: Int, limit: Int, minimumModified: Date?) async throws -> PageDTO<ReadingDTO> {
        return PageDTO(items: [], totalCount: 0, hasMore: false)
    }
}
#endif
