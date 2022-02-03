//
//  File.swift
//  
//
//  Created by siamak rostami on 11/14/1400 AP.
//

import Foundation
import CoreImage

class ImageResizer{
    class func resizeImage(inputImage : URL , imageSize : CGSize) -> CIImage?{
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

