//
//  VideoSourceAdapter.swift
//  AmazonChimeSDKMedia
//
//  Created by Smith, Henry on 9/28/20.
//  Copyright © 2020 Amazon. All rights reserved.
//

import Foundation

import Foundation
import CoreMedia
import AmazonChimeSDKMedia

class VideoSourceAdapter: NSObject, VideoSink, VideoSourceInternal {
    private let sinks = ConcurrentMutableSet()
    private let source: VideoSource

    init(source: VideoSource) {
        self.source = source
        super.init()

        source.addVideoSink(sink: self)
    }

    func onVideoFrameReceived(frame: VideoFrame) {
        if let buffer: VideoFramePixelBuffer = frame.buffer as? VideoFramePixelBuffer {
            ObserverUtils.forEach(observers: sinks) { (sink: VideoSinkInternal) in
                sink.didReceive(buffer.pixelBuffer, timestamp: frame.timestamp, rotation: Int32(frame.rotation))
            }
        } else {
            return
        }
    }

    func addVideoSink(_ sink: VideoSinkInternal!) {
        sinks.add(sink as Any)
    }

    func removeVideoSink(_ sink: VideoSinkInternal!) {
        sinks.remove(sink as Any)
    }
}
