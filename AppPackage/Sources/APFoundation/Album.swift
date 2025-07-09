import Foundation

public struct Album: Equatable, Identifiable, Hashable {
    public let id: UUID
    public var title: String
    public var tags: [String]
    
    public init(id: UUID = UUID(), title: String, tags: [String] = []) {
        self.id = id
        self.title = title
        self.tags = tags
    }
}
