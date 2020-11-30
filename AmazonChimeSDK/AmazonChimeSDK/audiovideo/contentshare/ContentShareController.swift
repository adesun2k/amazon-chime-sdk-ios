//
//  ContentShareController.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `ContentShareController` exposes methods for starting and stopping content share with a source.
@objc public protocol ContentShareController {
    /// Start sharing the content of a given `ContentShareSource`.
    /// Once sharing has started successfully, `ContentShareObserver.contentShareDidStart` will
    /// be notified. If sharing fails or stops, `ContentShareObserver.contentShareDidStop`
    /// will be notified with `ContentShareStatus` as the cause.
    /// Repeatedly calling this API will stop previous content share source if applicable and start the given source.
    /// - Parameter source: source of content to be shared
    func startContentShare(contentShareSource: ContentShareSource)

    /// Stop sharing the content of a `ContentShareSource` that previously started.
    /// Once the sharing stops successfully, `ContentShareObserver.contentShareDidStop`
    /// will be notified with status code `ContentShareStatusCode.OK`.
    func stopContentShare()

    /// Subscribe the given observer to content share events (sharing started and stopped).
    /// - Parameter observer: observer to be notified for events
    func addContentShareObserver(observer: ContentShareObserver)

    /// Unsubscribe the given observer from content share events.
    /// - Parameter observer: observer to be removed for events
    func removeContentShareObserver(observer: ContentShareObserver)
}
