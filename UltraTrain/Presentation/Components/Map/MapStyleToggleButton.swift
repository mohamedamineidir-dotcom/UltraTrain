import SwiftUI

struct MapStyleToggleButton: View {
    @Binding var style: MapStylePreference

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                style = nextStyle
            }
        } label: {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
    }

    private var nextStyle: MapStylePreference {
        switch style {
        case .standard: .satellite
        case .satellite: .hybrid
        case .hybrid: .standard
        }
    }

    private var iconName: String {
        switch style {
        case .standard: "map"
        case .satellite: "globe.americas"
        case .hybrid: "square.stack.3d.up"
        }
    }
}
