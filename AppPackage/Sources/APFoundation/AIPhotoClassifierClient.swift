
import Dependencies
import Photos
import UIKit // UIImage를 사용하기 위해 추가

public struct AIPhotoClassifierClient: Sendable {
    public var classifyPhotos: @Sendable ([PHAsset]) async -> [Album]
}

extension AIPhotoClassifierClient: DependencyKey {
    public static let liveValue = Self(
        classifyPhotos: { assets in
            let imageClassificationService = ImageClassificationService()
            var classifiedAlbums: [Album] = []
            let imageManager = PHCachingImageManager()
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true // 동기적으로 이미지 요청
            requestOptions.deliveryMode = .highQualityFormat // 고품질 이미지 요청

            for asset in assets {
                await withCheckedContinuation { continuation in
                    imageManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: requestOptions) { image, _ in
                        guard let uiImage = image else {
                            continuation.resume(returning: ())
                            return
                        }

                        imageClassificationService.classifyImage(uiImage) { result in
                            switch result {
                            case .success(let identifier):
                                let album = Album(title: identifier, tags: [identifier])
                                classifiedAlbums.append(album)
                            case .failure(let error):
                                print("Image classification failed: \(error.localizedDescription)")
                            }
                            continuation.resume(returning: ())
                        }
                    }
                }
            }

            // 분류된 앨범들을 병합하거나 그룹화하는 로직 (필요시 추가 구현)
            var finalAlbums: [Album] = []
            var albumMap: [String: Album] = [:]

            for album in classifiedAlbums {
                if var existingAlbum = albumMap[album.title] {
                    existingAlbum.tags.append(contentsOf: album.tags)
                    albumMap[album.title] = existingAlbum
                } else {
                    albumMap[album.title] = album
                }
            }
            finalAlbums = Array(albumMap.values)

            return finalAlbums
        }
    )

    public static let testValue = Self(
        classifyPhotos: { _ in [] }
    )
}

public extension DependencyValues {
    var aiPhotoClassifierClient: AIPhotoClassifierClient {
        get { self[AIPhotoClassifierClient.self] }
        set { self[AIPhotoClassifierClient.self] = newValue }
    }
}
