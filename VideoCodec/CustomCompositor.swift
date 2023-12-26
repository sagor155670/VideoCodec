//
//  CustomCompositor.swift
//  VideoCodec
//
//  Created by Saiful Islam Sagor on 26/12/23.
//

import Foundation
import AVFoundation
import VideoToolbox
import SwiftUI


class CustomCompositor: NSObject, AVVideoCompositing {
    
    private var renderContext: AVVideoCompositionRenderContext?
    
    var sourcePixelBufferAttributes: [String : Any]?{
        get{
            return ["\(kCVPixelBufferPixelFormatTypeKey)": kCVPixelFormatType_32BGRA]
        }
    }
    
    var requiredPixelBufferAttributesForRenderContext: [String : Any]{
        get{
            return ["\(kCVPixelBufferPixelFormatTypeKey)" : kCVPixelFormatType_32BGRA]
        }
    }
    
    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        renderContext =  newRenderContext
    }
    
    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        /* This is where you will process your frames, for each sequence of frame you
                 will recieve a render context that supplies a new empty frame , and instructions
                 that are assigned to the render context as well*/
        let request = asyncVideoCompositionRequest
        var destinationFrame = request.renderContext.newPixelBuffer()
        
        if request.sourceTrackIDs.count == 2{
            let firstFrame = request.sourceFrame(byTrackID: request.sourceTrackIDs[0].int32Value)
            let secondFrame = request.sourceFrame(byTrackID: request.sourceTrackIDs[1].int32Value)
            
            let instruction =  request.videoCompositionInstruction
            
            if let instr = instruction as? CustomOverlayInstruction, let rotate = instr.rotateSecondAsset{
                CVPixelBufferLockBaseAddress(firstFrame!, .readOnly)
                CVPixelBufferLockBaseAddress(secondFrame!, .readOnly)
                CVPixelBufferLockBaseAddress(destinationFrame!, CVPixelBufferLockFlags(rawValue: 0))
                
                var firstImage = createSourceImage(from: firstFrame)
                var secondImage = createSourceImage(from: secondFrame)
                
                var destWidth =  CVPixelBufferGetWidth(destinationFrame!)
                var destheight = CVPixelBufferGetHeight(destinationFrame!)
                
                if rotate{
//                    you can rotate the image however you see fit or need to. You can also attach additional instruction to help you.determine the necessary changes
                }
                
                let frame = CGRect(x: 0, y: 0, width: destWidth, height: destheight)
                var innerFrame = CGRect(x: 0, y: 0, width: (Double(destWidth) * 0.3), height: (Double(destheight) * 0.2))
                
                let backgroundLayer = CALayer()
                backgroundLayer.frame = frame
                backgroundLayer.contentsGravity = .resizeAspect
                backgroundLayer.contents = firstImage
                
                let overlayLayer = CALayer()
                overlayLayer.frame = innerFrame
                overlayLayer.contentsGravity = .resizeAspect
                overlayLayer.contents = secondImage
                
                let finalLayer =  CALayer()
                finalLayer.frame = frame
                finalLayer.backgroundColor = Color.clear.cgColor
                finalLayer.addSublayer(backgroundLayer)
                finalLayer.addSublayer(overlayLayer)
                
                //create image using the CALayer
                let fullImage = imageWithLayer(layer: finalLayer)
                
                var gc : CGContext?
                if let destination = destinationFrame, let image = firstImage?.colorSpace{
                    gc =  CGContext(data: CVPixelBufferGetBaseAddress(destination),
                                    width: destWidth, height: destheight,
                                    bitsPerComponent: 8,
                                    bytesPerRow: CVPixelBufferGetBytesPerRow(destination),
                                    space: image,
                                    bitmapInfo: firstImage?.bitmapInfo.rawValue ?? 0)
                }
                //draw in the image using CGContext
                gc?.draw(fullImage, in: frame)
                
//                make sure you flush the current CALayers , if you fail to,Swift will hold on to them and cause a memory leak
                CATransaction.flush()
                //unlock addresses after finishing
                CVPixelBufferUnlockBaseAddress(destinationFrame!, CVPixelBufferLockFlags(rawValue: 0))
                CVPixelBufferUnlockBaseAddress(firstFrame!, .readOnly)
                CVPixelBufferUnlockBaseAddress(secondFrame!, .readOnly)
                
                //end function with request.finish
                request.finish(withComposedVideoFrame: destinationFrame!)
            }
        }
        else{
            request.finish(withComposedVideoFrame: request.sourceFrame(byTrackID: request.sourceTrackIDs[0].int32Value)!)
        }
        
        
    }
    
    func createSourceImage(from buffer: CVPixelBuffer?) -> CGImage?{
        var image : CGImage?
        VTCreateCGImageFromCVPixelBuffer(buffer!, options: nil, imageOut: &image)
        return image
    }
    
    func imageWithLayer(layer: CALayer) -> CGImage {
        UIGraphicsBeginImageContextWithOptions(layer.bounds.size, layer.isOpaque, 0.0)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!.cgImage!
    }
    
    
}
