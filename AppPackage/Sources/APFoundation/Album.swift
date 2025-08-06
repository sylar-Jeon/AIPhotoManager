import Foundation

public struct Album: Equatable, Identifiable, Hashable {
    public let id: UUID
    public var title: String
    public var tags: [String]
    public var photos: [Photo]
    
    public init(id: UUID = UUID(), title: String, tags: [String] = [], photos: [Photo] = []) {
        self.id = id
        self.title = title
        self.tags = tags
        self.photos = photos
    }
}
