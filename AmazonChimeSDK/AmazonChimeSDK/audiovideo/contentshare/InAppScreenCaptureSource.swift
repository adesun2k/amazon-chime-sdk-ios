//
//  InAppScreenCaptureSource.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import ReplayKit

/// `InAppScreenCaptureSource` is used to share  screen capture within the app. When the app is in the background,
/// there is no sample sent to handler, and screen sharing is paused. `InAppScreenCaptureSource` is only available
/// on iOS 11+ because of `RPScreenRecorder.startCapture(handler:completionHandler:)` method.
/// `InAppScreenCaptureSource` does not support rotation while it's in progress. 
@available(iOS 11.0, *)
@objcMembers public class InAppScreenCaptureSource: NSObject, VideoCaptureSource {
    public var videoContentHint: VideoContentHint = .text

    private let logger: Logger
    private let observers = ConcurrentMutableSet()
    private let sinks = ConcurrentMutableSet()
    private var screenRecorder: RPScreenRecorder {
        return RPScreenRecorder.shared()
    }

    public init(logger: Logger) {
        self.logger = logger
        super.init()
    }

    public func start() {
        if screenRecorder.isRecording {
            stop()
        }
        screenRecorder.startCapture(handler: { [weak self] sampleBuffer, sampleBufferType, error in
            guard let strongSelf = self else { return }
            if error != nil {
                strongSelf.logger.error(msg: "RPScreenRecorder capture error received: \(error.debugDescription)")
            } else {
                switch sampleBufferType {
                case .video:
                    strongSelf.processVideo(sampleBuffer: sampleBuffer)
                case .audioApp, .audioMic:
                    break
                @unknown default:
                    break
                }
            }
        }, completionHandler: { [weak self] error in
            guard let strongSelf = self else { return }
            if let error = error {
                strongSelf.logger.error(msg: "RPScreenRecorder start failed: \(error.localizedDescription)" )
                ObserverUtils.forEach(observers: strongSelf.observers) { (observer: CaptureSourceObserver) in
                    observer.captureDidFail(error: .systemFailure)
                }
            } else {
                strongSelf.logger.info(msg: "RPScreenRecorder start succeeded.")
                ObserverUtils.forEach(observers: strongSelf.observers) { (observer: CaptureSourceObserver) in
                    observer.captureDidStart()
                }
            }
        })
    }

    public func stop() {
        if !screenRecorder.isRecording {
            logger.info(msg: "RPScreenRecorder not recording, so skipping stop")
            return
        }
        screenRecorder.stopCapture { [weak self] error in
            guard let strongSelf = self else { return }
            if let error = error {
                strongSelf.logger.error(msg: "RPScreenRecorder stop failed: \(error.localizedDescription)")
                ObserverUtils.forEach(observers: strongSelf.observers) { (observer: CaptureSourceObserver) in
                    observer.captureDidFail(error: .systemFailure)
                }
            } else {
                strongSelf.logger.info(msg: "RPScreenRecorder stop succeeded.")
                ObserverUtils.forEach(observers: strongSelf.observers) { (observer: CaptureSourceObserver) in
                    observer.captureDidStop()
                }
            }
        }
    }

    public func addCaptureSourceObserver(observer: CaptureSourceObserver) {
        observers.add(observer)
    }

    public func removeCaptureSourceObserver(observer: CaptureSourceObserver) {
        observers.remove(observer)
    }

    public func addVideoSink(sink: VideoSink) {
        sinks.add(sink)
    }

    public func removeVideoSink(sink: VideoSink) {
        sinks.remove(sink)
    }

    public func processVideo(sampleBuffer: CMSampleBuffer) {
        guard CMSampleBufferGetNumSamples(sampleBuffer) == 1,
              CMSampleBufferIsValid(sampleBuffer),
              CMSampleBufferDataIsReady(sampleBuffer),
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {

            ObserverUtils.forEach(observers: observers) { (observer: CaptureSourceObserver) in
                observer.captureDidFail(error: .invalidFrame)
            }
            logger.error(msg: "InAppScreenCaptureSource invalid frame received")
            return
        }

        let videoRotation = sampleBuffer.getVideoRotation()
        let timeStampNs = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) *
            Double(Constants.nanosecondsPerSecond)
        let frame = VideoFrame(timestampNs: Int64(timeStampNs),
                               rotation: videoRotation,
                               buffer: VideoFramePixelBuffer(pixelBuffer: pixelBuffer))
        sinks.forEach { sink in
            if let sink = sink as? VideoSink {
                sink.onVideoFrameReceived(frame: frame)
            }
        }
    }
}
