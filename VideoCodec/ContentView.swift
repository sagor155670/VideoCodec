    //
    //  ContentView.swift
    //  VideoCodec
    //
    //  Created by Saiful Islam Sagor on 21/11/23.
    //

import SwiftUI
import AVFoundation
import Photos
import AVKit

struct ContentView: View, ProgressCountProtocol {
    func getWriterPercentage(percentCount count: Int) {
        self.percent = count
    }
    

    

    
    @State var inputVideoPlayer:AVPlayer? = nil
    @State var outputVideoPlayer:AVPlayer? = nil
    @State var isloading:Bool = false
    @State var selectedMediaURL: URL? = nil
    @State var isShowingPicker:Bool = false
    @State var percent:Int = 0
    @State var exportObj:Export? = nil

    var body: some View {
        
        VStack {
            if self.outputVideoPlayer != nil {
                
                VStack{
                    VideoPlayer(player: inputVideoPlayer)
                        .ignoresSafeArea(.all)
                    
                    
                    VideoPlayer(player: outputVideoPlayer)
                        .ignoresSafeArea(.all)
                    
                    HStack{
                        Button{
                            inputVideoPlayer?.seek(to: CMTime.zero)
                            inputVideoPlayer?.play()
                            outputVideoPlayer?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
                            outputVideoPlayer?.play()
                        }label: {
                            Text("Play")
                                .fontWeight(.heavy)
                                .frame(width: 60,height: 30)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        Button{
                            self.outputVideoPlayer = nil
                            self.inputVideoPlayer = nil
                            self.selectedMediaURL = nil
                        }label: {
                            Text("Back")
                                .fontWeight(.heavy)
                                .frame(width: 60,height: 30)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    
                }
                
            }
            else if self.isloading{
                VStack{
                    Button{
                        exportObj!.cancellWriting()
                        self.isloading = false
                    }label: {
                        Text("Cancell")
                    }
                    Text("sampleNo: \(self.percent)")
                    ProgressView()
                        .frame(width: 100,height: 100)
                }
            }
            else{
                HStack{
                    Button{
                        if self.selectedMediaURL == nil {
                            print("No video Selected")
                        }else{
                            DispatchQueue.global(qos: .background).async {
                                let startTime = CFAbsoluteTimeGetCurrent()
//                                extractFramesFromVideo(videoUrl: selectedMediaURL ?? Bundle.main.url(forResource: "test", withExtension: "MOV")! )
//                                ExportVideowithMixAudio(videoUrl: selectedMediaURL ?? Bundle.main.url(forResource: "test", withExtension: "MOV")! )
//                                InsertImageWithVideoTracksRealTime(videoUrl: selectedMediaURL ?? Bundle.main.url(forResource: "test", withExtension: "MOV")!)
//                                callExporter(videoUrl: selectedMediaURL ?? Bundle.main.url(forResource: "test", withExtension: "MOV")!)
//                                ExportMixedVideo(videoUrl: selectedMediaURL ?? Bundle.main.url(forResource: "test", withExtension: "MOV")!)
                                ExportMixedVideo2(videoUrl: selectedMediaURL ?? Bundle.main.url(forResource: "test", withExtension: "MOV")!)
                                
                             
                                let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
                                print("elapsed time: \(elapsedTime)")
                            }
                            isloading = true
                        }
                    }label: {
                        Text("Test")
                            .fontWeight(.heavy)
                            .frame(width: 150,height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    Button{
                        isShowingPicker = true
                    }label: {
                        Text("Pick a Video")
                            .fontWeight(.heavy)
                            .frame(width: 150,height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        
                    }

                }
                
            }
        }
        .onAppear{
            let export = ExportBuilder()
                            .setResolution("4K")
                            .setFramerate(30)
                            .setBitrateType("Low")
                            .build()
            let bitrate = ExportUtils.calculateBitrate(frameRate: export.frameRate, resolution: export.Resolution, bitrateType: export.BitrateType)
            print(bitrate)
            export.DisplayConfiguration()
            
        }
        .onChange(of: selectedMediaURL) { _ in
            if selectedMediaURL != nil{
                inputVideoPlayer = AVPlayer(url: selectedMediaURL ?? Bundle.main.url(forResource: "test", withExtension: "MOV")!)
            }
        }
        .sheet(isPresented: $isShowingPicker) {
        
            MediaPicker(selectedMediaUrl: $selectedMediaURL, isShowingPicker: $isShowingPicker, mediaTypes: ["public.movie"])
        }
        
    }
    
    
    
    func extractFramesFromVideo(videoUrl: URL ) {
        
        let asset = AVAsset(url: videoUrl)
        let audioAsset = AVAsset(url:  Bundle.main.url(forResource: "audio", withExtension: "m4a")!)
        let frameRate:Float = getFrameRate(asset: asset) ?? 30
        print("Framerate: \(frameRate)")
        let duration = CMTimeGetSeconds(asset.duration)
        print("Video duration: \(duration)")
        print("audio duration: \(audioAsset.duration)")
        let estimatedSizeInMB = estimatedOutputFileSize(AverageBitRateForVideo: 7000000, AverageBitRateForAudio: 256000, VideoDuration: duration)
        print("Estimated Size: \(estimatedSizeInMB)")

        
        do{
                // Create an AVAssetReader instance
            let assetReader = try AVAssetReader(asset: asset)
            
                // Get video track
            let videoTrack = asset.tracks(withMediaType: .video).first!
                // Get audio track
            guard let audioTrack = asset.tracks(withMediaType: .audio).first else{
                self.isloading = false
                return
            }
                //making outputsettings
            let videoReaderOutputSetting: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
            ]
            let audioReaderSettings: [String: Any] = [AVFormatIDKey: kAudioFormatLinearPCM]
            
                //Create an AVAssetReaderTrackOutput and add it to the reader
            let videoTrackOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoReaderOutputSetting)
            let audioTrackOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: audioReaderSettings)
            assetReader.add(videoTrackOutput)
            assetReader.add(audioTrackOutput)

            
                // Create an AVAssetWriter instance
            let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
            let assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
            
            let videoWriterOutputSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.hevc,
                AVVideoWidthKey: videoTrack.naturalSize.width,
                AVVideoHeightKey: videoTrack.naturalSize.height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: NSNumber(value: 7542000) ,
//                    AVVideoQualityKey: 0.85
//                    AVVideoMaxKeyFrameIntervalKey : 1,
//                    AVVideoExpectedSourceFrameRateKey: 30
                    AVVideoProfileLevelKey: "HEVC_Main_AutoLevel"
                ] as [String : Any]
            ]
            let videoWriterOutputSettings2: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: 1280,
                AVVideoHeightKey: 720,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: NSNumber(value: 7542000) ,
                    AVVideoMaxKeyFrameIntervalKey : 1,
//                    AVVideoExpectedSourceFrameRateKey: 30
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264High40
                ] as [String : Any]
                ]

            let audioWriterOutputSettings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
                AVEncoderBitRateKey: 200000
            ]

                // Create an AVAssetWriterInput and add it to the writer
            let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoWriterOutputSettings)
            let audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioWriterOutputSettings)
//            let audio2WriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioWriterOutputSettings)
            
//            audioWriterInput.transform = audioTrack.preferredTransform
            videoWriterInput.transform = videoTrack.preferredTransform
            
            assetWriter.add(videoWriterInput)
            assetWriter.add(audioWriterInput)
//            assetWriter.add(audio2WriterInput)
            
                // Start Reading and Writing
            assetReader.startReading()
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: .zero)
            
            let processingQueue = DispatchQueue(label: "processingQueue")

            audioWriterInput.requestMediaDataWhenReady(on: processingQueue) {
                while audioWriterInput.isReadyForMoreMediaData {
                    if let sampleBuffer = audioTrackOutput.copyNextSampleBuffer() {
                        audioWriterInput.append(sampleBuffer)
                    } else {
                        audioWriterInput.markAsFinished()
                    }
                }
            }
                // Read Samples and Write them into the new video
            var sampleNo = 0
            while let sampleBuffer = videoTrackOutput.copyNextSampleBuffer(){
                print("Reading sample no: \(sampleNo)")
                while !videoWriterInput.isReadyForMoreMediaData {
                    usleep(10) // Sleep for a very short time
                }
                
                print("Writing sample no: \(sampleNo)")
                videoWriterInput.append(sampleBuffer)
                sampleNo += 1
            }
            
                // Finish writing
            videoWriterInput.markAsFinished()
//            audioWriterInput.markAsFinished()
            assetWriter.finishWriting {
                if assetWriter.status == .completed {
                    print("Writing completed successfully.")
                        // Save video to photo library
                    
                    let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
                        switch photoAuthorizationStatus {
                        case .authorized:
                            print("Access is granted by user")
                        case .notDetermined:
                            PHPhotoLibrary.requestAuthorization({
                                (newStatus) in
                                print("status is \(newStatus)")
                                if newStatus == PHAuthorizationStatus.authorized {
                                    /* do stuff here */
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
                    
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
                    }) { saved, error in
                        if saved {
                            print("Video saved successfully.")
                            self.outputVideoPlayer = AVPlayer(url: outputURL)
                            
                            
                        } else {
                            print("An error occurred: \(error?.localizedDescription ?? "Unknown error")")
                        }
                    }
                } else if assetWriter.status == .failed {
                    print("An error occurred: \(assetWriter.error?.localizedDescription ?? "Unknown error")")
                }
                isloading = false
            }
            
        } catch {
            print("Error with \(error.localizedDescription)")
        }
    }
    
    func ExportVideowithMixAudio(videoUrl: URL ) {
        
        let asset = AVAsset(url: videoUrl)
        let audioAsset = AVAsset(url:  Bundle.main.url(forResource: "mono2", withExtension: "m4a")!)  /*48khz*/
        let audioAsset2 = AVAsset(url:  Bundle.main.url(forResource: "stereo2", withExtension: "m4a")!)
        let frameRate:Float = getFrameRate(asset: asset) ?? 30
        print("Framerate: \(frameRate)")
        let duration = CMTimeGetSeconds(asset.duration)
        print("Video duration: \(duration)")
        print("audio duration: \(audioAsset.duration)")
        
        let composition = AVMutableComposition()
        
        guard let track1 = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid),
              let track2 = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
//            ,let track3 = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        else {
            return
        }

            
        
        do{
                // Create an AVAssetReader instance
            let assetReader = try AVAssetReader(asset: asset)
            
                // Get video track
            let videoTrack = asset.tracks(withMediaType: .video).first!
            
                // Get audio track
            guard let audioTrack = asset.tracks(withMediaType: .audio).first else{
                self.isloading = false
                return
            }
    
            guard let audioTrack2 = audioAsset.tracks(withMediaType: .audio).first else{
                self.isloading = false
                return
            }
            guard let audioTrack3 = audioAsset2.tracks(withMediaType: .audio).first else{
                self.isloading = false
                return
            }
        
//            getSamplingRate(audioTrack: audioTrack2)

            print(audioTrack3.timeRange.duration)
            try track1.insertTimeRange(CMTimeRange(start: .zero, duration: audioTrack2.timeRange.duration) , of: audioTrack2, at: .zero)
            try track2.insertTimeRange(CMTimeRange(start: .zero , duration: audioTrack3.timeRange.duration), of: audioTrack3, at: .zero )
//            try track3.insertTimeRange(CMTimeRange(start: CMTime(seconds: 130, preferredTimescale: audioTrack3.timeRange.duration.timescale), duration: audioTrack3.timeRange.duration), of: audioTrack3, at: CMTime(seconds: track1.timeRange.duration.seconds, preferredTimescale: audioTrack.timeRange.duration.timescale))

            
            composition.removeTimeRange(CMTimeRange(start: asset.duration, end: composition.duration))
            
            let mixComposition = AVMutableAudioMix()
            
            let mixParameters = AVMutableAudioMixInputParameters(track: track1)
//            let mixParameters2 = AVMutableAudioMixInputParameters(track: track2)
//            let mixParameters3 = AVMutableAudioMixInputParameters(track: track3)
        
          

            mixParameters.setVolumeRamp(fromStartVolume: 0, toEndVolume: 1, timeRange: CMTimeRange(start: CMTime(seconds: 10, preferredTimescale: 600), duration: CMTime(seconds: 20, preferredTimescale: 600)))
//            mixParameters2.setVolumeRamp(fromStartVolume:  1, toEndVolume: 0.1, timeRange: CMTimeRange(start: .zero, duration: composition.duration))
//            mixParameters2.setVolumeRamp(fromStartVolume: 1, toEndVolume: 0.5 , timeRange: CMTimeRange(start: .zero, duration: composition.duration))no3
            
            mixComposition.inputParameters = [mixParameters /*,mixParameters2,mixParameters3*/]
            print(mixParameters.description)
            getSamplingRate(audioTrack: composition.tracks(withMediaType: .audio).first!)
        
                //making outputsettings
            let videoReaderOutputSetting: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
            ]
            let audioReaderSettings: [String: Any] = [AVFormatIDKey: kAudioFormatLinearPCM]
            
                //Create an AVAssetReaderTrackOutput and add it to the reader
            let videoTrackOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoReaderOutputSetting)
//            let audioTrackOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: audioReaderSettings)
            let audioMixOutput = AVAssetReaderAudioMixOutput(audioTracks: composition.tracks(withMediaType: .audio), audioSettings: audioReaderSettings)
            audioMixOutput.audioMix = mixComposition
            
            assetReader.add(videoTrackOutput)
            print("total audio duration: \(CMTimeGetSeconds(composition.duration))")
            
            let audioAssetReader = try AVAssetReader(asset: composition)
            audioAssetReader.add(audioMixOutput)

            
                // Create an AVAssetWriter instance
            let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
            let assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
            
            let videoWriterOutputSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.hevc,
                AVVideoWidthKey: videoTrack.naturalSize.width,
                AVVideoHeightKey: videoTrack.naturalSize.height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: NSNumber(value: 10000000) ,
//                    AVVideoMaxKeyFrameIntervalKey : 1,
//                    AVVideoExpectedSourceFrameRateKey: 30
//                    AVVideoProfileLevelKey: "HEVC_Main_AutoLevel"
                ] as [String : Any]
            ]
            let audioWriterOutputSettings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
                AVEncoderBitRateKey: 256000
            ]

                // Create an AVAssetWriterInput and add it to the writer
            let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoWriterOutputSettings)
            let audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioWriterOutputSettings)

            videoWriterInput.transform = videoTrack.preferredTransform
            
            assetWriter.add(videoWriterInput)
            assetWriter.add(audioWriterInput)

            
                // Start Reading and Writing
            assetReader.startReading()
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
            var sampleNo = 0
            while let sampleBuffer = videoTrackOutput.copyNextSampleBuffer(){
                print("Reading sample no: \(sampleNo)")
                while !videoWriterInput.isReadyForMoreMediaData {
                    usleep(10) // Sleep for a very short time
                }
                
                print("Writing sample no: \(sampleNo)")
                videoWriterInput.append(sampleBuffer)
                sampleNo += 1
            }
            
                // Finish writing
            videoWriterInput.markAsFinished()
//            audioWriterInput.markAsFinished()
            assetWriter.finishWriting {
                if assetWriter.status == .completed {
                    print("Writing completed successfully.")
                        // Save video to photo library
                    
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
                    
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
                    }) { saved, error in
                        if saved {
                            print("Video saved successfully.")
                            self.outputVideoPlayer = AVPlayer(url: outputURL)
                            
                            
                        } else {
                            print("An error occurred: \(error?.localizedDescription ?? "Unknown error")")
                        }
                    }
                } else if assetWriter.status == .failed {
                    print("An error occurred: \(assetWriter.error?.localizedDescription ?? "Unknown error")")
                }
                isloading = false
            }
            
        } catch {
            print("Error with \(error.localizedDescription)")
        }
    }
    
    func InsertImageWithVideoTrackswhileExporting(videoUrl: URL ) {
        
        let videoAsset1 = AVAsset(url: videoUrl)

//        let frameRate:Float = getFrameRate(asset: videoAsset1) ?? 30
//        print("Framerate: \(frameRate)")
//        let duration = CMTimeGetSeconds(videoAsset1.duration)
//        print("Video duration: \(duration)")
        let videoAsset2 = AVAsset(url: Bundle.main.url(forResource: "test3", withExtension: "MOV")! )
        
        let composition = AVMutableComposition()
        
        guard let track1 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
//              let track2 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let track3 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        else {
            return
        }

            
        
        do{
            
                // Get video track
            let videoTrack = videoAsset1.tracks(withMediaType: .video).first!
            guard let videoTrack2 = videoAsset2.tracks(withMediaType: .video).first else{
                self.isloading = false
                return
            }
        

            try track1.insertTimeRange(CMTimeRange(start: .zero, duration: videoTrack.timeRange.duration) , of: videoTrack, at: .zero)
//            try track2.insertTimeRange(CMTimeRange(start: .zero , duration: audioTrack3.timeRange.duration), of: audioTrack3, at: .zero )
            try track1.insertEmptyTimeRange(CMTimeRange(start: track1.timeRange.end , duration: CMTime(seconds: 10, preferredTimescale: videoTrack.timeRange.duration.timescale)))
            try track3.insertTimeRange(CMTimeRange(start: .zero , duration: videoTrack2.timeRange.duration), of: videoTrack2, at: videoTrack.timeRange.duration + CMTime(seconds: 10, preferredTimescale: videoTrack2.timeRange.duration.timescale))
           
            
            let imageLayer = CALayer()
            imageLayer.contents = UIImage(named: "image2.jpg")?.cgImage
            imageLayer.frame = CGRect(x: 0, y: 0, width: composition.naturalSize.width, height: composition.naturalSize.height)
            imageLayer.contentsGravity = .resizeAspect
            
            let videoLayer = CALayer()
            videoLayer.frame = CGRect(x: 0, y: 0, width: composition.naturalSize.width, height: composition.naturalSize.height)
//            videoLayer.contentsGravity = .resizeAspectFill
            
            // Set the time range for the image overlay
            let overlayStartTime = CMTime(seconds: videoTrack.timeRange.duration.seconds, preferredTimescale: videoTrack.timeRange.duration.timescale) // Set the start time for the overlay
            let overlayDuration = CMTime(seconds: 10, preferredTimescale: videoTrack.timeRange.duration.timescale) // Set the duration for the overlay
            imageLayer.beginTime = CFTimeInterval(CMTimeGetSeconds(overlayStartTime))
            imageLayer.duration = CFTimeInterval(CMTimeGetSeconds(overlayDuration))

                // Create a parent layer and add the video and image layers
            let parentLayer = CALayer()
            parentLayer.frame = CGRect(x: 0, y: 0, width: composition.naturalSize.width, height: composition.naturalSize.height)
//            parentLayer.contentsGravity = .resizeAspectFill
            parentLayer.addSublayer(videoLayer)
            parentLayer.addSublayer(imageLayer)
            
            
            
//            composition.removeTimeRange(CMTimeRange(start: asset.duration, end: composition.duration))
            
            let videoComposition = AVMutableVideoComposition(propertiesOf: composition)
//            videoComposition.frameDuration = CMTime(seconds: 1, preferredTimescale: 30)
//            videoComposition.renderSize = videoTrack.naturalSize
        
            videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
            
//            // Create player item
//            let playerItem = AVPlayerItem(asset: composition)
//            playerItem.videoComposition = videoComposition
//            
//            self.outputVideoPlayer = AVPlayer(playerItem: playerItem)
//            isloading = false
//            return
                //making outputsettings
            let videoReaderOutputSetting: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
            ]
            
                //Create an AVAssetReaderTrackOutput and add it to the reader
            let videoCompositionOutput = AVAssetReaderVideoCompositionOutput(videoTracks: composition.tracks(withMediaType: .video), videoSettings: videoReaderOutputSetting)

            videoCompositionOutput.videoComposition = videoComposition
            print("total video duration: \(CMTimeGetSeconds(composition.duration))")
            
            let assetReader = try AVAssetReader(asset: composition)
            assetReader.add(videoCompositionOutput)

            
                // Create an AVAssetWriter instance
            let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
            let assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
            
            let videoWriterOutputSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.hevc,
                AVVideoWidthKey: composition.naturalSize.width,
                AVVideoHeightKey: composition.naturalSize.height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: NSNumber(value: 10000000) ,
//                    AVVideoMaxKeyFrameIntervalKey : 1,
//                    AVVideoExpectedSourceFrameRateKey: 30
//                    AVVideoProfileLevelKey: "HEVC_Main_AutoLevel"
                ] as [String : Any]
            ]


                // Create an AVAssetWriterInput and add it to the writer
            let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoWriterOutputSettings)
//            videoWriterInput.expectsMediaDataInRealTime = false

            videoWriterInput.transform = videoTrack.preferredTransform
            
            assetWriter.add(videoWriterInput)

            
                // Start Reading and Writing
            assetReader.startReading()
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: .zero)
            
//            let processingQueue = DispatchQueue(label: "processingQueue")

                // Read Samples and Write them into the new video
            var sampleNo = 0
            while let sampleBuffer = videoCompositionOutput.copyNextSampleBuffer(){
                print("Reading sample no: \(sampleNo)")
                while !videoWriterInput.isReadyForMoreMediaData {
                    usleep(10) // Sleep for a very short time
                }
                
                print("Writing sample no: \(sampleNo)")
                videoWriterInput.append(sampleBuffer)
                sampleNo += 1
            }
//            videoWriterInput.requestMediaDataWhenReady(on: DispatchQueue.global(qos: .default)) {
//                while videoWriterInput.isReadyForMoreMediaData{
//                    if let sampleBuffer = videoCompositionOutput.copyNextSampleBuffer(){
//                        videoWriterInput.append(sampleBuffer)
//                    }else{
//                        videoWriterInput.markAsFinished()
//                    }
//                }
//            }
            
                // Finish writing
            videoWriterInput.markAsFinished()
//            audioWriterInput.markAsFinished()
            assetWriter.finishWriting {
                if assetWriter.status == .completed {
                    print("Writing completed successfully.")
                        // Save video to photo library
                    
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
                    
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
                    }) { saved, error in
                        if saved {
                            print("Video saved successfully.")
                            self.outputVideoPlayer = AVPlayer(url: outputURL)
                            
                            
                        } else {
                            print("An error occurred: \(error?.localizedDescription ?? "Unknown error")")
                        }
                    }
                } else if assetWriter.status == .failed {
                    print("An error occurred: \(assetWriter.error?.localizedDescription ?? "Unknown error")")
                }
                isloading = false
            }
            
        } catch {
            print("Error with \(error.localizedDescription)")
        }
    }
    
    func InsertImageWithVideoTracksRealTime(videoUrl: URL ) {
        
        let videoAsset1 = AVAsset(url: videoUrl)

//        let frameRate:Float = getFrameRate(asset: videoAsset1) ?? 30
//        print("Framerate: \(frameRate)")
//        let duration = CMTimeGetSeconds(videoAsset1.duration)
//        print("Video duration: \(duration)")
        let videoAsset2 = AVAsset(url: Bundle.main.url(forResource: "test3", withExtension: "MOV")! )
        
//        self.mergeMovies(videoURLs: [videoUrl, Bundle.main.url(forResource: "test3", withExtension: "MOV")!]) { result in
//            
//        }

        let composition = AVMutableComposition()
        
        guard let track1 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
//              let track2 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let track3 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        else {
            return
        }

            
        
        do{
            
                // Get video track
            let videoTrack = videoAsset1.tracks(withMediaType: .video).first!
            
            guard let videoTrack2 = videoAsset2.tracks(withMediaType: .video).first else{
                self.isloading = false
                return
            }
        

            try track1.insertTimeRange(CMTimeRange(start: .zero, duration: videoTrack.timeRange.duration) , of: videoTrack, at: .zero)
//            try track2.insertTimeRange(CMTimeRange(start: .zero , duration: audioTrack3.timeRange.duration), of: audioTrack3, at: .zero )
            track1.insertEmptyTimeRange(CMTimeRange(start: videoTrack.timeRange.end , duration: CMTime(seconds: 10, preferredTimescale: videoTrack.timeRange.duration.timescale)))
            try track1.insertTimeRange(CMTimeRange(start: .zero , duration: videoTrack2.timeRange.duration), of: videoTrack2, at: videoTrack.timeRange.duration + CMTime(seconds: 10, preferredTimescale: 600))
           
            
            let overlayImage = CIImage(image: UIImage(named: "image.jpeg")!)
            let videoSize = videoTrack.naturalSize
            
            let compositionForPlayer = AVMutableVideoComposition(asset: composition ) { filterRequest in
                let source = filterRequest.sourceImage.clampedToExtent()
                let currentTime = filterRequest.compositionTime
                if currentTime > videoTrack.timeRange.end && currentTime < CMTimeAdd(videoAsset1.duration, CMTime(seconds: 10, preferredTimescale: videoTrack.timeRange.duration.timescale)){
//                    let overlayFiltre = CIFilter(name: "CISourceOverCompositing")
//                    overlayFiltre?.setValue(overlayImage, forKey: kCIInputImageKey)
//                    overlayFiltre?.setValue(nil, forKey: kCIInputBackgroundImageKey)
//                    let outputImage = overlayFiltre?.outputImage ?? overlayImage
                    let overlayImageSize =  overlayImage!.extent.size
                    let outputImage =  overlayImage!.transformed(by: CGAffineTransform(scaleX: videoSize.width / overlayImageSize.width, y: videoSize.height / overlayImageSize.height))
                    filterRequest.finish(with: outputImage, context: nil)
                }else{
                    filterRequest.finish(with: source, context: nil)
                }
            }
            compositionForPlayer.frameDuration = CMTime(value: 1, timescale: 60)
            compositionForPlayer.renderSize = videoTrack.naturalSize
            
//            // Create player item
//            let playerItem = AVPlayerItem(asset: composition )
//            playerItem.videoComposition = compositionForPlayer
//
//            self.outputVideoPlayer = AVPlayer(playerItem: playerItem)
//            isloading = false
//            return
            
            let videoReaderOutputSetting: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
            ]
            
                //Create an AVAssetReaderTrackOutput and add it to the reader
            let videoCompositionOutput = AVAssetReaderVideoCompositionOutput(videoTracks: composition.tracks(withMediaType: .video), videoSettings: videoReaderOutputSetting)

            videoCompositionOutput.videoComposition = compositionForPlayer
            print("total video duration: \(CMTimeGetSeconds(composition.duration))")
            
            let assetReader = try AVAssetReader(asset: composition)
            assetReader.add(videoCompositionOutput)

            
                // Create an AVAssetWriter instance
            let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
            let assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
            
            let videoWriterOutputSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.hevc,
                AVVideoWidthKey: composition.naturalSize.width,
                AVVideoHeightKey: composition.naturalSize.height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: NSNumber(value: 10000000) ,
//                    AVVideoMaxKeyFrameIntervalKey : 1,
//                    AVVideoExpectedSourceFrameRateKey: 30
//                    AVVideoProfileLevelKey: "HEVC_Main_AutoLevel"
                ] as [String : Any]
            ]


                // Create an AVAssetWriterInput and add it to the writer
            let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoWriterOutputSettings)
//            videoWriterInput.expectsMediaDataInRealTime = false

            videoWriterInput.transform = composition.preferredTransform
            
            assetWriter.add(videoWriterInput)

            
                // Start Reading and Writing
            assetReader.startReading()
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: .zero)
            
            
            var sampleNo = 0
            while let sampleBuffer = videoCompositionOutput.copyNextSampleBuffer(){
                print("Reading sample no: \(sampleNo)")
                while !videoWriterInput.isReadyForMoreMediaData {
                    usleep(10) // Sleep for a very short time
                }
                
                print("Writing sample no: \(sampleNo)")
                videoWriterInput.append(sampleBuffer)
                sampleNo += 1
            }
            
                // Finish writing
            videoWriterInput.markAsFinished()
//            audioWriterInput.markAsFinished()
            assetWriter.finishWriting {
                if assetWriter.status == .completed {
                    print("Writing completed successfully.")
                        // Save video to photo library
                    
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
                    
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
                    }) { saved, error in
                        if saved {
                            print("Video saved successfully.")
                            self.outputVideoPlayer = AVPlayer(url: outputURL)
                            
                            
                        } else {
                            print("An error occurred: \(error?.localizedDescription ?? "Unknown error")")
                        }
                    }
                } else if assetWriter.status == .failed {
                    print("An error occurred: \(assetWriter.error?.localizedDescription ?? "Unknown error")")
                }
                isloading = false
            }
        
        } catch {
            print("Error with \(error.localizedDescription)")
        }
    }

    func callExporter(videoUrl: URL){
        let videoAsset1 = AVAsset(url: videoUrl)
        let videoAsset2 = AVAsset(url: Bundle.main.url(forResource: "test", withExtension: "MOV")! )
        let videoAsset3 = AVAsset(url: Bundle.main.url(forResource: "test2", withExtension: "MOV")! )
        let vTrack1 = videoAsset1.tracks(withMediaType: .video).first
        let vTrack2 = videoAsset2.tracks(withMediaType: .video).first
        let vTrack3 = videoAsset3.tracks(withMediaType: .video).first
        
        let audioAsset1 = AVAsset(url: Bundle.main.url(forResource: "mono2", withExtension: "m4a")! )
        let audioAsset2 = AVAsset(url: Bundle.main.url(forResource: "audio2", withExtension: "m4a")! )
        let aTrack1 = audioAsset1.tracks(withMediaType: .audio).first
        let atrack2 = audioAsset2.tracks(withMediaType: .audio).first
        var videoTracks: [AVAssetTrack] = []
        var audioTracks: [AVAssetTrack] = []
        videoTracks.append(vTrack1!)
//        videoTracks.append(vTrack2!)
//        videoTracks.append(vTrack3!)
        audioTracks.append(aTrack1!)
        audioTracks.append(atrack2!)
        
        let export = ExportBuilder()
                        .setVideoTracks(videoTracks: videoTracks)
                        .setAudioTracks(audioTracks: audioTracks)
                        .setResolution("4K")
                        .setFramerate(25)
                        .setBitrateType("Low")
                        .build()
        
//        self.sampleNo = export.sampleNo
        export.percentage = self
        self.exportObj = export
        exportObj!.ExportAsset()
        
        
//        self.isloading = false
//        self.outputVideoPlayer = AVPlayer(url: videoUrl)
//        return
        

    }
    
    func ExportMixedVideo(videoUrl: URL ) {
        
        let asset = AVAsset(url: videoUrl)
        let videoAsset1 = AVAsset(url: videoUrl)
        let videoAsset2 = AVAsset(url:  Bundle.main.url(forResource: "video2", withExtension: "MOV")!)
        let frameRate:Float = getFrameRate(asset: asset) ?? 30
        print("Framerate: \(frameRate)")
//        let duration = CMTimeGetSeconds(asset.duration)
//        print("Video duration: \(duration)")
//        print("audio duration: \(audioAsset.duration)")
        
        let composition = AVMutableComposition()
        
        guard let track1 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let track2 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
//            ,let track3 = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        else {
            return
        }

            
        
        do{
                // Create an AVAssetReader instance
            let assetReader = try AVAssetReader(asset: asset)
            
                // Get video track
            let videoTrack = asset.tracks(withMediaType: .video).first!
            
                // Get audio track
//            guard let audioTrack = asset.tracks(withMediaType: .audio).first else{
//                self.isloading = false
//                return
//            }
    
            guard let vTrack1 = videoAsset1.tracks(withMediaType: .video).first else{
                self.isloading = false
                return
            }
            guard let vTrack2 = videoAsset2.tracks(withMediaType: .video).first else{
                self.isloading = false
                return
            }
        

            try track1.insertTimeRange(CMTimeRange(start: .zero, duration: vTrack1.timeRange.duration) , of: vTrack1, at: .zero)
            try track2.insertTimeRange(CMTimeRange(start: .zero , duration: vTrack2.timeRange.duration), of: vTrack2, at: .zero )
//            try track3.insertTimeRange(CMTimeRange(start: CMTime(seconds: 130, preferredTimescale: audioTrack3.timeRange.duration.timescale), duration: audioTrack3.timeRange.duration), of: audioTrack3, at: CMTime(seconds: track1.timeRange.duration.seconds, preferredTimescale: audioTrack.timeRange.duration.timescale))

            
            composition.removeTimeRange(CMTimeRange(start: asset.duration, end: composition.duration))
            
            let mainInstruction = AVMutableVideoCompositionInstruction()
            mainInstruction.timeRange = CMTimeRangeMake(start: .zero, duration: composition.duration)

            let layerInstruction1 = AVMutableVideoCompositionLayerInstruction(assetTrack: track1)
            let layerInstruction2 = AVMutableVideoCompositionLayerInstruction(assetTrack: track2)
            
            // Here we can set the transform to display videos side by side
            let videoSize = track1.naturalSize

 

            // Apply the scaling to both video tracks to fit them on the screen
            let scaledTransform = CGAffineTransform(scaleX: 0.5, y: 1)
            let moveLeft = CGAffineTransform(translationX: 0, y: 0)
            let moveRight = CGAffineTransform(translationX: videoSize.width * 0.5 , y: 0)

            layerInstruction1.setTransform(scaledTransform.concatenating(moveLeft), at: .zero)
            layerInstruction2.setTransform(scaledTransform.concatenating(moveRight), at: .zero)

            // Update the mainComposition's render size to fit both videos side by side
//            let scaledVideoWidth = videoSize.width * scale * 2
//            let scaledVideoHeight = videoSize.height * scale
                       
            mainInstruction.layerInstructions = [layerInstruction1, layerInstruction2]

            
            let mainComposition = AVMutableVideoComposition()
            mainComposition.instructions = [mainInstruction]
            mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
//            mainComposition.renderSize = CGSize(width: scaledVideoWidth, height: scaledVideoHeight) 
            mainComposition.renderSize = videoSize
            
            let playerItem = AVPlayerItem(asset: composition)
            playerItem.videoComposition = mainComposition
            self.isloading = false
            self.outputVideoPlayer = AVPlayer(playerItem: playerItem)
            return
                //making outputsettings
            let videoReaderOutputSetting: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
            ]
//            let audioReaderSettings: [String: Any] = [AVFormatIDKey: kAudioFormatLinearPCM]
            
                //Create an AVAssetReaderTrackOutput and add it to the reader
            let videoTrackOutput = AVAssetReaderVideoCompositionOutput(videoTracks: composition.tracks(withMediaType: .video), videoSettings: videoReaderOutputSetting)
//            let audioTrackOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: audioReaderSettings)

            
            assetReader.add(videoTrackOutput)
            print("total audio duration: \(CMTimeGetSeconds(composition.duration))")
            
//            let audioAssetReader = try AVAssetReader(asset: composition)
//            audioAssetReader.add(audioMixOutput)

            
                // Create an AVAssetWriter instance
            let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
            let assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
            
            let videoWriterOutputSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.hevc,
                AVVideoWidthKey: videoTrack.naturalSize.width,
                AVVideoHeightKey: videoTrack.naturalSize.height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: NSNumber(value: 10000000) ,
//                    AVVideoMaxKeyFrameIntervalKey : 1,
//                    AVVideoExpectedSourceFrameRateKey: 30
//                    AVVideoProfileLevelKey: "HEVC_Main_AutoLevel"
                ] as [String : Any]
            ]
            let audioWriterOutputSettings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
                AVEncoderBitRateKey: 256000
            ]

                // Create an AVAssetWriterInput and add it to the writer
            let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoWriterOutputSettings)
            let audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioWriterOutputSettings)

            videoWriterInput.transform = videoTrack.preferredTransform
            
            assetWriter.add(videoWriterInput)
            assetWriter.add(audioWriterInput)

            
                // Start Reading and Writing
            assetReader.startReading()
//            audioAssetReader.startReading()
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: .zero)
            
//            let processingQueue = DispatchQueue(label: "processingQueue")
//
//            audioWriterInput.requestMediaDataWhenReady(on: processingQueue) {
//                while audioWriterInput.isReadyForMoreMediaData {
//                    if let sampleBuffer = audioMixOutput.copyNextSampleBuffer() {
//                        audioWriterInput.append(sampleBuffer)
//                    } else {
//                        audioWriterInput.markAsFinished()
//                    }
//                }
//            }
                // Read Samples and Write them into the new video
            var sampleNo = 0
            while let sampleBuffer = videoTrackOutput.copyNextSampleBuffer(){
                print("Reading sample no: \(sampleNo)")
                while !videoWriterInput.isReadyForMoreMediaData {
                    usleep(10) // Sleep for a very short time
                }
                
                print("Writing sample no: \(sampleNo)")
                videoWriterInput.append(sampleBuffer)
                sampleNo += 1
            }
            
                // Finish writing
            videoWriterInput.markAsFinished()
//            audioWriterInput.markAsFinished()
            assetWriter.finishWriting {
                if assetWriter.status == .completed {
                    print("Writing completed successfully.")
                        // Save video to photo library
                    
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
                    
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
                    }) { saved, error in
                        if saved {
                            print("Video saved successfully.")
                            self.outputVideoPlayer = AVPlayer(url: outputURL)
                            
                            
                        } else {
                            print("An error occurred: \(error?.localizedDescription ?? "Unknown error")")
                        }
                    }
                } else if assetWriter.status == .failed {
                    print("An error occurred: \(assetWriter.error?.localizedDescription ?? "Unknown error")")
                }
                isloading = false
            }
            
        } catch {
            print("Error with \(error.localizedDescription)")
        }
    }
    
    func ExportMixedVideo2(videoUrl: URL ) {
        
        let asset = AVAsset(url: videoUrl)
        let videoAsset1 = AVAsset(url: videoUrl)
        let videoAsset2 = AVAsset(url:  Bundle.main.url(forResource: "video2", withExtension: "MOV")!)
        let frameRate:Float = getFrameRate(asset: asset) ?? 30
        print("Framerate: \(frameRate)")
//        let duration = CMTimeGetSeconds(asset.duration)
//        print("Video duration: \(duration)")
//        print("audio duration: \(audioAsset.duration)")
        
        let composition = AVMutableComposition()
        
        guard let track1 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let track2 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
//            ,let track3 = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        else {
            return
        }

            
        
        do{
                // Create an AVAssetReader instance
            let assetReader = try AVAssetReader(asset: asset)
            
                // Get video track
            let videoTrack = asset.tracks(withMediaType: .video).first!

    
            guard let vTrack1 = videoAsset1.tracks(withMediaType: .video).first else{
                self.isloading = false
                return
            }
            guard let vTrack2 = videoAsset2.tracks(withMediaType: .video).first else{
                self.isloading = false
                return
            }
        

            try track1.insertTimeRange(CMTimeRange(start: .zero, duration: vTrack1.timeRange.duration) , of: vTrack1, at: .zero)
            try track2.insertTimeRange(CMTimeRange(start: .zero , duration: vTrack2.timeRange.duration), of: vTrack2, at: .zero )

            
            composition.removeTimeRange(CMTimeRange(start: asset.duration, end: composition.duration))
            
            let instruction = CustomOverlayInstruction(timeRange: CMTimeRange(start: .zero, duration: videoAsset2.duration), rotateSceondAsset: true, videoTracks: composition.tracks(withMediaType: .video))
//            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
//            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: vTrack1)
//            instruction.layerInstructions = [layerInstruction]

            let mainComposition = AVMutableVideoComposition()
            mainComposition.customVideoCompositorClass = CustomCompositor.self
            mainComposition.instructions = [instruction]
            mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
            mainComposition.renderSize = CGSize(width: composition.naturalSize.width, height: composition.naturalSize.height)
            
            let playerItem = AVPlayerItem(asset: composition)
            playerItem.videoComposition = mainComposition
          
            self.isloading = false
            self.outputVideoPlayer = AVPlayer(playerItem: playerItem)
            return
            
            
        } catch {
            print("Error with \(error.localizedDescription)")
        }
    }
  
    public func mergeMoviesbyNewazVai(videoURLs: [URL], outcome: @escaping (Result<URL, Error>) -> Void) {
      let acceptableVideoExtensions = ["mov", "mp4", "m4v"]
      let _videoURLs = videoURLs.filter({ !$0.absoluteString.contains(".DS_Store") && acceptableVideoExtensions.contains($0.pathExtension.lowercased()) })
      
      /// guard against missing URLs
      guard !_videoURLs.isEmpty else {
        return
      }
      
      var videoAssets: [AVURLAsset] = []
      var completeMoviePath: URL?
      
      for path in _videoURLs {
        if let _url = URL(string: path.absoluteString) {
          videoAssets.append(AVURLAsset(url: _url))
        }
      }
      
      if let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
        /// create a path to the video file
        completeMoviePath = URL(fileURLWithPath: documentsPath).appendingPathComponent("outputVideo.mp4")
        
        if let completeMoviePath = completeMoviePath {
          if FileManager.default.fileExists(atPath: completeMoviePath.path) {
            do {
              /// delete an old duplicate file
              try FileManager.default.removeItem(at: completeMoviePath)
            } catch {
              DispatchQueue.main.async {
                outcome(.failure(error))
              }
            }
          }
        }
      } else {
        
      }
      
      let composition = AVMutableComposition()
      
      if let completeMoviePath = completeMoviePath {
        
        /// add audio and video tracks to the composition
        if let videoTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid),
           let audioTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
          
          var insertTime = CMTime(seconds: 0, preferredTimescale: 1)
          
          /// for each URL add the video and audio tracks and their duration to the composition
          for sourceAsset in videoAssets {
            do {
              if let assetVideoTrack = sourceAsset.tracks(withMediaType: .video).first, let assetAudioTrack = sourceAsset.tracks(withMediaType: .audio).first {
                let frameRange = CMTimeRange(start: CMTime(seconds: 0, preferredTimescale: 1), duration: sourceAsset.duration)
                try videoTrack.insertTimeRange(frameRange, of: assetVideoTrack, at: insertTime)
                try audioTrack.insertTimeRange(frameRange, of: assetAudioTrack, at: insertTime)
                
                videoTrack.preferredTransform = assetVideoTrack.preferredTransform
              }
              
              insertTime = insertTime + sourceAsset.duration
            } catch {
              DispatchQueue.main.async {
                outcome(.failure(error))
              }
            }
          }
          
            
            let playerItem = AVPlayerItem(asset: composition )
//            playerItem.videoComposition = compositionForPlayer
            
            self.outputVideoPlayer = AVPlayer(playerItem: playerItem)
            isloading = false
            
          /// try to start an export session and set the path and file type
//          if let exportSession = AVAssetExportSession(asset: composition, presetName:  AVAssetExportPresetHighestQuality) {
//            exportSession.outputURL = completeMoviePath
//            exportSession.outputFileType = AVFileType.mp4
//            exportSession.shouldOptimizeForNetworkUse = true
//            
//            /// try to export the file and handle the status cases
//            exportSession.exportAsynchronously(completionHandler: {
//              switch exportSession.status {
//              case .failed:
//                if let _error = exportSession.error {
//                  DispatchQueue.main.async {
//                    outcome(.failure(_error))
//                  }
//                }
//                
//              case .cancelled:
//                if let _error = exportSession.error {
//                  DispatchQueue.main.async {
//                    outcome(.failure(_error))
//                  }
//                }
//                
//              default:
//                print("finished")
//                DispatchQueue.main.async {
//                  outcome(.success(completeMoviePath))
//                }
//              }
//            })
//          } else {
//            
//          }
        }
      }
    }
    
}




func estimatedOutputFileSize(AverageBitRateForVideo: Double, AverageBitRateForAudio: Double, VideoDuration: Double)-> Double{
    let totalBitRate = AverageBitRateForAudio + AverageBitRateForVideo
    let estimatedSizeInByte = (totalBitRate * VideoDuration) / 8
    let estimatedSizeInMB = estimatedSizeInByte / (1024 * 1024)
    return estimatedSizeInMB
}

func getSamplingRate(audioTrack: AVAssetTrack){
    let format1 = audioTrack.formatDescriptions as? [CMAudioFormatDescription]
    let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(format1![0])
    print("track samplingRate: \(asbd?.pointee.mSampleRate)")
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
