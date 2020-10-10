//
//  DefaultCapturerVideoSource.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import AVFoundation
import Foundation

@objcMembers public class DefaultCameraCaptureSource: NSObject, VideoSource {
    public var videoContentHint: VideoContentHint = .none

    private let sinks = ConcurrentMutableSet()

    private var session = AVCaptureSession()
    private var device: AVCaptureDevice?
    private var input: AVCaptureDeviceInput?
    private var output = AVCaptureVideoDataOutput()

    public func addVideoSink(sink: VideoSink) {
        sinks.add(sink)
    }

    public func removeVideoSink(sink: VideoSink) {
        sinks.remove(sink)
    }

    public func start() {
        session = AVCaptureSession()
        device = AVCaptureDevice.default(for: AVMediaType.video)

        session.beginConfiguration()
        device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                         for: .video, position: .unspecified)
        guard
            let deviceInput = try? AVCaptureDeviceInput(device: device!),
            session.canAddInput(deviceInput)
        else { return }
        session.addInput(deviceInput)

        let queue = DispatchQueue(label: "captureQueue")
        output.setSampleBufferDelegate(self, queue: queue)

        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        session.commitConfiguration()
        session.startRunning()
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
        switch connection.videoOrientation {
        case .portrait:
            rotation = .rotation0
        case .portraitUpsideDown:
            rotation = .rotation180
        case .landscapeLeft:
            rotation = .rotation90
        case .landscapeRight:
            rotation = .rotation270
        @unknown default:
            rotation = .rotation0
        }

        let frame = VideoFrame(timestampNs: Int64(timestampNs),
                               rotation: rotation,
                               buffer: buffer)
        ObserverUtils.forEach(observers: self.sinks) { (sink: VideoSink) in
            sink.onVideoFrameReceived(frame: frame)
        }
    }
}
