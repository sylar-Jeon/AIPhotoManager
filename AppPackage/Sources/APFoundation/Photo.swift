
import Foundation
import Photos

public struct Photo: Equatable, Identifiable, Hashable, @unchecked Sendable {
    public let id: String
    public let asset: PHAsset
    
    public init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.asset = asset
    }
}
