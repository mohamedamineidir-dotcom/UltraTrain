import SwiftUI

/// Wraps the camera and the analysis wait into ONE continuous
/// full-screen presentation. Camera → (photo taken) → analyzing overlay,
/// still the same presentation → `onFinished` fires only once analysis
/// has actually resolved.
///
/// This exists specifically so the parent's `fullScreenCover` doesn't
/// dismiss until results are ready: dismissing it earlier (e.g. right
/// after capture, before analysis finishes) would briefly reveal
/// whatever's underneath — the food-entry form — before the results
/// sheet gets presented, which read as "it flashed back to the form for
/// a split second."
struct FoodPhotoCaptureFlow: View {
    let analysisService: any FoodPhotoAnalysisServiceProtocol
    let onFinished: (Data, Result<[AnalyzedFoodItem], Error>) -> Void

    @State private var capturedPhotoData: Data?

    var body: some View {
        Group {
            if let capturedPhotoData {
                AnalyzingFoodPhotoView(photoData: capturedPhotoData)
                    .task {
                        do {
                            let items = try await analysisService.analyzePhoto(capturedPhotoData)
                            onFinished(capturedPhotoData, .success(items))
                        } catch {
                            onFinished(capturedPhotoData, .failure(error))
                        }
                    }
            } else {
                FoodPhotoCameraView { data in
                    capturedPhotoData = data
                }
            }
        }
    }
}
