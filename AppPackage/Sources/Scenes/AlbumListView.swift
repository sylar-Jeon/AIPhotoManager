
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
                    }
                }
            }
            .navigationTitle("Albums")
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
