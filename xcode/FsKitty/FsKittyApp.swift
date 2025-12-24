import SwiftUI

@main
struct FsKittyApp: App {
    init() {
        // Register the embedded extension on app launch
        registerExtension()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private func registerExtension() {
        guard let appBundle = Bundle.main.bundleURL as URL?,
              let extensionURL = Bundle.main.builtInPlugInsURL?.appendingPathComponent("FsKittyExt.appex") else {
            print("Could not find extension bundle")
            return
        }

        // Check if extension exists
        guard FileManager.default.fileExists(atPath: extensionURL.path) else {
            print("Extension not found at: \(extensionURL.path)")
            return
        }

        // Use pluginkit to register the extension
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
        task.arguments = ["-a", extensionURL.path]

        do {
            try task.run()
            task.waitUntilExit()
            if task.terminationStatus == 0 {
                print("Extension registered successfully")
            } else {
                print("Extension registration returned status: \(task.terminationStatus)")
            }
        } catch {
            print("Failed to register extension: \(error)")
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "externaldrive.connected.to.line.below")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("FsKitty")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("FSKit File System Extension")
                .font(.headline)
                .foregroundColor(.secondary)

            Divider()
                .padding(.horizontal, 40)

            VStack(alignment: .leading, spacing: 12) {
                Text("To enable the file system extension:")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(alignment: .top, spacing: 8) {
                    Text("1.")
                        .foregroundColor(.secondary)
                    Text("Open System Settings")
                }

                HStack(alignment: .top, spacing: 8) {
                    Text("2.")
                        .foregroundColor(.secondary)
                    Text("Go to General → Login Items & Extensions")
                }

                HStack(alignment: .top, spacing: 8) {
                    Text("3.")
                        .foregroundColor(.secondary)
                    Text("Enable \"fskitty\" under File System Extensions")
                }
            }
            .font(.subheadline)
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)

            Spacer()

            Text("Server: 127.0.0.1:10001")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(40)
        .frame(minWidth: 400, minHeight: 400)
    }
}
