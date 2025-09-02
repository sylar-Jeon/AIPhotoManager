
import ComposableArchitecture
import SwiftUI
import PhotosUI
import APFoundation

public struct AlbumDetailView: View {
    @Bindable var store: StoreOf<AlbumDetailFeature>

    private let imageManager = PHCachingImageManager()
    private let thumbnailSize = CGSize(width: 150, height: 150)

    public var body: some View {
        VStack {
            Text(store.album.title ?? "Untitled Album")
                .font(.largeTitle)
                .padding()
            
            if store.isLoadingPhotos {
                ProgressView("Loading photos...")
            } else if store.photos.isEmpty {
                ContentUnavailableView("No Photos", systemImage: "photo")
            } else {
                photoGrid
            }
        }
        .navigationTitle(store.album.title ?? "Untitled Album")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { detailToolbar }
        .onAppear {
            store.send(.onAppear)
        }
        .sheet(item: $store.scope(state: \.destination, action: \.destination)) { store in
            AlbumSelectionView(store: store)
        }
        .fullScreenCover(item: $store.scope(state: \.photoViewer, action: \.photoViewer)) { store in
            PhotoViewerView(store: store)
        }
        .alert("Rename Album", isPresented: $store.isRenameAlertPresented.sending(\.setIsRenameAlertPresented)) {
            TextField("New Album Name", text: $renameText)
            Button("Rename") {
                store.send(.renameAlbum(newName: renameText))
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter a new name for the album.")
        }
    }

    @State private var renameText = ""

    private var photoGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                ForEach(store.photos) { photo in
                    PhotoThumbnailView(asset: photo.asset, imageManager: imageManager, thumbnailSize: thumbnailSize)
                        .onTapGesture {
                            store.send(.photoTapped(photo))
                        }
                        .overlay(alignment: .topTrailing) {
                            if store.isEditing {
                                Image(systemName: store.selection.contains(photo.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(.blue)
                                    .padding(5)
                            }
                        }
                }
            }
            .padding()
        }
    }

    @ToolbarContentBuilder
    private var detailToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(store.isEditing ? "Done" : "Select") {
                store.send(.setEditMode(isEditing: !store.isEditing))
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Rename") {
                store.send(.renameButtonTapped)
            }
        }
        ToolbarItem(placement: .bottomBar) {
            if store.isEditing {
                Button("Move Selected (\(store.selection.count))") {
                    store.send(.moveButtonTapped)
                }
                .disabled(store.selection.isEmpty)
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
        store: Store(initialState: AlbumDetailFeature.State(album: AlbumModel(assetCollection: PHAssetCollection()))) {
            AlbumDetailFeature()
        }
    )
}
