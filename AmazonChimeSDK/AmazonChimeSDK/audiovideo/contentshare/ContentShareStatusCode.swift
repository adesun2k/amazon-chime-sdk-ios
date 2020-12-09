//
//  ContentShareStatusCode.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `ContentShareStatusCode` indicates the reason the content share event occurred.
@objc public enum ContentShareStatusCode: Int, CustomStringConvertible {
    /// Everything is OK so far.
    case ok = 0

    /// This can happen when the content share video connection is in an unrecoverable failed state.
    case videoServiceFailed = 1

    public var description: String {
        switch self {
        case .ok:
            return "ok"
        case .videoServiceFailed:
            return "videoServiceFailed"
        }
    }
}
