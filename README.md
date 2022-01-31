
# Watermark

Creates watermark frame for your video


## Installation

Install Watermark with SPM

    
## Usage/Examples

```swift
import Watermark

fileprivate var watermark = WatermarkHandler()

 watermark.createWatermarkForVideoFrom(videoUrl: URL, imageUrl: URL) { downloadProgress in

    // Show download Progress
            
    } watermarkProgress: { watermarkProgress in

    // Show Watermark Progress
            
    } exportCompletion: { exportSession in

    // Do sth with export status
            
    } cachedWatermark: { cachedWatermark in

     // Do sth with cached watermark status
            
    }

```

