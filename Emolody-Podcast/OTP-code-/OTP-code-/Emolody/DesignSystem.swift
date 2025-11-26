//
//  DesignSystem.swift
//  emolody2
import SwiftUI

// ثابت: ثيم فاتح فقط (لا Dark Mode)
enum Brand {
    static let primary       = Color(red: 0.53, green: 0.40, blue: 0.96)
    static let bg1           = Color(red: 0.97, green: 0.95, blue: 0.99)
    static let bg2           = Color(red: 0.95, green: 0.92, blue: 0.99)
    static let textPrimary   = Color.black
    static let textSecondary = Color.black.opacity(0.6)
    static let card          = Color.white
    static let shadow        = Color.black.opacity(0.06)
    static let border        = Color.black.opacity(0.08)
}

// ✅ أسماء جديدة لتفادي أي تصادم مع تعريفات سابقة
struct AppScreenBackground: View {
    var body: some View {
        LinearGradient(colors: [Brand.bg1, Brand.bg2],
                       startPoint: .top, endPoint: .bottom)
        .ignoresSafeArea()
    }
}

// ViewModifier بدل الامتداد لتفادي غموض الدوال
struct AppCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Brand.card)
            .cornerRadius(16)
            .shadow(color: Brand.shadow, radius: 6, y: 3)
    }
}

// اختصار آمن غير متعارض
extension View {
    func appCard() -> some View { self.modifier(AppCardStyle()) }
}

// حاوية بطاقة اختيارية لو تحبين تستخدميها بدل الـ modifier
struct AppCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View { content.modifier(AppCardStyle()) }
}
