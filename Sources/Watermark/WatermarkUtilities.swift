//
//  File.swift
//  
//
//  Created by siamak rostami on 11/14/1400 AP.
//

import Foundation

class WatermarkUtilities{
    
    class func createTemporaryOutputPath(from url : URL) -> URL{
        let fileMgr = FileManager.default
        let dirPaths = fileMgr.urls(for: .documentDirectory, in: .userDomainMask)
        let filePath = dirPaths[0].appendingPathComponent(url.lastPathComponent)
        WatermarkUtilities.checkFileExistance(in: filePath)
        return filePath
    }
    
    class func createWatermarkOutputPath(from url : URL) -> URL{
        let fileMgr = FileManager.default
        let dirPaths = fileMgr.urls(for: .documentDirectory, in: .userDomainMask)
        let filePath = dirPaths[0].appendingPathComponent("Watermarked-\(url.lastPathComponent)")
        WatermarkUtilities.checkFileExistance(in: filePath)
        return filePath
    }
    
    fileprivate class func checkFileExistance(in url : URL){
        if FileManager.default.fileExists(atPath: url.path){
            do{
                try FileManager.default.removeItem(at: url)
            }catch{
                debugPrint(error.localizedDescription)
            }
        }else{
            debugPrint("file doesn't exist")
        }
    }
    
    class func isFileExist(at url : URL) -> Bool{
        let dirPaths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let filePath = dirPaths[0].appendingPathComponent(url.lastPathComponent)
        if FileManager.default.fileExists(atPath: filePath.path){
            return true
        }
        return false
    }
    
    class func isWatermarkedVideoExist(videoUrl : URL) -> Bool{
        if FileManager.default.fileExists(atPath: videoUrl.path){
            return true
        }
        return false
    }
    
    class func fileLocationForOriginalVideo(url : URL) -> URL{
        let dirPaths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let filePath = dirPaths[0].appendingPathComponent(url.lastPathComponent)
        return filePath
    }
    class func fileLocationForWatermarkVideo(url : URL) -> URL{
        let dirPaths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let filePath = dirPaths[0].appendingPathComponent("Watermarked-\(url.lastPathComponent)")
        return filePath
    }
    
    class func calculateProgress(currentTime : Double? , estimatedTime : Double?) -> Double?{
        guard let currentTime = currentTime , let estimatedTime = estimatedTime else {
            return nil
        }
        guard estimatedTime > 0 , currentTime > 0 else {return nil}
        let progress = currentTime/estimatedTime
        return progress
    }
    
    class func isWatermarkedCacheAvailable(videoUrl: URL) -> Bool{
        let watermarkUrl = WatermarkUtilities.fileLocationForWatermarkVideo(url: videoUrl)
        return WatermarkUtilities.isWatermarkedVideoExist(videoUrl: watermarkUrl)
    }
    
    
    
    
    
}
