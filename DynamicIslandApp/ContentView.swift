import SwiftUI
import ActivityKit

struct ContentView: View {
    @State private var mode: IslandDisplayMode = .text
    @State private var compactText: String = "DEV"
    @State private var expandedTitle: String = "Hoàng Linh"
    @State private var expandedSubtitle: String = "Nguyễn Bố Mày aka Hoàng Linh"
    
    @State private var selectedIcon: String = "terminal.fill"
    @State private var iconColor: Color = .green
    @State private var textColor: Color = .cyan
    
    @State private var cityName: String = "Hanoi"
    @State private var weatherInfo: String = "26°C"
    @State private var isLoadingWeather: Bool = false
    @State private var statusMessage: String = ""
    
    let presetIcons = [
        "terminal.fill", "flame.fill", "bolt.fill", "star.fill", "heart.fill",
        "gamecontroller.fill", "crown.fill", "moon.stars.fill", "sun.max.fill", "cloud.rain.fill",
        "headphones", "music.note", "sparkles", "pawprint.fill", "car.fill",
        "bicycle", "airplane", "battery.100", "clock.fill", "wifi"
    ]
    
    let columns = [GridItem(.adaptive(minimum: 42))]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Chế độ góc phải Đảo động")) {
                    Picker("Chế độ", selection: $mode) {
                        ForEach(IslandDisplayMode.allCases, id: \.self) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                if mode == .weather {
                    Section(header: Text("Cấu hình Thời tiết (Open-Meteo)")) {
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
                        Text("Hiển thị hiện tại: \(weatherInfo)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Nội dung chữ hiển thị")) {
                    if mode == .text {
                        TextField("Chữ góc phải (ngắn < 6 ký tự)", text: $compactText)
                    }
                    TextField("Tiêu đề khi mở rộng Đảo", text: $expandedTitle)
                    TextField("Dòng phụ khi mở rộng Đảo", text: $expandedSubtitle)
                }
                
                Section(header: Text("Chọn Icon (SF Symbols)")) {
                    LazyVGrid(columns: columns, spacing: 12) {
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
                    .padding(.vertical, 6)
                    
                    TextField("Hoặc tự gõ tên SF Symbol...", text: $selectedIcon)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section(header: Text("Tùy chỉnh màu sắc")) {
                    ColorPicker("Màu Icon", selection: $iconColor, supportsOpacity: false)
                    ColorPicker("Màu Chữ / Đồng hồ", selection: $textColor, supportsOpacity: false)
                }
                
                Section {
                    Button(action: {
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
            .navigationTitle("Island Studio")
        }
    }
    
    func startOrUpdateActivity() async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            statusMessage = "Bạn chưa bật quyền Live Activities trong Cài đặt iPhone."
            return
        }
        
        let state = MyIslandAttributes.ContentState(
            compactText: compactText,
            expandedTitle: expandedTitle,
            expandedSubtitle: expandedSubtitle,
            iconName: selectedIcon,
            iconColorHex: iconColor.toHex(),
            textColorHex: textColor.toHex(),
            mode: mode,
            weatherInfo: weatherInfo
        )
        let content = ActivityContent(state: state, staleDate: nil)
        
        // Nếu đã có Đảo đang chạy thì cập nhật trực tiếp thay vì tạo mới
        if let existingActivity = Activity<MyIslandAttributes>.activities.first {
            await existingActivity.update(content)
            statusMessage = "Đã cập nhật giao diện mới lên Dynamic Island!"
        } else {
            do {
                let attributes = MyIslandAttributes()
                let _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
                statusMessage = "Đã đẩy lên Dynamic Island thành công!"
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
            
            let weatherURLString = "https://api.open-meteo.com/v1/forecast?latitude=\(place.latitude)&longitude=\(place.longitude)&current_weather=true"
            guard let weatherURL = URL(string: weatherURLString) else { return }
            
            let (wData, _) = try await URLSession.shared.data(from: weatherURL)
            let wResult = try JSONDecoder().decode(WeatherResponse.self, from: wData)
            let temp = Int(round(wResult.current_weather.temperature))
            
            weatherInfo = "\(temp)°C"
            expandedTitle = "\(place.name): \(temp)°C"
            statusMessage = "Đã lấy thời tiết \(place.name) (\(temp)°C). Bấm Cập nhật để đẩy lên Đảo!"
        } catch {
            statusMessage = "Lỗi lấy thời tiết: \(error.localizedDescription)"
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