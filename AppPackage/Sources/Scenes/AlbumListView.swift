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
                            NavigationLink(destination:
                                AlbumDetailView(
                                    store: store.scope(
                                        state: \.albums[id: album.id]!,
                                        action: \.album(id: album.id, action: .self)
                                    )
                                )
                            ) {
                                VStack(alignment: .leading) {
                                    Text(album.title)
                                    Text("Tags: \(album.tags.joined(separator: ", "))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .simultaneousGesture(TapGesture().onEnded { // Handle selection in edit mode
                                if store.isEditingAlbums {
                                    store.send(.albumTapped(album))
                                }
                            })
                            .overlay(alignment: .topTrailing) {
                                if store.isEditingAlbums {
                                    Image(systemName: store.selection.contains(album.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(.blue)
                                        .padding(5)
                                }
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
