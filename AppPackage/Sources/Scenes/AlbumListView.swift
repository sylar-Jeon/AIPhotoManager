import ComposableArchitecture
import SwiftUI

public struct AlbumListView: View {
    @Bindable var store: StoreOf<AlbumListFeature>

    public var body: some View {
        NavigationStackStore(self.store.scope(state: \.path, action: \.path)) {
            Group {
                if store.isLoading {
                    ProgressView()
                } else {
                    List {
                        ForEach(store.albums) { album in
                            NavigationLink(state: AlbumDetailFeature.State(album: album)) {
                                AlbumRowView(
                                    album: album,
                                    isEditing: store.isEditingAlbums,
                                    isSelected: store.selection.contains(album.id),
                                    onTapped: {
                                        store.send(.albumTapped(album))
                                    }
                                )
                            }
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(store.isEditingAlbums ? "Done" : "Edit") {
                        store.send(.setEditMode(isEditing: !store.isEditingAlbums))
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    if store.isEditingAlbums {
                        Button("Merge Selected (\(store.selection.count))") {
                            store.send(.mergeButtonTapped)
                        }
                        .disabled(store.selection.count < 2)
                    }
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        } destination: { store in
            AlbumDetailView(store: store)
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
