//
//  DefaultCapturerVideoSource.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import AVFoundation
import Foundation
import UIKit

@objcMembers public class DefaultCameraCaptureSource: NSObject, CameraCaptureSource {
    public var videoContentHint: VideoContentHint = .none

    private let deviceType = AVCaptureDevice.DeviceType.builtInWideAngleCamera
    private let sinks = ConcurrentMutableSet()
    private let captureSourceObservers = ConcurrentMutableSet()
    private let output = AVCaptureVideoDataOutput()
    private let captureQueue = DispatchQueue(label: "captureQueue")
    private static let defaultCaptureFormat = VideoCaptureFormat(width: (Constants.maxSupportedVideoHeight / 9) * 16,
                                                                 height: Constants.maxSupportedVideoHeight,
                                                                 maxFrameRate: Constants.maxSupportedVideoFrameRate)

    private var session = AVCaptureSession()
    private var orientation = UIDeviceOrientation.portrait
    private var captureDevice: AVCaptureDevice?

    override public init() {
        super.init()

        device = MediaDevice.listVideoDevices().first { mediaDevice in
            mediaDevice.type == MediaDeviceType.videoFrontCamera
        }
        captureDevice = AVCaptureDevice.default(deviceType,
                                               for: .video,
                                               position: .front)

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(deviceOrientationDidChange),
                                       name: UIDevice.orientationDidChangeNotification,
                                       object: nil)
    }

    public var device: MediaDevice? {
        didSet {
            guard let device = device else { return }
            let isUsingFrontCamera = device.type == .videoFrontCamera
            captureDevice = AVCaptureDevice.default(deviceType,
                                                    for: .video,
                                                    position: isUsingFrontCamera ? .front : .back)
            if session.isRunning {
                stop()
                start()
            }
        }
    }

    public var format: VideoCaptureFormat = defaultCaptureFormat {
        didSet {
            if captureDevice != nil, session.isRunning {
                stop()
                start()
            }
        }
    }

    public var torchEnabled: Bool = false {
        didSet {
            if let captureDevice = captureDevice, captureDevice.hasTorch, captureDevice.isTorchAvailable {
                try? captureDevice.lockForConfiguration()
                if torchEnabled {
                    captureDevice.torchMode = .on
                } else {
                    captureDevice.torchMode = .off
                }
                captureDevice.unlockForConfiguration()
            } else {
                torchEnabled = false
            }
        }
    }

    public func addVideoSink(sink: VideoSink) {
        sinks.add(sink)
    }

    public func removeVideoSink(sink: VideoSink) {
        sinks.remove(sink)
    }

    public func start() {
        session = AVCaptureSession()

        guard let captureDevice = captureDevice else {
            return
        }

        session.beginConfiguration()

        guard let deviceInput = try? AVCaptureDeviceInput(device: captureDevice),
            session.canAddInput(deviceInput) else {
            session.commitConfiguration()
            ObserverUtils.forEach(observers: captureSourceObservers) { (observer: CaptureSourceObserver) in
                observer.captureDidFail(error: .configurationFailure)
            }
            return
        }
        session.addInput(deviceInput)

        updateDeviceCaptureFormat()

        output.setSampleBufferDelegate(self, queue: captureQueue)

        if session.canAddOutput(output) {
            session.addOutput(output)
        } else {
            session.commitConfiguration()
            ObserverUtils.forEach(observers: captureSourceObservers) { (observer: CaptureSourceObserver) in
                observer.captureDidFail(error: .configurationFailure)
            }
            return
        }

        session.commitConfiguration()

        updateOrientation()

        session.startRunning()

        // If the torch was currently on, starting the sessions
        // would turn it off.  See if we can turn it back on.
        let currentTorchEnabled = torchEnabled
        self.torchEnabled = currentTorchEnabled

        ObserverUtils.forEach(observers: captureSourceObservers) { (observer: CaptureSourceObserver) in
            observer.captureDidStart()
        }
    }

    public func stop() {
        session.stopRunning()

        // If the torch was currently on, stopping the sessions
        // would turn it off.  See if we can turn it back on.
        let currentTorchEnabled = torchEnabled
        self.torchEnabled = currentTorchEnabled

        ObserverUtils.forEach(observers: captureSourceObservers) { (observer: CaptureSourceObserver) in
            observer.captureDidStop()
        }
    }

    public func switchCamera() {
        let isUsingFrontCamera = device?.type == .videoFrontCamera
        device = MediaDevice.listVideoDevices().first { mediaDevice in
            mediaDevice.type == (isUsingFrontCamera ? .videoBackCamera : .videoFrontCamera)
        }
    }

    public func addCaptureSourceObserver(observer: CaptureSourceObserver) {
        captureSourceObservers.add(observer)
    }

    public func removeCaptureSourceObserver(observer: CaptureSourceObserver) {
        captureSourceObservers.remove(observer)
    }

    private func updateOrientation() {
        guard let connection = output.connection(with: AVMediaType.video) else {
            return
        }
        orientation = UIDevice.current.orientation

        switch orientation {
        case .portrait:
            connection.videoOrientation = .portrait
        case .landscapeLeft:
            connection.videoOrientation = .landscapeRight
        case .portraitUpsideDown:
            connection.videoOrientation = .portraitUpsideDown
        case .landscapeRight:
            connection.videoOrientation = .landscapeLeft
        default:
            connection.videoOrientation = .portrait
        }
    }

    private func updateDeviceCaptureFormat() {
        guard let captureDevice = captureDevice else {
            return
        }
        // choose a supported format that is closest to `self.format`.
        try? captureDevice.lockForConfiguration()
        let newAVFormat = captureDevice.formats.min { avFormatA, avFormatB in
            let formatA = MediaDevice.getVideoCaptureFormat(from: avFormatA)
            let formatB = MediaDevice.getVideoCaptureFormat(from: avFormatB)
            let diffA = abs(formatA.width - format.width) + abs(formatA.height - format.height)
            let diffB = abs(formatB.width - format.width) + abs(formatB.height - format.height)
            return diffA < diffB
        }
        guard let chosenFormat = newAVFormat, chosenFormat != captureDevice.activeFormat else {
            captureDevice.unlockForConfiguration()
            return
        }
        captureDevice.activeFormat = chosenFormat
        captureDevice.unlockForConfiguration()
    }

    @objc private func deviceOrientationDidChange(notification: NSNotification) {
        captureQueue.async {
            self.updateOrientation()
        }
    }
}

extension DefaultCameraCaptureSource: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from _: AVCaptureConnection) {
        guard CMSampleBufferGetNumSamples(sampleBuffer) == 1,
            CMSampleBufferIsValid(sampleBuffer),
            CMSampleBufferDataIsReady(sampleBuffer),
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {

            ObserverUtils.forEach(observers: captureSourceObservers) { (observer: CaptureSourceObserver) in
                observer.captureDidFail(error: .systemFailure)
            }
            return
        }
        let buffer = VideoFramePixelBuffer(pixelBuffer: pixelBuffer)
        let timestampNs = CMTimeGetSeconds(CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer))
            * Double(Constants.nanosecondsPerSecond)

        let frame = VideoFrame(timestampNs: Int64(timestampNs),
                               rotation: .rotation0,
                               buffer: buffer)
        sinks.forEach { item in
            guard let sink = item as? VideoSink else { return }
            sink.onVideoFrameReceived(frame: frame)
        }
    }
}
