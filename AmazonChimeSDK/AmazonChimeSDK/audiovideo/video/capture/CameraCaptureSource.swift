//
//  CameraCaptureSource.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `CameraCaptureSource` is an interface for camera capture sources with additional features
/// not covered by `VideoCaptureSource`
@objc public protocol CameraCaptureSource: VideoCaptureSource {
    /// Current camera device.
    /// May be called regardless of whether `start` or `stop` has been called.
    var device: MediaDevice? { get set }

    /// Toggle for flashlight on the current device.  Will succeed if current device has access to
    /// flashlight, otherwise will stay `false`.  May be called regardless of whether `start` or `stop`
    /// has been called.
    var torchEnabled: Bool { get set }

    /// Current camera capture format.
    /// May be called regardless of whether `start` or `stop` has been called.
    var format: VideoCaptureFormat { get set }

    /// Helper function to switch from front to back cameras or reverse.  This also switches from
    /// any external cameras to the front camera.
    func switchCamera()
}
