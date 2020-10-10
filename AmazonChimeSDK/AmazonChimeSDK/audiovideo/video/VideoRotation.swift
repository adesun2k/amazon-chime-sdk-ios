//
//  VideoRotation.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import AmazonChimeSDKMedia
import Foundation

@objc public enum VideoRotation: Int {
    case rotation0 = 0
    case rotation90 = 90
    case rotation180 = 180
    case rotation270 = 270

    var toInternal: AmazonChimeSDKMedia.VideoRotation {
        return AmazonChimeSDKMedia.VideoRotation(rawValue: UInt(rawValue)) ?? .rotation0
    }

    init(internalValue: AmazonChimeSDKMedia.VideoRotation) {
        self = VideoRotation(rawValue: Int(internalValue.rawValue)) ?? .rotation0
    }

    var description: String {
        switch self {
        case .rotation0:
            return "rotation_0"
        case .rotation90:
            return "rotation_90"
        case .rotation180:
            return "rotation_180"
        case .rotation270:
            return "rotation_270"
        }
    }
}
