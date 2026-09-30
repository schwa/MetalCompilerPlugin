import SwiftUI
import ShadersA
import ShadersB

@main
struct HostApp: App {
    var body: some Scene {
        WindowGroup {
            Text("swiftSeesDebugDefine: \(ShadersA.swiftSeesDebugDefine)")
        }
    }
}
