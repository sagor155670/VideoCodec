//
//  CustomInstruction.swift
//  VideoCodec
//
//  Created by Saiful Islam Sagor on 26/12/23.
//

import Foundation
import AVKit

class CustomOverlayInstruction: NSObject, AVVideoCompositionInstructionProtocol{
    
    var timeRange: CMTimeRange
    
    var enablePostProcessing: Bool = true
    
    var containsTweening: Bool = false
    
    var requiredSourceTrackIDs: [NSValue]?
    
    var passthroughTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
    
    var rotateSecondAsset: Bool?
    var videoTracks: [AVAssetTrack]
    
    init(timeRange: CMTimeRange, rotateSceondAsset: Bool, videoTracks: [AVAssetTrack]) {
        self.timeRange = timeRange
        self.rotateSecondAsset = rotateSceondAsset
        self.videoTracks = videoTracks
    }
    
    func makeOpacityInstructions() -> [AVMutableVideoCompositionLayerInstruction] {
        var opacityInstructions: [AVMutableVideoCompositionLayerInstruction] = []
        for track in videoTracks {
            let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
            instruction.setOpacity(0.0, at: track.timeRange.end)
            opacityInstructions.append(instruction)
        }
        return opacityInstructions
    }
}
