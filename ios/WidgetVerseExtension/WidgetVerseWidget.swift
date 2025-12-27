import WidgetKit
import SwiftUI

// WidgetKit extension stub. Add this file to the Widget target in Xcode.
// Replace the App Group ID and key to match the Flutter/iOS shared storage contract.
private enum SharedConfig {
    static let appGroupId = "group.gorda.holyverso"
    static let widgetVerseKey = "widgetVerse" // Must match Flutter channel.
}

private enum HolyVersoColors {
    // Holy Gold
    static let holyGold = Color(red: 244/255, green: 210/255, blue: 122/255)
    // Midnight Faith
    static let midnightFaith = Color(red: 26/255, green: 41/255, blue: 64/255)
    static let midnightFaithDark = Color(red: 18/255, green: 26/255, blue: 42/255)
    // Pure White
    static let pureWhite = Color.white
    // Morning Light
    static let morningLight = Color(red: 126/255, green: 169/255, blue: 225/255)
}

private enum WidgetVersePlaceholder {
    static let message = "Abre HolyVerso para actualizar el versículo"

    static let sample = WidgetVerseModel(
        date: "2024-01-01",
        versionCode: "RVR1960",
        versionName: "Reina-Valera 1960",
        reference: "Juan 3:16",
        text: "Porque de tal manera amó Dios al mundo, que ha dado a su Hijo unigénito.",
        fontSize: 16.0
    )
}

struct WidgetVerseModel: Codable {
    let date: String
    let versionCode: String
    let versionName: String
    let reference: String
    let text: String
    let fontSize: Double

    enum CodingKeys: String, CodingKey {
        case date
        case versionCode = "version_code"
        case versionName = "version_name"
        case reference
        case text
        case fontSize = "font_size"
        case camelVersionCode = "versionCode"
        case camelVersionName = "versionName"
    }

    init(
        date: String,
        versionCode: String,
        versionName: String,
        reference: String,
        text: String,
        fontSize: Double = 16.0
    ) {
        self.date = date
        self.versionCode = versionCode
        self.versionName = versionName
        self.reference = reference
        self.text = text
        self.fontSize = fontSize
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
        fontSize = try container.decodeIfPresent(Double.self, forKey: .fontSize) ?? 16.0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(versionCode, forKey: .versionCode)
        try container.encode(versionName, forKey: .versionName)
        try container.encode(reference, forKey: .reference)
        try container.encode(text, forKey: .text)
        try container.encode(fontSize, forKey: .fontSize)
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
        Task {
            let now = Date()
            let calendar = Calendar.current
            
            var savedVerse = loadSavedVerse()
            var isPlaceholder = savedVerse == nil

            // Si no hay verso o es de otro día, intentar traerlo directo desde la API
            if savedVerse == nil || !isVerseCurrentDate(savedVerse) {
                if let latestVerse = await fetchLatestVerse(currentVerse: savedVerse) {
                    savedVerse = latestVerse
                    isPlaceholder = false
                }
            }

            let entry = WidgetVerseEntry(
                date: now,
                verse: savedVerse ?? WidgetVersePlaceholder.sample,
                isPlaceholder: isPlaceholder && savedVerse == nil
            )

            // Si no tenemos verso fresco, reintentar pronto; si lo tenemos, refrescar cada 6h
            let hoursUntilNextRefresh = (savedVerse == nil || !isVerseCurrentDate(savedVerse)) ? 1 : 6
            let nextRefresh = calendar.date(byAdding: .hour, value: hoursUntilNextRefresh, to: now)
                ?? now.addingTimeInterval(Double(hoursUntilNextRefresh) * 3600)
            
            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
        }
    }

    private func loadSavedVerse() -> WidgetVerseModel? {
        guard
            let defaults = UserDefaults(suiteName: SharedConfig.appGroupId),
            let raw = defaults.string(forKey: SharedConfig.widgetVerseKey),
            let data = raw.data(using: .utf8)
        else { 
            print("[Widget] No verse found in shared defaults")
            return nil 
        }

        let verse = try? JSONDecoder().decode(WidgetVerseModel.self, from: data)
        print("[Widget] Loaded verse with date: \(verse?.date ?? "nil")")
        return verse
    }

    private func fetchLatestVerse(currentVerse: WidgetVerseModel?) async -> WidgetVerseModel? {
        guard let defaults = UserDefaults(suiteName: SharedConfig.appGroupId) else {
            print("[Widget] App Group not configured")
            return nil
        }

        guard let jwtToken = defaults.string(forKey: "jwt_token"), !jwtToken.isEmpty else {
            print("[Widget] No JWT token available for fetch")
            return nil
        }

        let apiUrl = defaults.string(forKey: "api_url") ?? "https://api.holyverso.com"
        guard let url = URL(string: "\(apiUrl)/verse/today") else {
            print("[Widget] Invalid API URL: \(apiUrl)")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200 ... 299).contains(httpResponse.statusCode) else {
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("[Widget] HTTP error while fetching verse: \(status)")
                return nil
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("[Widget] Invalid JSON payload for verse")
                return nil
            }

            let verseData = (json["data"] as? [String: Any]) ?? json
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let today = dateFormatter.string(from: Date())
            let fontSize = currentVerse?.fontSize ?? 16.0

            let verse = WidgetVerseModel(
                date: today,
                versionCode: verseData["version_code"] as? String
                    ?? verseData["versionCode"] as? String
                    ?? "",
                versionName: verseData["version_name"] as? String
                    ?? verseData["versionName"] as? String
                    ?? "",
                reference: verseData["reference"] as? String ?? "",
                text: verseData["text"] as? String ?? "",
                fontSize: fontSize
            )

            saveVerseToSharedDefaults(verse, defaults: defaults)
            print("[Widget] Verse fetched directly from API: \(verse.reference)")
            return verse
        } catch {
            print("[Widget] Failed to fetch verse: \(error)")
            return nil
        }
    }

    private func saveVerseToSharedDefaults(
        _ verse: WidgetVerseModel,
        defaults: UserDefaults? = nil
    ) {
        let defaults = defaults ?? UserDefaults(suiteName: SharedConfig.appGroupId)
        guard
            let defaults,
            let data = try? JSONEncoder().encode(verse),
            let jsonString = String(data: data, encoding: .utf8)
        else {
            print("[Widget] Could not encode verse for storage")
            return
        }

        defaults.set(jsonString, forKey: SharedConfig.widgetVerseKey)
        defaults.synchronize()
    }
    
    private func isVerseCurrentDate(_ verse: WidgetVerseModel?) -> Bool {
        guard let verse = verse else { 
            print("[Widget] No verse to check date")
            return false 
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let verseDate = dateFormatter.date(from: verse.date) else {
            print("[Widget] Could not parse verse date: \(verse.date)")
            return false
        }
        
        let today = dateFormatter.string(from: Date())
        let verseDateString = dateFormatter.string(from: verseDate)
        
        print("[Widget] Comparing dates - Today: \(today), Verse: \(verseDateString)")
        return today == verseDateString
    }
}

struct WidgetVerseView: View {
    @Environment(\.widgetFamily) private var family

    let entry: WidgetVerseEntry

    private var isMedium: Bool { family == .systemMedium }

    var body: some View {
        ZStack(alignment: .leading) {
            if entry.isPlaceholder || entry.verse == nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text(WidgetVersePlaceholder.message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(HolyVersoColors.pureWhite.opacity(0.85))
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(0.9)
                        .accessibilityLabel("Widget sin datos, abre la app para sincronizar.")
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.vertical, isMedium ? 4 : 2)
            } else if let verse = entry.verse {
                VStack(alignment: .leading, spacing: isMedium ? 4 : 2) {
                    Text(verse.text)
                        .font(.system(size: CGFloat(verse.fontSize), weight: .medium))
                        .foregroundColor(HolyVersoColors.pureWhite.opacity(0.85))
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil) // Mostrar todas las líneas posibles, truncar solo si el contenedor se queda corto.
                        .truncationMode(.tail)
                        .layoutPriority(1) // Dar prioridad a ocupar altura disponible.
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .accessibilityLabel("Versículo del día")

                    HStack(alignment: .bottom, spacing: nil) {
                        Text(verse.reference)
                            .font(.system(size: isMedium ? 12 : 10, weight: .regular))
                            .foregroundColor(HolyVersoColors.holyGold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .shadow(color: HolyVersoColors.holyGold.opacity(0.5), radius: 4, x: 0, y: 0)

                        Spacer()

                        Text(verse.versionName)
                            .font(.system(size: isMedium ? 11 : 9, weight: .regular))
                            .foregroundColor(HolyVersoColors.pureWhite.opacity(0.6))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.vertical, isMedium ? 4 : 2)
            }
        }
        .containerBackground(for: .widget) {
            // Fondo compatible con iOS 17+/18 para evitar el aviso de containerBackground.
            LinearGradient(
                colors: [
                    HolyVersoColors.midnightFaithDark.opacity(0.9),
                    HolyVersoColors.midnightFaith.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct WidgetVerseWidget: Widget {
    let kind: String = "WidgetVerse"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetVerseProvider()) { entry in
            WidgetVerseView(entry: entry)
        }
        .configurationDisplayName("HolyVerso")
        .description("Luz y Palabra para cada día.")
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
                    verse: WidgetVersePlaceholder.sample,
                    isPlaceholder: false
                )
            )
                .previewContext(WidgetPreviewContext(family: .systemMedium))
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
