//
//  DefaultModality.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `DefaultModality` is a backwards compatible extension of the
/// attendee id (UUID string) and session token schemas (base 64 string).
/// It appends #<modality> to either strings, which indicates the modality
/// of the participant.
///
/// For example,
/// `attendeeId`: "abcdefg"
/// `contentAttendeeId`: "abcdefg#content"
/// `contentAttendeeId.base`: "abcdefg"
/// `contentAttendeeId.modality`: "content"
/// `contentAttendeeId.hasModality(type: .content)`: true
@objc public class DefaultModality: NSObject {
    public let id: String
    public let base: String
    public let modality: String?
    public static let separator: Character = "#"

    init(id: String) {
        self.id = id
        let substrings = id.split(separator: DefaultModality.separator)
        base = String(substrings[0])
        if substrings.count == 2 {
            modality = String(substrings[1])
        } else {
            modality = nil
        }
    }

    public func hasModality(type: ModalityType) -> Bool {
        return modality == type.description
    }
}