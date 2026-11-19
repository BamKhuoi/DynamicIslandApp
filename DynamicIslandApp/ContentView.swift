import SwiftUI
import ActivityKit

struct ContentView: View {
    @State private var mode: IslandDisplayMode = .text
    @State private var fontStyle: IslandFontStyle = .monospaced
    @State private var compactText: String = ""
    @State private var expandedTitle: String = ""
    @State private var expandedSubtitle: String = ""

    @State private var useEmoji: Bool = false
    @State private var emojiText: String = "🔥"
    @State private var selectedIcon: String = "terminal.fill"

    @State private var iconColor: Color = Color(hex: "00FF9C")
    @State private var textColor: Color = Color(hex: "00E5FF")
    @State private var keylineColor: Color = Color(hex: "00E5FF")
    @State private var useKeyline: Bool = true

    @State private var cityName: String = "Hanoi"
    @State private var weatherInfo: String = "26°C"
    @State private var isLoadingWeather: Bool = false

    @State private var countdownMinutes: Int = 25
    @State private var countdownSeconds: Int = 0

    @State private var counterValue: Int = 0
    @State private var showCounter: Bool = true
    @State private var showLauncher: Bool = true
    @State private var shortcuts: [QuickShortcut] = MyIslandAttributes.ContentState.defaultShortcuts

    @State private var customPresets: [IslandPreset] = []
    @State private var showingSavePresetAlert: Bool = false
    @State private var newPresetName: String = ""

    @State private var previewExpanded: Bool = false
    @State private var statusMessage: String = ""

    private let lastConfigKey = "island_studio_last_config_v2"
    private let customPresetsKey = "island_studio_custom_presets_v2"

    let presetIcons = [
        "terminal.fill", "flame.fill", "bolt.fill", "star.fill", "heart.fill",
        "gamecontroller.fill", "crown.fill", "moon.stars.fill", "sun.max.fill", "cloud.rain.fill",
        "headphones", "music.note", "sparkles", "dumbbell.fill", "timer",
        "bicycle", "airplane", "battery.100", "clock.fill", "wifi"
    ]

    let columns = [GridItem(.adaptive(minimum: 42))]

    var currentPreviewState: MyIslandAttributes.ContentState {
        let duration = max(1, countdownMinutes * 60 + countdownSeconds)
        return MyIslandAttributes.ContentState(
            compactText: compactText,
            expandedTitle: expandedTitle,
            expandedSubtitle: expandedSubtitle,
            iconName: selectedIcon,
            useEmoji: useEmoji,
            emojiText: emojiText,
            iconColorHex: iconColor.toHex(),
            textColorHex: textColor.toHex(),
            keylineColorHex: keylineColor.toHex(),
            useKeyline: useKeyline,
            fontStyle: fontStyle,
            mode: mode,
            weatherInfo: weatherInfo,
            countdownStart: Date(),
            countdownEnd: Date().addingTimeInterval(TimeInterval(duration)),
            counter: counterValue,
            showCounter: showCounter,
            showLauncher: showLauncher,
            shortcuts: shortcuts
        )
    }

    var allPresets: [IslandPreset] {
        IslandPreset.builtInPresets + customPresets
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Khung Live Preview ghim cố định trên cùng
                IslandLivePreviewHeader(
                    state: currentPreviewState,
                    countdownText: String(format: "%02d:%02d", countdownMinutes, countdownSeconds),
                    isExpanded: $previewExpanded
                )

                Form {
                    // Preset nhanh
                    Section(header: Text("Preset nhanh (Chạm để áp dụng)")) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(allPresets) { preset in
                                    Button(action: {
                                        applyPreset(preset)
                                    }) {
                                        HStack(spacing: 6) {
                                            if preset.state.useEmoji {
                                                Text(preset.state.emojiText)
                                            } else {
                                                Image(systemName: preset.state.iconName)
                                                    .foregroundColor(Color(hex: preset.state.iconColorHex))
                                            }
                                            Text(preset.name)
                                                .font(.caption.bold())
                                                .foregroundColor(.primary)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.secondary.opacity(0.15))
                                        .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        if !preset.isBuiltIn {
                                            Button(role: .destructive) {
                                                deletePreset(preset)
                                            } label: {
                                                Label("Xóa Preset", systemImage: "trash")
                                            }
                                        }
                                    }
                                }

                                Button(action: {
                                    newPresetName = ""
                                    showingSavePresetAlert = true
                                }) {
                                    Label("Lưu mới", systemImage: "plus")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.cyan.opacity(0.2))
                                        .foregroundColor(.cyan)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    // Chế độ hiển thị
                    Section(header: Text("Chế độ góc phải Đảo động")) {
                        Picker("Chế độ", selection: $mode) {
                            ForEach(IslandDisplayMode.allCases, id: \.self) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker("Kiểu chữ", selection: $fontStyle) {
                            ForEach(IslandFontStyle.allCases, id: \.self) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                    }

                    // Cấu hình Đếm ngược
                    if mode == .countdown {
                        Section(header: Text("Thời gian đếm ngược (Pomodoro / Nghỉ tập)")) {
                            HStack(spacing: 8) {
                                quickTimerButton(label: "1p", mins: 1, secs: 0)
                                quickTimerButton(label: "90s", mins: 1, secs: 30)
                                quickTimerButton(label: "5p", mins: 5, secs: 0)
                                quickTimerButton(label: "25p", mins: 25, secs: 0)
                                quickTimerButton(label: "45p", mins: 45, secs: 0)
                            }
                            Stepper("Phút: \(countdownMinutes)", value: $countdownMinutes, in: 0...180)
                            Stepper("Giây: \(countdownSeconds)", value: $countdownSeconds, in: 0...59, step: 5)
                        }
                    }

                    // Cấu hình Thời tiết
                    if mode == .weather {
                        Section(header: Text("Thời tiết tự động (Open-Meteo)")) {
                            HStack {
                                TextField("Tên thành phố (VD: Hanoi)", text: $cityName)
                                Button(action: {
                                    Task { await fetchWeather() }
                                }) {
                                    if isLoadingWeather {
                                        ProgressView()
                                    } else {
                                        Text("Cập nhật")
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                            Text("Hiện tại: \(weatherInfo)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Nội dung chữ
                    Section(header: Text("Nội dung hiển thị")) {
                        if mode == .text {
                            TextField("Chữ góc phải (< 6 ký tự)", text: $compactText)
                        }
                        TextField("Tiêu đề khi mở rộng Đảo", text: $expandedTitle)
                        TextField("Dòng phụ khi mở rộng Đảo", text: $expandedSubtitle)
                    }

                    // Icon hoặc Emoji
                    Section(header: Text("Biểu tượng (SF Symbols / Emoji)")) {
                        Toggle("Dùng Emoji thay cho Icon", isOn: $useEmoji)

                        if useEmoji {
                            TextField("Nhập 1 Emoji (VD: 🔥, ⚡, 🎧)", text: $emojiText)
                                .font(.title2)
                        } else {
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(presetIcons, id: \.self) { icon in
                                    Image(systemName: icon)
                                        .font(.title3)
                                        .frame(width: 40, height: 40)
                                        .background(selectedIcon == icon ? iconColor.opacity(0.25) : Color.clear)
                                        .foregroundColor(selectedIcon == icon ? iconColor : .primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedIcon == icon ? iconColor : Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                        .onTapGesture {
                                            selectedIcon = icon
                                        }
                                }
                            }
                            .padding(.vertical, 4)

                            TextField("Hoặc gõ tên SF Symbol tùy ý...", text: $selectedIcon)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                    }

                    // Màu sắc & Viền Neon
                    Section(header: Text("Màu sắc & Viền Neon")) {
                        ColorPicker("Màu Icon / Thanh tiến trình", selection: $iconColor, supportsOpacity: false)
                        ColorPicker("Màu Chữ / Đồng hồ", selection: $textColor, supportsOpacity: false)
                        Toggle("Bật viền phát sáng Neon", isOn: $useKeyline)
                        if useKeyline {
                            ColorPicker("Màu viền Neon", selection: $keylineColor, supportsOpacity: false)
                        }
                    }

                    // Tiện ích mở rộng trên Đảo
                    Section(header: Text("Tương tác & Bệ phóng App")) {
                        Toggle("Hiện bộ đếm (+ / -) trên Đảo", isOn: $showCounter)
                        if showCounter {
                            Stepper("Giá trị ban đầu: \(counterValue)", value: $counterValue, in: 0...999)
                        }

                        Toggle("Hiện phím tắt mở nhanh App", isOn: $showLauncher)
                        if showLauncher {
                            ForEach($shortcuts) { $item in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: item.icon)
                                            .foregroundColor(iconColor)
                                            .frame(width: 24)
                                        TextField("Tên", text: $item.name)
                                            .font(.subheadline.bold())
                                        TextField("SF Icon", text: $item.icon)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .autocapitalization(.none)
                                    }
                                    TextField("URL Scheme (VD: youtube://)", text: $item.urlString)
                                        .font(.caption)
                                        .foregroundColor(.cyan)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }

                    // Nút điều khiển chính
                    Section {
                        Button(action: {
                            saveLastConfig()
                            Task { await startOrUpdateActivity() }
                        }) {
                            HStack {
                                Spacer()
                                Label("Bật / Cập nhật Dynamic Island", systemImage: "sparkles")
                                    .font(.headline)
                                Spacer()
                            }
                        }
                        .foregroundColor(.green)

                        Button(role: .destructive, action: {
                            Task { await stopAllActivities() }
                        }) {
                            HStack {
                                Spacer()
                                Label("Tắt Dynamic Island", systemImage: "xmark.circle")
                                Spacer()
                            }
                        }
                    }

                    if !statusMessage.isEmpty {
                        Section {
                            Text(statusMessage)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Island Studio Pro")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .onAppear {
                loadSavedData()
            }
            .alert("Lưu Preset mới", isPresented: $showingSavePresetAlert) {
                TextField("Tên Preset (VD: Chill tối)", text: $newPresetName)
                Button("Hủy", role: .cancel) {}
                Button("Lưu") {
                    saveCurrentAsPreset()
                }
            }
        }
    }

    func quickTimerButton(label: String, mins: Int, secs: Int) -> some View {
        Button(label) {
            countdownMinutes = mins
            countdownSeconds = secs
        }
        .font(.caption.bold())
        .buttonStyle(.bordered)
        .tint(countdownMinutes == mins && countdownSeconds == secs ? iconColor : .gray)
    }

    func applyPreset(_ preset: IslandPreset) {
        let s = preset.state
        mode = s.mode
        fontStyle = s.fontStyle
        compactText = s.compactText
        expandedTitle = s.expandedTitle
        expandedSubtitle = s.expandedSubtitle
        useEmoji = s.useEmoji
        emojiText = s.emojiText
        selectedIcon = s.iconName
        iconColor = Color(hex: s.iconColorHex)
        textColor = Color(hex: s.textColorHex)
        keylineColor = Color(hex: s.keylineColorHex)
        useKeyline = s.useKeyline
        weatherInfo = s.weatherInfo
        counterValue = s.counter
        showCounter = s.showCounter
        showLauncher = s.showLauncher
        shortcuts = s.shortcuts
        countdownMinutes = preset.countdownMinutes
        countdownSeconds = preset.countdownSeconds
        cityName = preset.cityName
        saveLastConfig()
        statusMessage = "Đã nạp Preset '\(preset.name)'. Bấm Cập nhật để đẩy lên Đảo!"
    }

    func saveCurrentAsPreset() {
        let trimmed = newPresetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let preset = IslandPreset(
            name: trimmed,
            state: currentPreviewState,
            countdownMinutes: countdownMinutes,
            countdownSeconds: countdownSeconds,
            cityName: cityName,
            isBuiltIn: false
        )
        customPresets.append(preset)
        if let encoded = try? JSONEncoder().encode(customPresets) {
            UserDefaults.standard.set(encoded, forKey: customPresetsKey)
        }
        statusMessage = "Đã lưu Preset '\(trimmed)'."
    }

    func deletePreset(_ preset: IslandPreset) {
        customPresets.removeAll { $0.id == preset.id }
        if let encoded = try? JSONEncoder().encode(customPresets) {
            UserDefaults.standard.set(encoded, forKey: customPresetsKey)
        }
    }

    func saveLastConfig() {
        let snapshot = IslandPreset(
            id: "last-config",
            name: "Last",
            state: currentPreviewState,
            countdownMinutes: countdownMinutes,
            countdownSeconds: countdownSeconds,
            cityName: cityName,
            isBuiltIn: false
        )
        if let encoded = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(encoded, forKey: lastConfigKey)
        }
    }

    func loadSavedData() {
        if let data = UserDefaults.standard.data(forKey: customPresetsKey),
           let decoded = try? JSONDecoder().decode([IslandPreset].self, from: data) {
            customPresets = decoded
        }
        if let data = UserDefaults.standard.data(forKey: lastConfigKey),
           let last = try? JSONDecoder().decode(IslandPreset.self, from: data) {
            applyPreset(last)
            statusMessage = ""
        }
    }

    func startOrUpdateActivity() async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            statusMessage = "Bạn chưa bật quyền Live Activities trong Cài đặt iPhone."
            return
        }

        let state = currentPreviewState
        let content = ActivityContent(state: state, staleDate: nil)

        if let existingActivity = Activity<MyIslandAttributes>.activities.first {
            await existingActivity.update(content)
            statusMessage = "Đã cập nhật Dynamic Island!"
        } else {
            do {
                let attributes = MyIslandAttributes()
                let _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
                statusMessage = "Đã bật Dynamic Island thành công!"
            } catch {
                statusMessage = "Lỗi: \(error.localizedDescription)"
            }
        }
    }

    func stopAllActivities() async {
        for activity in Activity<MyIslandAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        statusMessage = "Đã tắt Dynamic Island."
    }

    func fetchWeather() async {
        isLoadingWeather = true
        defer { isLoadingWeather = false }

        let encodedCity = cityName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Hanoi"
        guard let geoURL = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(encodedCity)&count=1&format=json") else { return }

        do {
            let (geoData, _) = try await URLSession.shared.data(from: geoURL)
            let geoResult = try JSONDecoder().decode(GeoResponse.self, from: geoData)
            guard let place = geoResult.results?.first else {
                statusMessage = "Không tìm thấy thành phố \(cityName)."
                return
            }

            let weatherURLString = "https://api.open-meteo.com/v1/forecast?latitude=\(place.latitude)&longitude=\(place.longitude)¤t_weather=true"
            guard let weatherURL = URL(string: weatherURLString) else { return }

            let (wData, _) = try await URLSession.shared.data(from: weatherURL)
            let wResult = try JSONDecoder().decode(WeatherResponse.self, from: wData)
            let temp = Int(round(wResult.current_weather.temperature))

            weatherInfo = "\(temp)°C"
            expandedTitle = "\(place.name): \(temp)°C"
            saveLastConfig()
            statusMessage = "Đã lấy thời tiết \(place.name) (\(temp)°C). Bấm Cập nhật để đẩy lên Đảo!"
        } catch {
            statusMessage = "Lỗi lấy thời tiết: \(error.localizedDescription)"
        }
    }
}

struct IslandLivePreviewHeader: View {
    let state: MyIslandAttributes.ContentState
    let countdownText: String
    @Binding var isExpanded: Bool

    var body: some View {
        let iconColor = Color(hex: state.iconColorHex)
        let textColor = Color(hex: state.textColorHex)
        let borderColor = state.useKeyline ? Color(hex: state.keylineColorHex) : Color.white.opacity(0.15)

        VStack(spacing: 6) {
            Group {
                if isExpanded {
                    VStack(spacing: 10) {
                        HStack {
                            previewIcon(font: .title2, color: iconColor)
                            Spacer()
                            VStack(spacing: 2) {
                                Text(state.expandedTitle)
                                    .font(.system(.subheadline, design: state.fontStyle.design).bold())
                                    .foregroundColor(textColor)
                                    .lineLimit(1)
                                Text(state.expandedSubtitle)
                                    .font(.system(.caption2, design: state.fontStyle.design))
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                            Spacer()
                            previewMetric(color: textColor, compact: false)
                        }

                        if state.mode == .countdown {
                            Capsule()
                                .fill(iconColor.opacity(0.3))
                                .frame(height: 5)
                                .overlay(alignment: .leading) {
                                    Capsule()
                                        .fill(iconColor)
                                        .frame(width: 140, height: 5)
                                }
                        }

                        if state.showCounter || state.showLauncher {
                            HStack(spacing: 8) {
                                if state.showCounter {
                                    HStack(spacing: 6) {
                                        Image(systemName: "minus.circle.fill").foregroundColor(.gray)
                                        Text("\(state.counter)")
                                            .font(.system(.caption, design: .monospaced).bold())
                                            .foregroundColor(textColor)
                                        Image(systemName: "plus.circle.fill").foregroundColor(iconColor)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Capsule())
                                }

                                if state.showLauncher {
                                    HStack(spacing: 6) {
                                        ForEach(state.shortcuts.prefix(4)) { item in
                                            VStack(spacing: 2) {
                                                Image(systemName: item.icon)
                                                    .font(.caption2)
                                                    .foregroundColor(iconColor)
                                                Text(item.name)
                                                    .font(.system(size: 8))
                                                    .foregroundColor(.white.opacity(0.8))
                                                    .lineLimit(1)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 4)
                                            .background(Color.white.opacity(0.08))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: 340)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(borderColor, lineWidth: state.useKeyline ? 1.5 : 1)
                    )
                    .shadow(color: state.useKeyline ? borderColor.opacity(0.45) : .clear, radius: 10)
                } else {
                    HStack {
                        previewIcon(font: .caption, color: iconColor)
                        Spacer()
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 12, height: 12)
                        Spacer()
                        previewMetric(color: textColor, compact: true)
                    }
                    .padding(.horizontal, 14)
                    .frame(width: 210, height: 36)
                    .background(Color.black)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(borderColor, lineWidth: state.useKeyline ? 1.5 : 1)
                    )
                    .shadow(color: state.useKeyline ? borderColor.opacity(0.5) : .clear, radius: 8)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
            .onTapGesture {
                isExpanded.toggle()
            }

            Text(isExpanded ? "Chạm vào Đảo để thu gọn preview" : "Chạm vào Đảo để xem trước khi mở rộng")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemGroupedBackground))
    }

    @ViewBuilder
    func previewIcon(font: Font, color: Color) -> some View {
        if state.useEmoji {
            Text(state.emojiText.isEmpty ? "✨" : state.emojiText).font(font)
        } else {
            Image(systemName: state.iconName).font(font).foregroundColor(color)
        }
    }

    @ViewBuilder
    func previewMetric(color: Color, compact: Bool) -> some View {
        let font: Font = .system(compact ? .caption2 : .caption, design: state.fontStyle.design).bold()
        switch state.mode {
        case .text:
            Text(state.compactText).font(font).foregroundColor(color).lineLimit(1)
        case .clock:
            Text("12:30:45").font(font).foregroundColor(color)
        case .weather:
            Text(state.weatherInfo).font(font).foregroundColor(color)
        case .countdown:
            Text(countdownText).font(font).foregroundColor(color)
        }
    }
}

struct GeoResponse: Decodable {
    let results: [GeoPlace]?
}

struct GeoPlace: Decodable {
    let name: String
    let latitude: Double
    let longitude: Double
}

struct WeatherResponse: Decodable {
    let current_weather: CurrentWeather
}

struct CurrentWeather: Decodable {
    let temperature: Double
}