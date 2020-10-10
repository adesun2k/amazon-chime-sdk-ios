//
//  VideoSourceAdapter.swift
//  AmazonChimeSDKMedia
//
//  Created by Smith, Henry on 9/28/20.
//  Copyright © 2020 Amazon. All rights reserved.
//

import AmazonChimeSDKMedia
import CoreMedia
import Foundation

class VideoSourceAdapter: NSObject, VideoSink, VideoSourceInternal {
    var contentHint: AmazonChimeSDKMedia.VideoContentHint

    private let sinks = ConcurrentMutableSet()
    private let source: VideoSource

    init(source: VideoSource) {
        self.source = source
        self.contentHint = source.videoContentHint.toInternal
        super.init()

        source.addVideoSink(sink: self)
    }

    func onVideoFrameReceived(frame: VideoFrame?) {
        guard let frame = frame, let buffer: VideoFramePixelBuffer = frame.buffer as? VideoFramePixelBuffer else {
            return
        }
        ObserverUtils.forEach(observers: sinks) { (sink: VideoSinkInternal) in
            sink.didReceive(buffer.pixelBuffer,
                            timestampNs: Int64(frame.timestampNs),
                            rotation: frame.rotation.toInternal)
        }
    }

    func addVideoSink(_ sink: VideoSinkInternal?) {
        if let sink = sink {
            sinks.add(sink)
        }
    }

    func removeVideoSink(_ sink: VideoSinkInternal?) {
        if let sink = sink {
            sinks.remove(sink)
        }
    }
}
