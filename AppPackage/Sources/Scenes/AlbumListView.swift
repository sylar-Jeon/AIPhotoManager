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
                            NavigationLink(destination: AlbumDetailView(
                                store: Store(initialState: AlbumDetailFeature.State(album: album)) {
                                    AlbumDetailFeature()
                                }
                            )) {
                                VStack(alignment: .leading) {
                                    Text(album.title)
                                    Text("Tags: \(album.tags.joined(separator: ", "))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
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
