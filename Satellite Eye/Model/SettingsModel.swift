import Foundation
import SwiftUI

enum AppearanceMode: String {
    case light, dark, automatic
}

class SettingsModel: ObservableObject {
    @Published var showVisibleOnly: Bool {
        didSet {
            UserDefaults.standard.set(showVisibleOnly, forKey: "showVisibleOnly")
        }
    }

    @Published var appearanceMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode")
        }
    }

    @Published var twilightAngle: Double { // Nuevo campo para el ángulo del crepúsculo
        didSet {
            UserDefaults.standard.set(twilightAngle, forKey: "twilightAngle")
        }
    }
    
    @Published var predictionDays: Int { // Días de predicción (nuevo campo)
        didSet {
            UserDefaults.standard.set(predictionDays, forKey: "predictionDays")
        }
    }

    @Published var language: String {
        didSet {
            UserDefaults.standard.set(language, forKey: "language")
        }
    }

    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }
    func resetSightingSettings() {
        self.showVisibleOnly = true
        self.predictionDays = 7
        self.twilightAngle = 0
    }

    init() {
        self.showVisibleOnly = UserDefaults.standard.bool(forKey: "showVisibleOnly")
        let appearanceModeRawValue = UserDefaults.standard.string(forKey: "appearanceMode") ?? AppearanceMode.automatic.rawValue
        self.appearanceMode = AppearanceMode(rawValue: appearanceModeRawValue) ?? .automatic
        let savedTwilightAngle = UserDefaults.standard.double(forKey: "twilightAngle")
        self.twilightAngle = savedTwilightAngle != 0 ? savedTwilightAngle : 0
        self.language = UserDefaults.standard.string(forKey: "language") ?? "English"
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        let savedPredictionDays = UserDefaults.standard.integer(forKey: "predictionDays")
        self.predictionDays = savedPredictionDays != 0 ? savedPredictionDays : 7
    }
}
