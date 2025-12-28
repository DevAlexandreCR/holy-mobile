import Foundation
import BackgroundTasks
import WidgetKit

@available(iOS 13.0, *)
class DailyVerseFetchTask {
    static let shared = DailyVerseFetchTask()
    
    private let taskIdentifier = "gorda.holyverso.dailyVerseFetch"
    private let appGroupId = "group.gorda.holyverso"
    private let widgetVerseKey = "widgetVerse"
    
    private init() {}
    
    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil
        ) { task in
            self.handleDailyVerseFetch(task: task as! BGAppRefreshTask)
        }
    }
    
    func scheduleNextFetch(retryInHour: Bool = false, immediate: Bool = false) {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        let calendar = Calendar.current
        
        if immediate {
            // Run as soon as possible (in a few seconds)
            request.earliestBeginDate = Date(timeIntervalSinceNow: 5)
            print("[DailyVerseFetchTask] Immediate update requested")
        } else if retryInHour {
            // Retry in one hour if needed
            request.earliestBeginDate = calendar.date(byAdding: .hour, value: 1, to: Date())
            print("[DailyVerseFetchTask] Retry scheduled in 1 hour")
        } else {
            // Schedule for 5:00 AM the next day (or today if it's before 5 AM)
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = 5
            components.minute = 0
            components.second = 0
            
            if let targetDate = calendar.date(from: components), targetDate < Date() {
                // If it's already past 5 AM, schedule for tomorrow
                request.earliestBeginDate = calendar.date(byAdding: .day, value: 1, to: targetDate)
            } else {
                request.earliestBeginDate = calendar.date(from: components)
            }
        }
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("[DailyVerseFetchTask] Task scheduled for \(request.earliestBeginDate?.description ?? "unknown")")
        } catch {
            print("[DailyVerseFetchTask] Failed to schedule task: \(error)")
        }
    }
    
    private func handleDailyVerseFetch(task: BGAppRefreshTask) {
        print("[DailyVerseFetchTask] Starting daily verse fetch...")
        
        // Set an expiration handler
        task.expirationHandler = {
            print("[DailyVerseFetchTask] Task expired before completion")
            self.scheduleNextFetch(retryInHour: true) // Retry in one hour
        }
        
        // Perform the request
        Task {
            do {
                let shouldRetry = try await fetchAndSaveDailyVerse()
                
                if shouldRetry {
                    // If the verse was not loaded (missing token or offline), retry in one hour
                    print("[DailyVerseFetchTask] Verse not loaded, will retry in 1 hour")
                    scheduleNextFetch(retryInHour: true)
                } else {
                    // If it loaded successfully, schedule for 5 AM tomorrow
                    print("[DailyVerseFetchTask] Task completed successfully, scheduled for tomorrow")
                    scheduleNextFetch(retryInHour: false)
                }
                
                task.setTaskCompleted(success: true)
            } catch {
                print("[DailyVerseFetchTask] Task failed: \(error)")
                // On error, retry in one hour
                scheduleNextFetch(retryInHour: true)
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    private func fetchAndSaveDailyVerse() async throws -> Bool {
        // Check if today's verse is already stored
        if hasVerseForToday() {
            print("[DailyVerseFetchTask] Already have verse for today")
            return false // No retry needed
        }
        
        // Get the JWT token from Keychain
        guard let jwtToken = getJWTToken() else {
            print("[DailyVerseFetchTask] No JWT token found")
            return true // Retry in one hour in case the user signs in
        }
        
        // Read the stored API URL
        guard let apiBaseUrl = getApiUrl() else {
            print("[DailyVerseFetchTask] No API URL found")
            return true // Retry in one hour
        }
        
        // Build the request URL
        guard let url = URL(string: "\(apiBaseUrl)/verse/today") else {
            throw NSError(domain: "DailyVerseFetchTask", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // Build the request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15
        
        // Perform the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "DailyVerseFetchTask", code: 2, userInfo: [NSLocalizedDescriptionKey: "HTTP error"])
        }
        
        // Parse the response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "DailyVerseFetchTask", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])
        }
        
        let verseData = (json["data"] as? [String: Any]) ?? json
        
        // Build the WidgetVerse payload
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        let widgetVerse: [String: Any] = [
            "date": today,
            "version_code": verseData["version_code"] as? String ?? "",
            "version_name": verseData["version_name"] as? String ?? "",
            "reference": verseData["reference"] as? String ?? "",
            "text": verseData["text"] as? String ?? "",
            "font_size": 16.0
        ]
        
        // Convert to a JSON string
        let jsonData = try JSONSerialization.data(withJSONObject: widgetVerse)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw NSError(domain: "DailyVerseFetchTask", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to create JSON string"])
        }
        
        // Save to shared UserDefaults
        guard let sharedDefaults = UserDefaults(suiteName: appGroupId) else {
            throw NSError(domain: "DailyVerseFetchTask", code: 5, userInfo: [NSLocalizedDescriptionKey: "App Group not configured"])
        }
        
        sharedDefaults.set(jsonString, forKey: widgetVerseKey)
        sharedDefaults.synchronize()
        
        // Refresh widgets
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        print("[DailyVerseFetchTask] Verse saved and widgets updated for \(today)")
        return false // No retry needed; the verse loaded successfully
    }
    
    private func hasVerseForToday() -> Bool {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupId),
              let jsonString = sharedDefaults.string(forKey: widgetVerseKey),
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dateString = json["date"] as? String else {
            return false
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        return dateString == today
    }
    
    private func getJWTToken() -> String? {
        // Try reading the token from UserDefaults (written by Flutter)
        if let sharedDefaults = UserDefaults(suiteName: appGroupId),
           let token = sharedDefaults.string(forKey: "jwt_token") {
            return token
        }
        
        // Also try standard UserDefaults as a fallback
        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            return token
        }
        
        return nil
    }
    
    private func getApiUrl() -> String? {
        // Read the API URL saved by Flutter
        if let sharedDefaults = UserDefaults(suiteName: appGroupId),
           let apiUrl = sharedDefaults.string(forKey: "api_url") {
            return apiUrl
        }
        
        // Fallback to the default API URL
        return "https://api.holyverso.com"
    }
}
