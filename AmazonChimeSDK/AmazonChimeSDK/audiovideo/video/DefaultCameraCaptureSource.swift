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

@objcMembers public class DefaultCameraCaptureSource: NSObject, VideoSource {
    public var videoContentHint: VideoContentHint = .none
    public private(set) var isUsingFrontCamera = false

    private let deviceType = AVCaptureDevice.DeviceType.builtInWideAngleCamera
    private let sinks = ConcurrentMutableSet()
    private let output = AVCaptureVideoDataOutput()
    private let captureQueue = DispatchQueue(label: "captureQueue")

    private var session = AVCaptureSession()
    private var captureDevice: AVCaptureDevice? {
        return AVCaptureDevice.default(deviceType,
                                       for: .video,
                                       position: isUsingFrontCamera ? .front : .back)
    }

    public var device: MediaDevice? {
        get {
            guard session.isRunning, let captureDevice = captureDevice  else {
                return nil
            }
            return MediaDevice(label: captureDevice.localizedName, type: isUsingFrontCamera ? .videoFrontCamera : .videoBackCamera)
        }
        set(newDevice) {
            if let newDevice = newDevice {
                isUsingFrontCamera = newDevice.type == .videoFrontCamera
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
            return
        }
        session.addInput(deviceInput)

        output.setSampleBufferDelegate(self, queue: captureQueue)

        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        session.commitConfiguration()
        session.startRunning()
    }

    public func stop() {
        session.stopRunning()
    }

    public func switchCamera() {
        isUsingFrontCamera = !isUsingFrontCamera
        stop()
        start()
    }

    // TODO: not working, torch does not stay on
    public func toggleTorch(on: Bool) {
        if let captureDevice = captureDevice, captureDevice.hasTorch, captureDevice.isTorchAvailable {
            try? captureDevice.lockForConfiguration()
            if on {
                captureDevice.torchMode = .on
                try? captureDevice.setTorchModeOn(level: 1)
            } else {
                captureDevice.torchMode = .off
            }
            captureDevice.unlockForConfiguration()
        }
    }
}

extension DefaultCameraCaptureSource: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let buffer = VideoFramePixelBuffer(pixelBuffer: pixelBuffer)
        let timestampNs = CMTimeGetSeconds(CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer))
            * Double(Constants.nanosecondsPerSecond)
        var rotation: VideoRotation

        let orientation: UIDeviceOrientation = UIDevice.current.orientation
        print(orientation.rawValue)

        switch orientation {
        case .portrait:
            rotation = .rotation0
            connection.videoOrientation = .portrait
        case .landscapeLeft:
            rotation = .rotation90
            connection.videoOrientation = .landscapeLeft
        case .portraitUpsideDown:
            rotation = .rotation180
            connection.videoOrientation = .portraitUpsideDown
        case .landscapeRight:
            rotation = .rotation270
            connection.videoOrientation = .landscapeRight
        default:
            rotation = .rotation0
            connection.videoOrientation = .portrait
        }

        let frame = VideoFrame(timestampNs: Int64(timestampNs),
                               rotation: rotation,
                               buffer: buffer)
        ObserverUtils.forEach(observers: sinks) { (sink: VideoSink) in
            sink.onVideoFrameReceived(frame: frame)
        }
    }
}
