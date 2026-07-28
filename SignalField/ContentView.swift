import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var monitor: SignalMonitor

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    overview
                    signalCard(title: "Wi‑Fi", icon: "wifi", accent: Color(red: 0.09, green: 0.36, blue: 0.33)) {
                        HStack(alignment: .lastTextBaseline) {
                            Text(monitor.wifi.quality > 0 ? "\(monitor.wifi.quality)" : "—")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                            Text(monitor.wifi.quality > 0 ? "%" : "")
                                .font(.headline).foregroundStyle(.secondary)
                        }
                        Text(monitor.wifi.ssid).font(.headline)
                        Text("\(monitor.wifi.status) · \(monitor.wifi.detail)").font(.caption).foregroundStyle(.secondary)
                        Gauge(value: Double(monitor.wifi.quality), in: 0...100) { } currentValueLabel: { Text("\(monitor.wifi.quality)%") }
                            .tint(.green)
                    }
                    signalCard(title: "Cellular", icon: "antenna.radiowaves.left.and.right", accent: Color.orange) {
                        HStack(alignment: .lastTextBaseline, spacing: 10) {
                            Text(monitor.cellular.radio).font(.system(size: 44, weight: .bold, design: .rounded))
                            Text(monitor.cellular.is5G ? "LIVE" : "RADIO").font(.caption.weight(.bold)).foregroundStyle(monitor.cellular.is5G ? .green : .secondary)
                        }
                        Text(monitor.cellular.detail).font(.headline)
                        Text("Apple does not expose raw 5G dBm/RSRP to third-party apps.").font(.caption).foregroundStyle(.secondary)
                    }
                    coveragePreview
                    if monitor.locationDenied { permissionNotice }
                    Text("Updated \(monitor.updatedAt, style: .time) · readings stay on this iPhone")
                        .font(.caption2).foregroundStyle(.secondary)
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
        VStack(alignment: .leading, spacing: 7) {
            Text("SIGNAL OVERVIEW").font(.caption2.monospaced().weight(.medium)).tracking(1.3).foregroundStyle(.secondary)
            Text("Know where your connection works.").font(.system(size: 34, weight: .bold, design: .rounded)).tracking(-1.2)
            Text("Pull down to refresh the live radio status.").font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private var overview: some View {
        HStack(spacing: 12) {
            metric(title: "WI‑FI", value: monitor.wifi.quality > 0 ? "\(monitor.wifi.quality)%" : "—", detail: "quality")
            metric(title: "CELLULAR", value: monitor.cellular.radio, detail: monitor.cellular.is5G ? "5G detected" : "radio")
        }
    }

    private func metric(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) { Text(title).font(.caption2.monospaced()).foregroundStyle(.secondary); Text(value).font(.title2.bold()); Text(detail).font(.caption).foregroundStyle(.secondary) }
            .frame(maxWidth: .infinity, alignment: .leading).padding(16).background(.background).clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func signalCard<Content: View>(title: String, icon: String, accent: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon).font(.headline).foregroundStyle(accent)
            content()
        }
        .padding(18).background(.background).clipShape(RoundedRectangle(cornerRadius: 16)).shadow(color: .black.opacity(0.04), radius: 8, y: 3)
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
                HStack(spacing: 44) { point(0.92, .green); point(0.72, .green); point(0.42, .orange); point(0.58, .yellow) }
            }.frame(height: 140)
            Text("The native version reads the current radio. Add walk-test points in the PWA for full floorplan coverage.").font(.caption).foregroundStyle(.secondary)
        }
        .padding(18).background(.background).clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func point(_ value: Double, _ color: Color) -> some View {
        Circle().fill(color).frame(width: 34, height: 34).overlay(Text("\(Int(value * 100))").font(.caption2.bold()).foregroundStyle(.white)).shadow(radius: 3)
    }

    private var permissionNotice: some View {
        Label("Location permission is required for the current Wi‑Fi network. Enable it in Settings → Signal Field → Location.", systemImage: "location.slash")
            .font(.caption).foregroundStyle(.orange).padding(14).background(.orange.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview { ContentView().environmentObject(SignalMonitor()) }
