//
//  ScreenBackground.swift
//  Emolody
//
//  Created by toleen alghamdi on 23/04/1447 AH.
//

import SwiftUI

/// الخلفية تتكيّف مع الوضعين Light/Dark
struct ScreenBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Group {
            if scheme == .dark {
                Color(.systemBackground) // الخلفية في الداكن
            } else {
                LinearGradient(
                    colors: [
                        Brand.bg1, // تدرّج فاتح في الوضع الفاتح
                        Brand.bg2  // تدرّج داكن قليلًا
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }
        }
        .ignoresSafeArea()
    }
}
