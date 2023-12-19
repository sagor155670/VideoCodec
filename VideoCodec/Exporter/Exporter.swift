//
//  Exporter.swift
//  VideoCodec
//
//  Created by Saiful Islam Sagor on 18/12/23.
//

import Foundation
import AVFoundation

class Exporter {
    var videoAssets: [AVAsset]
    var audioAssets: [AVAsset]
    
    init(videoAssets: [AVAsset], audioAssets: [AVAsset]) {
        self.videoAssets = videoAssets
        self.audioAssets = audioAssets
    }
    
    }
