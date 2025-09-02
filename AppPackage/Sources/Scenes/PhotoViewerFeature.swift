
import ComposableArchitecture
import SwiftUI
import Photos
import APFoundation

@Reducer
public struct PhotoViewerFeature : Sendable{
    @ObservableState
    public struct State: Equatable {
        public var photos: IdentifiedArrayOf<Photo>
        public var selectedPhotoID: Photo.ID
        
        public init(photos: IdentifiedArrayOf<Photo>, selectedPhotoID: Photo.ID) {
            self.photos = photos
            self.selectedPhotoID = selectedPhotoID
        }
    }

    public enum Action {
        case dismiss
        case setSelectedPhotoID(Photo.ID)
    }

    @Dependency(\.dismiss) var dismiss

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .dismiss:
                return .run { _ in await self.dismiss() }
            case let .setSelectedPhotoID(photoID):
                state.selectedPhotoID = photoID
                return .none
            }
        }
    }
    
    public init() {}
}
