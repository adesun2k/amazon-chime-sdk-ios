//
//  DeviceSelectionViewController.swift
//  AmazonChimeSDKDemo
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import AmazonChimeSDK
import UIKit

class DeviceSelectionViewController: UIViewController {
    @IBOutlet weak var audioDevicePicker: UIPickerView!
    @IBOutlet weak var videoDevicePicker: UIPickerView!
    @IBOutlet weak var videoFormatPicker: UIPickerView!
    @IBOutlet weak var videoPreviewImageView: DefaultVideoRenderView!
    @IBOutlet weak var joinButton: UIButton!

    var model: DeviceSelectionModel?

    override func viewDidLoad() {
        super.viewDidLoad()

        audioDevicePicker.delegate = self
        audioDevicePicker.dataSource = self
        videoDevicePicker.delegate = self
        videoDevicePicker.dataSource = self
        videoFormatPicker.delegate = self
        videoFormatPicker.dataSource = self
        model?.cameraCaptureSource.addVideoSink(sink: videoPreviewImageView)
        model?.cameraCaptureSource.start()
    }

    @IBAction func joinButtonTapped(_ sender: UIButton) {
        guard let model = model else {
            return
        }
        model.cameraCaptureSource.stop()
        MeetingModule.shared().deviceSelected(model)
    }
}

extension DeviceSelectionViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard let model = model else {
            return nil
        }
        if pickerView == audioDevicePicker {
            if row >= model.audioDevices.count {
                return nil
            }
            return model.audioDevices[row].label
        } else if pickerView == videoDevicePicker {
            if row >= model.videoDevices.count {
                return nil
            }
            return model.videoDevices[row].label
        } else if pickerView == videoFormatPicker {
            if row >= model.supportedVideoFormat.count {
                return nil
            }
            let format = model.supportedVideoFormat[row]
            return "\(format.height) x \(format.width) @ \(format.frameRate)"
        } else {
            return nil
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard let model = model else {
            return
        }
        if pickerView == audioDevicePicker {
            if row >= model.audioDevices.count {
                return
            }
            model.selectedAudioDeviceIndex = row
        } else if pickerView == videoDevicePicker {
            if row >= model.videoDevices.count {
                return
            }
            model.selectedVideoDeviceIndex = row
            videoPreviewImageView.mirror = model.shouldMirrorPreview
        } else if pickerView == videoFormatPicker {
            if row >= model.supportedVideoFormat.count {
                return
            }
            model.selectedVideoFormatIndex = row
        } else {
            return
        }
    }
}

extension DeviceSelectionViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        guard let model = model else {
            return 0
        }
        if pickerView == audioDevicePicker {
            return model.audioDevices.count
        } else if pickerView == videoDevicePicker {
            return model.videoDevices.count
        } else if pickerView == videoFormatPicker {
            return model.supportedVideoFormat.count
        } else {
            return 0
        }
    }
}
