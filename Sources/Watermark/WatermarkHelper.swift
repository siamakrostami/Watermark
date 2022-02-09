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
public typealias WatermarkImagesCompletion = ((URL? , UIImage?) -> Void)


open class WatermarkHelper{
    
    private var localImageURL : URL!
    private var localVideoURL : URL!
    public init(){}
    
    public func addWatermarkToImage(mainImage : URL,mainImageDownloadProgress : @escaping DownloadProgressCompletion,downloadError : @escaping DownloadErrorCompletion,cachedWatermark:@escaping WatermarkExistCompletion){
        let temp = self.fileLocationForWatermarkVideo(url: mainImage)
        if self.isFileExist(at: temp){
            cachedWatermark(temp)
            return
        }
        self.downloadMediaFile(url: mainImage, target: .backgroundMainImageDownloading) { download in
            mainImageDownloadProgress(download)
            if download?.downloadStatus == .cached{
                guard let downloadURL = download?.downloadedURL else {return}
                cachedWatermark(downloadURL)
            }
        } downloadError: { error in
            downloadError(error)
        }

    }
    
    public func createWatermarkForVideoFrom(videoUrl : URL , imageUrl : URL ,imageDownloadProgress : @escaping DownloadProgressCompletion, videoDownloadProgress:@escaping DownloadProgressCompletion , watermarkProgress:@escaping WatermakrProgressCompletion , exportCompletion:@escaping ExportSessionCompletion , cachedWatermark:@escaping WatermarkExistCompletion , downloadError : @escaping DownloadErrorCompletion){
        
        switch imageUrl.isLocal(){
        case true:
            let tempPath = Utility.createTemporaryOutputPath(from: imageUrl)
            switch self.isFileExist(at:tempPath){
            case true:
                self.localImageURL = tempPath
            default:
                let imageData = try? Data(contentsOf: imageUrl)
                try? imageData?.write(to: tempPath)
                self.localImageURL = tempPath
                imageDownloadProgress(nil)
                switch self.isFileExist(at: videoUrl){
                case true:
                    videoDownloadProgress(nil)
                    self.localVideoURL = fileLocationForOriginalVideo(url: videoUrl)
                    self.addWatermarkToVideo(videoURL: self.localVideoURL, imageUrl: self.localImageURL) { watermark in
                        watermarkProgress(watermark)
                    } exportComletion: { exportSession in
                        exportCompletion(exportSession)
                    } cachedWatermark: { cached in
                        cachedWatermark(cached)
                    }
                    
                default:
                    self.downloadMediaFile(url: videoUrl, target: .videoDownloading) { [weak self] videoProgress in
                        guard let `self` = self else {return}
                        videoDownloadProgress(videoProgress)
                        if videoProgress?.downloadStatus == .cached{
                            self.addWatermarkToVideo(videoURL: self.localVideoURL, imageUrl: self.localImageURL) { watermark in
                                watermarkProgress(watermark)
                            } exportComletion: { exportSession in
                                exportCompletion(exportSession)
                            } cachedWatermark: { cached in
                                cachedWatermark(cached)
                            }
                        }
                        
                    } downloadError: { videoError in
                        downloadError(videoError)
                    }
                    
                }
            }
        default:
            switch self.isFileExist(at: imageUrl){
            case true:
                self.localImageURL = self.fileLocationForOriginalVideo(url: imageUrl)
                switch self.isFileExist(at: videoUrl){
                case true:
                    videoDownloadProgress(nil)
                    self.localVideoURL = self.fileLocationForOriginalVideo(url: videoUrl)
                    self.addWatermarkToVideo(videoURL: self.localVideoURL, imageUrl: self.localImageURL) { watermark in
                        watermarkProgress(watermark)
                    } exportComletion: { exportSession in
                        exportCompletion(exportSession)
                    } cachedWatermark: { cached in
                        cachedWatermark(cached)
                    }
                default:
                    self.downloadMediaFile(url: videoUrl, target: .videoDownloading) { [weak self] videoProgress in
                        guard let `self` = self else {return}
                        videoDownloadProgress(videoProgress)
                        if videoProgress?.downloadStatus == .cached{
                            self.addWatermarkToVideo(videoURL: self.localVideoURL, imageUrl: self.localImageURL) { watermark in
                                watermarkProgress(watermark)
                            } exportComletion: { exportSession in
                                exportCompletion(exportSession)
                            } cachedWatermark: { cached in
                                cachedWatermark(cached)
                            }
                        }
                        
                    } downloadError: { videoError in
                        downloadError(videoError)
                    }
                }
            default:
                self.downloadMediaFile(url: imageUrl, target: .imageDownloading) { [weak self] imageDownload in
                    guard let `self` = self else {return}
                    imageDownloadProgress(imageDownload)
                    if imageDownload?.downloadStatus == .cached{
                        switch self.isFileExist(at: videoUrl){
                        case true:
                            videoDownloadProgress(nil)
                            self.addWatermarkToVideo(videoURL: self.localVideoURL, imageUrl: self.localImageURL) { watermark in
                                watermarkProgress(watermark)
                            } exportComletion: { exportSession in
                                exportCompletion(exportSession)
                            } cachedWatermark: { cached in
                                cachedWatermark(cached)
                            }
                        default:
                            self.downloadMediaFile(url: videoUrl, target: .videoDownloading) { [weak self] videoProgress in
                                guard let `self` = self else {return}
                                videoDownloadProgress(videoProgress)
                                if videoProgress?.downloadStatus == .cached{
                                    self.addWatermarkToVideo(videoURL: self.localVideoURL, imageUrl: self.localImageURL) { watermark in
                                        watermarkProgress(watermark)
                                    } exportComletion: { exportSession in
                                        exportCompletion(exportSession)
                                    } cachedWatermark: { cached in
                                        cachedWatermark(cached)
                                    }
                                }
                                
                                
                            } downloadError: { videoError in
                                downloadError(videoError)
                            }
                        }
                    }
                    
                } downloadError: { imageError in
                    downloadError(imageError)
                }
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
    
    private func downloadMediaFile(url : URL ,target :DownloadCaes ,completion:@escaping DownloadProgressCompletion , downloadError:@escaping DownloadErrorCompletion){
        self.downloadMedia(url: url) { [weak self] mediaProgress, mediaURL, mediaError in
            guard let `self` = self else {
                completion(nil)
                return
            }
            let mediaModel = DownloadModel()
            mediaModel.downloadTarget = target
            if mediaError == nil{
                if mediaURL == nil{
                    mediaModel.downloadStatus = .downloadInProgress
                    mediaModel.downloadProgress = mediaProgress
                    completion(mediaModel)
                }else{
                    guard let downloadedMedia = mediaURL else {return}
                    mediaModel.downloadedURL = downloadedMedia
                    switch target{
                    case .videoDownloading:
                        self.localVideoURL = downloadedMedia
                    default:
                        self.localImageURL = downloadedMedia
                    }
                    mediaModel.downloadStatus = .cached
                    completion(mediaModel)
                }
            }else{
                downloadError(mediaError)
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
