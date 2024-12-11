import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsModel

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sighting Settings")) {
                    // Toggle for Show Visible Only
                    Toggle(isOn: $viewModel.showVisibleOnly, label: {
                        Text("Show Visible Only")
                    })
                    
                    VStack {
                        Slider(value: $viewModel.twilightAngle, in: -18...0, step: 0.1) {
                            Text("Text Size")
                        }
                        Text("Twilight Angle: \(String(format: "%.1f", viewModel.twilightAngle))°")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    HStack {
                        Text("Prediction Days")
                        Picker("Select Prediction Days", selection: $viewModel.predictionDays) {
                            ForEach(1..<11) { day in
                                Text("\(day)").tag(day)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 100)
                    }
                }
                
                Button(action: {
                    viewModel.resetSightingSettings()
                }) {
                    Text("Reset to Default")
                        .foregroundColor(.red) // Puedes darle el color que prefieras
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                Section(header: Text("Appearance")) {
                    Picker("Appearance Mode", selection: $viewModel.appearanceMode) {
                        Text("Automatic").tag(AppearanceMode.automatic)
                        Text("Light").tag(AppearanceMode.light)
                        Text("Dark").tag(AppearanceMode.dark)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Language")) {
                    Picker("Language", selection: $viewModel.language) {
                        Text("English").tag("English")
                        Text("Spanish").tag("Spanish")
                        // Add more languages as needed
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Notifications")) {
                    Toggle(isOn: $viewModel.notificationsEnabled, label: {
                        Text("Enable Notifications")
                    })
                }
            }
            .navigationTitle("Settings")
        }
        .preferredColorScheme(colorScheme(from: viewModel.appearanceMode))
    }

    private func colorScheme(from appearanceMode: AppearanceMode) -> ColorScheme? {
        switch appearanceMode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .automatic:
            return nil
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    @State static private var settingsModel = SettingsModel()

    static var previews: some View {
        SettingsView(viewModel: settingsModel)
    }
}
