import SwiftUI
import ActivityKit

struct ContentView: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("App điều khiển Dynamic Island")
                .font(.headline)
            
            Button("Đẩy chữ lên Đảo") {
                startLiveActivity()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
    }
    
    func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = MyIslandAttributes()
        let state = MyIslandAttributes.ContentState(customText: "Hoàng Linh đang code!") 
        let content = ActivityContent(state: state, staleDate: nil)
        
        do {
            let _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
        } catch {
            print("Lỗi kích hoạt Dynamic Island: \(error.localizedDescription)")
        }
    }
}