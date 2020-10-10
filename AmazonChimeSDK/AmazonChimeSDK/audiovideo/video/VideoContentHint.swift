//
//  VideoContentHint.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import AmazonChimeSDKMedia
import Foundation

// https://www.w3.org/TR/mst-content-hint/#video-content-hints
@objc public enum VideoContentHint: Int {
    case none = 0
    case motion = 1
    case detail = 2
    case text = 3

    var toInternal: AmazonChimeSDKMedia.VideoContentHint {
        return AmazonChimeSDKMedia.VideoContentHint(rawValue: UInt(rawValue)) ?? .none
    }

    var description: String {
        switch self {
        case .none:
            return "none"
        case .motion:
            return "motion"
        case .detail:
            return "detail"
        case .text:
            return "text"
        }
    }
}
