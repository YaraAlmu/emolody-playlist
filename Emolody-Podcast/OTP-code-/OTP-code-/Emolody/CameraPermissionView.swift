//
//  CameraPermissionView.swift
//  emolody2
//
//  Created by toleen alghamdi on 08/04/1447 AH.
//
import SwiftUI
import AVFoundation

struct CameraPermissionView: View {
    @ObservedObject var camera: CameraService
    var onSkip: () -> Void = {}        // ← جديد
    @State private var showError = false

    var body: some View {
        ZStack { AppScreenBackground()
            VStack(spacing: 28) {
                Spacer().frame(height: 36)

                ZStack {
                    Circle().fill(Brand.primary.opacity(0.18))
                        .frame(width: 160, height: 160)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(Brand.primary)
                }

                VStack(spacing: 10) {
                    Text("Camera Access")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Brand.textPrimary)

                    Text("To detect your mood and create the perfect playlist, we need access to your camera. No recordings will be saved.")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 16))
                        .foregroundStyle(Brand.textSecondary)
                        .padding(.horizontal, 28)
                        .lineSpacing(2)
                }

                Spacer()

                Button {
                    camera.requestAccess { ok in
                        if ok { camera.start() } else { showError = true }
                    }
                } label: {
                    Text("Allow Camera Access")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Brand.primary)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .shadow(color: Brand.primary.opacity(0.25), radius: 12, y: 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)

                // Not Now → يرجع للهوم
                Button("Not Now") { onSkip() }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Brand.textSecondary)
                    .padding(.bottom, 22)
            }
        }
        .alert("Camera access is required", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please enable camera access in Settings > Privacy > Camera.")
        }
        .onAppear {
            camera.isAuthorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        }
    }
}
