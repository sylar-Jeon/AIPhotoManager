
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
    private let imageClassificationService = ImageClassificationService()

    func classify(asset: PHAsset) async -> (Photo, String)? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = false

        let (imageData, _) = await withCheckedContinuation { (continuation: CheckedContinuation<(Data, String), Never>) in
            imageManager.requestImageDataAndOrientation(for: asset, options: options) { data, uti, _, _ in
                guard let data = data, let uti = uti else {
                    // This can be called multiple times, so we can't resume with nil here.
                    // We will just return and let the timeout handle it if no image is ever returned.
                    return
                }
                continuation.resume(returning: (data, uti))
            }
        }

        guard let uiImage = UIImage(data: imageData) else {
            return nil
        }

        return await withCheckedContinuation { continuation in
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
