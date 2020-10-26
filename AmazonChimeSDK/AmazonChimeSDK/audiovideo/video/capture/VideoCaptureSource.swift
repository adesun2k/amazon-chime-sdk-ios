//
//  VideoCaptureSource.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `VideoCaptureSource` is an interface for various video capture sources which can emit `VideoFrame` objects.
/// All the APIs in this protocol can be called regardless of whether the `MeetingSession.audioVideo` has started or not.
@objc public protocol VideoCaptureSource: VideoSource {
    /// Start capturing on this source and emitting video frames.
    func start()

    /// Stop capturing on this source and cease emitting video frames.
    func stop()

    /// Add a capture source observer to receive callbacks from the source.
    /// - Parameters:
    ///   - observer: - New observer.
    func addCaptureSourceObserver(observer: CaptureSourceObserver)

    /// Remove a capture source observer.
    /// - Parameters:
    ///   - observer: - Observer to remove.
    func removeCaptureSourceObserver(observer: CaptureSourceObserver)
}
