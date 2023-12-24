//
//  Exporter.swift
//  VideoCodec
//
//  Created by Saiful Islam Sagor on 18/12/23.
//

import Foundation
import AVFoundation
import Photos

class Export {
    var videoTracks: [AVAssetTrack]
    var audioTracks: [AVAssetTrack]
    var outputUrl: URL?
    var Resolution: String
    var frameRate: Int
    var BitrateType: String
    var sampleNo: Int
    var percentage: ProgressCountProtocol?

    init(videoTracks: [AVAssetTrack], audioTracks: [AVAssetTrack], outputUrl: URL? = nil, Resolution: String, frameRate: Int, BitrateType: String, sampleNo: Int = 0) {
        self.videoTracks = videoTracks
        self.audioTracks = audioTracks
        self.outputUrl = outputUrl
        self.Resolution = Resolution
        self.frameRate = frameRate
        self.BitrateType = BitrateType
        self.sampleNo = sampleNo
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
        var currentTime = CMTime.zero
        for track in videoTracks {
            guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else{
                return
            }
            let trackDuration = track.timeRange.duration
            
            do{
                try videoTrack.insertTimeRange(track.timeRange, of: track, at: currentTime)
            }catch{
                
            }
           currentTime = CMTimeAdd(currentTime, trackDuration)
        }
        
        var currenTimeAudio = CMTime.zero
        for track in audioTracks{
            guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else{
                return
            }
            let trackDuration = track.timeRange.duration
            
            do{
                try audioTrack.insertTimeRange(track.timeRange, of: track, at: .zero)
            }catch{
                print("timerange could not be inserted!")
            }
           currenTimeAudio = CMTimeAdd(currenTimeAudio , trackDuration)
        }
        
        composition.removeTimeRange(CMTimeRange(start: currentTime , duration: composition.duration))
        
        let videoReaderSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
        ]
        let audioReaderSettings: [String: Any] = [AVFormatIDKey: kAudioFormatLinearPCM]
        
//        let videoComposition = AVMutableVideoComposition(asset: composition) { filterRequest in
//            let source = filterRequest.sourceImage
//            let outputImage = source.transformed(by: CGAffineTransform(scaleX: composition.naturalSize.width / source.extent.width, y: composition.naturalSize.height / source.extent.height) )
//            filterRequest.finish(with: outputImage, context: nil)
//        }
        let videoComposition = AVMutableVideoComposition()
        var layerInstructions: [AVMutableVideoCompositionLayerInstruction] = []
        for track in composition.tracks(withMediaType: .video){
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
            layerInstruction.setOpacity(0, at: track.timeRange.end)
            
            let trackSize = track.naturalSize
            let videoSize = composition.naturalSize
            let transform = CGAffineTransform(scaleX: videoSize.width / trackSize.width , y: videoSize.height / trackSize.height)
            layerInstruction.setTransform(transform, at: .zero)
            layerInstructions.append(layerInstruction)
        }
        
        let videoCompositionInstruction = AVMutableVideoCompositionInstruction()
        videoCompositionInstruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
        videoCompositionInstruction.layerInstructions = layerInstructions
        videoComposition.instructions = [videoCompositionInstruction]
        
        videoComposition.frameDuration = CMTime(value: 1, timescale: CMTimeScale(self.frameRate))
        videoComposition.renderSize = composition.naturalSize
        
        let videoCompositionOutput = AVAssetReaderVideoCompositionOutput(videoTracks: composition.tracks(withMediaType: .video), videoSettings: videoReaderSettings)
        videoCompositionOutput.videoComposition = videoComposition
        
        let audioMixer = AVMutableAudioMix()
        let inputParameters = AVMutableAudioMixInputParameters()
        
        audioMixer.inputParameters = [inputParameters]
        
        let audioMixOutput = AVAssetReaderAudioMixOutput(audioTracks: composition.tracks(withMediaType: .audio), audioSettings: nil)
        audioMixOutput.audioMix = audioMixer
        
        do{
            let VideoAssetReader = try AVAssetReader(asset: composition)
            let audioAssetReader = try AVAssetReader(asset: composition)
            
            VideoAssetReader.add(videoCompositionOutput)
            audioAssetReader.add(audioMixOutput)
            
            let defaultUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
            
            let assetWriter = try AVAssetWriter(outputURL: self.outputUrl ?? defaultUrl, fileType: .mov)
            
            let videoFrameSize = self.frameSize()
            let bitrate = self.calculateBitrate()
            
            let totalFrames = composition.duration.seconds * Double(self.frameRate)
            
            let videoWriterSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.hevc,
                AVVideoWidthKey: videoFrameSize.width,
                AVVideoHeightKey: videoFrameSize.height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: NSNumber(value: bitrate * 1000) ,
    //                    AVVideoMaxKeyFrameIntervalKey : 1,
    //                    AVVideoExpectedSourceFrameRateKey: 30
    //                    AVVideoProfileLevelKey: "HEVC_Main_AutoLevel"
                ] as [String : Any]
            ]
            
            let audioWriterSettings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
                AVEncoderBitRateKey: 256000
            ]
            
            let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoWriterSettings)
            let audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioWriterSettings)
            
            videoWriterInput.transform = composition.preferredTransform
            
            assetWriter.add(videoWriterInput)
            assetWriter.add(audioWriterInput)
            
            VideoAssetReader.startReading()
            audioAssetReader.startReading()
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: .zero)
            
            let processingQueue = DispatchQueue(label: "processingQueue")

            audioWriterInput.requestMediaDataWhenReady(on: processingQueue) {
                while audioWriterInput.isReadyForMoreMediaData {
                    if let sampleBuffer = audioMixOutput.copyNextSampleBuffer() {
                        audioWriterInput.append(sampleBuffer)
                    } else {
                        audioWriterInput.markAsFinished()
                    }
                }
            }
            
                // Read Samples and Write them into the new video
//            var sampleNo = 0
            while let sampleBuffer = videoCompositionOutput.copyNextSampleBuffer(){
                print("Reading sample no: \(sampleNo)")
                while !videoWriterInput.isReadyForMoreMediaData {
                    usleep(10) // Sleep for a very short time
                }
                
                print("Writing sample no: \(sampleNo)")
                videoWriterInput.append(sampleBuffer)
                sampleNo += 1
                let percentage = Double(sampleNo) * 100 / totalFrames
                self.percentage?.getWriterPercentage(percentCount: Int(percentage))
            }
            
            videoWriterInput.markAsFinished()
            
            assetWriter.finishWriting {
                if assetWriter.status == .completed{
                    self.SaveAsset()
                }else if assetWriter.status == .failed {
                    print("An error occurred: \(assetWriter.error?.localizedDescription ?? "Unknown error")")
                }
            }

        }catch{
            print("Error with \(error.localizedDescription)")
        }
        

        

    }
    
    
    func SaveAsset(){
        //Checking and Taking permission
         self.checkPermission()
        
        let defaultUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
        PHPhotoLibrary.shared().performChanges({
            
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.outputUrl ?? defaultUrl)
        }) { saved, error in
            if saved {
                print("Video saved successfully.")
            } else {
                print("An error occurred: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    func checkPermission(){
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
            switch photoAuthorizationStatus {
            case .authorized:
                print("Access is granted by user")
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization({
                    (newStatus) in
                    print("status is \(newStatus)")
                    if newStatus == PHAuthorizationStatus.authorized {
                        print("success")
                    }
                })
                print("It is not determined until now")
            case .restricted:
                print("User do not have access to photo album.")
            case .denied:
                print("User has denied the permission.")
            @unknown default:
                print("Unknown status")
            }

    }
    
    func frameSize() -> CGSize {
        var size = CGSize.zero
        if self.Resolution == "420P"{
            size = CGSize(width: 854, height: 480)
        }else if self.Resolution == "720P"{
            size =  CGSize(width: 1280, height: 720)
        }else if self.Resolution == "1080P"{
            size = CGSize(width: 1920, height: 1080)
        }else if self.Resolution == "2K"{
            size = CGSize(width: 2560, height: 1440)
        }else if self.Resolution == "4K"{
            size = CGSize(width: 3840, height: 2160)
        }
        return size
    }
    
    func DisplayConfiguration(){
        print("Resolution: \(Resolution) BitrateType: \(BitrateType)")
    }
    
    }
