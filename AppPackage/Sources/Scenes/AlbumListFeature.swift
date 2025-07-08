
import Foundation
import APFoundation
import ComposableArchitecture

// For mock data
public struct Album: Equatable, Identifiable, Hashable {
    public let id: UUID
    public var title: String
    
    public init(id: UUID = UUID(), title: String) {
        self.id = id
        self.title = title
    }
}

@Reducer
public struct AlbumListFeature {
    @ObservableState
    public struct State: Equatable {
        public var albums: IdentifiedArrayOf<Album> = []
        public var isLoading = false
        
        public init(albums: IdentifiedArrayOf<Album> = [], isLoading: Bool = false) {
            self.albums = albums
            self.isLoading = isLoading
        }
    }

    public enum Action {
        case onAppear
        case albumsResponse([Album])
    }

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.isLoading else { return .none }
                state.isLoading = true
                return .run { send in
                    // Simulate a network/database call
                    try await Task.sleep(for: .seconds(1.5))
                    let mockAlbums = [
                        Album(title: "Summer Vacation 2024"),
                        Album(title: "Family Photos"),
                        Album(title: "Cute Pets")
                    ]
                    await send(.albumsResponse(mockAlbums))
                }

            case let .albumsResponse(albums):
                state.isLoading = false
                state.albums = IdentifiedArray(uniqueElements: albums)
                return .none
            }
        }
    }
    
    public init() {}
}
