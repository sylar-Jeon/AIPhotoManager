
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
        
        public init(album: Album, photos: IdentifiedArrayOf<Photo> = [], isLoadingPhotos: Bool = false) {
            self.album = album
            self.photos = photos
            self.isLoadingPhotos = isLoadingPhotos
        }
    }

    public enum Action {
        case onAppear
        case photosLoaded([PHAsset])
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
            }
        }
    }
    
    public init() {}
}
