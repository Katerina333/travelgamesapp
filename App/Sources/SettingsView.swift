import SwiftUI
import DesignSystem

/// App settings — appearance and language (§4.4, §5.1). Presented as a sheet
/// from the home screen.
struct SettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LocaleManager.self) private var localeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    private var tokens: ThemeTokens { themeManager.tokens(systemDark: colorScheme == .dark) }

    var body: some View {
        NavigationStack {
            Form {
                Section("settings.appearance") {
                    Picker("settings.theme", selection: themeBinding) {
                        Text("settings.theme.auto").tag(ThemeMode.auto)
                        Text("settings.theme.light").tag(ThemeMode.light)
                        Text("settings.theme.night").tag(ThemeMode.night)
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Picker("settings.language", selection: languageBinding) {
                        ForEach(LocaleManager.languages, id: \.tag) { lang in
                            if lang.tag == LocaleManager.systemTag {
                                Text("settings.language.system").tag(lang.tag)
                            } else {
                                Text(verbatim: lang.name).tag(lang.tag)
                            }
                        }
                    }
                    .pickerStyle(.inline)
                    .accessibilityIdentifier("picker.language")
                } header: {
                    Text("settings.language")
                } footer: {
                    Text("settings.language.footer")
                }
            }
            .navigationTitle("settings.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") { dismiss() }
                        .accessibilityIdentifier("btn.settingsDone")
                }
            }
        }
    }

    private var themeBinding: Binding<ThemeMode> {
        Binding(get: { themeManager.mode }, set: { themeManager.mode = $0 })
    }

    private var languageBinding: Binding<String> {
        Binding(get: { localeManager.tag }, set: { localeManager.tag = $0 })
    }
}
