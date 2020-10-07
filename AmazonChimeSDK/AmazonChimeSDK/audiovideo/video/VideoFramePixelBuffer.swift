//
//  VideoFramePixelBuffer.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CoreVideo

@objcMembers public class VideoFramePixelBuffer: VideoFrameBuffer {
    public func width() -> Int {
        return CVPixelBufferGetWidth(pixelBuffer)
    }

    public func height() -> Int {
        return CVPixelBufferGetHeight(pixelBuffer)
    }

    public let pixelBuffer: CVPixelBuffer

    public init(pixelBuffer: CVPixelBuffer) {
        self.pixelBuffer = pixelBuffer
    }
}
