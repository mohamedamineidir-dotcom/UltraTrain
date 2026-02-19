import SwiftUI

struct NutritionIntervalPicker: View {
    let label: String
    @Binding var valueMinutes: Int
    let range: [Int]
    let allowOff: Bool

    init(label: String, valueMinutes: Binding<Int>, range: [Int], allowOff: Bool = false) {
        self.label = label
        self._valueMinutes = valueMinutes
        self.range = range
        self.allowOff = allowOff
    }

    var body: some View {
        Picker(label, selection: $valueMinutes) {
            if allowOff {
                Text("Off").tag(0)
            }
            ForEach(range, id: \.self) { minutes in
                Text("\(minutes) min").tag(minutes)
            }
        }
    }
}
