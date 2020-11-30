//
//  ScreenShareModel.swift
//  AmazonChimeSDKDemo
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import AmazonChimeSDK
import Foundation

class ScreenShareModel: NSObject {
    let appGroupUserDefaults = UserDefaults(suiteName: "group.com.amazonaws.services.chime.SDKDemo")
    let userDefaultsKeyMeetingId = "demoMeetingId"
    let userDefaultsKeyCredentials = "demoMeetingCredentials"
    let userDefaultsKeyUrls = "demoMeetingUrls"
    let logger = ConsoleLogger(name: "ScreenShareModel")
    let meetingSessionConfig: MeetingSessionConfiguration
    let contentShareController: ContentShareController
    var observer: NSKeyValueObservation?

    var tileId: Int? {
        didSet {
            tileIdDidSetHandler?(tileId)
        }
    }

    var isAvailable: Bool {
        return tileId != nil
    }

    var isInAppContentShareActive = false {
        willSet(newValue) {
            if newValue == isInAppContentShareActive {
                return
            }
            if newValue {
                inAppScreenCaptureSource?.start()
            } else {
                inAppScreenCaptureSource?.stop()
            }
        }
    }

    lazy var inAppScreenCaptureSource: VideoCaptureSource? = {
        if #available(iOS 11.0, *) {
            let source = InAppScreenCaptureSource(logger: logger)
            source.addCaptureSourceObserver(observer: self)
            return source
        }
        return nil
    }()

    var tileIdDidSetHandler: ((Int?) -> Void)?
    var viewUpdateHandler: ((Bool) -> Void)?

    init(meetingSessionConfig: MeetingSessionConfiguration,
         contentShareController: ContentShareController) {

        self.meetingSessionConfig = meetingSessionConfig
        self.contentShareController = contentShareController
        super.init()
    }

    // Broadcast extension is retrieving data from shared App Group User Defaults
    // to recreate the MeetingSessionConfig and share device level content.
    // See AmazonChimeSDKDemoBroadcast/SampleHandler for more details.
    func saveMeetingSessionConfigToUserDefaults() {
        guard let appGroupUserDefaults = appGroupUserDefaults else {
            logger.error(msg: "App Group User Defaults not found")
            return
        }
        appGroupUserDefaults.set(meetingSessionConfig.meetingId, forKey: userDefaultsKeyMeetingId)
        let encoder = JSONEncoder()
        if let credentials = try? encoder.encode(meetingSessionConfig.credentials) {
            appGroupUserDefaults.set(credentials, forKey: userDefaultsKeyCredentials)
        }
        if let urls = try? encoder.encode(meetingSessionConfig.urls) {
            appGroupUserDefaults.set(urls, forKey: userDefaultsKeyUrls)
        }
    }

    func deleteMeetingSessionConfigFromUserDefaults() {
        guard let appGroupUserDefaults = appGroupUserDefaults else {
            logger.error(msg: "App Group User Defaults not found")
            return
        }
        appGroupUserDefaults.removeObject(forKey: userDefaultsKeyMeetingId)
        appGroupUserDefaults.removeObject(forKey: userDefaultsKeyCredentials)
        appGroupUserDefaults.removeObject(forKey: userDefaultsKeyUrls)
    }
}

extension ScreenShareModel: CaptureSourceObserver {
    func captureDidStart() {
        logger.info(msg: "InAppScreenCaptureSource did start")
        let contentShareSource = ContentShareSource()
        contentShareSource.videoSource = inAppScreenCaptureSource
        contentShareController.startContentShare(contentShareSource: contentShareSource)
        deleteMeetingSessionConfigFromUserDefaults()
    }

    func captureDidStop() {
        logger.info(msg: "InAppScreenCaptureSource did stop")
        contentShareController.stopContentShare()
        saveMeetingSessionConfigToUserDefaults()
    }

    func captureDidFail(error: CaptureSourceError) {
        logger.error(msg: "InAppScreenCaptureSource did fail: \(error.description)")
        contentShareController.stopContentShare()
        saveMeetingSessionConfigToUserDefaults()
    }
}
