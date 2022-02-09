//
//  DownloadModel.swift
//  Watermark
//
//  Created by siamak rostami on 11/1/1400 AP.
//

import Foundation

public enum DownloadCaes : String{
    case
    imageDownloading = "Fetching Watermark",
    videoDownloading = "Downloading Video",
    backgroundMainImageDownloading = "Downloading Image"
}

open class DownloadModel{
    open var downloadStatus : DownloadStatus?
    open var downloadProgress : Double?
    open var downloadTarget : DownloadCaes!
    var downloadedURL : URL!
    public init(){}
}
