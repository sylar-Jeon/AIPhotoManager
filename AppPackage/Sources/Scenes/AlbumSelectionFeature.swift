
import ComposableArchitecture
import SwiftUI
import APFoundation

@Reducer
public struct AlbumSelectionFeature {
    @ObservableState
    public struct State: Equatable {
        public var albums: IdentifiedArrayOf<Album>
        
        public init(albums: IdentifiedArrayOf<Album>) {
            self.albums = albums
        }
    }

    public enum Action {
        case albumTapped(Album)
        case cancelButtonTapped
    }

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .albumTapped(let album):
                // This action will be handled by the parent feature (AlbumDetailFeature)
                return .none
            case .cancelButtonTapped:
                // This action will be handled by the parent feature (AlbumDetailFeature)
                return .none
            }
        }
    }
    
    public init() {}
}
