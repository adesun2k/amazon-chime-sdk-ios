//
//  DefaultContentShareController.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import AmazonChimeSDKMedia
import Foundation

@objcMembers public class DefaultContentShareController: NSObject, ContentShareController {
    private let contentShareClientController: ContentShareClientController

    public init(configuration: MeetingSessionConfiguration, logger: Logger) {
        contentShareClientController = DefaultContentShareClientController(configuration: configuration, logger: logger)
        super.init()
    }

    public func startContentShare(contentShareSource: ContentShareSource) {
        if let videoSource = contentShareSource.videoSource {
            contentShareClientController.startVideoSharing(source: videoSource)
        }
    }

    public func stopContentShare() {
        contentShareClientController.stopVideoSharing()
    }

    public func addContentShareObserver(observer: ContentShareObserver) {
        contentShareClientController.subscribeToVideoClientStateChange(observer: observer)
    }

    public func removeContentShareObserver(observer: ContentShareObserver) {
        contentShareClientController.unsubscribeFromVideoClientStateChange(observer: observer)
    }
}
