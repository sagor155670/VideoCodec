    //
    //  Codec.swift
    //  VideoCodec
    //
    //  Created by Saiful Islam Sagor on 21/11/23.
    //


import SwiftUI
import AVFoundation


//func extractFrames(videoName: String, fileExtension: String ){
//    guard let videoUrl = Bundle.main.url(forResource: videoName, withExtension: fileExtension) else{
//        print("Video not found!")
//        return
//    }
//    let asset = AVAsset(url: videoUrl)
//    let frameRate:Float = getFrameRate(asset: asset) ?? 30
//    print("Framerate: \(frameRate)")
//    let duration = CMTimeGetSeconds(asset.duration)
//    print("Video duration: \(duration)")
//
////    let times:[NSValue] = generateCMTimeArray(for: asset, withFrameRate: frameRate)
////    print(times)
//
//    do{
//        // Create an AVAssetReader instance
//        let assetReader = try AVAssetReader(asset: asset)
//
//        // Get video track
//        let videoTrack = asset.tracks(withMediaType: .video).first!
//
//        //making outputsettings
//        let outputSetting: [String: Any] = [
//            kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32BGRA)
//        ]
//
//        //Create an AVAssetReaderTrackOutput and add it to the reader
//        let trackOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: outputSetting)
//        assetReader.add(trackOutput)
//
//        //Start Reading
//        assetReader.startReading()
//
//        //Read Smaples
//        while let sampleBuffer = trackOutput.copyNextSampleBuffer(){
//            print(sampleBuffer.formatDescription as Any)
////            print(sampleBuffer.attachments)
////            print(sampleBuffer.outputPresentationTimeStamp)
////           let Ctime = sampleBuffer.outputPresentationTimeStamp
////            let timeinsec = CMTimeGetSeconds(Ctime)
////            print(timeinsec)
//            if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer){
//                print("inside imagebuffer.")
//                let ciImage = CIImage(cvImageBuffer: imageBuffer)
//                let context = CIContext()
//                if let cgImage = context.createCGImage(ciImage, from: ciImage.extent){
//                   let uiImage = UIImage(cgImage: cgImage)
////                    print(uiImage)
//                }
//            }
//        }
//        if assetReader.status == .completed {
//            print("Reading completed succesfully.")
//        }else if assetReader.status == .failed{
//            print("An error occured: \(assetReader.error?.localizedDescription ?? "Unknown error")")
//        }else if assetReader.status == .cancelled{
//            print("Reading was cancelled")
//        }
//
//    }catch{
//        print("Error with \(error.localizedDescription)")
//    }
//}

func getFrameRate(asset: AVAsset) -> Float? {
    let tracks = asset.tracks(withMediaType: .video)
    let frameRate:Float? =  tracks.first?.nominalFrameRate
    return frameRate
}

func generateCMTimeArray(for videoAsset: AVAsset, withFrameRate frameRate: Float) -> [NSValue]{
    let duration = CMTimeGetSeconds(videoAsset.duration)
    print("Video duration: \(duration)")
    var timeArray: [NSValue] = []
    print("Total frames: \(duration * Float64(frameRate))")
    for i in 0..<Int(duration * Float64(frameRate + 1)) {
        let time = CMTime(value: CMTimeValue(i), timescale: CMTimeScale(frameRate))
        let value = NSValue(time: time)
        timeArray.append(value)
    }
    return timeArray
}

func MixandSaveAudio(){
    let audioMixComposition = AVMutableComposition()
    
    let audioAsset = AVAsset(url:  Bundle.main.url(forResource: "audio", withExtension: "m4a")!)
    let audio2Asset = AVAsset(url:  Bundle.main.url(forResource: "audio", withExtension: "m4a")!)
    do{
        let audioAssetReader = try AVAssetReader(asset: audioMixComposition)
        
        let audioTrack = audioMixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        try audioTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: audioAsset.duration), of: audioAsset.tracks(withMediaType: .audio)[0], at: .zero)
        let audio2Track = audioMixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        try audioTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: audio2Asset.duration), of: audio2Asset.tracks(withMediaType: .audio)[0] , at: .zero)
        
        let audioTrackOutput = AVAssetReaderTrackOutput(track: audioMixComposition.tracks(withMediaType: .audio)[0], outputSettings: nil)
        audioAssetReader.add(audioTrackOutput)
        
    }catch{
        print("The error occured: \(error.localizedDescription)")
    }

}


//func extractFrames(videoName: String, fileExtension: String ){
//    guard let videoUrl = Bundle.main.url(forResource: videoName, withExtension: fileExtension) else{
//        print("Video not found!")
//        return
//    }
//    let asset = AVAsset(url: videoUrl)
//    let frameRate:Float = getFrameRate(asset: asset) ?? 30
//    print("Framerate: \(frameRate)")
//    let duration = CMTimeGetSeconds(asset.duration)
//    print("Video duration: \(duration)")
//
////    let times:[NSValue] = generateCMTimeArray(for: asset, withFrameRate: frameRate)
////    print(times)
//    
//    do{
//        // Create an AVAssetReader instance
//        let assetReader = try AVAssetReader(asset: asset)
//        
//        // Get video track
//        let videoTrack = asset.tracks(withMediaType: .video).first!
//        
//        //making outputsettings
//        let outputSetting: [String: Any] = [
//            kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32BGRA)
//        ]
//        
//        //Create an AVAssetReaderTrackOutput and add it to the reader
//        let trackOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: outputSetting)
//        assetReader.add(trackOutput)
//        
//        //Start Reading
//        assetReader.startReading()
//        
//        //Read Smaples
//        while let sampleBuffer = trackOutput.copyNextSampleBuffer(){
////                print(sampleBuffer.formatDescription as Any)
////            print(sampleBuffer.attachments)
////            print(sampleBuffer.outputPresentationTimeStamp)
////           let Ctime = sampleBuffer.outputPresentationTimeStamp
////            let timeinsec = CMTimeGetSeconds(Ctime)
////            print(timeinsec)
//            if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer){
//                print("inside imagebuffer.")
//                let ciImage = CIImage(cvImageBuffer: imageBuffer)
//                let context = CIContext()
//                if let cgImage = context.createCGImage(ciImage, from: ciImage.extent){
//                    self.image = UIImage(cgImage: cgImage)
////                    print(uiImage)
//                }
//            }
//        }
//        if assetReader.status == .completed {
//            print("Reading completed succesfully.")
//        }else if assetReader.status == .failed{
//            print("An error occured: \(assetReader.error?.localizedDescription ?? "Unknown error")")
//        }else if assetReader.status == .cancelled{
//            print("Reading was cancelled")
//        }
//        
//    }catch{
//        print("Error with \(error.localizedDescription)")
//    }
//}
