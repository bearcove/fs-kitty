import SwiftUI

@main
struct FsKittyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
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
