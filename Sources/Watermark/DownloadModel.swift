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
    videoDownloading = "Downloading Video"
}

open class DownloadModel{
    open var downloadStatus : DownloadStatus?
    open var downloadProgress : Double?
    open var downloadTarget : DownloadCaes!
    public init(){}
}
