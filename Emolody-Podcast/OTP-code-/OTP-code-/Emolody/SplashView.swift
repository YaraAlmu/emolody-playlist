import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void   // ← مهم

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let titleSize = max(44, width * 0.13)
            let noteSize  = titleSize * 0.55
            let subtitleSize = max(14, width * 0.035)

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 240/255, green: 231/255, blue: 1.00),
                        Color(red: 234/255, green: 216/255, blue: 1.00)
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    Spacer(minLength: geo.size.height * 0.22)

                    HStack(alignment: .bottom, spacing: 6) {
                        Text("Emo")
                            .font(.system(size: titleSize, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 155/255, green: 123/255, blue: 1.0))

                        Text("lody")
                            .font(.system(size: titleSize, weight: .black, design: .rounded))
                            .foregroundColor(.black)

                        Image(systemName: "music.note")
                            .font(.system(size: noteSize, weight: .regular))
                            .baselineOffset(-noteSize * 0.12)
                            .foregroundStyle(Color(red: 155/255, green: 123/255, blue: 1.0))
                            .opacity(0.95)
                    }
                    .fixedSize()
                    .padding(.horizontal)

                    Text("Feel your mood. Hear your world.")
                        .font(.system(size: subtitleSize, weight: .regular, design: .rounded))
                        .foregroundColor(Color(.sRGB, red: 0.28, green: 0.28, blue: 0.28, opacity: 1))

                    Spacer()
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                onFinished() // ← يرجّع التحكم لـ EmolodyApp
            }
        }
    }
}
