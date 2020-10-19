//
//  VideoCaptureFormat.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `VideoCaptureFormat`describes a given capture format that may be possible to apply to a `VideoCaptureSource`.
@objc public class VideoCaptureFormat: NSObject {
    /// Capture width in pixels.
    public let width: Int

    /// Capture height in pixels.
    public let height: Int

    /// Max frame rate.  When used as input this implies the desired frame rate as well.
    public let maxFrameRate: Int

    public init(width: Int, height: Int, maxFrameRate: Int) {
        self.width = width
        self.height = height
        self.maxFrameRate = maxFrameRate
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? VideoCaptureFormat else {
            return false
        }
        return width == object.width
            && height == object.height
            && maxFrameRate == object.maxFrameRate
    }
}
