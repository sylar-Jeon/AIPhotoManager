import Dependencies
import Photos

public struct PhotoClient: Sendable {
    public var requestAuthorization: @Sendable () async -> PHAuthorizationStatus
    public var fetchPhotos: @Sendable () async -> [PHAsset]
}

extension PhotoClient: DependencyKey {
    public static let liveValue = Self(
        requestAuthorization: { await PHPhotoLibrary.requestAuthorization(for: .readWrite) },
        fetchPhotos: { 
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            var assets: [PHAsset] = []
            allPhotos.enumerateObjects { asset, _, _ in
                assets.append(asset)
            }
            return assets
        }
    )

    public static let testValue = Self(
        requestAuthorization: { .authorized },
        fetchPhotos: { [] }
    )
}

public extension DependencyValues {
    var photoClient: PhotoClient {
        get { self[PhotoClient.self] }
        set { self[PhotoClient.self] = newValue }
    }
}