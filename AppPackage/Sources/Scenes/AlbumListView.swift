import ComposableArchitecture
import SwiftUI

public struct AlbumListView: View {
    @Bindable var store: StoreOf<AlbumListFeature>

    public var body: some View {
        NavigationView {
            Group {
                if store.isLoading {
                    ProgressView()
                } else {
                    List {
                        ForEach(store.albums) { album in
                            Text(album.title)
                        }
                        if store.fetchedPhotosCount > 0 {
                            Text("Fetched \(store.fetchedPhotosCount) photos.")
                        }
                    }
                }
            }
            .navigationTitle("Albums")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Scan Photos") {
                        store.send(.scanButtonTapped)
                    }
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }

    public init(store: StoreOf<AlbumListFeature>) {
        self.store = store
    }
}

#Preview {
    AlbumListView(
        store: Store(initialState: AlbumListFeature.State()) {
            AlbumListFeature()
        }
    )
}
