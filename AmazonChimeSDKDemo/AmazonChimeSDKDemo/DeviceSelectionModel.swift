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
    let cameraCaptureSource: DefaultCameraCaptureSource

    lazy var supportedVideoFormat: [[VideoCaptureFormat]] = {
        self.videoDevices.map { videoDevice in
            // Reverse these so the highest resolutions are first
            MediaDevice.listSupportedVideoCaptureFormats(mediaDevice: videoDevice).reversed()
        }
    }()

    var selectedAudioDeviceIndex = 0
    var selectedVideoDeviceIndex: Int = 0 {
        didSet {
            cameraCaptureSource.device = selectedVideoDevice
        }
    }

    var selectedVideoFormatIndex = 0 {
        didSet {
            cameraCaptureSource.format = selectedVideoFormat
        }
    }

    var selectedAudioDevice: MediaDevice {
        return audioDevices[selectedAudioDeviceIndex]
    }

    var selectedVideoDevice: MediaDevice {
        return videoDevices[selectedVideoDeviceIndex]
    }

    var selectedVideoFormat: VideoCaptureFormat {
        return supportedVideoFormat[selectedVideoDeviceIndex][selectedVideoFormatIndex]
    }

    var shouldMirrorPreview: Bool {
        return selectedVideoDevice.type == MediaDeviceType.videoFrontCamera
    }

    init(deviceController: DeviceController, cameraCaptureSource: DefaultCameraCaptureSource) {
        audioDevices = deviceController.listAudioDevices()
        // Reverse these so the front camera is the initial choice
        videoDevices = deviceController.listVideoDevices().reversed()
        self.cameraCaptureSource = cameraCaptureSource
        cameraCaptureSource.device = selectedVideoDevice
        cameraCaptureSource.format = selectedVideoFormat
    }
}
