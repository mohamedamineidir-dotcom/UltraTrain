#if OWNER_MODE
import SwiftUI

/// Seven tappable day chips spanning the session's current week, so
/// the owner can move a session to a different day without leaving
/// this sheet. Deliberately constrained to the 7 days of
/// `weekStartDate...weekEndDate` (not the whole plan) — a cross-week
/// move is a bigger, separate operation this editor doesn't attempt.
struct OwnerDayPicker: View {
    let weekStartDate: Date
    @Binding var selectedDate: Date

    private var days: [Date] {
        (0...6).map { weekStartDate.adding(days: $0) }
    }

    var body: some View {
        // Horizontally scrollable rather than a fixed 7-across HStack:
        // a rigid 7-chip row can be wider than the phone's screen once
        // day-number/weekday text takes its natural minimum width,
        // which overflowed off the trailing edge. Scrolling guarantees
        // it fits at any screen size instead of relying on compression.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(days, id: \.self) { day in
                    dayChip(day)
                }
            }
        }
    }

    private func dayChip(_ day: Date) -> some View {
        let isSelected = Calendar.current.isDate(day, inSameDayAs: selectedDate)
        return Button {
            selectedDate = day
        } label: {
            VStack(spacing: 2) {
                Text(day.formatted(.dateTime.weekday(.narrow)))
                    .font(.caption2.weight(.bold))
                Text(day.formatted(.dateTime.day()))
                    .font(.subheadline.bold())
            }
            .frame(width: 46)
            .padding(.vertical, Theme.Spacing.xs)
            .foregroundStyle(isSelected ? .white : Theme.Colors.secondaryLabel)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                    .fill(isSelected ? OwnerModeTheme.purple : Color.white.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
    }
}
#endif
