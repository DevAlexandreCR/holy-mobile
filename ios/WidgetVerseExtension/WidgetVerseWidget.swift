import WidgetKit
import SwiftUI

// WidgetKit extension stub. Add this file to the Widget target in Xcode.
// Replace the App Group ID and key to match the Flutter/iOS shared storage contract.
private enum SharedConfig {
    // TODO: Replace with the real App Group ID configured in Apple Developer portal.
    static let appGroupId = "group.biblewidget.app"
    static let widgetVerseKey = "widgetVerse" // Must match Flutter channel.
}

private enum WidgetVersePlaceholder {
    static let message = "Abre Bible Widget para actualizar el versículo"

    static let sample = WidgetVerseModel(
        date: "2024-01-01",
        versionCode: "RVR1960",
        versionName: "Reina-Valera 1960",
        reference: "Juan 3:16",
        text: "Porque de tal manera amó Dios al mundo, que ha dado a su Hijo unigénito."
    )
}

struct WidgetVerseModel: Codable {
    let date: String
    let versionCode: String
    let versionName: String
    let reference: String
    let text: String

    enum CodingKeys: String, CodingKey {
        case date
        case versionCode = "version_code"
        case versionName = "version_name"
        case reference
        case text
        case camelVersionCode = "versionCode"
        case camelVersionName = "versionName"
    }

    init(
        date: String,
        versionCode: String,
        versionName: String,
        reference: String,
        text: String
    ) {
        self.date = date
        self.versionCode = versionCode
        self.versionName = versionName
        self.reference = reference
        self.text = text
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decodeIfPresent(String.self, forKey: .date) ?? ""
        versionCode = try container.decodeIfPresent(String.self, forKey: .versionCode)
            ?? container.decodeIfPresent(String.self, forKey: .camelVersionCode)
            ?? ""
        versionName = try container.decodeIfPresent(String.self, forKey: .versionName)
            ?? container.decodeIfPresent(String.self, forKey: .camelVersionName)
            ?? ""
        reference = try container.decodeIfPresent(String.self, forKey: .reference) ?? ""
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(versionCode, forKey: .versionCode)
        try container.encode(versionName, forKey: .versionName)
        try container.encode(reference, forKey: .reference)
        try container.encode(text, forKey: .text)
    }
}

struct WidgetVerseEntry: TimelineEntry {
    let date: Date
    let verse: WidgetVerseModel?
    let isPlaceholder: Bool
}

struct WidgetVerseProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetVerseEntry {
        WidgetVerseEntry(date: Date(), verse: nil, isPlaceholder: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetVerseEntry) -> Void) {
        let savedVerse = loadSavedVerse()
        let entry = WidgetVerseEntry(
            date: Date(),
            verse: savedVerse ?? WidgetVersePlaceholder.sample,
            isPlaceholder: savedVerse == nil
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetVerseEntry>) -> Void) {
        let savedVerse = loadSavedVerse()
        let entry = WidgetVerseEntry(
            date: Date(),
            verse: savedVerse,
            isPlaceholder: savedVerse == nil
        )
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 12, to: Date()) ?? Date().addingTimeInterval(12 * 3600)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private func loadSavedVerse() -> WidgetVerseModel? {
        guard
            let defaults = UserDefaults(suiteName: SharedConfig.appGroupId),
            let raw = defaults.string(forKey: SharedConfig.widgetVerseKey),
            let data = raw.data(using: .utf8)
        else { return nil }

        return try? JSONDecoder().decode(WidgetVerseModel.self, from: data)
    }
}

struct WidgetVerseView: View {
    @Environment(\.widgetFamily) private var family

    let entry: WidgetVerseEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 18/255, green: 26/255, blue: 42/255),
                    Color(red: 26/255, green: 41/255, blue: 64/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(alignment: .leading, spacing: 8) {
                if entry.isPlaceholder || entry.verse == nil {
                    Text(WidgetVersePlaceholder.message)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(0.9)
                        .accessibilityLabel("Widget sin datos, abre la app para sincronizar.")
                } else if let verse = entry.verse {
                    Text(verse.text)
                        .font(family == .systemSmall ? .headline : .title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(family == .systemSmall ? 4 : 6)
                        .minimumScaleFactor(0.9)
                        .accessibilityLabel("Versículo del día")

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text(verse.reference)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 244/255, green: 210/255, blue: 122/255))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text(verse.versionCode.uppercased())
                            .font(.caption)
                            .foregroundColor(Color(red: 126/255, green: 169/255, blue: 225/255))
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding()
        }
    }
}

struct WidgetVerseWidget: Widget {
    let kind: String = "WidgetVerse"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetVerseProvider()) { entry in
            WidgetVerseView(entry: entry)
        }
        .configurationDisplayName("Bible Widget")
        .description("Muestra el versículo del día según tu versión favorita.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct WidgetVerseBundle: WidgetBundle {
    var body: some Widget {
        WidgetVerseWidget()
    }
}

struct WidgetVerseWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WidgetVerseView(
                entry: WidgetVerseEntry(
                    date: Date(),
                    verse: WidgetVersePlaceholder.sample,
                    isPlaceholder: false
                )
            )
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            WidgetVerseView(
                entry: WidgetVerseEntry(
                    date: Date(),
                    verse: nil,
                    isPlaceholder: true
                )
            )
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}
