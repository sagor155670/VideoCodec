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
    var workItem: DispatchWorkItem?
    
    init(videoTracks: [AVAssetTrack], audioTracks: [AVAssetTrack], outputUrl: URL? = nil, Resolution: String, frameRate: Int, BitrateType: String, sampleNo: Int = 0) {
        self.videoTracks = videoTracks
        self.audioTracks = audioTracks
        self.outputUrl = outputUrl
        self.Resolution = Resolution
        self.frameRate = frameRate
        self.BitrateType = BitrateType
        self.sampleNo = sampleNo
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
            let bitrate = ExportUtils.calculateBitrate(frameRate: self.frameRate, resolution: self.Resolution, bitrateType: self.BitrateType)
            
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
            
            workItem = DispatchWorkItem {
                    //            DispatchQueue.global().async {
                VideoAssetReader.startReading()
                audioAssetReader.startReading()
                assetWriter.startWriting()
                assetWriter.startSession(atSourceTime: .zero)
                
                let processingQueue = DispatchQueue(label: "processingQueue")
                
                audioWriterInput.requestMediaDataWhenReady(on: processingQueue) {
                    while audioWriterInput.isReadyForMoreMediaData {
                        if let sampleBuffer = audioMixOutput.copyNextSampleBuffer() {
                            if self.workItem?.isCancelled == true {
                                assetWriter.cancelWriting()
                                print("export cancelled!")
                                return
                            }
                            audioWriterInput.append(sampleBuffer)
                        } else {
                            audioWriterInput.markAsFinished()
                        }
                    }
                }
                
                    // Read Samples and Write them into the new video
                    //            var sampleNo = 0
                while let sampleBuffer = videoCompositionOutput.copyNextSampleBuffer(){
                    if self.workItem?.isCancelled == true {
                        assetWriter.cancelWriting()
                        print("export cancelled!")
                        return
                    }
                    print("Reading sample no: \(self.sampleNo)")
                    while !videoWriterInput.isReadyForMoreMediaData {
                        usleep(10) // Sleep for a very short time
                    }
                    
                    print("Writing sample no: \(self.sampleNo)")
                    videoWriterInput.append(sampleBuffer)
                    self.sampleNo += 1
                    let percentage = Double(self.sampleNo) * 100 / totalFrames
                    self.percentage?.getWriterPercentage(percentCount: Int(percentage))
                }
                
                videoWriterInput.markAsFinished()
                
                    //            }
                
                
                
                assetWriter.finishWriting {
                    if assetWriter.status == .completed{
                        self.SaveAsset()
                    }else if assetWriter.status == .failed {
                        print("An error occurred: \(assetWriter.error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
            
            DispatchQueue.global().async(execute: workItem!)
            
        }catch{
            print("Error with \(error.localizedDescription)")
        }
        
        
        
        
        
    }
    
    func cancellWriting(){
        workItem?.cancel()
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
        if self.Resolution == "480P"{
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
        let bitrate = ExportUtils.calculateBitrate(frameRate: self.frameRate, resolution: self.Resolution, bitrateType: self.BitrateType)
        print("Resolution: \(Resolution) BitrateType: \(BitrateType) bitRate: \(bitrate)")
    }
    
}
