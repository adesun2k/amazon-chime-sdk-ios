//
//  DefaultScreenCaptureSource.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import ReplayKit

// TODO: Move commented out frame drop/resend logic to separate class

/// `DefaultScreenCaptureSource` contains data pass through to sinks.
/// It does not directly contain any system library that captures the screen.
/// See `InAppScreenCaptureSource` if you want to only share screen from the app.
/// For device level screen broadcast, take a look at the `SampleHandler` in AmazonChimeSDKDemoBroadcast.
@objcMembers public class DefaultScreenCaptureSource: NSObject, VideoCaptureSource {
    public var videoContentHint: VideoContentHint = .text

    private let logger: Logger
    private let observers = ConcurrentMutableSet()
    private let sinks = ConcurrentMutableSet()

//    private let pixelBufferLockFlagReadOnly = CVPixelBufferLockFlags(rawValue: 0)
//    private let resendTimeIntervalMs = CMTime(value: CMTimeValue(Constants.millisecondsPerSecond / Constants.maxSupportedVideoFrameRate),
//                                              timescale: CMTimeScale(Constants.millisecondsPerSecond))
//    private let resendScheduleLeewayMs = DispatchTimeInterval.milliseconds(20)
//    private let resendQueue = DispatchQueue.global()
//    private var resendTimer: DispatchSourceTimer?
//
//    private var lastInputVideoFrame: CMSampleBuffer?
//    private var lastSendTimestamp: CMTime?

    public init(logger: Logger) {
        self.logger = logger
        super.init()
    }

    // For device level screen broadcast, app is responsible for starting the Broadcast Extension.
    // This method is overwritten in InAppScreenCaptureSource for In App only use case.
    public func start() {
    }

    public func stop() {
//        resendTimer?.cancel()
//        resendTimer = nil
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
            logger.error(msg: "DefaultScreenCaptureSource invalid frame received")
            return
        }
//        let currentTimestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
//        lastInputVideoFrame = sampleBuffer

//        // drop frame if the time difference is smaller than resendTimeInterval
//        if let lastTransmitTimestamp = self.lastSendTimestamp {
//            let delta = CMTimeSubtract(currentTimestamp, lastTransmitTimestamp)
//            if delta < resendTimeIntervalMs {
//                return
//            }
//        }

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

//    private func sendFrame(sampleBuffer: CMSampleBuffer) {
//        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
//            ObserverUtils.forEach(observers: observers) { (observer: CaptureSourceObserver) in
//                observer.captureDidFail(error: .invalidFrame)
//            }
//            logger.error(msg: "DefaultScreenCaptureSource invalid frame received")
//            return
//        }
//
//        let videoRotation = sampleBuffer.getVideoRotation()
//        let timeStampNs = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) *
//            Double(Constants.nanosecondsPerSecond)
//        let frame = VideoFrame(timestampNs: Int64(timeStampNs),
//                               rotation: videoRotation,
//                               buffer: VideoFramePixelBuffer(pixelBuffer: pixelBuffer))
//        sinks.forEach { sink in
//            if let sink = sink as? VideoSink {
//                sink.onVideoFrameReceived(frame: frame)
//            }
//        }
//
//        lastSendTimestamp = CMClockGetTime(CMClockGetHostTimeClock())
//        scheduleResendFrame()
//    }

//    private func scheduleResendFrame() {
//        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: resendQueue)
//        resendTimer = timer
//
//        // This timer is invoked every resendTimeInterval when no frame is sent from video source
//        timer.setEventHandler(handler: { [weak self] in
//            guard let strongSelf = self else {
//                timer.cancel()
//                return
//            }
//            if let lastInputVideoFrame = strongSelf.lastInputVideoFrame,
//                let lastSendTimestamp = strongSelf.lastSendTimestamp {
//
//                let currentTimestamp = CMClockGetTime(CMClockGetHostTimeClock())
//                let delta = CMTimeSubtract(currentTimestamp, lastSendTimestamp)
//
//                // Resend the last input frame if there is no new input frame after resendTimeInterval
//                if delta > strongSelf.resendTimeIntervalMs {
//                    strongSelf.sendFrame(sampleBuffer: lastInputVideoFrame)
//                } else {
//                    // Reset resending schedule if there is an input frame between internals
//                    let remainingSeconds = strongSelf.resendTimeIntervalMs.seconds - delta.seconds
//                    let deadline = DispatchTime.now() + DispatchTimeInterval.milliseconds(Int(remainingSeconds *
//                                                               Double(Constants.millisecondsPerSecond)))
//                    strongSelf.resendTimer?.schedule(deadline: deadline, leeway: strongSelf.resendScheduleLeewayMs)
//                }
//            }
//        })
//
//        timer.setCancelHandler(handler: {
//            self.lastInputVideoFrame = nil
//        })
//
//        let deadline = DispatchTime.now() + DispatchTimeInterval.milliseconds(Constants.millisecondsPerSecond /
//                                                                                Constants.maxSupportedVideoFrameRate)
//        timer.schedule(deadline: deadline, leeway: resendScheduleLeewayMs)
//        timer.activate()
//    }
}
