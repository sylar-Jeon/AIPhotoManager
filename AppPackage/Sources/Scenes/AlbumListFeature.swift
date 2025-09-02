
import ComposableArchitecture
import Foundation
import APFoundation
import Photos
import IdentifiedCollections

public struct AlbumModel: Equatable, Identifiable {
    public let id: String
    public let assetCollection: PHAssetCollection
    public var title: String? {
        assetCollection.localizedTitle
    }

    public init(assetCollection: PHAssetCollection) {
        self.id = assetCollection.localIdentifier
        self.assetCollection = assetCollection
    }
}

@Reducer
public struct AlbumListFeature : Sendable {
    @ObservableState
    public struct State: Equatable {
        public var albums: IdentifiedArrayOf<AlbumModel> = []
        public var path = StackState<AlbumDetailFeature.State>()
        public var isLoading = false
        public var fetchedPhotosCount: Int = 0
        public var selection: Set<AlbumModel.ID> = []
        public var isEditingAlbums = false
        
        public init(albums: IdentifiedArrayOf<AlbumModel> = [], isLoading: Bool = false, fetchedPhotosCount: Int = 0, selection: Set<AlbumModel.ID> = [], isEditingAlbums: Bool = false) {
            self.albums = albums
            self.isLoading = isLoading
            self.fetchedPhotosCount = fetchedPhotosCount
            self.selection = selection
            self.isEditingAlbums = isEditingAlbums
        }
    }

    public enum Action {
        case onAppear
        case albumsResponse([PHAssetCollection])
        case scanButtonTapped
        case authorizationResponse(PHAuthorizationStatus)
        case photosResponse([PHAsset])
        case path(StackAction<AlbumDetailFeature.State, AlbumDetailFeature.Action>)
        case setEditMode(isEditing: Bool)
        case albumTapped(AlbumModel)
        case mergeButtonTapped
        case deleteButtonTapped
    }

    @Dependency(\.photoClient) var photoClient
    @Dependency(\.aiPhotoClassifierClient) var aiPhotoClassifierClient
    @Dependency(\.photoLibraryClient) var photoLibraryClient

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.isLoading else { return .none }
                state.isLoading = true
                return .run { send in
                    let albums = try await self.photoLibraryClient.fetchAlbums()
                    await send(.albumsResponse(albums))
                }

            case let .albumsResponse(albums):
                state.isLoading = false
                state.albums = IdentifiedArray(uniqueElements: albums.map(AlbumModel.init))
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
                    for album in classifiedAlbums {
                        let newAlbum = try await self.photoLibraryClient.createAlbum(album.title)
                        try await self.photoLibraryClient.addPhotos(album.photos.compactMap { $0.asset }, newAlbum)
                    }
                    let albums = try await self.photoLibraryClient.fetchAlbums()
                    await send(.albumsResponse(albums))
                }

            case .path(.element(id: _, action: .delegate(let delegateAction))):
                switch delegateAction {
                case let .albumUpdated(album):
                    state.albums[id: album.id] = album
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
                let newTitle = selectedAlbums.compactMap { $0.title }.joined(separator: " + ")
                let albumIdentifiers = selectedAlbums.map { $0.id }
                
                return .run { [albumIdentifiers] send in
                    let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: albumIdentifiers, options: nil)
                    var albumsToMerge: [PHAssetCollection] = []
                    fetchResult.enumerateObjects { collection, _, _ in
                        albumsToMerge.append(collection)
                    }
                    _ = try await self.photoLibraryClient.mergeAlbums(albumsToMerge, newTitle)
                    let albums = try await self.photoLibraryClient.fetchAlbums()
                    await send(.albumsResponse(albums))
                }
                
            case .deleteButtonTapped:
                let selection = state.selection
                let selectedAlbums = state.albums.filter { selection.contains($0.id) }
                let albumIdentifiers = selectedAlbums.map { $0.id }
                return .run { [albumIdentifiers] send in
                    let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: albumIdentifiers, options: nil)
                    var albumsToDelete: [PHAssetCollection] = []
                    fetchResult.enumerateObjects { collection, _, _ in
                        albumsToDelete.append(collection)
                    }
                    try await self.photoLibraryClient.deleteAlbums(albumsToDelete)
                    let albums = try await self.photoLibraryClient.fetchAlbums()
                    await send(.albumsResponse(albums))
                }
            }
        }
        .forEach(\State.path, action: /Action.path) {
            AlbumDetailFeature()
        }
    }
    
    public init() {}
}
