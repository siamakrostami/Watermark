//
//  Utility.swift
//  Watermark
//
//  Created by siamak rostami on 10/30/1400 AP.
//

import Foundation
import AVKit


 class Utility{
    
     class func isImageExist(at url : URL) -> Bool{
        let dirPaths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let filePath = dirPaths[0].appendingPathComponent(url.lastPathComponent)
        if FileManager.default.fileExists(atPath: filePath.path){
            return true
        }
        return false
    }
    
    class func fileLocationForImage(url : URL) -> URL{
        let dirPaths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let filePath = dirPaths[0].appendingPathComponent(url.lastPathComponent)
        return filePath
    }
    
    
    
    class func createTemporaryOutputPath(from url : URL) -> URL{
        let fileMgr = FileManager.default
        let dirPaths = fileMgr.urls(for: .documentDirectory, in: .userDomainMask)
        let filePath = dirPaths[0].appendingPathComponent(url.lastPathComponent)
        Utility.checkFileExistance(in: filePath)
        return filePath
    }
    class func createWatermarkOutputPath(from url : URL) -> URL{
        let fileMgr = FileManager.default
        let dirPaths = fileMgr.urls(for: .documentDirectory, in: .userDomainMask)
        let filePath = dirPaths[0].appendingPathComponent("Watermarked-\(url.lastPathComponent)")
        Utility.checkFileExistance(in: filePath)
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
}
