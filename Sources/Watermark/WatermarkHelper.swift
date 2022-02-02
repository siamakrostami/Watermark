//
//  WatermarkHelper.swift
//  Watermark
//
//  Created by siamak rostami on 10/30/1400 AP.
//

import UIKit
import AssetsLibrary
import AVFoundation
import AVKit
import CoreImage
import Alamofire

public typealias DownloadProgressCompletion = ((DownloadModel?) -> Void)
public typealias WatermakrProgressCompletion = ((Double?) -> Void)
public typealias ExportSessionCompletion = ((AVAssetExportSession?) -> Void)
public typealias AlamofireDownloadProgress = ((Double? , URL? , Error?) -> Void)
public typealias WatermarkExistCompletion = ((URL?) -> Void)
public typealias DownloadErrorCompletion = ((Error?) -> Void)


open class WatermarkHelper{
    
    private var localImageURL : URL!
    public init(){}
    
    public func createWatermarkForVideoFrom(videoUrl : URL , imageUrl : URL ,imageDownloadProgress : @escaping DownloadProgressCompletion, videoDownloadProgress:@escaping DownloadProgressCompletion , watermarkProgress:@escaping WatermakrProgressCompletion , exportCompletion:@escaping ExportSessionCompletion , cachedWatermark:@escaping WatermarkExistCompletion , downloadError : @escaping DownloadErrorCompletion){
        
        //Download image
        self.downloadMedia(url: imageUrl) { [weak self] imageProgress, imageOutput, imageError in
            guard let `self` = self else {return}
            let imageModel = DownloadModel()
            imageModel.downloadTarget = .imageDownloading
            if imageError == nil{
                if imageOutput == nil{
                    imageModel.downloadStatus = .downloadInProgress
                    imageModel.downloadProgress = imageProgress
                    imageDownloadProgress(imageModel)
                }else{
                    imageDownloadProgress(nil)
                    guard let downloadedImage = imageOutput else {return}
                    self.localImageURL = downloadedImage
                    //Download video
                    self.downloadMedia(url: videoUrl) { videoProgress, videoOutput, videoError in
                        let videoModel = DownloadModel()
                        videoModel.downloadTarget = .videoDownloading
                        if videoError == nil{
                            if videoOutput == nil{
                                videoModel.downloadStatus = .downloadInProgress
                                videoModel.downloadProgress = videoProgress
                                videoDownloadProgress(videoModel)
                            }else{
                                videoDownloadProgress(nil)
                                guard let videoOutputURL = videoOutput else {return}
                                //Add watermark to video
                                self.addWatermarkToVideo(videoURL: videoOutputURL, imageUrl: self.localImageURL) { watermarkExportProgress in
                                    watermarkProgress(watermarkExportProgress)
                                } exportComletion: { exportSession in
                                    exportCompletion(exportSession)
                                } cachedWatermark: { cachedWatermarkURL in
                                    cachedWatermark(cachedWatermarkURL)
                                }
                            }
                        }else{
                            downloadError(videoError)
                        }
                    }
                }
            }else{
                downloadError(imageError)
            }
        }
        
    }
    
    private func addWatermarkToVideo(videoURL : URL , imageUrl : URL , watermarkProgress: @escaping WatermakrProgressCompletion , exportComletion:@escaping ExportSessionCompletion , cachedWatermark:@escaping WatermarkExistCompletion){
        let watermarkPath = self.fileLocationForWatermarkVideo(url: videoURL)
        var outputURL : URL!
        if self.isFileExist(at: watermarkPath){
            cachedWatermark(watermarkPath)
            return
        }else{
            outputURL = Utility.createWatermarkOutputPath(from: videoURL)
        }
        var currentTime : Double!
        var estimatedFinishTime : Double!
        let mixComposition = AVMutableComposition()
        let asset = AVAsset(url: videoURL)
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
            exportComletion(nil)
            return
        }
        exportSession.estimateMaximumDuration { time, error in
            estimatedFinishTime = time.seconds
        }
        let watermarkFilter = CIFilter(name: "CISourceOverCompositing")!
        let tempWatermark = CIImage(contentsOf: imageUrl)
        var watermarkImage : CIImage!
        
        let videoComposition = AVVideoComposition(asset: asset) { (filteringRequest) in
            currentTime = filteringRequest.compositionTime.seconds
            watermarkProgress(self.calculateProgress(currentTime: currentTime, estimatedTime: estimatedFinishTime))
            let source = filteringRequest.sourceImage.clampedToExtent()
            guard let imageSize = tempWatermark?.extent.size else {return}
            if imageSize != videoTrack.naturalSize{
                watermarkImage = self.resizeImage(inputImage: imageUrl, imageSize: videoTrack.naturalSize)
            }else{
                watermarkImage = tempWatermark
            }
            watermarkFilter.setValue(source, forKey: "inputBackgroundImage")
            watermarkFilter.setValue(watermarkImage, forKey: "inputImage")
            filteringRequest.finish(with: watermarkFilter.outputImage!, context: nil)
        }
        
        exportSession.timeRange = timerange
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.videoComposition = videoComposition
        exportSession.exportAsynchronously { () -> Void in
            exportComletion(exportSession)
        }
        
        
    }
}

extension WatermarkHelper{
    
    private func downloadMedia(url : URL , completion: @escaping AlamofireDownloadProgress){
        let destination: DownloadRequest.Destination = { _, _ in
            let documentsURL = Utility.createTemporaryOutputPath(from: url)
            return (documentsURL, [.removePreviousFile])
        }
        AF.request(url).validate().response { response in
            switch response.result{
            case .failure(let error):
                completion(nil,nil,error)
            default:
                AF.download(url, interceptor: nil, to: destination)
                    .downloadProgress { progress in
                        completion(progress.fractionCompleted,nil,nil)
                    }
                    .validate()
                    .response { response in
                        switch response.result{
                        case .success(let urls):
                            completion(nil,urls,nil)
                        case .failure(let error):
                            completion(nil,nil,error)
                        }
                    }
            }
        }
    }
    
    private func isFileExist(at url : URL) -> Bool{
        let dirPaths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let filePath = dirPaths[0].appendingPathComponent(url.lastPathComponent)
        if FileManager.default.fileExists(atPath: filePath.path){
            return true
        }
        return false
    }
    
    private func fileLocationForOriginalVideo(url : URL) -> URL{
        let dirPaths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let filePath = dirPaths[0].appendingPathComponent(url.lastPathComponent)
        return filePath
    }
    private func fileLocationForWatermarkVideo(url : URL) -> URL{
        let dirPaths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let filePath = dirPaths[0].appendingPathComponent("Watermarked-\(url.lastPathComponent)")
        return filePath
    }
    
    private func calculateProgress(currentTime : Double? , estimatedTime : Double?) -> Double?{
        guard let currentTime = currentTime , let estimatedTime = estimatedTime else {
            return nil
        }
        guard estimatedTime > 0 , currentTime > 0 else {return nil}
        let progress = currentTime/estimatedTime
        return progress
    }
    
    
    private func resizeImage(inputImage : URL , imageSize : CGSize) -> CIImage?{
        let sourceImage = CIImage(contentsOf: inputImage, options: nil)
        let resizeFilter = CIFilter(name:"CILanczosScaleTransform")!
        let targetSize = imageSize
        let scale = targetSize.height / (sourceImage?.extent.height)!
        let aspectRatio = targetSize.width/((sourceImage?.extent.width)! * scale)
        resizeFilter.setValue(sourceImage, forKey: kCIInputImageKey)
        resizeFilter.setValue(scale, forKey: kCIInputScaleKey)
        resizeFilter.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)
        let outputImage = resizeFilter.outputImage
        return outputImage
    }
}
