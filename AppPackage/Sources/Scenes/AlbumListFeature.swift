
import ComposableArchitecture
import Foundation
import APFoundation
import Photos
import IdentifiedCollections

@Reducer
public struct AlbumListFeature : Sendable {
    @ObservableState
    public struct State: Equatable {
        public var albums: IdentifiedArrayOf<Album> = []
        public var isLoading = false
        public var fetchedPhotosCount: Int = 0
        public var selection: Set<Album.ID> = []
        public var isEditingAlbums = false
        
        public init(albums: IdentifiedArrayOf<Album> = [], isLoading: Bool = false, fetchedPhotosCount: Int = 0, selection: Set<Album.ID> = [], isEditingAlbums: Bool = false) {
            self.albums = albums
            self.isLoading = isLoading
            self.fetchedPhotosCount = fetchedPhotosCount
            self.selection = selection
            self.isEditingAlbums = isEditingAlbums
        }
    }

    public enum Action {
        case onAppear
        case albumsResponse([Album])
        case scanButtonTapped
        case authorizationResponse(PHAuthorizationStatus)
        case photosResponse([PHAsset])
        case classifiedAlbumsResponse([Album])
        case album(id: Album.ID, action: AlbumDetailFeature.Action)
        case setEditMode(isEditing: Bool)
        case albumTapped(Album)
        case mergeButtonTapped
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

            case .album(id: _, action: .renameAlbum(let newName)):
                // Handle album rename propagation
                // The album in state.albums is already updated by the AlbumDetailFeature's reducer
                print("Album renamed to: \(newName)")
                return .none

            case .album: // Other actions from AlbumDetailFeature
                return .none

            case let .setEditMode(isEditing):
                state.isEditingAlbums = isEditing
                state.selection = [] // Clear selection when entering/exiting edit mode
                return .none

            case let .albumTapped(album):
                if state.isEditingAlbums {
                    if state.selection.contains(album.id) {
                        state.selection.remove(album.id)
                    } else {
                        state.selection.insert(album.id)
                    }
                }
                return .none

            case .mergeButtonTapped:
                // Simulate merging albums
                guard state.selection.count > 1 else { return .none }
                let selectedAlbums = state.albums.filter { state.selection.contains($0.id) }
                let newTitle = selectedAlbums.map { $0.title }.joined(separator: " + ")
                let newTags = Array(Set(selectedAlbums.flatMap { $0.tags }))
                let mergedAlbum = Album(title: newTitle, tags: newTags)

                state.albums.removeAll(where: { state.selection.contains($0.id) })
                state.albums.append(mergedAlbum)
                state.selection = []
                state.isEditingAlbums = false
                return .none
            }
        }
        .forEach(\.$albums, action: \.album) {
            AlbumDetailFeature()
        }
    }
    
    public init() {}
}
