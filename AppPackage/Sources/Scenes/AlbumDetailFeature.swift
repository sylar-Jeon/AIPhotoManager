
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
        public var selection: Set<Photo.ID> = []
        public var isEditing = false
        public var isRenameAlertPresented = false
        @Presents var destination: AlbumSelectionFeature.State?
        @Presents var photoViewer: PhotoViewerFeature.State?
        
        public init(album: Album, photos: IdentifiedArrayOf<Photo> = [], isLoadingPhotos: Bool = false, selection: Set<Photo.ID> = [], isEditing: Bool = false, isRenameAlertPresented: Bool = false, destination: AlbumSelectionFeature.State? = nil, photoViewer: PhotoViewerFeature.State? = nil) {
            self.album = album
            self.photos = IdentifiedArray(uniqueElements: album.photos)
            self.isLoadingPhotos = isLoadingPhotos
            self.selection = selection
            self.isEditing = isEditing
            self.isRenameAlertPresented = isRenameAlertPresented
            self.destination = destination
            self.photoViewer = photoViewer
        }
    }

    public enum Action {
        case onAppear
        case renameButtonTapped
        case renameAlbum(newName: String)
        case setEditMode(isEditing: Bool)
        case photoTapped(Photo)
        case moveButtonTapped
        case movePhotos(toAlbum: Album)
        case destination(PresentationAction<AlbumSelectionFeature.Action>)
        case photoViewer(PresentationAction<PhotoViewerFeature.Action>)
        case delegate(Delegate)
        case setIsRenameAlertPresented(Bool)

        public enum Delegate {
            case albumUpdated(Album)
            case movePhotos(from: Album, to: Album, photos: [Photo])
        }
    }

    @Dependency(\.photoClient) var photoClient

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.photos = IdentifiedArray(uniqueElements: state.album.photos)
                return .none
                
            case .renameButtonTapped:
                state.isRenameAlertPresented = true
                return .none
                
            case let .renameAlbum(newName):
                state.album.title = newName
                state.isRenameAlertPresented = false
                return .send(.delegate(.albumUpdated(state.album)))
                
            case let .setEditMode(isEditing):
                state.isEditing = isEditing
                state.selection = []
                return .none
                
            case let .photoTapped(photo):
                if state.isEditing {
                    if state.selection.contains(photo.id) {
                        state.selection.remove(photo.id)
                    } else {
                        state.selection.insert(photo.id)
                    }
                } else {
                    state.photoViewer = PhotoViewerFeature.State(photos: state.photos, selectedPhotoID: photo.id)
                }
                return .none
                
            case .moveButtonTapped:
                // In a real app, you would fetch all albums here.
                // For now, we assume the parent feature will handle this.
                state.destination = AlbumSelectionFeature.State(albums: [])
                return .none
                
            case let .movePhotos(toAlbum):
                let photosToMove = state.photos.filter { state.selection.contains($0.id) }
                return .send(.delegate(.movePhotos(from: state.album, to: toAlbum, photos: Array(photosToMove))))
                
            case .destination(.presented(.albumTapped(let album))):
                return .send(.movePhotos(toAlbum: album))
                
            case .destination:
                return .none
                
            case .photoViewer:
                return .none

            case .delegate:
                return .none

            case let .setIsRenameAlertPresented(isPresented):
                state.isRenameAlertPresented = isPresented
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) {
            AlbumSelectionFeature()
        }
        .ifLet(\.$photoViewer, action: \.photoViewer) {
            PhotoViewerFeature()
        }
    }
}
