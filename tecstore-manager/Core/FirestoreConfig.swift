import FirebaseFirestore

// MARK: - Firestore Offline Persistence

enum FirestoreConfig {
    /// Call once in AppDelegate before any Firestore query executes.
    /// PersistentCacheSettings replaces the deprecated isPersistenceEnabled API.
    static func enableOfflinePersistence() {
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(
            sizeBytes: NSNumber(value: FirestoreCacheSizeUnlimited)
        )
        Firestore.firestore().settings = settings
    }
}

// MARK: - Collection Name Constants

enum Collections {
    static let usuarios  = "usuarios"
    static let productos = "productos"
    static let clientes  = "clientes"
    static let ventas    = "ventas"
}
