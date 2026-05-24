//
//  LeaderboardManager.swift
//  GeoShot
//
//  Created by João Ribeiro on 24/05/2026.
//

import Foundation

struct LeaderboardRecord: Identifiable {
    let id: String
    let name: String
    let score: Int
    let time: TimeInterval
}

class LeaderboardManager {
    static let shared = LeaderboardManager()
    
    private let projectId = "geoshotgame"
    private let apiKey = "AIzaSyAqeViqDcTRszXRuHZdHdWdE-P8aZ3bRj8"
    
    private var baseURL: URL {
        return URL(string: "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/(default)/documents")!
    }
    
    // MARK: - Session Variables
    
    var idToken: String? {
        UserDefaults.standard.string(forKey: "firebase_id_token")
    }
    
    var userId: String? {
        UserDefaults.standard.string(forKey: "firebase_user_id")
    }
    
    var userEmail: String? {
        UserDefaults.standard.string(forKey: "firebase_user_email")
    }
    
    var isAnonymous: Bool {
        return userId != nil && userEmail == nil
    }
    
    private init() {}
    
    private func saveSession(token: String, uid: String, email: String?) {
        UserDefaults.standard.set(token, forKey: "firebase_id_token")
        UserDefaults.standard.set(uid, forKey: "firebase_user_id")
        UserDefaults.standard.set(email, forKey: "firebase_user_email")
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Auth REST Methods
    
    func signInAnonymously(completion: @escaping (Bool) -> Void) {
        let urlString = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        let body: [String: Any] = ["returnSecureToken": true]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else {
                completion(false)
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let token = json["idToken"] as? String,
               let uid = json["localId"] as? String {
                
                // If we already have a linked email, don't overwrite it with a fresh anonymous session
                if self.userEmail != nil {
                    completion(true)
                    return
                }
                
                self.saveSession(token: token, uid: uid, email: nil)
                completion(true)
            } else {
                completion(false)
            }
        }
        task.resume()
    }
    
    func linkAccount(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentToken = idToken else {
            completion(.failure(NSError(domain: "LeaderboardManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Utilizador não autenticado anonimamente."])))
            return
        }
        
        let urlString = "https://identitytoolkit.googleapis.com/v1/accounts:update?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "LeaderboardManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "URL de autenticação inválido."])))
            return
        }
        
        let body: [String: Any] = [
            "idToken": currentToken,
            "email": email,
            "password": password,
            "returnSecureToken": true
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data else {
                completion(.failure(error ?? NSError(domain: "LeaderboardManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Sem resposta do servidor de autenticação."])))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let errorMsg = self.parseError(data: data)
                completion(.failure(NSError(domain: "LeaderboardManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])))
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let token = json["idToken"] as? String,
               let uid = json["localId"] as? String,
               let emailRes = json["email"] as? String {
                self.saveSession(token: token, uid: uid, email: emailRes)
                completion(.success(()))
            } else {
                completion(.failure(NSError(domain: "LeaderboardManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Falha ao decodificar dados de vinculação."])))
            }
        }
        task.resume()
    }
    
    func signInWithEmail(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let urlString = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "LeaderboardManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "URL de login inválido."])))
            return
        }
        
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "returnSecureToken": true
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data else {
                completion(.failure(error ?? NSError(domain: "LeaderboardManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Sem resposta do servidor."])))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let errorMsg = self.parseError(data: data)
                completion(.failure(NSError(domain: "LeaderboardManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])))
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let token = json["idToken"] as? String,
               let uid = json["localId"] as? String,
               let emailRes = json["email"] as? String {
                self.saveSession(token: token, uid: uid, email: emailRes)
                completion(.success(()))
            } else {
                completion(.failure(NSError(domain: "LeaderboardManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Falha ao decodificar dados de sessão."])))
            }
        }
        task.resume()
    }
    
    private func parseError(data: Data) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let errorObj = json["error"] as? [String: Any],
           let message = errorObj["message"] as? String {
            switch message {
            case "EMAIL_EXISTS":
                return "Este email já está registado."
            case "INVALID_EMAIL":
                return "O formato do email é inválido."
            case "WEAK_PASSWORD : Password should be at least 6 characters":
                return "A palavra-passe deve ter pelo menos 6 caracteres."
            case "EMAIL_NOT_FOUND", "INVALID_PASSWORD":
                return "Email ou palavra-passe incorretos."
            default:
                return message
            }
        }
        return "Erro de autenticação."
    }
    
    // MARK: - Firestore Leaderboard Methods
    
    func submitScore(name: String, score: Int, time: TimeInterval, completion: @escaping (Bool) -> Void) {
        guard let token = idToken, let uid = userId else {
            print("Cannot submit score: User is not authenticated.")
            completion(false)
            return
        }
        
        let url = baseURL.appendingPathComponent("leaderboard")
        
        let payload = CreateDocumentRequest(
            fields: CreateDocumentRequest.Fields(
                name: CreateDocumentRequest.Fields.StringValue(stringValue: name),
                score: CreateDocumentRequest.Fields.IntegerValue(integerValue: String(score)),
                time: CreateDocumentRequest.Fields.DoubleValue(doubleValue: time),
                userId: CreateDocumentRequest.Fields.StringValue(stringValue: uid)
            )
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(payload)
        } catch {
            print("Failed to encode leaderboard payload: \(error)")
            completion(false)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to submit score: \(error)")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                completion(true)
            } else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("Failed to submit score, status code: \(statusCode)")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Response body: \(responseString)")
                }
                completion(false)
            }
        }
        task.resume()
    }
    
    func fetchTopScores(limit: Int = 5, completion: @escaping ([LeaderboardRecord]) -> Void) {
        let url = baseURL.appendingPathComponent(":runQuery")
        
        let query = RunQueryRequest(
            structuredQuery: RunQueryRequest.StructuredQuery(
                from: [RunQueryRequest.StructuredQuery.CollectionSelector(collectionId: "leaderboard")],
                orderBy: [
                    RunQueryRequest.StructuredQuery.Order(
                        field: RunQueryRequest.StructuredQuery.Order.FieldReference(fieldPath: "score"),
                        direction: "DESCENDING"
                    )
                ],
                limit: limit
            )
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(query)
        } catch {
            print("Failed to encode runQuery body: \(error)")
            completion([])
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to fetch top scores: \(error)")
                completion([])
                return
            }
            
            guard let data = data else {
                completion([])
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let responseElements = try decoder.decode([RunQueryResponseElement].self, from: data)
                
                var records: [LeaderboardRecord] = []
                for element in responseElements {
                    if let doc = element.document, let fields = doc.fields {
                        let name = fields.name?.stringValue ?? "???"
                        let scoreStr = fields.score?.integerValue ?? "0"
                        let score = Int(scoreStr) ?? 0
                        let time = fields.time?.doubleValue ?? 0.0
                        
                        let docId = doc.name?.components(separatedBy: "/").last ?? UUID().uuidString
                        
                        records.append(LeaderboardRecord(id: docId, name: name, score: score, time: time))
                    }
                }
                completion(records)
            } catch {
                if let emptyCheck = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]],
                   emptyCheck.first?.keys.contains("document") == false {
                    completion([])
                    return
                }
                
                print("Failed to decode runQuery response: \(error)")
                completion([])
            }
        }
        task.resume()
    }
}

// MARK: - Codable structures for API

private struct CreateDocumentRequest: Codable {
    struct Fields: Codable {
        struct StringValue: Codable {
            let stringValue: String
        }
        struct IntegerValue: Codable {
            let integerValue: String
        }
        struct DoubleValue: Codable {
            let doubleValue: Double
        }
        let name: StringValue
        let score: IntegerValue
        let time: DoubleValue
        let userId: StringValue
    }
    let fields: Fields
}

private struct RunQueryRequest: Codable {
    struct StructuredQuery: Codable {
        struct CollectionSelector: Codable {
            let collectionId: String
        }
        struct Order: Codable {
            struct FieldReference: Codable {
                let fieldPath: String
            }
            let field: FieldReference
            let direction: String
        }
        let from: [CollectionSelector]
        let orderBy: [Order]
        let limit: Int
    }
    let structuredQuery: StructuredQuery
}

private struct RunQueryResponseElement: Codable {
    struct Document: Codable {
        let name: String?
        struct Fields: Codable {
            struct StringValue: Codable {
                let stringValue: String?
            }
            struct IntegerValue: Codable {
                let integerValue: String?
            }
            struct DoubleValue: Codable {
                let doubleValue: Double?
            }
            let name: StringValue?
            let score: IntegerValue?
            let time: DoubleValue?
        }
        let fields: Fields?
    }
    let document: Document?
}
