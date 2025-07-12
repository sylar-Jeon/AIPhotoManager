
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
                let category = mapIdentifierToCategory(identifier)
                let album = Album(title: category, tags: [category])
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

    private static func mapIdentifierToCategory(_ identifier: String) -> String {
        let lowercasedIdentifier = identifier.lowercased()
        
        if lowercasedIdentifier.contains("person") || lowercasedIdentifier.contains("face") || lowercasedIdentifier.contains("human") {
            return "인물"
        } else if lowercasedIdentifier.contains("dog") || lowercasedIdentifier.contains("cat") || lowercasedIdentifier.contains("animal") || lowercasedIdentifier.contains("bird") || lowercasedIdentifier.contains("fish") {
            return "동물"
        } else if lowercasedIdentifier.contains("food") || lowercasedIdentifier.contains("dish") || lowercasedIdentifier.contains("meal") || lowercasedIdentifier.contains("fruit") || lowercasedIdentifier.contains("vegetable") {
            return "음식"
        } else if lowercasedIdentifier.contains("landscape") || lowercasedIdentifier.contains("nature") || lowercasedIdentifier.contains("mountain") || lowercasedIdentifier.contains("sea") || lowercasedIdentifier.contains("sky") || lowercasedIdentifier.contains("tree") {
            return "풍경"
        } else if lowercasedIdentifier.contains("car") || lowercasedIdentifier.contains("building") || lowercasedIdentifier.contains("object") || lowercasedIdentifier.contains("house") || lowercasedIdentifier.contains("furniture") {
            return "사물"
        } else {
            return "기타"
        }
    }

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
