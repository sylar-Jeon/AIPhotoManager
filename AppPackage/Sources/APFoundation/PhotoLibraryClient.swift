import Dependencies
import Photos

public struct PhotoLibraryClient: Sendable {
    public var fetchAlbums: @Sendable () async throws -> [PHAssetCollection]
    public var createAlbum: @Sendable (String) async throws -> PHAssetCollection
    public var addPhotos: @Sendable ([PHAsset], PHAssetCollection) async throws -> Void
    public var deleteAlbums: @Sendable ([PHAssetCollection]) async throws -> Void
    public var mergeAlbums: @Sendable ([PHAssetCollection], String) async throws -> PHAssetCollection
}

private let albumPrefix = "AIPhotoManager-"

extension PhotoLibraryClient: DependencyKey {
    public static let liveValue = Self(
        fetchAlbums: {
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title BEGINSWITH %@", albumPrefix)
            let result = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
            var albums: [PHAssetCollection] = []
            result.enumerateObjects { collection, _, _ in
                albums.append(collection)
            }
            return albums
        },
        createAlbum: { title in
            var placeholder: PHObjectPlaceholder? = nil
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: "\(albumPrefix)\(title)")
                placeholder = request.placeholderForCreatedAssetCollection
            }
            guard let placeholder = placeholder else { throw PhotoLibraryError.creationFailed }
            let result = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
            guard let album = result.firstObject else { throw PhotoLibraryError.creationFailed }
            return album
        },
        addPhotos: { photos, album in
            try await PHPhotoLibrary.shared().performChanges {
                guard let changeRequest = PHAssetCollectionChangeRequest(for: album) else { return }
                changeRequest.addAssets(photos as NSFastEnumeration)
            }
        },
        deleteAlbums: { albums in
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetCollectionChangeRequest.deleteAssetCollections(albums as NSFastEnumeration)
            }
        },
        mergeAlbums: { albums, newTitle in
            var newAlbumPlaceholder: PHObjectPlaceholder? = nil
            try await PHPhotoLibrary.shared().performChanges {
                let newAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: "\(albumPrefix)\(newTitle)")
                newAlbumPlaceholder = newAlbumRequest.placeholderForCreatedAssetCollection
                
                let assets = PHAsset.fetchAssets(in: albums.first!, options: nil)
                newAlbumRequest.addAssets(assets)
                
                PHAssetCollectionChangeRequest.deleteAssetCollections(albums as NSFastEnumeration)
            }
            guard let placeholder = newAlbumPlaceholder else { throw PhotoLibraryError.creationFailed }
            let result = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
            guard let album = result.firstObject else { throw PhotoLibraryError.creationFailed }
            return album
        }
    )

    public static let testValue = Self(
        fetchAlbums: { [] },
        createAlbum: { _ in throw PhotoLibraryError.notImplemented },
        addPhotos: { _, _ in },
        deleteAlbums: { _ in },
        mergeAlbums: { _, _ in throw PhotoLibraryError.notImplemented }
    )
}

public enum PhotoLibraryError: Error {
    case creationFailed
    case notImplemented
}

public extension DependencyValues {
    var photoLibraryClient: PhotoLibraryClient {
        get { self[PhotoLibraryClient.self] }
        set { self[PhotoLibraryClient.self] = newValue }
    }
}
