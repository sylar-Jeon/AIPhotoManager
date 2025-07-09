
import Dependencies
import Photos

public struct AIPhotoClassifierClient: Sendable {
    public var classifyPhotos: @Sendable ([PHAsset]) async -> [Album]
}

extension AIPhotoClassifierClient: DependencyKey {
    public static let liveValue = Self(
        classifyPhotos: { assets in
            // Simulate AI classification and tagging
            try? await Task.sleep(for: .seconds(2))
            
            var classifiedAlbums: [Album] = []
            
            // Simple simulation: group by a random tag for demonstration
            let possibleTags = ["Nature", "People", "Animals", "Food", "Travel", "Urban"]
            
            for asset in assets {
                let randomTag = possibleTags.randomElement() ?? "Untagged"
                // For simplicity, each asset becomes an album with one tag
                // In a real app, multiple assets would form an album based on common tags
                let album = Album(title: "\(randomTag) Photos", tags: [randomTag])
                classifiedAlbums.append(album)
            }
            
            // Further refine: group similar albums or merge
            var finalAlbums: [Album] = []
            var albumMap: [String: Album] = [:]
            
            for album in classifiedAlbums {
                if var existingAlbum = albumMap[album.title] {
                    // Merge logic (simplified)
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
