
import ComposableArchitecture
import Foundation
import Photos
import APFoundation

@Reducer
public struct AlbumDetailFeature : Sendable {
    @ObservableState
    public struct State: Equatable {
        public var album: AlbumModel
        public var photos: IdentifiedArrayOf<Photo> = []
        public var isLoadingPhotos = false
        public var selection: Set<Photo.ID> = []
        public var isEditing = false
        public var isRenameAlertPresented = false
        @Presents var destination: AlbumSelectionFeature.State?
        @Presents var photoViewer: PhotoViewerFeature.State?
        
        public init(album: AlbumModel, photos: IdentifiedArrayOf<Photo> = [], isLoadingPhotos: Bool = false, selection: Set<Photo.ID> = [], isEditing: Bool = false, isRenameAlertPresented: Bool = false, destination: AlbumSelectionFeature.State? = nil, photoViewer: PhotoViewerFeature.State? = nil) {
            self.album = album
            self.photos = photos
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
        case setDestination(AlbumSelectionFeature.State?)
        case movePhotos(toAlbum: PHAssetCollection)
        case destination(PresentationAction<AlbumSelectionFeature.Action>)
        case photoViewer(PresentationAction<PhotoViewerFeature.Action>)
        case delegate(Delegate)
        case setIsRenameAlertPresented(Bool)
        case photosResponse([PHAsset])

        public enum Delegate {
            case albumUpdated(AlbumModel)
        }
    }

    @Dependency(\.photoClient) var photoClient
    @Dependency(\.photoLibraryClient) var photoLibraryClient

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoadingPhotos = true
                return .run { [albumId = state.album.id] send in
                    let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumId], options: nil)
                    guard let album = fetchResult.firstObject else { return }
                    let assets = PHAsset.fetchAssets(in: album, options: nil)
                    var photos: [PHAsset] = []
                    assets.enumerateObjects { asset, _, _ in
                        photos.append(asset)
                    }
                    await send(.photosResponse(photos))
                }
                
            case let .photosResponse(photos):
                state.isLoadingPhotos = false
                state.photos = IdentifiedArray(uniqueElements: photos.map(Photo.init))
                return .none

            case .renameButtonTapped:
                state.isRenameAlertPresented = true
                return .none
                
            case let .renameAlbum(newName):
                state.isRenameAlertPresented = false
                let albumId = state.album.id
                return .run { [albumId, newName] send in
                    let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumId], options: nil)
                    guard let album = fetchResult.firstObject else { return }
                    try await PHPhotoLibrary.shared().performChanges {
                        guard let changeRequest = PHAssetCollectionChangeRequest(for: album) else { return }
                        changeRequest.title = newName
                    }
                }
                
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
                return .run { send in
                    let albums = try await self.photoLibraryClient.fetchAlbums()
                    await send(.setDestination(AlbumSelectionFeature.State(albums: IdentifiedArray(uniqueElements: albums.map(AlbumModel.init)))))
                }

            case let .setDestination(destination):
                state.destination = destination
                return .none
                
            case let .movePhotos(toAlbum):
                let photosToMove = state.photos.filter { state.selection.contains($0.id) }
                let assetsToMove = photosToMove.compactMap { $0.asset }
                return .run { [album = state.album.assetCollection] send in
                    try await self.photoLibraryClient.addPhotos(assetsToMove, toAlbum)
                    try await PHPhotoLibrary.shared().performChanges {
                        guard let changeRequest = PHAssetCollectionChangeRequest(for: album) else { return }
                        changeRequest.removeAssets(assetsToMove as NSFastEnumeration)
                    }
                }
                
            case .destination(.presented(.albumTapped(let album))):
                return .send(.movePhotos(toAlbum: album.assetCollection))
                
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
