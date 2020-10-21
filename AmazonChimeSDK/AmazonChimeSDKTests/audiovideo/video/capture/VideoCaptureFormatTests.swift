//
//  VideoCaptureFormatTests.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

@testable import AmazonChimeSDK
import XCTest

class VideoCaptureFormatTests: XCTestCase {
    func testInit() {
        let format = VideoCaptureFormat(width: 16, height: 9, maxFrameRate: 60)
        XCTAssertEqual(format.width, 16)
        XCTAssertEqual(format.height, 9)
        XCTAssertEqual(format.maxFrameRate, 60)
    }

    func testIsEqual() {
        let format1 = VideoCaptureFormat(width: 16, height: 9, maxFrameRate: 60)
        let format2 = VideoCaptureFormat(width: 16, height: 9, maxFrameRate: 60)
        XCTAssertEqual(format1, format2)
    }

    func testIsNotEqual() {
        let format1 = VideoCaptureFormat(width: 16, height: 9, maxFrameRate: 60)
        let format2 = VideoCaptureFormat(width: 16, height: 9, maxFrameRate: 30)
        XCTAssertNotEqual(format1, format2)
    }
}
