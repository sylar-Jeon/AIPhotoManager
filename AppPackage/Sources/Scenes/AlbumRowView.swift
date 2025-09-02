
import SwiftUI
import ComposableArchitecture
import APFoundation
import Photos

struct AlbumRowView: View {
    let album: AlbumModel
    let isEditing: Bool
    let isSelected: Bool
    let onTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(album.title ?? "Untitled Album")
        }
        .simultaneousGesture(TapGesture().onEnded {
            onTapped()
        })
        .overlay(alignment: .topTrailing) {
            if isEditing {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(AppColor.primary)
                    .padding(AppSpacing.small)
            }
        }
    }
}

#Preview {
    AlbumRowView(
        album: AlbumModel(assetCollection: PHAssetCollection()),
        isEditing: true,
        isSelected: true,
        onTapped: {}
    )
}
