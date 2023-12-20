//
//  Exporter.swift
//  VideoCodec
//
//  Created by Saiful Islam Sagor on 18/12/23.
//

import Foundation
import AVFoundation

class Export {
    var videoTracks: [AVAssetTrack]
    var audioTracks: [AVAssetTrack]
    var outputUrl: URL?
    var Resolution: String
    var frameRate: Int
    var BitrateType: String

    init(videoTracks: [AVAssetTrack], audioTracks: [AVAssetTrack], outputUrl: URL, Resolution: String, frameRate: Int, BitrateType: String) {
        self.videoTracks = videoTracks
        self.audioTracks = audioTracks
        self.outputUrl = outputUrl
        self.Resolution = Resolution
        self.frameRate = frameRate
        self.BitrateType = BitrateType
    }
    
    func calculateBitrate() -> Int {
        
        let frameRateType: String = self.frameRate <= 30 ? "less" : "grater"
        let outputConfiguration = self.Resolution + frameRateType + self.BitrateType
        print(outputConfiguration)
        
        enum Configuration: String {
            case _480PlessLow
            case _480PlessRecommended
            case _480PlessHigh
            case _480PgraterLow
            case _480PgraterRecommended
            case _480PgraterHigh
            case _720PlessLow
            case _720PlessRecommended
            case _720PlessHigh
            case _720PgraterLow
            case _720PgraterRecommended
            case _720PgraterHigh
            case _1080PlessLow
            case _1080PlessRecommended
            case _1080PlessHigh
            case _1080PgraterLow
            case _1080PgraterRecommended
            case _1080PgraterHigh
            case _2KlessLow
            case _2KlessRecommended
            case _2KlessHigh
            case _2KgraterLow
            case _2KgraterRecommended
            case _2KgraterHigh
            case _4KlessLow
            case _4KlessRecommended
            case _4KlessHigh
            case _4KgraterLow
            case _4KgraterRecommended
            case _4KgraterHigh
        }
        let config = "_\(outputConfiguration)"
        print(config)
        // bitrates in kbps
        switch Configuration(rawValue: config) {
        case ._480PlessLow:
            let bitrate = 2000
            return bitrate
        case ._480PlessRecommended:
            let bitrate = 3000
            return bitrate
        case ._480PlessHigh:
            let bitrate = 4000
            return bitrate
        case ._480PgraterLow:
            let bitrate = 3000
            return bitrate
        case ._480PgraterRecommended:
            let bitrate = 4000
            return bitrate
        case ._480PgraterHigh:
            let bitrate = 5500
            return bitrate
        case ._720PlessLow:
            let bitrate = 5000
            return bitrate
        case ._720PlessRecommended:
            let bitrate = 7000
            return bitrate
        case ._720PlessHigh:
            let bitrate = 9000
            return bitrate
        case ._720PgraterLow:
            let bitrate = 7000
            return bitrate
        case ._720PgraterRecommended:
            let bitrate = 10000
            return bitrate
        case ._720PgraterHigh:
            let bitrate = 12500
            return bitrate
        case ._1080PlessLow:
            let bitrate = 10000
            return bitrate
        case ._1080PlessRecommended:
            let bitrate = 11500
            return bitrate
        case ._1080PlessHigh:
            let bitrate = 14500
            return bitrate
        case ._1080PgraterLow:
            let bitrate = 14000
            return bitrate
        case ._1080PgraterRecommended:
            let bitrate = 16500
            return bitrate
        case ._1080PgraterHigh:
            let bitrate = 20500
            return bitrate
        case ._2KlessLow:
            let bitrate = 19000
            return bitrate
        case ._2KlessRecommended:
            let bitrate = 20000
            return bitrate
        case ._2KlessHigh:
            let bitrate = 21000
            return bitrate
        case ._2KgraterLow:
            let bitrate = 2000
            return bitrate
        case ._2KgraterRecommended:
            let bitrate = 2000
            return bitrate
        case ._2KgraterHigh:
            let bitrate = 2000
            return bitrate
        case ._4KlessLow:
            let bitrate = 23500
            return bitrate
        case ._4KlessRecommended:
            let bitrate = 28000
            return bitrate
        case ._4KlessHigh:
            let bitrate = 32500
            return bitrate
        case ._4KgraterLow:
            let bitrate = 33000
            return bitrate
        case ._4KgraterRecommended:
            let bitrate = 40000
            return bitrate
        case ._4KgraterHigh:
            let bitrate = 46500
            return bitrate
        
        case .none:
            print("Not a Valid Case")
            return 1000
        }
     
    }
    func ExportAsset(){
        guard let outputUrl = self.outputUrl else {
            print("output url is not valid!")
            return
        }
        
        let composition = AVMutableComposition()
        
        for track in videoTracks {
            guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else{
                return
            }
            let trackDuration = track.timeRange.duration
            var currentTime = CMTime.zero
            do{
                try videoTrack.insertTimeRange(track.timeRange, of: track, at: currentTime)
            }catch{
                
            }
           currentTime = CMTimeAdd(currentTime, trackDuration)
        }
        
        for track in audioTracks{
            guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else{
                return
            }
            let trackDuration = track.timeRange.duration
            var currentTime = CMTime.zero
            
            do{
                try audioTrack.insertTimeRange(track.timeRange, of: track, at: currentTime)
            }catch{
                
            }
           currentTime = CMTimeAdd(currentTime, trackDuration)
        }

    }
    func DisplayConfiguration(){
        print("Resolution: \(Resolution) BitrateType: \(BitrateType)")
    }
    
    }
