import SwiftUI

struct MapStyleToggleButton: View {
    @Binding var style: MapStylePreference
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 16
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            if reduceMotion {
                style = nextStyle
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    style = nextStyle
                }
            }
        } label: {
            Image(systemName: iconName)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .accessibilityLabel("Map style")
        .accessibilityValue(accessibilityStyleName)
        .accessibilityHint("Cycles through map style options")
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

    private var accessibilityStyleName: String {
        switch style {
        case .standard: "Standard"
        case .satellite: "Satellite"
        case .hybrid: "Hybrid"
        }
    }
}
