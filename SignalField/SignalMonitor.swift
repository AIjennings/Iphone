import Foundation
import Combine
import NetworkExtension
import CoreTelephony
import CoreLocation

@MainActor
final class SignalMonitor: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var wifi = WiFiReading()
    @Published private(set) var cellular = CellularReading()
    @Published private(set) var updatedAt = Date()
    @Published var locationDenied = false

    private let locationManager = CLLocationManager()
    private let telephony = CTTelephonyNetworkInfo()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        refresh()
    }

    func refresh() {
        updatedAt = Date()
        readCellular()
        guard CLLocationManager.locationServicesEnabled() else {
            locationDenied = true
            wifi = WiFiReading(status: "Location access needed", detail: "Enable Location Services to read the current Wi‑Fi network.")
            return
        }
        NEHotspotNetwork.fetchCurrent { [weak self] network in
            Task { @MainActor in
                guard let self else { return }
                if let network {
                    let quality = Int((network.signalStrength * 100).rounded())
                    self.wifi = WiFiReading(ssid: network.ssid, quality: quality, dbm: nil, status: "Connected", detail: network.isSecure ? "Secure network" : "Open network")
                } else {
                    self.wifi = WiFiReading(status: "Unavailable", detail: "iOS did not return the current Wi‑Fi network.")
                }
                self.updatedAt = Date()
            }
        }
    }

    private func readCellular() {
        let radio = telephony.serviceCurrentRadioAccessTechnology?.values.first
        let name: String
        let is5G: Bool
        switch radio {
        case CTRadioAccessTechnologyNR, CTRadioAccessTechnologyNRNSA:
            name = "5G"; is5G = true
        case CTRadioAccessTechnologyLTE:
            name = "LTE"; is5G = false
        case CTRadioAccessTechnologyWCDMA:
            name = "3G"; is5G = false
        default:
            name = radio == nil ? "Unavailable" : "Cellular"; is5G = false
        }
        cellular = CellularReading(radio: name, is5G: is5G, detail: is5G ? "5G radio detected" : "Current cellular radio")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationDenied = manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse { refresh() }
    }
}

struct WiFiReading {
    var ssid = "Not connected"
    var quality = 0
    var dbm: Int? = nil
    var status = "Waiting"
    var detail = "Current Wi‑Fi signal"
}

struct CellularReading {
    var radio = "Unavailable"
    var is5G = false
    var detail = "Current cellular radio"
}
