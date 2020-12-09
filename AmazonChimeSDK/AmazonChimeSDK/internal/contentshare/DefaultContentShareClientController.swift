//
//  DefaultContentShareClientController.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import AmazonChimeSDKMedia
import Foundation

@objcMembers public class DefaultContentShareVideoClientController: NSObject, ContentShareVideoClientController {
    private let configuration: MeetingSessionConfiguration
    private let videoClient: VideoClient
    private let logger: Logger
    private let contentShareObservers = ConcurrentMutableSet()
    private let videoSourceAdapter = VideoSourceAdapter()
    private var isSharing = false
    private let videoConfig: VideoConfiguration = {
        let config = VideoConfiguration()
        config.isUsing16by9AspectRatio = true
        config.isUsingPixelBufferRenderer = true
        config.isUsingOptimizedTwoSimulcastStreamTable = true
        config.isContentShare = true
        return config
    }()

    public init(configuration: MeetingSessionConfiguration, logger: Logger) {
        self.configuration = configuration
        self.logger = logger
        videoClient = DefaultVideoClient(logger: logger)
        super.init()
        videoClient.delegate = self
        videoClient.setReceiving(false)
    }

    public func startVideoShare(source: VideoSource) {
        if isSharing {
            stopVideoShare()
        }
        startVideoClient()
        videoSourceAdapter.source = source
        videoClient.setExternalVideoSource(videoSourceAdapter)
        videoClient.setSending(true)
        isSharing = true
    }

    public func stopVideoShare() {
        if !isSharing {
            return
        }
        videoClient.setSending(false)
        stopVideoClient()
        isSharing = false
    }

    private func startVideoClient() {
        videoClient.start(configuration.meetingId,
                          token: configuration.credentials.joinToken,
                          sending: false,
                          config: videoConfig,
                          appInfo: DeviceUtils.getDetailedInfo())
    }

    private func stopVideoClient() {
        videoClient.stop()
    }

    public func subscribeToVideoClientStateChange(observer: ContentShareObserver) {
        contentShareObservers.add(observer)
    }

    public func unsubscribeFromVideoClientStateChange(observer: ContentShareObserver) {
        contentShareObservers.remove(observer)
    }
}

extension DefaultContentShareVideoClientController: VideoClientDelegate {
    public func videoClientRequestTurnCreds(_ client: VideoClient?) {
        let turnControlUrl = configuration.urls.turnControlUrl
        let meetingId = configuration.meetingId
        let signalingUrl = configuration.urls.signalingUrl
        let joinTokenBase = DefaultModality(id: configuration.credentials.joinToken).base
        TURNRequestService.postTURNRequest(meetingId: meetingId,
                                           turnControlUrl: turnControlUrl,
                                           joinToken: joinTokenBase,
                                           logger: logger) { [weak self] turnCredentials in
            if let strongSelf = self, let turnCredentials = turnCredentials {
                let turnResponse = turnCredentials.toTURNSessionResponse(urlRewriter: strongSelf.configuration.urlRewriter,
                                                                         signalingUrl: signalingUrl)
                strongSelf.videoClient.updateTurnCreds(turnResponse, turn: VIDEO_CLIENT_TURN_FEATURE_ON)
            } else {
                self?.logger.error(msg: "Failed to update TURN Credentials")
            }
        }
    }

    public func videoClientIsConnecting(_ client: VideoClient?) {
        logger.info(msg: "ContentShare videoClientIsConnecting")
    }

    public func videoClientDidConnect(_ client: VideoClient?, controlStatus: Int32) {
        logger.info(msg: "ContentShare videoClientDidConnect")
        ObserverUtils.forEach(observers: contentShareObservers) { (observer: ContentShareObserver) in
            observer.contentShareDidStart()
        }
    }

    public func videoClientDidFail(_ client: VideoClient?, status: video_client_status_t, controlStatus: Int32) {
        logger.info(msg: "ContentShare videoClientDidFail")
        ObserverUtils.forEach(observers: contentShareObservers) { (observer: ContentShareObserver) in
            observer.contentShareDidStop(status: ContentShareStatus(statusCode: .videoServiceFailed))
        }
    }

    public func videoClientDidStop(_ client: VideoClient?) {
        logger.info(msg: "ContentShare videoClientDidStop")
        ObserverUtils.forEach(observers: contentShareObservers) { (observer: ContentShareObserver) in
            observer.contentShareDidStop(status: ContentShareStatus(statusCode: .ok))
        }
    }
}
