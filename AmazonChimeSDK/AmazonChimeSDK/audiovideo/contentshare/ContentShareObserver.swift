//
//  ContentShareObserver.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `ContentShareObserver` handles all callbacks related to the content share.
/// By implementing the callback functions and registering with `ContentShareController.addContentShareObserver`,
/// one can get notified with content share status events.
@objc public protocol ContentShareObserver {
    /// Called when the content share has started.
    /// This callback will be called on the main thread.
    func contentShareDidStart()

    /// Called when the content share has stopped with the
    /// reason provided in the status. The content is not
    /// shared with other attendees anymore. If you no longer need to share the source,
    /// stop the source when this callback is called.
    /// This callback will be called on the main thread.
    /// - Parameter status: the reason why the content share has stopped
    func contentShareDidStop(status: ContentShareStatus)
}
