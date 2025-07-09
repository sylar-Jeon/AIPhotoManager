
import ComposableArchitecture
import Foundation
import APFoundation
import Photos

// For mock data
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

@Reducer
public struct AlbumListFeature : Sendable {
    @ObservableState
    public struct State: Equatable {
        public var albums: IdentifiedArrayOf<Album> = []
        public var isLoading = false
        public var fetchedPhotosCount: Int = 0
        
        public init(albums: IdentifiedArrayOf<Album> = [], isLoading: Bool = false, fetchedPhotosCount: Int = 0) {
            self.albums = albums
            self.isLoading = isLoading
            self.fetchedPhotosCount = fetchedPhotosCount
        }
    }

    public enum Action {
        case onAppear
        case albumsResponse([Album])
        case scanButtonTapped
        case authorizationResponse(PHAuthorizationStatus)
        case photosResponse([PHAsset])
        case classifiedAlbumsResponse([Album])
    }

    @Dependency(\.photoClient) var photoClient
    @Dependency(\.aiPhotoClassifierClient) var aiPhotoClassifierClient

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
                
            case .scanButtonTapped:
                return .run { send in
                    let status = await self.photoClient.requestAuthorization()
                    await send(.authorizationResponse(status))
                }

            case let .authorizationResponse(status):
                switch status {
                case .authorized, .limited:
                    print("Photo library access granted.")
                    return .run { send in
                        let photos = await self.photoClient.fetchPhotos()
                        await send(.photosResponse(photos))
                    }
                case .denied, .restricted:
                    print("Photo library access denied.")
                    return .none
                case .notDetermined:
                    print("Photo library access not determined.")
                    return .none
                @unknown default:
                    fatalError()
                }

            case let .photosResponse(photos):
                state.fetchedPhotosCount = photos.count
                print("Fetched \(photos.count) photos.")
                return .run { send in
                    let classifiedAlbums = await self.aiPhotoClassifierClient.classifyPhotos(photos)
                    await send(.classifiedAlbumsResponse(classifiedAlbums))
                }

            case let .classifiedAlbumsResponse(albums):
                state.isLoading = false
                state.albums = IdentifiedArray(uniqueElements: albums)
                print("Classified into \(albums.count) albums.")
                return .none
            }
        }
    }
    
    public init() {}
}
