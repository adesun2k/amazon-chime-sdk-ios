//
//  SampleHandler.swift
//  AmazonChimeSDKDemo
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//
// swiftlint:disable private_over_fileprivate

import AmazonChimeSDK
import ReplayKit

let appGroupId = "YOUR_APP_GROUP_ID"

let userDefaultsKeyMeetingId = "demoMeetingId"
let userDefaultsKeyCredentials = "demoMeetingCredentials"
let userDefaultsKeyUrls = "demoMeetingUrls"

class SampleHandler: RPBroadcastSampleHandler {
    let logger = ConsoleLogger(name: "SampleHandler")
    let appGroupUserDefaults = UserDefaults(suiteName: appGroupId)
    var currentMeetingSession: MeetingSession?
    var observer: NSKeyValueObservation?
    lazy var screenCaptureSource = DefaultScreenCaptureSource(logger: logger)
    lazy var contentShareSource: ContentShareSource = {
        let source = ContentShareSource()
        source.videoSource = screenCaptureSource
        return source
    }()

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
        guard let config = getSavedMeetingSessionConfig() else {
            logger.error(msg: "Unable to recreate MeetingSessionConfiguration from Broadcast Extension")
            finishBroadcastWithError(NSError(domain: "AmazonChimeSDKDemoBroadcast", code: 0))
            return
        }
        currentMeetingSession = DefaultMeetingSession(configuration: config, logger: logger)
        screenCaptureSource.start()
        currentMeetingSession?.audioVideo.startContentShare(source: contentShareSource)

        // If the meetingId is changed from the demo app, we need to observe the meetingId and stop broadcast
        observer = appGroupUserDefaults?.observe(\.demoMeetingId,
                                                 options: [.new, .old]) { [weak self] (_, _) in
            guard let strongSelf = self else { return }
            strongSelf.finishBroadcastWithError(NSError(domain: "AmazonChimeSDKDemoBroadcast", code: 0))
        }
    }

    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
    }

    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
    }

    override func broadcastFinished() {
        // User has requested to finish the broadcast.
        screenCaptureSource.stop()
        currentMeetingSession?.audioVideo.stopContentShare()
        observer?.invalidate()
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case .video:
            // Handle video sample buffer
            screenCaptureSource.processVideo(sampleBuffer: sampleBuffer)
        case .audioApp:
            // Amazon Chime SDK does not support passing app audio yet.
            break
        case .audioMic:
            // Microphone audio is passed through the app instead of the app extension.
            break
        @unknown default:
            // Unknown sample buffer types will not be handled.
            break
        }
    }

    // Recreate the MeetingSessionConfiguration from the active meeting in the app
    private func getSavedMeetingSessionConfig() -> MeetingSessionConfiguration? {
        guard let appGroupUserDefaults = appGroupUserDefaults else {
            logger.error(msg: "App Group User Defaults not found")
            return nil
        }
        let decoder = JSONDecoder()
        if let meetingId = appGroupUserDefaults.demoMeetingId,
           let credentialsData = appGroupUserDefaults.demoMeetingCredentials,
           let urlsData = appGroupUserDefaults.demoMeetingUrls,
           let credentials = try? decoder.decode(MeetingSessionCredentials.self, from: credentialsData),
           let urls = try? decoder.decode(MeetingSessionURLs.self, from: urlsData) {

            return MeetingSessionConfiguration(meetingId: meetingId,
                                               credentials: credentials,
                                               urls: urls,
                                               urlRewriter: URLRewriterUtils.defaultUrlRewriter)
        }
        return nil
    }
}

extension UserDefaults {
    @objc dynamic var demoMeetingId: String? {
        return string(forKey: userDefaultsKeyMeetingId)
    }
    @objc dynamic var demoMeetingCredentials: Data? {
        return object(forKey: userDefaultsKeyCredentials) as? Data
    }
    @objc dynamic var demoMeetingUrls: Data? {
        return object(forKey: userDefaultsKeyUrls) as? Data
    }
}
