
import SwiftUI
import ComposableArchitecture
import APFoundation

struct AlbumRowView: View {
    let album: Album
    let isEditing: Bool
    let isSelected: Bool
    let onTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(album.title)
            Text("Tags: \(album.tags.joined(separator: ", "))")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .simultaneousGesture(TapGesture().onEnded {
            onTapped()
        })
        .overlay(alignment: .topTrailing) {
            if isEditing {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(.blue)
                    .padding(5)
            }
        }
    }
}

#Preview {
    AlbumRowView(
        album: Album(title: "Sample Album", tags: ["Nature", "Travel"]),
        isEditing: true,
        isSelected: true,
        onTapped: {}
    )
}
