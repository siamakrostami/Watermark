//
//  File.swift
//  
//
//  Created by siamak rostami on 11/14/1400 AP.
//

import Foundation
import Combine
import AVKit
import AVFoundation
import UIKit

public protocol CreateWatermarkProtocols{
    func addWatermarkToVideo(videoUrl : URL , watermarkUrl : URL)
    func addWatermarkToImage(mainImage : URL , watermarkImage : URL)
}

open class WatermarkHandler{
    open var exportProgress = CurrentValueSubject<Double?,Never>(nil)
    open var currentExportSession = CurrentValueSubject<AVAssetExportSession?,Never>(nil)
    open var assetError = CurrentValueSubject<Error?,Never>(nil)
    open var exportError = CurrentValueSubject<Error?,Never>(nil)
    open var cachedWatermarkURL = CurrentValueSubject<URL?,Never>(nil)
    open var watermarkImage = CurrentValueSubject<UIImage?,Never>(nil)
    public init(){}
}

extension WatermarkHandler : CreateWatermarkProtocols{
    
    public func addWatermarkToVideo(videoUrl: URL, watermarkUrl: URL) {
        
        var outputVideoPath : URL!
        switch WatermarkUtilities.isWatermarkedCacheAvailable(videoUrl: videoUrl){
        case true:
            outputVideoPath = WatermarkUtilities.fileLocationForWatermarkVideo(url: videoUrl)
            cachedWatermarkURL.send(outputVideoPath)
            return
        default:
            outputVideoPath = WatermarkUtilities.createWatermarkOutputPath(from: videoUrl)
        }

        let asset = AVAsset(url: videoUrl)
        let assetKeys = ["duration"]
        asset.loadValuesAsynchronously(forKeys: assetKeys) {
            var error : NSError? = nil
            switch asset.statusOfValue(forKey: assetKeys[0], error: &error){
            case .loaded:
                self.createWatermarkFromAssets(asset: asset, videoUrl: videoUrl, watermarkURL: watermarkUrl, outputUrl: outputVideoPath)
            case .failed,.cancelled:
                self.assetError.send(error)
                return
            default:
                break
            }
        }
    }
    
    private func createWatermarkFromAssets(asset : AVAsset , videoUrl : URL , watermarkURL : URL , outputUrl: URL){
        var currentTime : Double!
        var estimatedFinishTime : Double!
        let mixComposition = AVMutableComposition()
        let videoTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
        let timerange = CMTimeRangeMake(start: CMTime.zero, duration: asset.duration)
        
        let compositionVideoTrack:AVMutableCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid))!
        
        do {
            try compositionVideoTrack.insertTimeRange(timerange, of: videoTrack, at: CMTime.zero)
            compositionVideoTrack.preferredTransform = videoTrack.preferredTransform
        } catch {
            print(error)
        }
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            self.currentExportSession.send(nil)
            return
        }
        exportSession.estimateMaximumDuration { time, error in
            estimatedFinishTime = time.seconds
        }
        let watermarkFilter = CIFilter(name: "CISourceOverCompositing")!
        let tempWatermark = CIImage(contentsOf: watermarkURL)
        var watermarkImage : CIImage!
        
        let videoComposition = AVVideoComposition(asset: asset) { (filteringRequest) in
            currentTime = filteringRequest.compositionTime.seconds
            self.exportProgress.send(WatermarkUtilities.calculateProgress(currentTime: currentTime, estimatedTime: estimatedFinishTime))
            let source = filteringRequest.sourceImage.clampedToExtent()
            guard let imageSize = tempWatermark?.extent.size else {return}
            if imageSize != videoTrack.naturalSize{
                watermarkImage = ImageResizer.resizeImage(inputImage: watermarkURL, imageSize: videoTrack.naturalSize)
            }else{
                watermarkImage = tempWatermark
            }
            watermarkFilter.setValue(source, forKey: "inputBackgroundImage")
            watermarkFilter.setValue(watermarkImage, forKey: "inputImage")
            filteringRequest.finish(with: watermarkFilter.outputImage!, context: nil)
        }
        
        exportSession.timeRange = timerange
        exportSession.outputURL = outputUrl
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.videoComposition = videoComposition
        exportSession.exportAsynchronously { () -> Void in
            self.currentExportSession.send(exportSession)
            self.exportError.send(exportSession.error)
        }
    }
    
    public func addWatermarkToImage(mainImage: URL, watermarkImage: URL) {
        guard let mainCIImage = CIImage(contentsOf: mainImage) else {return}
        guard let watermarkCIimage = CIImage(contentsOf: watermarkImage) else {return}
        let backgroundImage = UIImage(ciImage: mainCIImage)
        let watermarkImage = UIImage(ciImage: watermarkCIimage)
        UIGraphicsBeginImageContextWithOptions(backgroundImage.size, false, 0.0)
        backgroundImage.draw(in: CGRect(x: 0.0, y: 0.0, width: backgroundImage.size.width, height: backgroundImage.size.height))
        watermarkImage.draw(in: CGRect(x: 0.0, y: 0.0, width: backgroundImage.size.width, height: backgroundImage.size.height))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.watermarkImage.send(result)
    }
    
    
    
    
}
