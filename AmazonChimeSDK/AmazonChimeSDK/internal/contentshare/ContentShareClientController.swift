//
//  ContentShareClientController.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

@objc public protocol ContentShareClientController {
    func startVideoSharing(source: VideoSource)
    func stopVideoSharing()
    func subscribeToVideoClientStateChange(observer: ContentShareObserver)
    func unsubscribeFromVideoClientStateChange(observer: ContentShareObserver)
}
