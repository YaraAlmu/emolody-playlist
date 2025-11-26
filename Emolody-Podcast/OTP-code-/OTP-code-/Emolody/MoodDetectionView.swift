//
//  MoodDetectionView.swift
//  emolody2
//
//  Created by toleen alghamdi on 08/04/1447 AH.
import SwiftUI
import AVFoundation

struct MoodDetectionView: View {
    @ObservedObject var camera: CameraService
    var onDone: () -> Void = {}

    var body: some View {
        ZStack {
            AppScreenBackground()

            VStack(alignment: .leading, spacing: 18) {
                Text("Mood Detection")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Brand.textPrimary)

                Text("Analyzing your mood...")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Brand.primary.opacity(0.9))

                ZStack {
                    RoundedRectangle(cornerRadius: 26)
                        .fill(.white.opacity(0.15))

                    CameraPreviewView(session: camera.session)
                        .clipShape(RoundedRectangle(cornerRadius: 26))

                    Circle()
                        .stroke(Brand.primary.opacity(0.45), lineWidth: 8)
                        .frame(width: 270, height: 270)
                }
                .frame(height: 360)

                Text(camera.moodText)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Brand.textPrimary)

                ProgressBar(progress: camera.moodProgress,
                            fill: Brand.primary,
                            track: .gray.opacity(0.25))
                    .frame(height: 10)

                Spacer()

                Button("Continue") {
                    onDone()
                }
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Brand.primary)
                .foregroundStyle(.white)
                .clipShape(Capsule())

                Button("Skip Detection") { onDone() }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.gray)
                    .padding(.bottom, 18)
            }
            .padding(.horizontal, 24)
        }
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
    }
}

// Progress bar
private struct ProgressBar: View {
    var progress: CGFloat
    var fill: Color
    var track: Color

    var body: some View {
        GeometryReader { geo in
            let w = max(0, min(1, progress)) * geo.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule().frame(width: w).foregroundStyle(fill)
            }
        }
    }
}
