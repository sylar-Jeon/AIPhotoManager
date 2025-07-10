
import ComposableArchitecture
import SwiftUI
import PhotosUI
import APFoundation

public struct PhotoViewerView: View {
    @Bindable var store: StoreOf<PhotoViewerFeature>

private let imageManager = PHCachingImageManager()

    public var body: some View {
        TabView(selection: $store.selectedPhotoID.sending(\.setSelectedPhotoID)) {
            ForEach(store.photos) { photo in
                FullPhotoView(asset: photo.asset, imageManager: imageManager)
                    .tag(photo.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            Button {
                store.send(.dismiss)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
            }
        }
    }
    
    public init(store: StoreOf<PhotoViewerFeature>) {
        self.store = store
    }
}

struct FullPhotoView: View {
    let asset: PHAsset
    let imageManager: PHCachingImageManager
    @State private var image: Image? = nil

    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
            }
        }
        .onAppear(perform: loadImage)
        .onChange(of: asset) { _ in loadImage() } // Reload image if asset changes
    }

    private func loadImage() {
        imageManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: nil) { uiImage, _ in
            if let uiImage = uiImage {
                self.image = Image(uiImage: uiImage)
            }
        }
    }
}

#Preview {
    PhotoViewerView(
        store: Store(initialState: PhotoViewerFeature.State(
            photos: [
                Photo(asset: PHAsset()), // Placeholder asset
                Photo(asset: PHAsset())  // Placeholder asset
            ],
            selectedPhotoID: "" // Placeholder ID
        )) {
            PhotoViewerFeature()
        }
    )
}
