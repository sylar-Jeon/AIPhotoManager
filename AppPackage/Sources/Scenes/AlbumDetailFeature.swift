
import ComposableArchitecture
import Foundation
import Photos
import APFoundation

@Reducer
public struct AlbumDetailFeature : Sendable {
    @ObservableState
    public struct State: Equatable {
        public var album: Album
        public var photos: IdentifiedArrayOf<Photo> = []
        public var isLoadingPhotos = false
        public var alert: AlertState<Action.Alert>?
        public var selection: Set<Photo.ID> = []
        public var isEditing = false
        @Presents var destination: AlbumSelectionFeature.State?
        @Presents var photoViewer: PhotoViewerFeature.State?
        
        public init(album: Album, photos: IdentifiedArrayOf<Photo> = [], isLoadingPhotos: Bool = false, alert: AlertState<Action.Alert>? = nil, selection: Set<Photo.ID> = [], isEditing: Bool = false, destinationSelection: AlbumSelectionFeature.State? = nil, photoViewer: PhotoViewerFeature.State? = nil) {
            self.album = album
            self.photos = photos
            self.isLoadingPhotos = isLoadingPhotos
            self.alert = alert
            self.selection = selection
            self.isEditing = isEditing
            self.destinationSelection = destinationSelection
            self.photoViewer = photoViewer
        }
    }

    public enum Action {
        case onAppear
        case photosLoaded([PHAsset])
        case renameButtonTapped
        case renameAlbum(newName: String)
        case alert(PresentationAction<Alert>)
        case setEditMode(isEditing: Bool)
        case photoTapped(Photo)
        case moveButtonTapped
        case movePhotos(toAlbum: Album)
        case destinationSelection(PresentationAction<AlbumSelectionFeature.Action>)
        case photoViewer(PresentationAction<PhotoViewerFeature.Action>)

        public enum Alert: Equatable {
            case confirmRename(newName: String)
        }
    }

    @Dependency(\.photoClient) var photoClient

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.isLoadingPhotos else { return .none }
                state.isLoadingPhotos = true
                // In a real app, you'd filter photos based on album's classification/tags
                // For now, we'll just fetch all photos and simulate filtering later.
                return .run { send in
                    let allPhotos = await self.photoClient.fetchPhotos()
                    await send(.photosLoaded(allPhotos))
                }
                
            case let .photosLoaded(assets):
                state.isLoadingPhotos = false
                // Simulate filtering photos for this specific album based on tags
                // This is a placeholder for actual AI-based photo-to-album mapping
                let filteredAssets = assets.filter { asset in
                    // Simple simulation: if album title contains a tag, include some photos
                    state.album.tags.contains { tag in
                        state.album.title.contains(tag)
                    }
                }
                state.photos = IdentifiedArray(uniqueElements: filteredAssets.map(Photo.init))
                return .none
                
            case .renameButtonTapped:
                state.alert = AlertState {
                    TextState("Rename Album")
                } actions: {
                    ButtonState(action: .confirmRename(newName: "")) { TextState("Rename") }
                    ButtonState(role: .cancel) { TextState("Cancel") }
                } message: {
                    TextState("Enter a new name for the album.")
                }
                return .none
                
            case let .renameAlbum(newName):
                state.album.title = newName
                return .none
                
            case .alert(.presented(.confirmRename(let newName))):
                state.album.title = newName
                return .none
                
            case .alert: // Dismissal or other alert actions
                return .none
                
            case let .setEditMode(isEditing):
                state.isEditing = isEditing
                state.selection = [] // Clear selection when entering/exiting edit mode
                return .none
                
            case let .photoTapped(photo):
                if state.isEditing {
                    state.selection.insert(photo.id)
                } else {
                    state.photoViewer = PhotoViewerFeature.State(photos: state.photos, selectedPhotoID: photo.id)
                }
                return .none
                
            case .moveButtonTapped:
                // Present a sheet to select destination album
                state.destinationSelection = AlbumSelectionFeature.State(albums: []) // Need to pass actual albums here
                return .none
                
            case let .movePhotos(toAlbum):
                // Simulate moving photos by removing them from current album
                state.photos.removeAll(where: { state.selection.contains($0.id) })
                state.selection = []
                state.isEditing = false
                state.destinationSelection = nil
                // In a real app, you'd update the target album's photos as well
                return .none
                
            case .destinationSelection(.presented(.albumTapped(let album))):
                return .send(.movePhotos(toAlbum: album))
                
            case .destinationSelection(.presented(.cancelButtonTapped)):
                state.destinationSelection = nil
                return .none
                
            case .destinationSelection: // Dismissal or other actions from AlbumSelectionFeature
                return .none
                
            case .photoViewer(.presented(.dismiss)):
                state.photoViewer = nil
                return .none
                
            case .photoViewer: // Other actions from PhotoViewerFeature
                return .none
            }
        }
        .ifLet(\State.alert, action: /Action.alert) // Handle alert actions
        .ifLet(\.$destination, action: \.destination) {
            AlbumSelectionFeature()
        }
        .ifLet(\.$photoViewer, action: \.photoViewer) {
            PhotoViewerFeature()
        }
    }
}
