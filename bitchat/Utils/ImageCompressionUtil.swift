//
// ImageCompressionUtil.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct ImageCompressionUtil {
    // Maximum dimensions for transmitted images
    static let maxImageDimension: CGFloat = 800
    
    // Maximum file size in bytes (500KB)
    static let maxImageSize: Int = 500 * 1024
    
    // Compress image to reasonable size for transmission
    static func compressImage(_ image: UIImage) -> Data? {
        // First resize if needed
        let resizedImage = resizeImage(image, maxDimension: maxImageDimension)
        
        // Start with high quality and reduce until size is acceptable
        var compressionQuality: CGFloat = 0.8
        var imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
        
        // Reduce quality until we're under the max size
        while let data = imageData, data.count > maxImageSize && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
        }
        
        return imageData
    }
    
    // Resize image maintaining aspect ratio
    private static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        
        // Check if resize is needed
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let aspectRatio = size.width / size.height
        var newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        #if os(iOS)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return resizedImage
        #else
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        image.draw(in: CGRect(origin: .zero, size: newSize))
        resizedImage.unlockFocus()
        return resizedImage
        #endif
    }
    
    // Create thumbnail for preview
    static func createThumbnail(_ image: UIImage, maxDimension: CGFloat = 100) -> UIImage {
        return resizeImage(image, maxDimension: maxDimension)
    }
    
    // Encode image data with wrapper tags
    static func encodeImageMessage(_ imageData: Data) -> String {
        let base64String = imageData.base64EncodedString()
        return "<image>\(base64String)</image>"
    }
    
    // Decode image from message content
    static func decodeImageMessage(_ content: String) -> Data? {
        // Look for image tags
        let pattern = "<image>(.*?)</image>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]),
              let match = regex.firstMatch(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count)),
              let range = Range(match.range(at: 1), in: content) else {
            return nil
        }
        
        let base64String = String(content[range])
        return Data(base64Encoded: base64String)
    }
    
    // Check if content contains an image
    static func containsImage(_ content: String) -> Bool {
        return content.contains("<image>") && content.contains("</image>")
    }
}