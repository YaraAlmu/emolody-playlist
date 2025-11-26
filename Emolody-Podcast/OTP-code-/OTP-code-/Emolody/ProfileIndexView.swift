//
//  ProfileIndexView.swift
//  Emolody
//
//  Created by toleen alghamdi on 14/04/1447 AH.
//
import SwiftUI

struct ProfileIndexView: View {
    var openProfile: () -> Void
    var body: some View {
        ZStack {
            AppScreenBackground()
            VStack(spacing: 16) {
                Text("Profile")
                    .font(.title2.bold())
                    .foregroundStyle(Brand.textPrimary)

                Button("Open Profile") {
                    openProfile()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Brand.primary)
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .shadow(color: Brand.primary.opacity(0.25), radius: 10, y: 6)

                Spacer()
            }
            .padding()
        }
    }
}
