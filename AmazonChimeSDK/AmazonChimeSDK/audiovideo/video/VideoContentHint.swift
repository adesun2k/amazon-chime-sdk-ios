//
//  VideoContentHint.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import AmazonChimeSDKMedia
import Foundation

/// `VideoContentHint` describes the content type of a video source so that downstream encoders, etc.
/// Implementations can be passed to the [AudioVideoFacade] to be used as the video source sent to remote participlants.
@objc public enum VideoContentHint: Int {
    /// No hint has been provided.
    case none = 0

    /// The track should be treated as if it contains video where motion is important.
    case motion = 1

    /// The track should be treated as if video details are extra important.
    case detail = 2

    /// The track should be treated as if video details are extra important, and that
    /// significant sharp edges and areas of consistent color can occur frequently.
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
