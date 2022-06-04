//
//  MLModel.swift
//  Becasso_NC2
//
//  Created by Simone Giordano on 09/12/21.
//

import Foundation
import CoreML
import CoreImage
import UIKit
import SwiftUI
import VideoToolbox
extension UIImage {
    
    func resizeImageTo(size: CGSize) -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: CGPoint.zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return resizedImage
    }
}

func predict(raw_image: UIImage) -> UIImage {
    
    let numStyles  = 1
    let styleIndex = 0
    
    let styleArray = try? MLMultiArray(shape: [numStyles] as [NSNumber], dataType: MLMultiArrayDataType.double)
    
    for i in 0...((styleArray?.count)!-1) {
        styleArray?[i] = 0.0
    }
    styleArray?[styleIndex] = 1.0
    
    
    
    
    // initialize model
    let model = StyleTransfer_VanGogh()
    
    // set input size of the model
    let modelInputSize = CGSize(width: 512, height: 512)
    
    // create a cvpixel buffer
    var pixelBuffer: CVPixelBuffer?
    let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
         kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
    CVPixelBufferCreate(kCFAllocatorDefault,
                        Int(modelInputSize.width),
                        Int(modelInputSize.height),
                        kCVPixelFormatType_32BGRA,
                        attrs,
                        &pixelBuffer)
    
    // put bytes into pixelBuffer
    let context = CIContext()

    let uiimage = raw_image.resizeImageTo(size: CGSize(width: 170.6, height:170.6))!
   
    let ciimage = CIImage(image: uiimage)
    context.render(ciimage!, to: pixelBuffer!)
    var cgImage: CGImage?
    //VTCreateCGImageFromCVPixelBuffer(pixelBuffer!, options: ., imageOut: &cgImage)
    //return UIImage(cgImage: cgImage!)
    
    // predict image
    do {
        let output = try model.prediction(image: pixelBuffer!)
        VTCreateCGImageFromCVPixelBuffer(output.stylizedImage, options: attrs, imageOut: &cgImage)
    }
    catch {
        
    }
    
    
    
    return UIImage(cgImage: cgImage!)
  
}


