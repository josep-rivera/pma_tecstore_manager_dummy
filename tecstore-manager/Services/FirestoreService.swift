import Foundation
import FirebaseFirestore

// ─────────────────────────────────────────────
// MARK: - FirestoreService
// ─────────────────────────────────────────────
//
// Thin generic CRUD helpers used by all domain services.
// Not a repository framework — just typed convenience wrappers
// over the Firestore SDK's Codable support.

enum FirestoreService {

    static let db = Firestore.firestore()

    // ─────────────────────────────────────────
    // MARK: - Read

    /// Fetch all documents in a collection and decode them.
    static func fetchAll<T: Decodable>(_ collection: String, as type: T.Type) async throws -> [T] {
        let snap = try await db.collection(collection).getDocuments()
        return try snap.documents.map { try $0.data(as: type) }
    }

    /// Fetch a single document by ID and decode it. Returns nil when the document doesn't exist.
    static func fetch<T: Decodable>(_ collection: String, id: String, as type: T.Type) async throws -> T? {
        let doc = try await db.collection(collection).document(id).getDocument()
        guard doc.exists else { return nil }
        return try doc.data(as: type)
    }

    // ─────────────────────────────────────────
    // MARK: - Write

    /// Add a new document with a Firestore-generated ID. Returns the new document ID.
    @discardableResult
    static func add<T: Encodable>(_ collection: String, _ value: T) async throws -> String {
        let ref = db.collection(collection).document()
        try ref.setData(from: value)
        return ref.documentID
    }

    /// Write a document at an explicit ID (upsert, no merge).
    /// Used for /usuarios/{uid} where the ID must equal the Firebase Auth uid.
    static func set<T: Encodable>(_ collection: String, id: String, _ value: T) async throws {
        try db.collection(collection).document(id).setData(from: value, merge: false)
    }

    /// Update specific fields on an existing document.
    static func update(_ collection: String, id: String, _ fields: [String: Any]) async throws {
        try await db.collection(collection).document(id).updateData(fields)
    }

    /// Delete a document by ID.
    static func delete(_ collection: String, id: String) async throws {
        try await db.collection(collection).document(id).delete()
    }

    // ─────────────────────────────────────────
    // MARK: - Batch

    /// Returns a new writable Firestore batch.
    static func batch() -> WriteBatch {
        db.batch()
    }
}
