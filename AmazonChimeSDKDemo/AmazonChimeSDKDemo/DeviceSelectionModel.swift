//
//  DeviceSelectionModel.swift
//  AmazonChimeSDKDemo
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import AmazonChimeSDK
import Foundation

class DeviceSelectionModel {
    let audioDevices: [MediaDevice]
    let videoDevices: [MediaDevice]
    let supportedVideoFormat: [VideoCaptureFormat]
    let cameraCaptureSource: DefaultCameraCaptureSource

    var selectedAudioDeviceIndex = 0
    var selectedVideoDeviceIndex: Int = 0 {
        didSet {
            cameraCaptureSource.stop()
            cameraCaptureSource.device = selectedVideoDevice
            cameraCaptureSource.start()
        }
    }
    var selectedVideoFormatIndex = 0

    var selectedAudioDevice: MediaDevice {
        return audioDevices[selectedAudioDeviceIndex]
    }

    var selectedVideoDevice: MediaDevice {
        return videoDevices[selectedVideoDeviceIndex]
    }

    var selectedVideoFormat: VideoCaptureFormat {
        return supportedVideoFormat[selectedVideoFormatIndex]
    }

    var shouldMirrorPreview: Bool {
        return selectedVideoDevice.type == MediaDeviceType.videoFrontCamera
    }

    init(deviceController: DeviceController, cameraCaptureSource: DefaultCameraCaptureSource) {
        audioDevices = deviceController.listAudioDevices()
        videoDevices = deviceController.listVideoDevices()

        // TODO: Get actual supported format
        supportedVideoFormat = [VideoCaptureFormat(width: 720, height: 1280, frameRate: 15),
                                VideoCaptureFormat(width: 600, height: 800, frameRate: 15),
                                VideoCaptureFormat(width: 240, height: 320, frameRate: 15)]
        self.cameraCaptureSource = cameraCaptureSource
    }
}
