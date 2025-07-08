//

import SwiftUI
import Scenes
import ComposableArchitecture

struct ContentView: View {
    var body: some View {
        AlbumListView(
            store: Store(initialState: AlbumListFeature.State()) {
                AlbumListFeature()
            }
        )
    }
}

#Preview {
    ContentView()
}
