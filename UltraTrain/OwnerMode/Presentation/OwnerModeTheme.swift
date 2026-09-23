#if OWNER_MODE
import SwiftUI

/// Shared accent for every owner-mode-only surface (banner, edit
/// sheet, loading screen) so it reads as one consistent "this is
/// owner mode" visual language rather than a patchwork of ad hoc
/// colors.
enum OwnerModeTheme {
    static let purple = Color(red: 0.62, green: 0.15, blue: 0.85)
}
#endif
