import MapKit
import SwiftUI

struct RunReplayView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: RunReplayViewModel

    init(run: CompletedRun) {
        _viewModel = State(initialValue: RunReplayViewModel(run: run))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                mapContent
                controlsOverlay
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        viewModel.pause()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("runReplay.doneButton")
                }
            }
            .task {
                viewModel.prepare()
            }
        }
    }

    // MARK: - Map Content

    private var mapContent: some View {
        Map {
            // Completed route up to current position
            if !viewModel.routeUpToCurrent.isEmpty {
                MapPolyline(coordinates: viewModel.routeUpToCurrent)
                    .stroke(Theme.Colors.primary, lineWidth: 4)
            }

            // Remaining route (grayed out)
            if !viewModel.remainingRoute.isEmpty {
                MapPolyline(coordinates: viewModel.remainingRoute)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 3)
            }

            // Start marker
            if let startCoord = viewModel.frames.first?.coordinate {
                Annotation("Start", coordinate: startCoord) {
                    startMarker
                }
            }

            // Finish marker
            if viewModel.frames.count > 1,
               let endCoord = viewModel.frames.last?.coordinate {
                Annotation("Finish", coordinate: endCoord) {
                    finishMarker
                }
            }

            // Current position marker
            if let current = viewModel.currentCoordinate {
                Annotation("", coordinate: current, anchor: .center) {
                    currentPositionMarker
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }

    // MARK: - Markers

    private var startMarker: some View {
        Circle()
            .fill(Theme.Colors.success)
            .frame(width: 14, height: 14)
            .overlay(
                Circle()
                    .stroke(.white, lineWidth: 2)
            )
            .shadow(radius: 2)
    }

    private var finishMarker: some View {
        Image(systemName: "flag.fill")
            .font(.caption)
            .foregroundStyle(.white)
            .padding(Theme.Spacing.xs)
            .background(
                Circle()
                    .fill(Theme.Colors.danger)
            )
            .shadow(radius: 2)
    }

    private var currentPositionMarker: some View {
        ZStack {
            Circle()
                .fill(Theme.Colors.primary.opacity(0.3))
                .frame(width: 28, height: 28)

            Circle()
                .fill(Theme.Colors.primary)
                .frame(width: 14, height: 14)
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: 2)
                )
        }
        .shadow(radius: 3)
    }

    // MARK: - Controls Overlay

    private var controlsOverlay: some View {
        VStack(spacing: Theme.Spacing.md) {
            ReplayStatsBar(
                pace: viewModel.currentPaceFormatted,
                heartRate: viewModel.currentHRFormatted,
                elevation: viewModel.currentElevationFormatted,
                distance: viewModel.currentDistanceFormatted
            )

            sliderSection

            ReplayControlsBar(
                isPlaying: viewModel.isPlaying,
                currentSpeed: viewModel.playbackSpeed,
                onTogglePlayPause: { viewModel.togglePlayPause() },
                onSpeedChanged: { viewModel.setSpeed($0) }
            )
        }
        .padding(Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Slider

    private var sliderSection: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Slider(
                value: Binding(
                    get: { viewModel.progress },
                    set: { newValue in
                        viewModel.pause()
                        viewModel.seekTo(progress: newValue)
                    }
                ),
                in: 0...1
            )
            .tint(Theme.Colors.primary)
            .accessibilityLabel("Replay progress")
            .accessibilityValue(
                "\(viewModel.elapsedTimeFormatted) of \(viewModel.totalTimeFormatted)"
            )
            .accessibilityIdentifier("runReplay.progressSlider")

            HStack {
                Text(viewModel.elapsedTimeFormatted)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.Colors.secondaryLabel)

                Spacer()

                Text(viewModel.totalTimeFormatted)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
    }
}
