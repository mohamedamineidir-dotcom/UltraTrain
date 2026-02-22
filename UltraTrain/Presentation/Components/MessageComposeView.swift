import SwiftUI
import MessageUI

struct MessageComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    let onFinished: @MainActor @Sendable () -> Void

    static var canSendText: Bool {
        MFMessageComposeViewController.canSendText()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinished: onFinished)
    }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.recipients = recipients
        controller.body = body
        controller.messageComposeDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(
        _ uiViewController: MFMessageComposeViewController,
        context: Context
    ) {}

    // MARK: - Coordinator

    final class Coordinator: NSObject, @preconcurrency MFMessageComposeViewControllerDelegate {
        private let onFinished: @MainActor @Sendable () -> Void

        init(onFinished: @MainActor @Sendable @escaping () -> Void) {
            self.onFinished = onFinished
        }

        @MainActor
        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            controller.dismiss(animated: true) { [onFinished] in
                onFinished()
            }
        }
    }
}
