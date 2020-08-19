//
//  VXRecognitionViewController.swift
//  mushroom
//
//  Created by Graham Lancashire on 18.06.19.
//  Copyright © 2019 Swift Management AG. All rights reserved.
//

import AVFoundation
import Foundation
import UIKit

class VXRecognitionViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var model: VXRecognitionModelProtocol?
    var predictions = [VXRecognitionPrediction]()

    var lastRecognition: Date?
    var recognitionRate = 1.0 / 10.0
    var recognitionRetentionTime = 10.0
    var confidenceAutoStop = 0.85

    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.frame = view.bounds
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        return layer
    }()

    lazy var cameraPreview: UIView = {
        let view = UIView()
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = UIColor.darkGray

        view.layer.addSublayer(self.previewLayer)
        return view
    }()

    lazy var collectionViewHeightConstraint: NSLayoutConstraint = {
        let size = VXRecognitionCell.defaultSize()

        return self.collectionView.heightAnchor.constraint(equalToConstant: size.height)
    }()

    lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()

        flowLayout.scrollDirection = .horizontal

        let cv = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: flowLayout)

        cv.dataSource = self
        cv.delegate = self

        cv.backgroundColor = UIColor.clear
        cv.isScrollEnabled = true
        cv.allowsMultipleSelection = false
        cv.allowsSelection = true
        cv.register(VXRecognitionCell.self, forCellWithReuseIdentifier: String(describing: VXRecognitionCell.self))
        return cv
    }()

    lazy var photoButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(named: "photoPick"), style: .done, target: self, action: #selector(handlePhotoButton(_:)))

        return button
    }()

    lazy var flashButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(named: "cameraTorchOff"), style: .done, target: self, action: #selector(handleFlashButton(_:)))

        return button
    }()

    lazy var sessionButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(named: "sessionStart"), style: .done, target: self, action: #selector(toggleSession(_:)))

        return button
    }()

    // let cameraButton = UIView()
    let captureSession = AVCaptureSession()

    let videoDataOutput = AVCaptureVideoDataOutput()
    var videoConnection: AVCaptureConnection?
    var activeInput: AVCaptureDeviceInput?
    var lastExecutedAt: Date?
    var pendingChanges: Bool = false

    private let sessionQueue = DispatchQueue(label: "SessionQueue")
    private var isConfigured = false
    private var isAuthorized = false
    private var isProcessing = false

    var cameraPosition = AVCaptureDevice.Position.back {
        didSet {
            sessionQueue.async {
                guard self.isConfigured else { return }

                let sessionIsRunning = self.captureSession.isRunning
                if sessionIsRunning {
                    self.captureSession.stopRunning()
                }

                guard self.setSessionInput() else {
                    print("[Error] setSessionInput failed")
                    return
                }

                self.setVideoOrientation()
                self.setVideoMirrored()

                if sessionIsRunning {
                    self.captureSession.startRunning()
                }
            }
        }
    }

    // MARK: - session configuration

    // video quality
    var videoQuality = AVCaptureSession.Preset.vga640x480 {
        didSet {
            sessionQueue.async {
                guard self.isConfigured else { return }

                self.captureSession.beginConfiguration()
                self.captureSession.sessionPreset = self.videoQuality
                self.captureSession.commitConfiguration()
            }
        }
    }

    var deviceOrientation = UIDeviceOrientation.portrait {
        didSet {
            guard deviceOrientation != oldValue else { return }

            switch deviceOrientation {
            case .portrait,
                 .portraitUpsideDown,
                 .landscapeLeft,
                 .landscapeRight:
                sessionQueue.async {
                    guard self.isConfigured else { return }

                    let sessionIsRunning = self.captureSession.isRunning
                    if sessionIsRunning {
                        self.captureSession.stopRunning()
                    }

                    self.setVideoOrientation()

                    if sessionIsRunning {
                        self.captureSession.startRunning()
                    }
                }
            default:
                deviceOrientation = oldValue
            }
        }
    }

    // video orientation
    private var videoOrientation: AVCaptureVideoOrientation {
        switch deviceOrientation {
        case .portrait:
            return AVCaptureVideoOrientation.portrait
        case .portraitUpsideDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        case .landscapeLeft:
            return AVCaptureVideoOrientation.landscapeRight
        case .landscapeRight:
            return AVCaptureVideoOrientation.landscapeLeft
        default:
            print("[WARN] unsupported deviceOrientation: \(deviceOrientation.rawValue)")
            return AVCaptureVideoOrientation.portrait
        }
    }

    // MARK: - Basic Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = false

        view.backgroundColor = UIColor.black
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // prepare UI
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isProcessing = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        torchMode(mode: .off)
        sessionState(false)
        isProcessing = false

        super.viewWillDisappear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = cameraPreview.bounds
    }

    // MARK: - Permission

    // check the permission for accessing camera
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            isAuthorized = true

        case .notDetermined:
            // stop session queue from executing configuring operation
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { success in
                self.isAuthorized = success
                // resume session queue to execute configuring operation
                self.sessionQueue.resume()
            })

        case .denied,
             .restricted:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }

    // MARK: - UI

    func setupUI() {
        // toolbar
        let buttons = [sessionButton, flashButton, photoButton]
        navigationItem.rightBarButtonItems = buttons

        // camerapreview
        view.addSubview(cameraPreview)
        cameraPreview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cameraPreview.topAnchor.constraint(equalTo: view.topAnchor),
            cameraPreview.leftAnchor.constraint(equalTo: view.leftAnchor),
            cameraPreview.rightAnchor.constraint(equalTo: view.rightAnchor),
            cameraPreview.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // camerapreview (collectionview)
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16.0),
            collectionView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16.0),
            collectionView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16.0),
            collectionViewHeightConstraint,
        ])
    }

    func torchMode(mode: AVCaptureDevice.TorchMode) {
        if let device = activeInput?.device, device.hasFlash {
            if device.torchMode != mode {
                captureSession.beginConfiguration()

                do {
                    try device.lockForConfiguration()
                    device.torchMode = mode
                    device.unlockForConfiguration()

                    flashButton.image = UIImage(named: device.torchMode == .on ? "cameraTorchOn" : "cameraTorchOff")

                } catch {
                    print(error.localizedDescription)
                }
                captureSession.commitConfiguration()
            }
        }
    }

    func sessionState(_ on: Bool) {
        if on {
            // make sure session is configured
            configure()
            // clear camerapreview
            addPreviewImage(image: nil)
        }

        if captureSession.isRunning == on {
            return
        }

        sessionButton.image = UIImage(named: on ? "sessionStop" : "sessionStart")

        // toggle session
        sessionQueue.async {
            if on {
                self.captureSession.startRunning()
            } else {
                self.captureSession.stopRunning()
            }
        }
    }

    @objc internal func toggleSession(_: UIBarButtonItem) {
        let isRunning = captureSession.isRunning

        sessionState(!isRunning)
    }

    @objc internal func handlePhotoButton(_: UIBarButtonItem) {
        sessionState(false)

        if Config.isDebug, false {
            let fileManager = FileManager.default

            guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.path else {
                return
            }

            do {
                let files = try fileManager.contentsOfDirectory(atPath: documentsPath + "/validation")
                for file in files {
                    print(file)
                    if let image = UIImage(contentsOfFile: documentsPath + "/validation/" + file) {
                        model?.recognize(image: image, completion: { predictions in
                            if let p = predictions?.first {
                                print("\(file) > \(file.split(separator: ".").first?.split(separator: "_").first ?? "") > \(p.name) > \(p.confidence ?? 0.0)")
                            } else {
                                print("\(file) > \(file.split(separator: ".").first?.split(separator: "_").first ?? "") > >")
                            }
                        })
                    }
                }

            } catch {
                print(error)
            }
        }

        // Get an image
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.allowsEditing = true
        pickerController.mediaTypes = ["public.image"]
        pickerController.sourceType = .photoLibrary
        present(pickerController, animated: true)
    }

    @objc internal func handleFlipButton(_: UIBarButtonItem) {
        cameraPosition = (cameraPosition == .front ? .back : .front)
    }

    @objc internal func handleFlashButton(_: UIBarButtonItem) {
        // toggle torch mode
        if let device = activeInput?.device, device.hasFlash {
            torchMode(mode: device.torchMode == .on ? .off : .on)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        collectionView.reloadData()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        let size = VXRecognitionCell.defaultSize()
        collectionViewHeightConstraint.constant = size.height
        collectionView.reloadData()
    }

    // MARK: - Setup Camera

    // set the orientation of the captured video buffer
    private func setVideoOrientation() {
        if let connection = videoDataOutput.connection(with: AVMediaType.video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = videoOrientation
            }
        }
    }

    // set the mirroring of the captured video buffer
    private func setVideoMirrored() {
        if let connection = videoDataOutput.connection(with: AVMediaType.video) {
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = cameraPosition == .front
            }
        }
    }

    // set input device
    private func setSessionInput() -> Bool {
        // discover the video capture device which matches the camera position
        func discoverCaptureDevice() -> AVCaptureDevice? {
            let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: .video, position: cameraPosition).devices
            if let captureDevice = devices.first {
                return captureDevice
            }
            return nil
        }

        guard let newCaptureDevice = discoverCaptureDevice() else {
            print("[Error] discoverCaptureDevice failed")
            return false
        }

        guard let newCaptureInput = try? AVCaptureDeviceInput(device: newCaptureDevice) else {
            print("[Error] init AVCaptureDeviceInput failed")
            return false
        }
        activeInput = newCaptureInput

        // modify session configuration
        captureSession.beginConfiguration()

        let currentInputs = captureSession.inputs
        for input in currentInputs {
            captureSession.removeInput(input)
        }

        if captureSession.canAddInput(newCaptureInput) {
            captureSession.addInput(newCaptureInput)
        }
        do {
            try newCaptureDevice.lockForConfiguration()
            let format = newCaptureDevice.activeFormat
            let desiredFrameRate: Int32 = 5
            let epsilon: Double = 0.00000001

            for range in format.videoSupportedFrameRateRanges {
                if range.minFrameRate <= (Double(desiredFrameRate) + epsilon),
                    range.maxFrameRate >= (Double(desiredFrameRate) - epsilon)
                {
                    newCaptureDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: desiredFrameRate)
                    newCaptureDevice.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: desiredFrameRate)
                    break
                }
            }
            newCaptureDevice.unlockForConfiguration()
        } catch {
            print(error.localizedDescription)
        }

        captureSession.commitConfiguration()

        return true
    }

    // set output device
    private func setSessionOutput() -> Bool {
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoDataOutputQueue"))

        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
            // videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: NSNumber(value: kCVPixelFormatType_32BGRA)]
            videoDataOutput.alwaysDiscardsLateVideoFrames = true

            setVideoOrientation()
            setVideoMirrored()
            // self.frameRate = 15

            return true
        }

        return false
    }

    // configure capture device and session
    func configure() {
        sessionQueue.async {
            guard !self.isConfigured else { return }

            self.checkPermission()
        }

        sessionQueue.async {
            guard !self.isConfigured else { return }

            guard self.isAuthorized else {
                print("[Error] permission denied")
                return
            }

            guard self.setSessionInput() else {
                print("[Error] setSessionInput failed")
                return
            }

            guard self.setSessionOutput() else {
                print("[Error] setSessionOutput failed")
                return
            }

            // set the capturing quality
            self.captureSession.sessionPreset = self.videoQuality

            self.isConfigured = true
            print("[Info] configure done !")
        }
    }

    func normalizedVideoFrame(_ frame: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(frame) else {
            return nil
        }
        let coreImage: CIImage = CIImage(cvPixelBuffer: imageBuffer)
        let context: CIContext = CIContext()
        guard let sample: CGImage = context.createCGImage(coreImage, from: coreImage.extent) else {
            return nil
        }
        return UIImage(cgImage: sample)
    }

    func captureOutput(_: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from _: AVCaptureConnection) {
        guard isProcessing else {
            return
        }

        guard let image = normalizedVideoFrame(sampleBuffer) else {
            return
        }
        if let d = lastRecognition {
            if abs(d.timeIntervalSinceNow) >= recognitionRate {
                lastRecognition = Date()
            } else {
                return
            }

        } else {
            lastRecognition = Date()
        }

        didCapture(image: image)
    }

    // MARK: - Cell Configuration (to be overriden)

    func configureCell(_ cell: VXRecognitionCell, prediction: VXRecognitionPrediction) {
        cell.prediction = prediction
        // do nothing, should be implemented in subclass
    }

    func selectPrediction(_: VXRecognitionPrediction) {
        // do nothing, should be implemented in subclass
        sessionState(false)
    }

    func filterPrediction(_: VXRecognitionPrediction) -> Bool {
        return true
    }

    // MARK: - Recognition handling

    func didCapture(image: UIImage) {
        model?.recognize(image: image, completion: { predictions in
            // a flow of predictions pours in
            if let ps = predictions, ps.count > 0 {
                var fastUpdate = self.predictions.count == 0

                for p in ps {
                    // check for existing predictions and replace them
                    if let row = self.predictions.firstIndex(where: { $0.name == p.name }) {
                        // only mark change when more than 5% change
                        self.pendingChanges = self.pendingChanges || (abs((p.confidence ?? 0.0) - (self.predictions[row].confidence ?? 0.0)) > 0.05)

                        self.predictions[row].confidence = p.confidence
                        print("updating \(p)")

                    } else if self.filterPrediction(p) {
                        // add new ones
                        self.predictions.append(p)
                        print("adding \(p)")
                        self.pendingChanges = true
                    }

                    // automatically stop if confidence higher than 0.85
                    if let confidence = p.confidence, confidence >= Float(self.confidenceAutoStop) {
                        // stop processing
                        self.sessionState(false)
                        fastUpdate = true
                    }
                }
                // filter out old predictions and remove them
                self.predictions = self.predictions.filter { abs($0.date?.timeIntervalSinceNow ?? 0.0) <= self.recognitionRetentionTime }

                // sort
                self.predictions.sort(by: { ($0.confidence ?? 0.0) > ($1.confidence ?? 0.0) })

                // check when last executed
                let timeInterval = Date().timeIntervalSince(self.lastExecutedAt ?? .distantPast)

                if timeInterval > 2.0 || fastUpdate, self.pendingChanges {
                    // Record execution
                    self.lastExecutedAt = Date()
                    self.pendingChanges = false
                    DispatchQueue.main.async {
                        print("Reload")
                        self.collectionView.reloadData()
                    }
                }
            }

        })
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource

extension VXRecognitionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return predictions.count
        // return min(self.predictions.count, 2)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: VXRecognitionCell.self), for: indexPath)

        if let c = cell as? VXRecognitionCell, self.predictions.count > indexPath.row {
            let prediction = self.predictions[indexPath.row]
            self.configureCell(c, prediction: prediction)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // do nothing, should be implemented in subclass
        // open detail view controller
        if let cell = collectionView.cellForItem(at: indexPath) as? VXRecognitionCell, let prediction = cell.prediction {
            selectPrediction(prediction)
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension VXRecognitionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        return VXRecognitionCell.defaultSize()
    }
}

extension VXRecognitionViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    //
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // clear camerapreview
        addPreviewImage(image: nil)
        predictions.removeAll()
        collectionView.reloadData()

        // do nothing
        picker.dismiss(animated: true, completion: nil)
    }

    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any])
    {
        picker.dismiss(animated: true, completion: nil)

        predictions.removeAll()
        collectionView.reloadData()

        guard let image = info[.editedImage] as? UIImage else {
            addPreviewImage(image: nil)
            return
        }
        // draw on camerapreview
        addPreviewImage(image: image)

        // self.cameraPreview.
        view.backgroundColor = UIColor.darkGray
        // Recognize it
        didCapture(image: image)
    }

    public func addPreviewImage(image: UIImage?) {
        // remove existing
        for s in cameraPreview.subviews {
            if let iv = s as? UIImageView {
                iv.removeFromSuperview()
            }
        }

        if let i = image {
            let imageView = UIImageView(image: i)
            imageView.tag = 999
            imageView.frame = cameraPreview.bounds
            imageView.contentMode = .scaleAspectFill
            imageView.translatesAutoresizingMaskIntoConstraints = false
            cameraPreview.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: cameraPreview.topAnchor),
                imageView.leftAnchor.constraint(equalTo: cameraPreview.leftAnchor),
                imageView.rightAnchor.constraint(equalTo: cameraPreview.rightAnchor),
                imageView.bottomAnchor.constraint(equalTo: cameraPreview.bottomAnchor),
            ])
        }
    }
}
