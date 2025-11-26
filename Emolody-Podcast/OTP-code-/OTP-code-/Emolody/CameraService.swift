import SwiftUI
import AVFoundation
import Vision
import CoreImage
import Combine

@MainActor
final class CameraService: NSObject, ObservableObject {

    // MARK: - Published (UI state)
    @Published var session = AVCaptureSession()
    @Published var isRunning = false
    @Published var moodText: String = "Analyzing your mood..."
    @Published var moodProgress: CGFloat = 0.12
    @Published var ringProgress: CGFloat = 0.0
    @Published var isAuthorized: Bool = false
    // MARK: - Queues
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    nonisolated let videoQueue = DispatchQueue(label: "camera.video.queue")

    // MARK: - Devices & IO
    private var deviceInput: AVCaptureDeviceInput?
    private var frontCamera: AVCaptureDevice?
    private let videoOutput = AVCaptureVideoDataOutput()

    // MARK: - CI
    private let ciContext = CIContext()

    // MARK: - Throttle & Smoothing
    /// نحتاج نقرأها ونكتبها من دالة delegate (خارج الـ MainActor) لذلك نسمّيها nonisolated(unsafe)
    nonisolated(unsafe) private var lastAnalysisTime: CFTimeInterval = 0
    private var ema: Double = 0 // exponential moving average

    // MARK: - Init
    override init() {
        super.init()
        // جهزي الكاميرا
        sessionQueue.async { [weak self] in
            Task { await self?.configureSession() }
        }
    }

    // MARK: - Public control
    func start() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
                Task { @MainActor in self.isRunning = true }
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                Task { @MainActor in self.isRunning = false }
            }
        }
    }

    // MARK: - Configure
    private func configureSession() async {
        session.beginConfiguration()
        session.sessionPreset = .high

        // كاميرا أمامية (لو TrueDepth موجودة خذيها، وإلا واسع الزاوية)
        if let cam = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front)
            ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            frontCamera = cam
        }

        guard let camera = frontCamera,
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        deviceInput = input

        // Video output
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        // توجيه
        if let conn = videoOutput.connection(with: .video) {
            if #available(iOS 17.0, *) {
                if conn.isVideoRotationAngleSupported(0) { conn.videoRotationAngle = 0 }
            } else {
                conn.videoOrientation = .portrait
            }
        }

        // Delegate على كيو خلفي
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)

        session.commitConfiguration()
    }
}

// MARK: - Permission
extension CameraService {
    func requestAccess(_ completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { ok in
                DispatchQueue.main.async { completion(ok) }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
}

// MARK: - Preview layer helper
extension CameraService {
    func makePreviewLayer() -> AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }
}

// MARK: - Delegate
extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {

    /// نخليها nonisolated عشان تشتغل على الـ videoQueue بدون قفز للـ Main
    nonisolated func captureOutput(_ output: AVCaptureOutput,
                                   didOutput sampleBuffer: CMSampleBuffer,
                                   from connection: AVCaptureConnection) {

        // Throttle: كل 0.15 ثانية تحليل
        let now = CACurrentMediaTime()
        if now - lastAnalysisTime < 0.15 { return }
        lastAnalysisTime = now

        guard let out = EmotionModelService.shared?.predict(from: sampleBuffer, isFront: true) else {
            // ما قدر يتنبأ — نخفف النص
            Task { @MainActor in
                self.moodText = "Please face the camera"
                self.moodProgress = 0.12
            }
            return
        }

        // UI update على MainActor + EMA smoothing
        Task { @MainActor in
            self.moodText = out.label
            self.ema = self.ema * 0.80 + Double(out.confidence) * 0.20
            self.moodProgress = CGFloat(max(0.08, min(1.0, self.ema)))
        }
    }
}
