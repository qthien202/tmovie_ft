import AVKit
import DesignSystem
import Models
import SwiftUI

/// Everything drawn over the video.
struct PlayerControls: View {
    let model: PlayerModel
    var close: () -> Void

    var body: some View {
        ZStack {
            if model.controlsVisible, !model.locked {
                LinearGradient(stops: [.init(color: .black.opacity(0.7), location: 0), .init(color: .clear, location: 0.25),
                                       .init(color: .clear, location: 0.7), .init(color: .black.opacity(0.8), location: 1)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            if model.buffering, !model.failed {
                ProgressView().controlSize(.large).tint(.white).allowsHitTesting(false)
            }

            if model.locked {
                if model.controlsVisible {
                    HStack {
                        RoundButton(icon: "lock.fill", label: "Mở khoá", size: 56) { model.locked = false; model.interact() }
                        Spacer()
                    }
                    .padding(.leading, 32)
                    .transition(.opacity)
                }
            } else {
                VStack(spacing: 0) {
                    if model.controlsVisible { topBar.transition(.move(edge: .top).combined(with: .opacity)) }
                    Spacer()
                    if model.controlsVisible { bottomBar.transition(.move(edge: .bottom).combined(with: .opacity)) }
                }
                if model.controlsVisible, !model.failed { centerTransport.transition(.scale(scale: 0.9).combined(with: .opacity)) }
                if model.failed, !model.offline { errorCard }
                cornerCards
            }

            if model.offline { offlineBanner }

            if model.panel != .none {
                HStack {
                    Spacer()
                    Group {
                        if model.panel == .settings { SettingsPanel(model: model) } else { EpisodePanel(model: model) }
                    }
                    .frame(width: 400)
                    .frame(maxHeight: .infinity)
                    .background(Color(white: 0.04).opacity(0.95))
                }
                .ignoresSafeArea()
                .transition(.move(edge: .trailing))
            }
        }
    }

    // MARK: Bars

    private var topBar: some View {
        HStack(spacing: 4) {
            IconButton(icon: "xmark", label: "Đóng", action: close)
            Spacer()
            if model.canShowDetail {
                IconButton(icon: "info.circle", label: "Thông tin phim") {
                    close()
                    Player.showDetail?(model.film)
                }
            }
            if model.pip != nil {
                IconButton(icon: "pip.enter", label: "Hình trong hình") { model.pip?.startPictureInPicture() }
            }
            AirPlayButton().frame(width: 44, height: 44)
        }
        .overlay {
            VStack(spacing: 2) {
                Text(model.film.name).font(.headline)
                Text([model.episode?.name, sleepLabel].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.subheadline).foregroundStyle(.white.opacity(0.7))
            }
            .lineLimit(1)
            .padding(.horizontal, 120)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var centerTransport: some View {
        HStack(spacing: 72) {
            IconButton(icon: "gobackward.10", label: "Lùi 10 giây", size: 64, weight: .regular) { model.seek(by: -10) }
            Button { model.toggle() } label: {
                Image(systemName: model.ended ? "arrow.counterclockwise" : model.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 96, height: 96)
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(model.isPlaying ? "Tạm dừng" : "Phát")
            IconButton(icon: "goforward.10", label: "Tới 10 giây", size: 64, weight: .regular) { model.seek(by: 10) }
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.35), radius: 12)
    }

    private var bottomBar: some View {
        VStack(spacing: 6) {
            HStack(spacing: 14) {
                Text(formatTime(model.position)).font(.footnote.monospacedDigit())
                SeekBar(model: model)
                Text("−" + formatTime(max(0, model.duration - model.position))).font(.footnote.monospacedDigit())
            }
            HStack(spacing: 36) {
                Menu {
                    Picker("Tốc độ", selection: Binding(get: { model.speed }, set: { model.setSpeed($0) })) {
                        ForEach([Float(0.5), 0.75, 1, 1.25, 1.5, 2], id: \.self) { Text(speedLabel($0)).tag($0) }
                    }
                } label: {
                    ActionLabel(icon: "gauge.with.dots.needle.67percent", title: "Tốc độ (\(model.speed == 1 ? "1×" : speedLabel(model.speed)))")
                }
                Button { model.locked = true; model.interact() } label: { ActionLabel(icon: "lock.open", title: "Khoá") }
                if model.hasEpisodeList {
                    Button { model.panel = .episodes; model.interact() } label: { ActionLabel(icon: "rectangle.stack", title: "Tập") }
                }
                Button { model.panel = .settings; model.interact() } label: { ActionLabel(icon: "captions.bubble", title: "Phụ đề & cài đặt") }
                if model.nextIndex != nil {
                    Button { model.playNext() } label: { ActionLabel(icon: "forward.end", title: "Tập tiếp") }
                }
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 24)
        .padding(.bottom, 4)
    }

    // MARK: Cards

    private var cornerCards: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 10) {
                    if let next = model.nextIndex, !model.nextCancelled, model.duration > 60,
                       (0.5...18).contains(model.duration - model.position) {
                        NextEpisodeCard(model: model, name: model.episodes[next].name ?? "Tập \(next + 1)")
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
            }
            .padding(.trailing, 24)
            .padding(.bottom, model.controlsVisible ? 100 : 28)
        }
    }

    private var errorCard: some View {
        VStack(spacing: 12) {
            Text("Không phát được tập này").font(.headline)
            Text("Thử lại hoặc đổi server trong danh sách tập.").font(.footnote).foregroundStyle(.secondary)
            HStack(spacing: 10) {
                Chip(text: "Thử lại", highlighted: true) { model.retry() }
                if model.hasEpisodeList { Chip(text: "Đổi server") { model.panel = .episodes } }
            }
        }
        .foregroundStyle(.white)
        .padding(24)
        .glassSurface(in: .rect(cornerRadius: 20))
    }

    private var offlineBanner: some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: "wifi.slash").foregroundStyle(.orange).symbolEffect(.pulse)
                Text("Mất kết nối mạng · sẽ tự phát lại khi có mạng").font(.subheadline.weight(.medium))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .glassSurface()
            .padding(.top, 70)
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .allowsHitTesting(false)
    }

    private var sleepLabel: String? {
        switch model.sleepMinutes {
        case 0: nil
        case -1: "Hẹn giờ: hết tập"
        default: "Hẹn giờ: \(model.sleepMinutes) phút"
        }
    }
}

func speedLabel(_ s: Float) -> String { s == 1 ? "Bình thường" : String(format: s == s.rounded() ? "%.0f×" : "%g×", s) }

// MARK: - Pieces

struct RoundButton: View {
    let icon: String
    let label: String
    var size: CGFloat = 44
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .semibold))
                .frame(width: size, height: size)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .glassSurface(in: .circle, interactive: true)
        .accessibilityLabel(label)
    }
}

/// A bare icon on the video; the whole frame is tappable, not just the glyph.
struct IconButton: View {
    let icon: String
    let label: String
    var size: CGFloat = 44
    var weight: Font.Weight = .semibold
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.45, weight: weight))
                .frame(width: size, height: size)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// Icon + title in the bottom action row.
private struct ActionLabel: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.subheadline.weight(.semibold))
        .frame(minHeight: 44)
        .contentShape(.rect)
    }
}

struct Chip: View {
    let text: String
    var highlighted = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(highlighted ? .black : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(highlighted ? AnyShapeStyle(.white) : AnyShapeStyle(.white.opacity(0.14)), in: .capsule)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }
}

private struct SeekBar: View {
    let model: PlayerModel
    @State private var dragging: Double?

    var body: some View {
        GeometryReader { geo in
            let duration = max(model.duration, 1)
            let fraction = (dragging ?? model.position) / duration
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.2)).frame(height: 4)
                Capsule().fill(.white.opacity(0.35)).frame(width: geo.size.width * min(1, model.buffered / duration), height: 4)
                Capsule().fill(LinearGradient(colors: [.brand, .brandLight], startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * min(1, max(0, fraction)), height: 4)
                Circle().fill(.white).frame(width: dragging == nil ? 12 : 18)
                    .offset(x: geo.size.width * min(1, max(0, fraction)) - (dragging == nil ? 6 : 9))
                if let dragging {
                    Text(formatTime(dragging))
                        .font(.footnote.bold().monospacedDigit())
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(.white, in: .rect(cornerRadius: 8))
                        .offset(x: min(max(0, geo.size.width * fraction - 28), geo.size.width - 56), y: -26)
                }
            }
            .frame(height: 32)
            .contentShape(.rect)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        dragging = min(max(0, v.location.x / geo.size.width), 1) * duration
                        model.interact()
                    }
                    .onEnded { _ in
                        if let dragging { model.seek(to: dragging) }
                        dragging = nil
                    }
            )
            .animation(.snappy(duration: 0.15), value: dragging == nil)
        }
        .frame(height: 32)
        .accessibilityElement()
        .accessibilityLabel("Tiến độ")
        .accessibilityValue(formatTime(model.position))
        .accessibilityAdjustableAction { direction in
            model.seek(by: direction == .increment ? 10 : -10)
        }
    }
}

private struct NextEpisodeCard: View {
    let model: PlayerModel
    let name: String

    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(url: FilmItem(model.film).thumbURL, maxPoints: 200)
                .frame(width: 120, height: 68)
                .overlay { Color.black.opacity(0.3) }
                .overlay {
                    Text("\(Int(max(0, model.duration - model.position)))")
                        .font(.title2.weight(.black).monospacedDigit())
                        .contentTransition(.numericText(countsDown: true))
                }
                .clipShape(.rect(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 6) {
                Text("TẬP TIẾP THEO").font(.caption2.weight(.bold)).tracking(1).foregroundStyle(Color.brandLight)
                Text(name).font(.subheadline.weight(.semibold)).lineLimit(1)
                HStack(spacing: 8) {
                    Chip(text: "Phát ngay", highlighted: true) { model.playNext() }
                    Chip(text: "Huỷ") { model.nextCancelled = true }
                }
            }
        }
        .foregroundStyle(.white)
        .padding(12)
        .frame(width: 380, alignment: .leading)
        .glassSurface(in: .rect(cornerRadius: 18))
    }
}

/// AVRoutePickerView for AirPlay.
private struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.tintColor = .white
        view.activeTintColor = UIColor(Color.brandLight)
        view.prioritizesVideoDevices = true
        return view
    }

    func updateUIView(_ view: AVRoutePickerView, context: Context) {}
}

// MARK: - Panels

private struct PanelHeader: View {
    let title: String
    let model: PlayerModel

    var body: some View {
        HStack {
            Text(title).font(.title3.bold())
            Spacer()
            RoundButton(icon: "xmark", label: "Đóng", size: 36) { model.panel = .none }
        }
    }
}

private struct OptionRow: View {
    let title: String
    let options: [(label: String, selected: Bool, pick: () -> Void)]

    var body: some View {
        if !options.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title.uppercased()).font(.caption.weight(.bold)).tracking(1).foregroundStyle(.secondary)
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(options.indices, id: \.self) { i in
                            Chip(text: options[i].label, highlighted: options[i].selected, action: options[i].pick)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}

private struct SettingsPanel: View {
    let model: PlayerModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PanelHeader(title: "Cài đặt phát", model: model)
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    OptionRow(title: "Tốc độ", options: [0.5, 0.75, 1, 1.25, 1.5, 2].map { (s: Float) in
                        (speedLabel(s), model.speed == s, { model.setSpeed(s) })
                    })
                    if model.variants.count > 1 {
                        OptionRow(title: "Chất lượng", options: [("Tự động", model.peakBitRate == 0, { model.setQuality(nil) })] +
                            model.variants.map { v in (v.height > 0 ? "\(v.height)p" : "\(Int(v.bandwidth / 1000)) kbps", model.peakBitRate == v.bandwidth, { model.setQuality(v) }) })
                    }
                    OptionRow(title: "Âm thanh", options: model.audioOptions.map { ($0.name, $0.selected, $0.select) })
                    OptionRow(title: "Phụ đề", options: model.subtitleOptions.map { ($0.name, $0.selected, $0.select) })
                    OptionRow(title: "Khung hình", options: [("Vừa", !model.fill, { model.fill = false }), ("Phóng", model.fill, { model.fill = true })])
                    OptionRow(title: "Hẹn giờ tắt", options: [(0, "Tắt"), (15, "15 phút"), (30, "30 phút"), (45, "45 phút"), (60, "60 phút"), (-1, "Hết tập này")].map { m, label in
                        (label, model.sleepMinutes == m, { model.setSleep(minutes: m) })
                    })
                }
            }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(.white)
        .padding(20)
        .task { await model.loadMediaOptions() }
    }
}

private struct EpisodePanel: View {
    let model: PlayerModel
    @State private var shown: Int?

    var body: some View {
        let server = shown ?? model.server
        let list = model.servers.indices.contains(server) ? model.servers[server] : []
        VStack(alignment: .leading, spacing: 16) {
            PanelHeader(title: "Danh sách tập", model: model)
            if model.servers.count > 1 {
                OptionRow(title: "Server", options: model.serverNames.indices.map { i in (model.serverNames[i], i == server, { shown = i }) })
            }
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(list.indices, id: \.self) { i in
                            let current = server == model.server && i == model.index
                            Button { model.switchTo(server: server, index: i) } label: {
                                Text(list[i].name ?? "\(i + 1)")
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(current ? AnyShapeStyle(Color.brand) : AnyShapeStyle(.white.opacity(0.1)), in: .rect(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            .disabled(list[i].streamURL == nil)
                            .opacity(list[i].streamURL == nil ? 0.35 : 1)
                            .id(i)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .onAppear { proxy.scrollTo(model.index, anchor: .center) }
            }
        }
        .foregroundStyle(.white)
        .padding(20)
    }
}
