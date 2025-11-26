import SwiftUI

/// شاشة التحقق من كود OTP باستخدام Twilio عبر OTPAPI
struct VerifyCodeView: View {
    let phone: String
    var onVerified: () -> Void

    @State private var code = ""
    @State private var verifying = false
    @State private var errorMsg: String?
    @State private var success = false

    // Resend timer
    @State private var seconds = 60
    @State private var canResend = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter the code sent to")
                .foregroundStyle(.secondary)

            Text(phone)
                .font(.headline)

            // حقل إدخال الكود
            TextField("6-digit code", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)   // AutoFill من SMS
                .multilineTextAlignment(.center)
                .font(.system(.title2, design: .monospaced))
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .onChange(of: code) { new in
                    code = String(new.filter(\.isNumber).prefix(6))
                    errorMsg = nil
                }

            // زر التحقق
            Button {
                Task { await verify() }
            } label: {
                ZStack {
                    Text("Verify").bold().opacity(verifying ? 0 : 1)
                    if verifying { ProgressView().tint(.white) }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(code.count == 6 ? Brand.primary : Brand.primary.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(code.count != 6 || verifying)

            // عرض الأخطاء
            if let e = errorMsg {
                Text(e)
                    .foregroundColor(.red)
                    .font(.footnote)
            }

            // عرض النجاح
            if success {
                Text("✅ Verified successfully!")
                    .foregroundColor(.green)
            }

            // زر الإعادة (Resend)
            if canResend {
                Button("Resend Code") {
                    Task { await resend() }
                }
                .foregroundColor(Brand.primary)
            } else {
                Text("Resend available in \(seconds)s")
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Verify Code")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startTimer() }
    }

    // MARK: - التحقق من الكود
    private func verify() async {
        errorMsg = nil
        verifying = true
        defer { verifying = false }

        do {
            let ok = try await OTPAPI.VerifyNumberView(phone: phone, code: code)

            if ok {
                success = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onVerified()
                }
            } else {
                errorMsg = "Incorrect code. Please try again."
            }

        } catch {
            errorMsg = error.localizedDescription
        }
    }

    // MARK: - إعادة الإرسال
    private func resend() async {
        do {
            let sent = try await OTPAPI.start(phone: phone)
            if sent {
                seconds = 60
                canResend = false
                startTimer()
            }
        } catch {
            errorMsg = error.localizedDescription
        }
    }

    // MARK: - المؤقّت
    private func startTimer() {
        canResend = false
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if seconds > 0 {
                seconds -= 1
            } else {
                timer.invalidate()
                canResend = true
            }
        }
    }
}
