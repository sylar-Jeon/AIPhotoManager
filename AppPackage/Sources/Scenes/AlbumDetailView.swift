
import ComposableArchitecture
import SwiftUI
import PhotosUI
import APFoundation

public struct AlbumDetailView: View {
    @Bindable var store: StoreOf<AlbumDetailFeature>

    private let imageManager = PHCachingImageManager()
    private let thumbnailSize = CGSize(width: 150, height: 150)

    public var body: some View {
        WithPerceptionTracking {
            VStack {
                Text(store.album.title)
                    .font(.largeTitle)
                    .padding()

                if store.isLoadingPhotos {
                    ProgressView("Loading photos...")
                } else if store.photos.isEmpty {
                    ContentUnavailableView("No Photos", systemImage: "photo")
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                            ForEach(store.photos) { photo in
                                PhotoThumbnailView(asset: photo.asset, imageManager: imageManager, thumbnailSize: thumbnailSize)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(store.album.title)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
    
    public init(store: StoreOf<AlbumDetailFeature>) {
        self.store = store
    }
}

struct PhotoThumbnailView: View {
    let asset: PHAsset
    let imageManager: PHCachingImageManager
    let thumbnailSize: CGSize
    @State private var image: Image? = nil

    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: thumbnailSize.width, height: thumbnailSize.height)
                    .clipped()
            } else {
                ProgressView()
                    .frame(width: thumbnailSize.width, height: thumbnailSize.height)
            }
        }
        .onAppear(perform: loadImage)
        .onChange(of: asset) { _ in loadImage() } // Reload image if asset changes
    }

    private func loadImage() {
        imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil) { uiImage, _ in
            if let uiImage = uiImage {
                self.image = Image(uiImage: uiImage)
            }
        }
    }
}

#Preview {
    AlbumDetailView(
        store: Store(initialState: AlbumDetailFeature.State(album: Album(title: "Sample Album", tags: ["Nature"]))) {
            AlbumDetailFeature()
        }
    )
}
