import DesignSystem
import SwiftUI

/// The app is for the owner and friends: a new device asks for access with a name and an email, the owner
/// approves it from the mail they get (the owner's Apps Script, private/apps-script/access.gs), and the
/// device, which alone holds the request's random id, opens. Once a device is in, it stays in.
/// Same contract as Android's `AccessGate`.
struct AccessGateView: View {
    @AppStorage("access.unlocked") private var unlocked = false
    @AppStorage("access.email") private var pendingEmail = ""
    @AppStorage("access.id") private var requestID = ""
    @AppStorage("access.requestedAt") private var requestedAt = 0.0
    @State private var name = ""
    @State private var email = ""
    @State private var busy = false
    @State private var error: String?
    @FocusState private var focused: Bool

    /// 24 h to approve + 24 h to pick it up; the script decides.
    private var pending: Bool { !requestID.isEmpty && Date.now.timeIntervalSince1970 - requestedAt < 48 * 3600 }
    private var validEmail: Bool { email.trimmingCharacters(in: .whitespaces).wholeMatch(of: /[^@\s]+@[^@\s]+\.[^@\s]+/) != nil }
    private var ready: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && validEmail && !busy }

    var body: some View {
        ZStack {
            Color.canvas.ignoresSafeArea()
            RadialGradient(gradient: Gradient(colors: [.brand.opacity(0.35), .clear]), center: .topLeading, startRadius: 0, endRadius: 600)
                .ignoresSafeArea()
            ScrollView {
                form
            }
            .scrollDismissesKeyboard(.interactively)
        }
        // While a request waits, ask every 10 s whether the owner approved it; the screen leaves on its own.
        .task(id: requestID) {
            while pending, !Task.isCancelled {
                await check()
                try? await Task.sleep(for: .seconds(10))
            }
        }
        .onAppear { focused = !pending }
    }

    private var form: some View {
        VStack(spacing: 14) {
            Wordmark(size: 34)
            Text(pending ? "Đang chờ duyệt…" : "App riêng tư").font(.title2.bold()).padding(.top, 8)
            Text(message).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            if !pending {
                TextField("Tên của bạn", text: $name)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.next)
                    .modifier(GateField())
                    .focused($focused)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.send)
                    .onSubmit { send() }
                    .modifier(GateField())
            }
            if let error { Text(error).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center) }
            if pending {
                ProgressView().padding(.top, 4)
                Button("Gửi lại yêu cầu") { requestID = ""; error = nil }
                    .font(.subheadline).foregroundStyle(.secondary).padding(.top, 4)
            } else {
                Button {
                    send()
                } label: {
                    Text(busy ? "Đang gửi…" : "Gửi yêu cầu")
                        .font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color.brand, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(PressableStyle())
                .disabled(!ready)
                .opacity(ready ? 1 : 0.5)
            }
        }
        .frame(maxWidth: 440)
        .padding(28)
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private var message: String {
        pending
            ? "Đã gửi yêu cầu. Chủ app duyệt xong là app tự mở, và bạn nhận mail báo ở \(pendingEmail)."
            : "TMovie chỉ dành cho bạn bè của chủ app. Gửi yêu cầu, chủ app duyệt là bạn vào được."
    }

    private func send() {
        guard ready else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        busy = true
        error = nil
        Task {
            let device = "\(UIDevice.current.model) iOS \(UIDevice.current.systemVersion)"
            let body = ["action": "request", "name": trimmedName, "email": trimmedEmail, "platform": "ios", "device": device]
            if let res = try? await Self.post(body), res["ok"] as? Bool == true, let id = res["id"] as? String {
                pendingEmail = trimmedEmail
                requestedAt = Date.now.timeIntervalSince1970
                requestID = id
            } else {
                error = "Không gửi được, kiểm tra mạng rồi thử lại nhé."
            }
            busy = false
        }
    }

    private func check() async {
        guard let res = try? await Self.post(["action": "status", "id": requestID]) else { return }
        if res["ok"] as? Bool == true {
            requestID = ""
            withAnimation(.cinematic) { unlocked = true }
        } else if res["pending"] as? Bool != true {
            requestID = ""
            error = "Yêu cầu đã hết hạn, gửi lại nhé."
        }
    }

    private static let endpoint = URL(string: "https://script.google.com/macros/s/AKfycbzM71C8tRgkWqKWYBpr97IcZCOkouZTTU55rWiU1n4g3MZHEq8dm9B9pHd6SC4kicSk-Q/exec")!

    /// Apps Script answers a POST with a redirect to the result, which URLSession follows.
    private static func post(_ body: [String: String]) async throws -> [String: Any] {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
}

private struct GateField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 18)
            .frame(minHeight: 54)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.white.opacity(0.18)))
    }
}
