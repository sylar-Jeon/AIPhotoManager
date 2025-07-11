
import SwiftUI

public enum AppColor {
    public static let primary = Color.blue
    public static let secondary = Color.gray
    public static let background = Color(.systemBackground)
    public static let textPrimary = Color(.label)
    public static let textSecondary = Color(.secondaryLabel)
}

public enum AppFont {
    public static let largeTitle = Font.largeTitle
    public static let title = Font.title
    public static let headline = Font.headline
    public static let body = Font.body
    public static let caption = Font.caption
}

public enum AppSpacing {
    public static let small: CGFloat = 8
    public static let medium: CGFloat = 16
    public static let large: CGFloat = 24
}
