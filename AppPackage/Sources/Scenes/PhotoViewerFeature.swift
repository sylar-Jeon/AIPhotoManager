
import ComposableArchitecture
import SwiftUI
import Photos
import APFoundation

@Reducer
public struct PhotoViewerFeature {
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
    }

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .dismiss:
                return .none
            }
        }
    }
    
    public init() {}
}
