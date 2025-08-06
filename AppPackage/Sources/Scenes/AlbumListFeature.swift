
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
        public var path = StackState<AlbumDetailFeature.State>()
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
        case path(StackAction<AlbumDetailFeature.State, AlbumDetailFeature.Action>)
        case setEditMode(isEditing: Bool)
        case albumTapped(Album)
        case mergeButtonTapped
        case deleteButtonTapped
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
                        Album(title: "Summer Vacation 2024", photos: []),
                        Album(title: "Family Photos", photos: []),
                        Album(title: "Cute Pets", photos: [])
                    ]
                    await send(.albumsResponse(mockAlbums))
                }

            case let .albumsResponse(albums):
                state.isLoading = false
                state.albums = IdentifiedArray(uniqueElements: albums)
                return .none
                
            case .scanButtonTapped:
                state.isLoading = true
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
                    state.isLoading = false
                    return .none
                case .notDetermined:
                    print("Photo library access not determined.")
                    state.isLoading = false
                    return .none
                @unknown default:
                    state.isLoading = false
                    return .none
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

            case .path(.element(id: _, action: .delegate(let delegateAction))):
                switch delegateAction {
                case let .albumUpdated(album):
                    state.albums[id: album.id] = album
                    return .none
                case let .movePhotos(from, to, photos):
                    guard var sourceAlbum = state.albums[id: from.id], var destinationAlbum = state.albums[id: to.id] else { return .none }
                    sourceAlbum.photos.removeAll { photos.contains($0) }
                    destinationAlbum.photos.append(contentsOf: photos)
                    state.albums[id: sourceAlbum.id] = sourceAlbum
                    state.albums[id: destinationAlbum.id] = destinationAlbum
                    return .none
                }

            case .path:
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
                } else {
                    state.path.append(AlbumDetailFeature.State(album: album))
                }
                return .none

            case .mergeButtonTapped:
                guard state.selection.count > 1 else { return .none }
                let selection = state.selection
                let selectedAlbums = state.albums.filter { selection.contains($0.id) }
                let newTitle = selectedAlbums.map { $0.title }.joined(separator: " + ")
                let newTags = Array(Set(selectedAlbums.flatMap { $0.tags }))
                let mergedPhotos = selectedAlbums.flatMap { $0.photos }
                let mergedAlbum = Album(title: newTitle, tags: newTags, photos: mergedPhotos)

                state.albums.removeAll(where: { selection.contains($0.id) })
                state.albums.append(mergedAlbum)
                state.selection = []
                state.isEditingAlbums = false
                return .none
                
            case .deleteButtonTapped:
                for id in state.selection {
                    state.albums.remove(id: id)
                }
                state.selection = []
                state.isEditingAlbums = false
                return .none
            }
        }
        .forEach(\.path, action: \.path) {
            AlbumDetailFeature()
        }
    }
    
    public init() {}
}
