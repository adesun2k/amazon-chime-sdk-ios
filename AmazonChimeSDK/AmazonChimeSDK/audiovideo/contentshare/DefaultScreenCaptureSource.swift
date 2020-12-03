//
//  DefaultScreenCaptureSource.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import ReplayKit

/// `DefaultScreenCaptureSource` contains data processing for in app or device level screen broadcast.
/// It does not directly contain any system library that captures the screen.
/// See `InAppScreenCaptureSource` if you want to only share screen from the app.
/// For device level screen broadcast, take a look at the `SampleHandler` in AmazonChimeSDKDemoBroadcast.
@objcMembers public class DefaultScreenCaptureSource: NSObject, VideoCaptureSource {
    public var videoContentHint: VideoContentHint = .text

    let logger: Logger
    let observers = ConcurrentMutableSet()

    private let pixelBufferLockFlagReadOnly = CVPixelBufferLockFlags(rawValue: 0)
    private let resendTimeIntervalMs = CMTime(value: CMTimeValue(Constants.millisecondsPerSecond /
                                                                Constants.maxSupportedVideoFrameRate),
                                            timescale: CMTimeScale(Constants.millisecondsPerSecond))
    private let resendScheduleLeewayMs = DispatchTimeInterval.milliseconds(20)
    private let sinks = ConcurrentMutableSet()
    private let resendQueue = DispatchQueue.global()

    private var lastInputVideoFrame: CMSampleBuffer?
    private var lastInputTimestamp: CMTime?
    private var lastSendTimestamp: CMTime?
    private var resendTimer: DispatchSourceTimer?

    public init(logger: Logger) {
        self.logger = logger
        super.init()
    }

    // For device level screen broadcast, app is responsible for starting the Broadcast Extension.
    // This method is overwritten in InAppScreenCaptureSource for In App only use case.
    public func start() {
    }

    public func stop() {
        resendTimer?.cancel()
        resendTimer = nil
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
        let currentTimestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        lastInputVideoFrame = sampleBuffer
        lastInputTimestamp = currentTimestamp

        // drop frame if the time difference is smaller than resendTimeInterval
        if let lastTransmitTimestamp = self.lastSendTimestamp {
            let delta = CMTimeSubtract(currentTimestamp, lastTransmitTimestamp)
            if delta < resendTimeIntervalMs {
                return
            }
        }

        sendFrame(sampleBuffer: sampleBuffer)
    }

    private func sendFrame(sampleBuffer: CMSampleBuffer) {
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

        CVPixelBufferLockBaseAddress(pixelBuffer, pixelBufferLockFlagReadOnly)

        var videoRotation = VideoRotation.rotation0
        // RPVideoSampleOrientationKey is only available on iOS 11+
        if #available(iOS 11.0, *) {
            if let sampleOrientation = CMGetAttachment(sampleBuffer,
                                                       key: RPVideoSampleOrientationKey as CFString,
                                                       attachmentModeOut: nil),
                let coreSampleOrientation = sampleOrientation.uint32Value,
                let orientation = CGImagePropertyOrientation(rawValue: coreSampleOrientation) {
                switch orientation {
                case .left, .leftMirrored:
                    videoRotation = .rotation90
                case .down, .downMirrored:
                    videoRotation = .rotation180
                case .right, .rightMirrored:
                    videoRotation = .rotation270
                default:
                    break
                }
            }
        }
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
        CVPixelBufferUnlockBaseAddress(pixelBuffer, pixelBufferLockFlagReadOnly)

        lastSendTimestamp = CMClockGetTime(CMClockGetHostTimeClock())
        scheduleResendFrame()
    }

    private func scheduleResendFrame() {
        let source = DispatchSource.makeTimerSource(flags: .strict, queue: resendQueue)
        resendTimer = source

        // This timer is invoked every resendTimeInterval when no frame is sent from video source
        source.setEventHandler(handler: { [weak self] in
            guard let strongSelf = self else {
                source.cancel()
                return
            }
            if let frame = strongSelf.lastInputVideoFrame,
                let lastHostTimestamp = strongSelf.lastSendTimestamp {

                let currentTimestamp = CMClockGetTime(CMClockGetHostTimeClock())
                let delta = CMTimeSubtract(currentTimestamp, lastHostTimestamp)

                // Resend the last input frame if there is no new input frame after resendTimeInterval
                if delta > strongSelf.resendTimeIntervalMs {
                    strongSelf.sendFrame(sampleBuffer: frame)
                } else {
                    // Reset resending schedule if there is an input frame between internals
                    let remainingMs = strongSelf.resendTimeIntervalMs.seconds - delta.seconds
                    let deadline = DispatchTime.now() + DispatchTimeInterval.milliseconds(Int(remainingMs *
                                                               Double(Constants.millisecondsPerSecond)))
                    strongSelf.resendTimer?.schedule(deadline: deadline, leeway: strongSelf.resendScheduleLeewayMs)
                }
            }
        })

        source.setCancelHandler(handler: {
            self.lastInputVideoFrame = nil
        })

        let deadline = DispatchTime.now() + DispatchTimeInterval.milliseconds(Constants.millisecondsPerSecond /
                                                                                Constants.maxSupportedVideoFrameRate)
        source.schedule(deadline: deadline, leeway: resendScheduleLeewayMs)
        source.activate()
    }
}
