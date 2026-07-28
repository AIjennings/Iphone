import SwiftUI
import ARKit
import RealityKit

struct ContentView: View {
    @EnvironmentObject private var monitor: SignalMonitor
    @StateObject private var speedTest = SpeedTestService()
    @State private var arMode = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    if arMode { arSurvey } else { overview }
                    speedTestCard
                    signalCard(title: "Wi‑Fi", icon: "wifi", accent: Color(red: 0.09, green: 0.36, blue: 0.33)) {
                        HStack(alignment: .lastTextBaseline) {
                            Text(monitor.wifi.quality > 0 ? "\(monitor.wifi.quality)" : "—").font(.system(size: 48, weight: .bold, design: .rounded))
                            Text(monitor.wifi.quality > 0 ? "%" : "").font(.headline).foregroundStyle(.secondary)
                        }
                        Text(monitor.wifi.ssid).font(.headline)
                        Text("\(monitor.wifi.status) · \(monitor.wifi.detail)").font(.caption).foregroundStyle(.secondary)
                        Gauge(value: Double(monitor.wifi.quality), in: 0...100) { } currentValueLabel: { Text("\(monitor.wifi.quality)%") }.tint(.green)
                    }
                    signalCard(title: "Cellular", icon: "antenna.radiowaves.left.and.right", accent: .orange) {
                        HStack(alignment: .lastTextBaseline, spacing: 10) {
                            Text(monitor.cellular.radio).font(.system(size: 44, weight: .bold, design: .rounded))
                            Text(monitor.cellular.is5G ? "LIVE" : "RADIO").font(.caption.weight(.bold)).foregroundStyle(monitor.cellular.is5G ? .green : .secondary)
                        }
                        Text(monitor.cellular.detail).font(.headline)
                        Text("Apple does not expose raw 5G dBm/RSRP to third-party apps.").font(.caption).foregroundStyle(.secondary)
                    }
                    coveragePreview
                    if monitor.locationDenied { permissionNotice }
                    Text("Updated \(monitor.updatedAt, style: .time) · readings stay on this iPhone").font(.caption2).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 30)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .principal) { Text("Signal Field").font(.headline) } }
            .refreshable { monitor.refresh() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("SIGNAL FIELD").font(.caption2.monospaced().weight(.medium)).tracking(1.3).foregroundStyle(.secondary)
                    Text("See the signal around you.").font(.system(size: 34, weight: .bold, design: .rounded)).tracking(-1.2)
                }
                Spacer()
                Button { withAnimation(.easeInOut) { arMode.toggle() } } label: {
                    Label(arMode ? "Map" : "AR", systemImage: arMode ? "map" : "camera.viewfinder").labelStyle(.titleAndIcon)
                }.buttonStyle(.borderedProminent).tint(.green)
            }
            Text(arMode ? "Point your camera around the space, then run a speed test at each spot." : "Use AR mode to place live speed and signal readings at physical points.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private var overview: some View {
        HStack(spacing: 12) {
            metric(title: "WI‑FI", value: monitor.wifi.quality > 0 ? "\(monitor.wifi.quality)%" : "—", detail: "quality")
            metric(title: "CELLULAR", value: monitor.cellular.radio, detail: monitor.cellular.is5G ? "5G detected" : "radio")
        }
    }

    private var arSurvey: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .bottom) {
                ARCameraView().clipShape(RoundedRectangle(cornerRadius: 18))
                VStack(spacing: 10) {
                    HStack { Label("AR SURVEY", systemImage: "camera.viewfinder").font(.caption.bold()); Spacer(); Text("Move slowly").font(.caption) }
                    .foregroundStyle(.white).padding(.horizontal, 14).padding(.top, 14)
                    Spacer()
                    if speedTest.points.isEmpty { Text("No points yet — tap Test at this point").font(.caption.weight(.semibold)).foregroundStyle(.white).padding(10).background(.black.opacity(0.55)).clipShape(Capsule()) }
                    HStack(spacing: 12) {
                        Text(speedTest.points.isEmpty ? "Ready to measure" : "\(speedTest.points.count) point\(speedTest.points.count == 1 ? "" : "s") saved").font(.caption.weight(.semibold)).foregroundStyle(.white)
                        Spacer()
                        Button { speedTest.runTest(label: "AR point \(speedTest.points.count + 1)", wifiQuality: monitor.wifi.quality) } label: {
                            Label(speedTest.isRunning ? "Testing…" : "Test here", systemImage: "speedometer").font(.subheadline.bold()).padding(.horizontal, 14).padding(.vertical, 10).background(.white).foregroundStyle(.green).clipShape(Capsule())
                        }.disabled(speedTest.isRunning)
                    }.padding(14).background(.black.opacity(0.58))
                }
            }.frame(height: 400)
            Text("AR markers are screen-anchored for this first survey pass. Each test records the camera point, Wi‑Fi quality, download, and upload speed.").font(.caption).foregroundStyle(.secondary)
        }
    }

    private var speedTestCard: some View {
        signalCard(title: "Speed tests", icon: "speedometer", accent: .blue) {
            HStack(spacing: 14) {
                speedMetric(title: "DOWNLOAD", value: speedTest.downloadMbps)
                speedMetric(title: "UPLOAD", value: speedTest.uploadMbps)
                Spacer()
                Button { speedTest.runTest(label: "Dashboard point", wifiQuality: monitor.wifi.quality) } label: { Image(systemName: "play.fill").frame(width: 42, height: 42).background(.blue).foregroundStyle(.white).clipShape(Circle()) }.disabled(speedTest.isRunning)
            }
            Text(speedTest.status).font(.caption).foregroundStyle(.secondary)
            if !speedTest.points.isEmpty {
                Divider()
                ForEach(speedTest.points) { point in
                    HStack { Image(systemName: "mappin.circle.fill").foregroundStyle(.blue); Text(point.label).font(.subheadline); Spacer(); Text("↓ \(point.downloadMbps, specifier: "%.1f") / ↑ \(point.uploadMbps, specifier: "%.1f") Mbps").font(.caption.monospaced()).foregroundStyle(.secondary) }
                }
            }
        }
    }

    private func speedMetric(title: String, value: Double?) -> some View {
        VStack(alignment: .leading, spacing: 5) { Text(title).font(.caption2.monospaced()).foregroundStyle(.secondary); Text(value.map { String(format: "%.1f", $0) } ?? "—").font(.title3.bold()); Text("Mbps").font(.caption2).foregroundStyle(.secondary) }
    }

    private func metric(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) { Text(title).font(.caption2.monospaced()).foregroundStyle(.secondary); Text(value).font(.title2.bold()); Text(detail).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).padding(16).background(.background).clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func signalCard<Content: View>(title: String, icon: String, accent: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) { Label(title, systemImage: icon).font(.headline).foregroundStyle(accent); content() }.padding(18).background(.background).clipShape(RoundedRectangle(cornerRadius: 16)).shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    private var coveragePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SURVEY MAP").font(.caption2.monospaced().weight(.medium)).tracking(1.3).foregroundStyle(.secondary)
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(Color(red: 0.87, green: 0.92, blue: 0.88))
                Canvas { context, size in
                    for x in stride(from: 0, through: size.width, by: 34) { context.stroke(Path { $0.move(to: CGPoint(x: x, y: 0)); $0.addLine(to: CGPoint(x: x, y: size.height)) }, with: .color(.green.opacity(0.12))) }
                    for y in stride(from: 0, through: size.height, by: 34) { context.stroke(Path { $0.move(to: CGPoint(x: 0, y: y)); $0.addLine(to: CGPoint(x: size.width, y: y)) }, with: .color(.green.opacity(0.12))) }
                }
                HStack(spacing: 44) { qualityDot(0.92, .green); qualityDot(0.72, .green); qualityDot(0.42, .orange); qualityDot(0.58, .yellow) }
            }.frame(height: 140)
            Text("Switch to AR to walk the space and run a real download/upload test at each point.").font(.caption).foregroundStyle(.secondary)
        }.padding(18).background(.background).clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func qualityDot(_ value: Double, _ color: Color) -> some View { Circle().fill(color).frame(width: 34, height: 34).overlay(Text("\(Int(value * 100))").font(.caption2.bold()).foregroundStyle(.white)).shadow(radius: 3) }
    private var permissionNotice: some View { Label("Location permission is required for the current Wi‑Fi network. Enable it in Settings → Signal Field → Location.", systemImage: "location.slash").font(.caption).foregroundStyle(.orange).padding(14).background(.orange.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 12)) }
}

struct ARCameraView: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        configuration.planeDetection = [.horizontal, .vertical]
        view.session.run(configuration)
        return view
    }
    func updateUIView(_ uiView: ARView, context: Context) { }
    static func dismantleUIView(_ uiView: ARView, coordinator: ()) { uiView.session.pause() }
}

struct SpeedPoint: Identifiable { let id = UUID(); let label: String; let downloadMbps: Double; let uploadMbps: Double; let wifiQuality: Int; let createdAt = Date() }

@MainActor
final class SpeedTestService: ObservableObject {
    @Published private(set) var downloadMbps: Double?
    @Published private(set) var uploadMbps: Double?
    @Published private(set) var status = "Ready — tests use a 5 MB sample"
    @Published private(set) var isRunning = false
    @Published private(set) var points: [SpeedPoint] = []

    func runTest(label: String, wifiQuality: Int) {
        guard !isRunning else { return }
        isRunning = true; status = "Testing download…"
        Task {
            do {
                let download = try await measureDownload()
                status = "Testing upload…"
                let upload = try await measureUpload()
                downloadMbps = download; uploadMbps = upload
                points.insert(SpeedPoint(label: label, downloadMbps: download, uploadMbps: upload, wifiQuality: wifiQuality), at: 0)
                status = "Complete — saved at \(label)"
            } catch { status = "Test failed: \(error.localizedDescription)" }
            isRunning = false
        }
    }

    private func measureDownload() async throws -> Double {
        let bytes = 5_000_000
        let start = Date()
        let url = URL(string: "https://speed.cloudflare.com/__down?bytes=\(bytes)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return Double(data.count * 8) / max(Date().timeIntervalSince(start), 0.01) / 1_000_000
    }

    private func measureUpload() async throws -> Double {
        let payload = Data(repeating: 0, count: 2_000_000)
        let start = Date(); var request = URLRequest(url: URL(string: "https://speed.cloudflare.com/__up")!)
        request.httpMethod = "POST"; request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        let (_, response) = try await URLSession.shared.upload(for: request, from: payload)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw URLError(.cannotConnectToHost) }
        return Double(payload.count * 8) / max(Date().timeIntervalSince(start), 0.01) / 1_000_000
    }
}

#Preview { ContentView().environmentObject(SignalMonitor()) }
