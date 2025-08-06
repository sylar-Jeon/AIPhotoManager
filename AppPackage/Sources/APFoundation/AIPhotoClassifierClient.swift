
import Dependencies
import Photos
import UIKit

public struct AIPhotoClassifierClient: Sendable {
    public var classifyPhotos: @Sendable ([PHAsset]) async -> [Album]
}

extension AIPhotoClassifierClient: DependencyKey {
    public static let liveValue = Self(
        classifyPhotos: { assets in
            let classifier = ImageClassifier()
            var classifiedPhotos: [String: [Photo]] = [:]

            await withTaskGroup(of: (Photo, String)?.self) { group in
                for asset in assets {
                    group.addTask {
                        await classifier.classify(asset: asset)
                    }
                }

                for await result in group {
                    if let (photo, category) = result {
                        classifiedPhotos[category, default: []].append(photo)
                    }
                }
            }

            return classifiedPhotos.map { category, photos in
                Album(title: category, tags: [category], photos: photos)
            }
        }
    )

    public static let testValue = Self(
        classifyPhotos: { _ in [] }
    )
}

private actor ImageClassifier {
    private let imageManager = PHCachingImageManager()
    private let requestOptions: PHImageRequestOptions
    private let imageClassificationService = ImageClassificationService()

    init() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        self.requestOptions = options
    }

    func classify(asset: PHAsset) async -> (Photo, String)? {
        await withCheckedContinuation { continuation in
            imageManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: requestOptions) { image, _ in
                guard let uiImage = image else {
                    continuation.resume(returning: nil)
                    return
                }

                self.imageClassificationService.classifyImage(uiImage) { result in
                    switch result {
                    case .success(let identifier):
                        let category = self.mapIdentifierToCategory(identifier)
                        continuation.resume(returning: (Photo(asset: asset), category))
                    case .failure(let error):
                        print("Image classification failed: \(error.localizedDescription)")
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }

    private func mapIdentifierToCategory(_ identifier: String) -> String {
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
}


public extension DependencyValues {
    var aiPhotoClassifierClient: AIPhotoClassifierClient {
        get { self[AIPhotoClassifierClient.self] }
        set { self[AIPhotoClassifierClient.self] = newValue }
    }
}
