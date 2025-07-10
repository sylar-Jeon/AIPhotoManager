
import ComposableArchitecture
import SwiftUI
import APFoundation

public struct AlbumSelectionView: View {
    @Bindable var store: StoreOf<AlbumSelectionFeature>

    public var body: some View {
        NavigationView {
            List {
                ForEach(store.albums) { album in
                    Button(album.title) {
                        store.send(.albumTapped(album))
                    }
                }
            }
            .navigationTitle("Select Destination Album")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        store.send(.cancelButtonTapped)
                    }
                }
            }
        }
    }
    
    public init(store: StoreOf<AlbumSelectionFeature>) {
        self.store = store
    }
}

#Preview {
    AlbumSelectionView(
        store: Store(initialState: AlbumSelectionFeature.State(albums: [
            Album(title: "Album 1"),
            Album(title: "Album 2"),
            Album(title: "Album 3")
        ])) {
            AlbumSelectionFeature()
        }
    )
}
