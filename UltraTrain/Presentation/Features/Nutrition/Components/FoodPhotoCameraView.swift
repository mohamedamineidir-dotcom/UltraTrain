import SwiftUI
@preconcurrency import AVFoundation

struct FoodPhotoCameraView: UIViewControllerRepresentable {
    let onPhotoTaken: (Data) -> Void

    func makeUIViewController(context: Context) -> FoodPhotoCameraViewController {
        let controller = FoodPhotoCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: FoodPhotoCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPhotoTaken: onPhotoTaken)
    }

    final class Coordinator: NSObject, FoodPhotoCameraDelegate {
        private let onPhotoTaken: (Data) -> Void

        init(onPhotoTaken: @escaping (Data) -> Void) {
            self.onPhotoTaken = onPhotoTaken
        }

        func didCapturePhoto(_ data: Data) {
            onPhotoTaken(data)
        }
    }
}

protocol FoodPhotoCameraDelegate: AnyObject {
    func didCapturePhoto(_ data: Data)
}

final class FoodPhotoCameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {

    weak var delegate: FoodPhotoCameraDelegate?
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasCaptured = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        checkCameraPermission()
    }

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    Task { @MainActor in self?.setupCamera() }
                } else {
                    Task { @MainActor in self?.showPermissionDeniedLabel() }
                }
            }
        default:
            showPermissionDeniedLabel()
        }
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            showUnavailableLabel()
            return
        }
        session.addInput(input)

        let output = AVCapturePhotoOutput()
        guard session.canAddOutput(output) else {
            showUnavailableLabel()
            return
        }
        session.addOutput(output)
        photoOutput = output

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.layer.bounds
        view.layer.addSublayer(preview)
        previewLayer = preview

        captureSession = session

        let capturedSession = session
        Task.detached(priority: .userInitiated) {
            capturedSession.startRunning()
        }

        setupCaptureButton()
        setupInstructionLabel()
    }

    private func setupCaptureButton() {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false

        let outerCircle = UIView()
        outerCircle.translatesAutoresizingMaskIntoConstraints = false
        outerCircle.backgroundColor = .white
        outerCircle.layer.cornerRadius = 36
        outerCircle.isUserInteractionEnabled = false

        let innerCircle = UIView()
        innerCircle.translatesAutoresizingMaskIntoConstraints = false
        innerCircle.backgroundColor = .white
        innerCircle.layer.cornerRadius = 30
        innerCircle.layer.borderWidth = 3
        innerCircle.layer.borderColor = UIColor.black.withAlphaComponent(0.2).cgColor
        innerCircle.isUserInteractionEnabled = false

        view.addSubview(outerCircle)
        outerCircle.addSubview(innerCircle)
        view.addSubview(button)

        NSLayoutConstraint.activate([
            outerCircle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            outerCircle.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            outerCircle.widthAnchor.constraint(equalToConstant: 72),
            outerCircle.heightAnchor.constraint(equalToConstant: 72),

            innerCircle.centerXAnchor.constraint(equalTo: outerCircle.centerXAnchor),
            innerCircle.centerYAnchor.constraint(equalTo: outerCircle.centerYAnchor),
            innerCircle.widthAnchor.constraint(equalToConstant: 60),
            innerCircle.heightAnchor.constraint(equalToConstant: 60),

            button.centerXAnchor.constraint(equalTo: outerCircle.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: outerCircle.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 72),
            button.heightAnchor.constraint(equalToConstant: 72)
        ])

        button.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        button.accessibilityLabel = "Take photo"
        button.accessibilityIdentifier = "foodPhoto.captureButton"
    }

    private func setupInstructionLabel() {
        let label = UILabel()
        label.text = "Take a photo of your food"
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .headline)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 1)
        label.layer.shadowOpacity = 0.7
        label.layer.shadowRadius = 3
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
    }

    @objc private func capturePhoto() {
        guard !hasCaptured, let photoOutput else { return }
        hasCaptured = true
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard let data = photo.fileDataRepresentation() else { return }
        Task { @MainActor [weak self] in
            self?.delegate?.didCapturePhoto(data)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }

    private func showUnavailableLabel() {
        let label = UILabel()
        label.text = "Camera unavailable.\nTry on a real device."
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func showPermissionDeniedLabel() {
        let label = UILabel()
        label.text = "Camera access denied.\nEnable in Settings > Privacy."
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
