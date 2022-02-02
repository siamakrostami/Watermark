//
//  File.swift
//  
//
//  Created by siamak rostami on 11/13/1400 AP.
//

import Foundation

extension URL{
    public func isLocal() -> Bool{
        if self.absoluteString.contains("http://") || self.absoluteString.contains("https://"){
            return false
        }
        return true
    }
}
