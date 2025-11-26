//
//  CameraPreviewView.swift
//  emolody2
//
//  Created by toleen alghamdi on 07/04/1447 AH.
//
import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> Preview {
        let v = Preview()
        v.backgroundColor = .clear
        v.videoPreviewLayer.session = session
        v.videoPreviewLayer.videoGravity = .resizeAspectFill
        return v
    }

    func updateUIView(_ uiView: Preview, context: Context) {
        uiView.videoPreviewLayer.session = session
    }

    final class Preview: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
