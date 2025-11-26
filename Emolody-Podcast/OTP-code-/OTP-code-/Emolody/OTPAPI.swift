import Foundation

struct OTPAPI {
    // 🔥 Use your ngrok URL
    static let baseURL = "https://arnita-headstrong-deliverly.ngrok-free.dev"

    // ================================
    // 1) Send OTP - FIXED VERSION
    // ================================
    static func start(phone: String) async throws -> Bool {
        let url = URL(string: "\(baseURL)/send-otp")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30  // Add timeout

        let body = ["phone": phone]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check HTTP status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "OTPAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
        }
        
        print("Send OTP - Status Code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let responseString = String(data: data, encoding: .utf8) ?? "No response"
            print("Server Error: \(responseString)")
            throw NSError(domain: "OTPAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        print("Send OTP Response: \(json ?? [:])")
        
        // Check for both possible response formats
        if let status = json?["status"] as? String {
            return status == "pending"
        } else if let success = json?["success"] as? Bool {
            return success
        }
        
        throw NSError(domain: "OTPAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
    }

    // ================================
    // 2) Verify OTP - FIXED VERSION
    // ================================
    static func VerifyNumberView(phone: String, code: String) async throws -> Bool {
        let url = URL(string: "\(baseURL)/verify-otp")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body = ["phone": phone, "code": code]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check HTTP status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "OTPAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
        }
        
        print("Verify OTP - Status Code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let responseString = String(data: data, encoding: .utf8) ?? "No response"
            print("Server Error: \(responseString)")
            throw NSError(domain: "OTPAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        print("Verify OTP Response: \(json ?? [:])")
        
        return (json?["success"] as? Bool) == true
    }
}
