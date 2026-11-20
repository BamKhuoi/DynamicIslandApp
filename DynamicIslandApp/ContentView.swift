import SwiftUI
import ActivityKit
import PhotosUI
import UIKit

struct ContentView: View {
    @State private var mode: IslandDisplayMode = .text
    @State private var fontStyle: IslandFontStyle = .monospaced
    @State private var compactText: String = "🤓"
    @State private var expandedTitle: String = "Hoàng Linh"
    @State private var expandedSubtitle: String = "Nguyễn Bố Mày"

    @State private var iconSource: IslandIconSource = .symbol
    @State private var emojiText: String = "🤓"
    @State private var selectedIcon: String = "terminal.fill"
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var masterImageData: Data? = nil
    @State private var customImageData: Data? = nil
    @State private var compressedImageSide: Int = 0
    @State private var lastPayloadBytes: Int = 0
    @State private var isPayloadOverLimit: Bool = false
    @State private var isUltraSharpMode: Bool = true
    @State private var photoIsCircle: Bool = true

    @State private var iconColor: Color = Color(hex: "00FF9C")
    @State private var textColor: Color = Color(hex: "00E5FF")
    @State private var keylineColor: Color = Color(hex: "38BDF8")
    @State private var useKeyline: Bool = true

    @State private var bgStyle: IslandBackgroundStyle = .glass
    @State private var bgColor: Color = Color(hex: "0EA5E9")
    @State private var bgColor2: Color = Color(hex: "7C3AED")

    @State private var cityName: String = "Hanoi"
    @State private var weatherInfo: String = "26°C"
    @State private var isLoadingWeather: Bool = false
    @State private var weatherStatus: String = ""

    @State private var countdownMinutes: Int = 25
    @State private var countdownSeconds: Int = 0

    @State private var batteryLevel: Int = 85
    @State private var isCharging: Bool = false

    @State private var counterValue: Int = 0
    @State private var showCounter: Bool = false

    @State private var showTodos: Bool = false
    @State private var todos: [TodoItem] = MyIslandAttributes.ContentState.defaultTodos

    @State private var showLauncher: Bool = false
    @State private var shortcuts: [QuickShortcut] = MyIslandAttributes.ContentState.defaultShortcuts

    @State private var customPresets: [IslandPreset] = []
    @State private var showingSavePresetAlert: Bool = false
    @State private var newPresetName: String = ""

    @State private var showingOverloadAlert: Bool = false
    @State private var overloadAlertMessage: String = ""

    @State private var previewExpanded: Bool = false
    @State private var statusMessage: String = ""

    private let lastConfigKey = "island_studio_last_config_v4"
    private let customPresetsKey = "island_studio_custom_presets_v4"
    private let masterImageKey = "island_studio_master_photo_v4"

    let presetIcons = [
        "terminal.fill", "flame.fill", "bolt.fill", "star.fill", "heart.fill",
        "gamecontroller.fill", "crown.fill", "moon.stars.fill", "sun.max.fill", "cloud.rain.fill",
        "headphones", "music.note", "sparkles", "dumbbell.fill", "timer",
        "bicycle", "airplane", "battery.100", "clock.fill", "wifi"
    ]

    let iconColumns = [GridItem(.adaptive(minimum: 42))]
    let modeColumns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var currentPreviewState: MyIslandAttributes.ContentState {
        let duration = max(1, countdownMinutes * 60 + countdownSeconds)
        return MyIslandAttributes.ContentState(
            compactText: compactText,
            expandedTitle: expandedTitle,
            expandedSubtitle: expandedSubtitle,
            iconSource: iconSource,
            iconName: selectedIcon,
            emojiText: emojiText,
            customImageData: iconSource == .photo ? (customImageData ?? masterImageData) : nil,
            photoIsCircle: photoIsCircle,
            iconColorHex: iconColor.toHex(),
            textColorHex: textColor.toHex(),
            keylineColorHex: keylineColor.toHex(),
            useKeyline: useKeyline,
            bgStyle: bgStyle,
            bgColorHex: bgColor.toHex(),
            bgColor2Hex: bgColor2.toHex(),
            fontStyle: fontStyle,
            mode: mode,
            weatherInfo: weatherInfo,
            countdownStart: Date(),
            countdownEnd: Date().addingTimeInterval(TimeInterval(duration)),
            stopwatchStart: Date(),
            batteryLevel: batteryLevel,
            isCharging: isCharging,
            counter: counterValue,
            showCounter: showCounter,
            showTodos: showTodos,
            todos: todos,
            showLauncher: showLauncher,
            shortcuts: shortcuts
        )
    }

    var allPresets: [IslandPreset] {
        IslandPreset.builtInPresets + customPresets
    }

    var payloadMeterColor: Color {
        if isPayloadOverLimit { return .red }
        if lastPayloadBytes >= 3650 { return .orange }
        return .green
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
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
                                            if preset.state.iconSource == .emoji {
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

                    // Chế độ hiển thị (Lưới 3x2 gọn gàng)
                    Section(header: Text("Chế độ góc phải Đảo động")) {
                        LazyVGrid(columns: modeColumns, spacing: 8) {
                            ForEach(IslandDisplayMode.allCases, id: \.self) { item in
                                Button(action: {
                                    mode = item
                                    if item == .battery {
                                        refreshLocalBattery()
                                    }
                                }) {
                                    Text(item.rawValue)
                                        .font(.caption.bold())
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(mode == item ? iconColor.opacity(0.25) : Color.secondary.opacity(0.12))
                                        .foregroundColor(mode == item ? iconColor : .primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(mode == item ? iconColor : Color.clear, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)

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

                    // Thông tin Bấm giờ
                    if mode == .stopwatch {
                        Section(header: Text("Đồng hồ bấm giờ (Stopwatch)")) {
                            Text("Đảo động sẽ tự động đếm từ 00:00 khi bạn bấm Cập nhật. Chạm giữ Đảo để bấm nút Reset về 0 bất kỳ lúc nào.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Thông tin Pin
                    if mode == .battery {
                        Section(header: Text("Trạng thái Pin hiện tại")) {
                            HStack {
                                Label(
                                    "\(batteryLevel)% \(isCharging ? "(Đang sạc)" : "")",
                                    systemImage: isCharging ? "battery.100.bolt" : "battery.75"
                                )
                                .foregroundColor(batteryLevel <= 20 && !isCharging ? .red : .green)
                                Spacer()
                                Button("Đọc lại") {
                                    refreshLocalBattery()
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }

                    // Cấu hình Thời tiết
                    if mode == .weather {
                        Section(header: Text("Thời tiết tự động (Open-Meteo)")) {
                            TextField("Tên thành phố (VD: Hanoi, Da Nang)", text: $cityName)
                                .autocorrectionDisabled(true)

                            Button(action: {
                                Task { await fetchWeather() }
                            }) {
                                HStack {
                                    if isLoadingWeather {
                                        ProgressView()
                                            .padding(.trailing, 6)
                                        Text("Đang lấy dữ liệu...")
                                    } else {
                                        Label("Cập nhật thời tiết ngay", systemImage: "cloud.sun.fill")
                                    }
                                }
                            }
                            .disabled(isLoadingWeather)

                            Text("Hiện tại: \(weatherInfo)")
                                .font(.footnote.bold())
                                .foregroundColor(.cyan)

                            if !weatherStatus.isEmpty {
                                Text(weatherStatus)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
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

                    // Biểu tượng: SF Symbol / Emoji / Ảnh thư viện
                    Section(
                        header: Text("Biểu tượng (Icon / Emoji / Ảnh từ máy)"),
                        footer: iconSource == .photo
                            ? Text(
                                showLauncher
                                    ? "Chế độ Tiêu chuẩn (đang bật Phím tắt nhanh). Tắt Phím tắt App để tự mở khóa ảnh Siêu nét 96×96 – 112×112 px."
                                    : "Chế độ Siêu nét đang bật — toàn bộ dung lượng trống đã dồn cho ảnh."
                            )
                            : nil
                    ) {
                        Picker("Loại biểu tượng", selection: $iconSource) {
                            ForEach(IslandIconSource.allCases, id: \.self) { src in
                                Text(src.rawValue).tag(src)
                            }
                        }
                        .pickerStyle(.segmented)

                        switch iconSource {
                        case .symbol:
                            LazyVGrid(columns: iconColumns, spacing: 10) {
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

                        case .emoji:
                            TextField("Nhập 1 Emoji (VD: 🔥, ⚡, 🎧)", text: $emojiText)
                                .font(.title2)

                        case .photo:
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                                HStack(spacing: 14) {
                                    if let data = customImageData ?? masterImageData, let uiImg = UIImage(data: data) {
                                        if photoIsCircle {
                                            Image(uiImage: uiImg)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 48, height: 48)
                                                .clipShape(Circle())
                                                .overlay(Circle().stroke(iconColor, lineWidth: 1.5))
                                        } else {
                                            Image(uiImage: uiImg)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 48, height: 48)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(iconColor, lineWidth: 1.5))
                                        }
                                    } else {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.title2)
                                            .foregroundColor(.cyan)
                                            .frame(width: 48, height: 48)
                                            .background(Color.cyan.opacity(0.15))
                                            .clipShape(Circle())
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text((customImageData ?? masterImageData) == nil ? "Chọn ảnh từ Thư viện" : "Đổi ảnh khác")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.cyan)
                                        if let data = customImageData {
                                            let badge = isUltraSharpMode ? "Siêu nét" : "Tiêu chuẩn"
                                            let resText = compressedImageSide > 0 ? "\(compressedImageSide)×\(compressedImageSide)px" : ""
                                            Text("\(badge) • \(resText) • \(data.count) B")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        } else {
                                            Text("Tự động nén độ nét tối đa theo hạn mức 4KB")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }

                            Toggle("Bo tròn kiểu Avatar", isOn: $photoIsCircle)
                        }
                    }

                    // Nền & Màu sắc
                    Section(
                        header: Text("Nền Đảo mở rộng & Màn hình khóa"),
                        footer: Text("Mẹo: Chọn Liquid Glass kết hợp 2 màu sáng (VD: Xanh dương + Tím) để tấm kính trong Đảo mở rộng lên màu rõ nhất.")
                    ) {
                        Picker("Kiểu nền", selection: $bgStyle) {
                            ForEach(IslandBackgroundStyle.allCases, id: \.self) { st in
                                Text(st.rawValue).tag(st)
                            }
                        }
                        .pickerStyle(.segmented)

                        ColorPicker("Màu nền chính", selection: $bgColor, supportsOpacity: false)
                        if bgStyle == .gradient || bgStyle == .glass {
                            ColorPicker(
                                bgStyle == .glass ? "Màu pha Liquid Glass 2" : "Màu nền thứ 2 (Gradient)",
                                selection: $bgColor2,
                                supportsOpacity: false
                            )
                        }
                    }

                    Section(header: Text("Màu chữ, Icon & Viền Neon")) {
                        ColorPicker("Màu Icon / Thanh tiến trình", selection: $iconColor, supportsOpacity: false)
                        ColorPicker("Màu Chữ / Đồng hồ", selection: $textColor, supportsOpacity: false)
                        Toggle("Bật viền phát sáng Neon", isOn: $useKeyline)
                        if useKeyline {
                            ColorPicker("Màu viền Neon", selection: $keylineColor, supportsOpacity: false)
                        }
                    }

                    // Mini To-Do Checklist
                    Section(
                        header: Text("Checklist 3 việc cần làm (Tương tác trên Đảo)"),
                        footer: Text(showTodos ? "Đang bật Checklist (tốn thêm ~220 B dung lượng Đảo)." : "Đang tắt Checklist — đã giải phóng dung lượng cho ảnh.")
                    ) {
                        Toggle("Hiện Checklist trên Đảo", isOn: $showTodos)
                        if showTodos {
                            ForEach($todos) { $todo in
                                HStack {
                                    Button(action: {
                                        todo.isDone.toggle()
                                    }) {
                                        Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(todo.isDone ? iconColor : .gray)
                                    }
                                    .buttonStyle(.plain)

                                    TextField("Nhập đầu việc...", text: $todo.title)
                                        .strikethrough(todo.isDone)
                                }
                            }

                            if todos.contains(where: { $0.isDone }) {
                                Button("Bỏ tích tất cả") {
                                    for i in todos.indices {
                                        todos[i].isDone = false
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.cyan)
                            }
                        }
                    }

                    // Bộ đếm & Bệ phóng App
                    Section(
                        header: Text("Bộ đếm & Bệ phóng mở nhanh App"),
                        footer: Text(
                            showLauncher
                                ? "Đang bật Phím tắt App (ảnh tự giữ mức Tiêu chuẩn để không vượt 4KB)."
                                : "Đang tắt Phím tắt App — ảnh tự mở khóa chế độ Siêu nét tối đa."
                        )
                    ) {
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

                    // Thanh theo dõi dung lượng 4KB trực tiếp
                    Section(header: Text("Dung lượng gói tin Live Activity (Giới hạn 4KB)")) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(isPayloadOverLimit ? "QUÁ TẢI — Sẽ lỗi Đảo động!" : "Mức an toàn")
                                    .font(.caption.bold())
                                    .foregroundColor(payloadMeterColor)
                                Spacer()
                                Text("\(lastPayloadBytes) / \(MyIslandAttributes.ContentState.hardPayloadLimit) B")
                                    .font(.caption.monospacedDigit().bold())
                                    .foregroundColor(payloadMeterColor)
                            }

                            ProgressView(
                                value: Double(min(lastPayloadBytes, MyIslandAttributes.ContentState.hardPayloadLimit)),
                                total: Double(MyIslandAttributes.ContentState.hardPayloadLimit)
                            )
                            .tint(payloadMeterColor)

                            if isPayloadOverLimit {
                                Text("Hãy rút ngắn tiêu đề/Checklist hoặc tắt bớt Phím tắt App để giảm dưới \(MyIslandAttributes.ContentState.safePayloadLimit) B.")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    // Nút điều khiển chính
                    Section {
                        Button(action: {
                            refreshLocalBattery()
                            recalculatePayloadAndPhoto()
                            saveLastConfig()
                            Task { await startOrUpdateActivity() }
                        }) {
                            HStack {
                                Spacer()
                                Label(
                                    isPayloadOverLimit ? "Quá tải 4KB — Cần giảm bớt nội dung" : "Bật / Cập nhật Dynamic Island",
                                    systemImage: isPayloadOverLimit ? "exclamationmark.triangle.fill" : "sparkles"
                                )
                                .font(.headline)
                                Spacer()
                            }
                        }
                        .foregroundColor(isPayloadOverLimit ? .orange : .green)

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
            .navigationTitle("Hoàng Linh's Island Studio")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .onAppear {
                loadSavedData()
                refreshLocalBattery()
                recalculatePayloadAndPhoto()
            }
            .onChange(of: showTodos) { _ in recalculatePayloadAndPhoto() }
            .onChange(of: showLauncher) { _ in recalculatePayloadAndPhoto() }
            .onChange(of: showCounter) { _ in recalculatePayloadAndPhoto() }
            .onChange(of: iconSource) { _ in recalculatePayloadAndPhoto() }
            .onChange(of: expandedTitle) { _ in recalculatePayloadAndPhoto() }
            .onChange(of: expandedSubtitle) { _ in recalculatePayloadAndPhoto() }
            .onChange(of: compactText) { _ in recalculatePayloadAndPhoto() }
            .onChange(of: selectedPhotoItem) { newItem in
                guard let newItem else { return }
                Task {
                    defer {
                        Task { @MainActor in
                            selectedPhotoItem = nil
                        }
                    }
                    do {
                        if let rawData = try await newItem.loadTransferable(type: Data.self),
                           let uiImg = UIImage(data: rawData),
                           let master = ImageCompressor.prepareMasterImage(uiImg) {
                            await MainActor.run {
                                masterImageData = master
                                UserDefaults.standard.set(master, forKey: masterImageKey)
                                iconSource = .photo
                                recalculatePayloadAndPhoto()
                                saveLastConfig()
                                let modeLabel = isUltraSharpMode ? "Siêu nét" : "Tiêu chuẩn"
                                statusMessage = "Đã nạp ảnh \(modeLabel) (\(compressedImageSide)×\(compressedImageSide)px • \(customImageData?.count ?? 0) B). Bấm Cập nhật để đẩy lên Đảo!"
                            }
                        } else {
                            await MainActor.run {
                                statusMessage = "Không thể đọc dữ liệu ảnh này, hãy thử chọn ảnh JPG/PNG khác."
                            }
                        }
                    } catch {
                        await MainActor.run {
                            statusMessage = "Lỗi tải ảnh: \(error.localizedDescription)"
                        }
                    }
                }
            }
            .alert("Lưu Preset mới", isPresented: $showingSavePresetAlert) {
                TextField("Tên Preset (VD: Chill tối)", text: $newPresetName)
                Button("Hủy", role: .cancel) {}
                Button("Lưu") {
                    saveCurrentAsPreset()
                }
            }
            .alert("Cảnh báo quá tải 4KB", isPresented: $showingOverloadAlert) {
                Button("Đã hiểu", role: .cancel) {}
            } message: {
                Text(overloadAlertMessage)
            }
        }
    }

    func recalculatePayloadAndPhoto() {
        let result = currentPreviewState.optimizedForLiveActivity(masterImageData: masterImageData)
        if iconSource == .photo {
            customImageData = result.state.customImageData
            compressedImageSide = result.imageSide
        }
        lastPayloadBytes = result.payloadBytes
        isPayloadOverLimit = result.isOverLimit
        isUltraSharpMode = result.isUltraSharpMode
    }

    func refreshLocalBattery() {
        let info = BatteryHelper.currentStatus()
        batteryLevel = info.level
        isCharging = info.isCharging
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
        iconSource = s.iconSource
        emojiText = s.emojiText
        selectedIcon = s.iconName
        if let presetImg = s.customImageData {
            customImageData = presetImg
        }
        photoIsCircle = s.photoIsCircle
        iconColor = Color(hex: s.iconColorHex)
        textColor = Color(hex: s.textColorHex)
        keylineColor = Color(hex: s.keylineColorHex)
        useKeyline = s.useKeyline
        bgStyle = s.bgStyle
        bgColor = Color(hex: s.bgColorHex)
        bgColor2 = Color(hex: s.bgColor2Hex)
        weatherInfo = s.weatherInfo
        counterValue = s.counter
        showCounter = s.showCounter
        showTodos = s.showTodos
        todos = s.todos.isEmpty ? MyIslandAttributes.ContentState.defaultTodos : s.todos
        showLauncher = s.showLauncher
        shortcuts = s.shortcuts.isEmpty ? MyIslandAttributes.ContentState.defaultShortcuts : s.shortcuts
        countdownMinutes = preset.countdownMinutes
        countdownSeconds = preset.countdownSeconds
        cityName = preset.cityName
        recalculatePayloadAndPhoto()
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
        if let master = UserDefaults.standard.data(forKey: masterImageKey) {
            masterImageData = master
        }
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
            await MainActor.run {
                statusMessage = "Bạn chưa bật quyền Live Activities trong Cài đặt iPhone."
            }
            return
        }

        let optimized = currentPreviewState.optimizedForLiveActivity(masterImageData: masterImageData)
        await MainActor.run {
            if iconSource == .photo {
                customImageData = optimized.state.customImageData
                compressedImageSide = optimized.imageSide
            }
            lastPayloadBytes = optimized.payloadBytes
            isPayloadOverLimit = optimized.isOverLimit
            isUltraSharpMode = optimized.isUltraSharpMode
        }

        // Chặn đẩy lên Đảo nếu quá ngưỡng an toàn để tránh lỗi khung xám
        if optimized.isOverLimit {
            await MainActor.run {
                overloadAlertMessage = "Tổng dữ liệu hiện tại là \(optimized.payloadBytes) / \(MyIslandAttributes.ContentState.hardPayloadLimit) bytes (vượt ngưỡng an toàn \(MyIslandAttributes.ContentState.safePayloadLimit) bytes).\n\nApp đã tạm chặn cập nhật để tránh lỗi khung xám trên Dynamic Island. Bạn hãy tắt bớt Checklist/Phím tắt App hoặc rút ngắn nội dung chữ rồi thử lại."
                showingOverloadAlert = true
                statusMessage = "Đã chặn cập nhật do quá tải (\(optimized.payloadBytes)/4096 B)."
            }
            return
        }

        let content = ActivityContent(state: optimized.state, staleDate: nil)
        let modeLabel = optimized.isUltraSharpMode ? "Siêu nét" : "Tiêu chuẩn"
        let summarySuffix = iconSource == .photo && optimized.imageSide > 0
            ? " (\(modeLabel) \(optimized.imageSide)×\(optimized.imageSide)px • \(optimized.imageBytes) B • Gói \(optimized.payloadBytes)/4096 B)"
            : " (Gói \(optimized.payloadBytes)/4096 B)"

        if let existingActivity = Activity<MyIslandAttributes>.activities.first {
            await existingActivity.update(content)
            await MainActor.run {
                statusMessage = "Đã cập nhật Dynamic Island!\(summarySuffix)"
            }
        } else {
            do {
                let attributes = MyIslandAttributes()
                let _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
                await MainActor.run {
                    statusMessage = "Đã bật Dynamic Island thành công!\(summarySuffix)"
                }
            } catch {
                await MainActor.run {
                    statusMessage = "Lỗi: \(error.localizedDescription)"
                }
            }
        }
    }

    func stopAllActivities() async {
        for activity in Activity<MyIslandAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        await MainActor.run {
            statusMessage = "Đã tắt Dynamic Island."
        }
    }

    func fetchWeather() async {
        await MainActor.run {
            isLoadingWeather = true
            weatherStatus = "Đang tìm \(cityName)..."
        }

        let trimmedCity = cityName.trimmingCharacters(in: .whitespacesAndNewlines)
        var geoComponents = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")
        geoComponents?.queryItems = [
            URLQueryItem(name: "name", value: trimmedCity.isEmpty ? "Hanoi" : trimmedCity),
            URLQueryItem(name: "count", value: "1"),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let geoURL = geoComponents?.url else {
            await MainActor.run {
                isLoadingWeather = false
                weatherStatus = "Tên thành phố không hợp lệ."
            }
            return
        }

        do {
            let (geoData, _) = try await URLSession.shared.data(from: geoURL)
            let geoResult = try JSONDecoder().decode(GeoResponse.self, from: geoData)
            guard let place = geoResult.results?.first else {
                await MainActor.run {
                    isLoadingWeather = false
                    weatherStatus = "Không tìm thấy thành phố '\(trimmedCity)'."
                }
                return
            }

            var weatherComponents = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
            weatherComponents?.queryItems = [
                URLQueryItem(name: "latitude", value: "\(place.latitude)"),
                URLQueryItem(name: "longitude", value: "\(place.longitude)"),
                URLQueryItem(name: "current", value: "temperature_2m"),
                URLQueryItem(name: "timezone", value: "auto")
            ]
            guard let weatherURL = weatherComponents?.url else { return }

            let (wData, _) = try await URLSession.shared.data(from: weatherURL)
            let wResult = try JSONDecoder().decode(WeatherResponse.self, from: wData)
            let temp = Int(round(wResult.current.temperature_2m))

            await MainActor.run {
                weatherInfo = "\(temp)°C"
                expandedTitle = "\(place.name): \(temp)°C"
                isLoadingWeather = false
                weatherStatus = "Đã cập nhật \(place.name): \(temp)°C"
                recalculatePayloadAndPhoto()
                saveLastConfig()
            }

            if Activity<MyIslandAttributes>.activities.first != nil {
                await startOrUpdateActivity()
            }
        } catch {
            await MainActor.run {
                isLoadingWeather = false
                weatherStatus = "Lỗi mạng: \(error.localizedDescription)"
            }
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
        let borderColor = state.useKeyline
            ? Color(hex: state.keylineColorHex)
            : Color(hex: state.bgColorHex).opacity(0.8)

        VStack(spacing: 6) {
            Group {
                if isExpanded {
                    VStack(spacing: 8) {
                        HStack {
                            previewIcon(size: 28, color: iconColor)
                                .padding(4)
                                .background(previewOuterPill)
                            Spacer()
                            HStack(spacing: 5) {
                                previewMetric(color: textColor, compact: false)
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(previewOuterPill)
                        }

                        VStack(spacing: 7) {
                            VStack(spacing: 2) {
                                Text(state.expandedTitle.isEmpty ? "Hoàng Linh's Island Studio" : state.expandedTitle)
                                    .font(.system(.subheadline, design: state.fontStyle.design).bold())
                                    .foregroundColor(textColor)
                                    .lineLimit(1)
                                Text(state.expandedSubtitle)
                                    .font(.system(.caption2, design: state.fontStyle.design))
                                    .foregroundColor(.white.opacity(0.82))
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)

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

                            if state.showTodos {
                                let activeTodos = state.todos.filter { !$0.title.trimmingCharacters(in: .whitespaces).isEmpty }
                                if !activeTodos.isEmpty {
                                    VStack(alignment: .leading, spacing: 3) {
                                        ForEach(activeTodos.prefix(3)) { todo in
                                            HStack(spacing: 6) {
                                                Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
                                                    .font(.caption2)
                                                    .foregroundColor(todo.isDone ? iconColor : .white.opacity(0.75))
                                                Text(todo.title)
                                                    .font(.system(.caption2, design: state.fontStyle.design))
                                                    .strikethrough(todo.isDone)
                                                    .foregroundColor(todo.isDone ? .white.opacity(0.45) : .white)
                                                    .lineLimit(1)
                                                Spacer()
                                            }
                                        }
                                    }
                                    .padding(6)
                                    .background(Color.white.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }

                            if state.showCounter || state.showLauncher {
                                HStack(spacing: 6) {
                                    if state.showCounter {
                                        HStack(spacing: 6) {
                                            Image(systemName: "minus.circle.fill").foregroundColor(.white.opacity(0.75))
                                            Text("\(state.counter)")
                                                .font(.system(.caption, design: .monospaced).bold())
                                                .foregroundColor(textColor)
                                            Image(systemName: "plus.circle.fill").foregroundColor(iconColor)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.14))
                                        .clipShape(Capsule())
                                    }

                                    if state.showLauncher {
                                        HStack(spacing: 5) {
                                            ForEach(state.shortcuts.prefix(4)) { item in
                                                VStack(spacing: 2) {
                                                    Image(systemName: item.icon)
                                                        .font(.caption2)
                                                        .foregroundColor(iconColor)
                                                    Text(item.name)
                                                        .font(.system(size: 8))
                                                        .foregroundColor(.white.opacity(0.92))
                                                        .lineLimit(1)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 4)
                                                .background(Color.white.opacity(0.14))
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(previewPanelBackground)
                    }
                    .padding(12)
                    .frame(maxWidth: 340)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(borderColor, lineWidth: state.useKeyline ? 1.5 : 1)
                    )
                    .shadow(color: borderColor.opacity(0.45), radius: 10)
                } else {
                    HStack {
                        previewIcon(size: 20, color: iconColor)
                        Spacer()
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 12, height: 12)
                        Spacer()
                        previewMetric(color: textColor, compact: true)
                    }
                    .padding(.horizontal, 14)
                    .frame(width: 215, height: 36)
                    .background(Color.black)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(borderColor, lineWidth: state.useKeyline ? 1.5 : 1)
                    )
                    .shadow(color: borderColor.opacity(0.5), radius: 8)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
            .onTapGesture {
                isExpanded.toggle()
            }

            Text(isExpanded ? "Chạm vào Đảo để thu gọn preview" : "Chạm vào Đảo để xem trước Liquid Glass mở rộng")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemGroupedBackground))
    }

    @ViewBuilder
    var previewOuterPill: some View {
        let c1 = Color(hex: state.bgColorHex)
        let c2 = Color(hex: state.bgColor2Hex)
        switch state.bgStyle {
        case .glass:
            Capsule()
                .fill(LinearGradient(colors: [c1.opacity(0.48), c2.opacity(0.30)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    Capsule().strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.72), .white.opacity(0.14), .white.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 0.85
                    )
                )
        case .solid:
            Capsule().fill(c1.opacity(0.92))
        case .gradient:
            Capsule().fill(LinearGradient(colors: [c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
    }

    @ViewBuilder
    var previewPanelBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        let c1 = Color(hex: state.bgColorHex)
        let c2 = Color(hex: state.bgColor2Hex)
        switch state.bgStyle {
        case .solid:
            shape.fill(c1)
        case .gradient:
            shape.fill(LinearGradient(colors: [c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .glass:
            ZStack {
                shape.fill(LinearGradient(colors: [c1.opacity(0.54), c2.opacity(0.34)], startPoint: .topLeading, endPoint: .bottomTrailing))
                shape.fill(LinearGradient(colors: [.white.opacity(0.30), .white.opacity(0.06), .clear, c2.opacity(0.20)], startPoint: .topLeading, endPoint: .bottomTrailing))
                shape.strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.78), c1.opacity(0.55), .white.opacity(0.10), .white.opacity(0.48)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1.0
                )
            }
        }
    }

    @ViewBuilder
    func previewIcon(size: CGFloat, color: Color) -> some View {
        switch state.iconSource {
        case .photo:
            if let data = state.customImageData, let uiImg = UIImage(data: data) {
                if state.photoIsCircle {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                } else {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: size * 0.25))
                }
            } else {
                Image(systemName: "photo.fill")
                    .font(.system(size: size * 0.7))
                    .foregroundColor(color)
            }
        case .emoji:
            Text(state.emojiText.isEmpty ? "✨" : state.emojiText)
                .font(.system(size: size * 0.85))
        case .symbol:
            Image(systemName: state.iconName)
                .font(.system(size: size * 0.78))
                .foregroundColor(color)
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
        case .stopwatch:
            Text("00:15").font(font).foregroundColor(color)
        case .battery:
            HStack(spacing: 3) {
                if state.isCharging {
                    Image(systemName: "bolt.fill").font(.caption2).foregroundColor(.green)
                }
                Text("\(state.batteryLevel)%")
                    .font(font)
                    .foregroundColor(state.batteryLevel <= 20 && !state.isCharging ? .red : .green)
            }
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
    let current: CurrentWeather
}

struct CurrentWeather: Decodable {
    let temperature_2m: Double
}