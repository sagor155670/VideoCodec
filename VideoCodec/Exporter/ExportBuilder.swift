//
//  ExportBuilder.swift
//  VideoCodec
//
//  Created by Saiful Islam Sagor on 20/12/23.
//

import Foundation
import AVFoundation


class ExportBuilder{
    private var videoTracks: [AVAssetTrack] = []
    private var audioTracks: [AVAssetTrack] = []
    private var outputUrl: URL? = nil
    private var Resolution: String = ""
    private var frameRate: Int = 30
    private var BitrateType: String = ""
    
    func setVideoTracks(videoTracks Tracks: [AVAssetTrack]) -> ExportBuilder{
        self.videoTracks = Tracks
        return self
    }
    
    func setAudioTracks(audioTracks Tracks: [AVAssetTrack]) -> ExportBuilder{
        self.audioTracks = Tracks
        return self
    }
    
    func setOutputUrl(outputUrl url: URL) -> ExportBuilder{
        self.outputUrl = url
        return self
    }
    
    func setResolution(_ resolution: String) -> ExportBuilder{
        self.Resolution = resolution
        return self
    }
    func setFramerate(_ framerate: Int) -> ExportBuilder{
        self.frameRate = framerate
        return self
    }
    
    func setBitrateType(_ bitrateType: String) -> ExportBuilder{
        self.BitrateType = bitrateType
        return self
    }
    func build() -> Export{
        return Export(videoTracks: videoTracks, audioTracks: audioTracks, outputUrl: outputUrl! , Resolution: Resolution, frameRate: frameRate, BitrateType: BitrateType)
    }
    
    
}

//let export = ExportBuilder()
//                .setResolution("4k")
//                .setBitrateType("Low")
//                .build()
//export.DisplayConfiguration()

