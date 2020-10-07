//
//  DefaultCapturerVideoSource.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import AVFoundation
import Foundation

@objcMembers public class DefaultCameraCaptureSource: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, VideoSource {
    private let sinks = ConcurrentMutableSet()

    private var session = AVCaptureSession()
    private var device: AVCaptureDevice?
    private var input: AVCaptureDeviceInput?
    private var output = AVCaptureVideoDataOutput()

    private let kNanosecondsPerSecond = 1000000000

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

    public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let buffer = VideoFramePixelBuffer(pixelBuffer: pixelBuffer)
        let timestamp = CMTimeGetSeconds(CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer))
            * Double(kNanosecondsPerSecond)
        let frame = VideoFrame(width: buffer.width(),
                               height: buffer.height(),
                               timestamp: Int(timestamp),
                               rotation: 0,
                               buffer: buffer)
        ObserverUtils.forEach(observers: self.sinks) { (sink: VideoSink) in
            sink.onVideoFrameReceived(frame: frame)
        }
    }
}
