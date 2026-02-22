import SwiftUI

struct WaypointAnnotationView: View {
    let index: Int
    let totalCount: Int

    private var circleColor: Color {
        if index == 0 {
            return Theme.Colors.success
        } else if index == totalCount - 1 {
            return Theme.Colors.danger
        } else {
            return Theme.Colors.primary
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(circleColor)
                .frame(width: 24, height: 24)

            Text("\(index + 1)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Waypoint \(index + 1) of \(totalCount)")
    }
}
