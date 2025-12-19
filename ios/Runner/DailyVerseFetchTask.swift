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
            // Ejecutar lo antes posible (en unos segundos)
            request.earliestBeginDate = Date(timeIntervalSinceNow: 5)
            print("[DailyVerseFetchTask] Immediate update requested")
        } else if retryInHour {
            // Si hay que reintentar, programar en 1 hora
            request.earliestBeginDate = calendar.date(byAdding: .hour, value: 1, to: Date())
            print("[DailyVerseFetchTask] Retry scheduled in 1 hour")
        } else {
            // Programar para las 5:00 AM del siguiente día (o de hoy si aún no son las 5am)
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = 5
            components.minute = 0
            components.second = 0
            
            if let targetDate = calendar.date(from: components), targetDate < Date() {
                // Si ya pasaron las 5 AM, programar para mañana
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
        
        // Crear una tarea para manejar la expiración
        task.expirationHandler = {
            print("[DailyVerseFetchTask] Task expired before completion")
            self.scheduleNextFetch(retryInHour: true) // Reintentar en 1 hora
        }
        
        // Ejecutar la petición
        Task {
            do {
                let shouldRetry = try await fetchAndSaveDailyVerse()
                
                if shouldRetry {
                    // Si no se cargó el verso (falta token o sin conexión), reintentar en 1 hora
                    print("[DailyVerseFetchTask] Verse not loaded, will retry in 1 hour")
                    scheduleNextFetch(retryInHour: true)
                } else {
                    // Si se cargó exitosamente, programar para mañana a las 5am
                    print("[DailyVerseFetchTask] Task completed successfully, scheduled for tomorrow")
                    scheduleNextFetch(retryInHour: false)
                }
                
                task.setTaskCompleted(success: true)
            } catch {
                print("[DailyVerseFetchTask] Task failed: \(error)")
                // En caso de error, reintentar en 1 hora
                scheduleNextFetch(retryInHour: true)
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    private func fetchAndSaveDailyVerse() async throws -> Bool {
        // Verificar si ya tenemos el verso del día actual
        if hasVerseForToday() {
            print("[DailyVerseFetchTask] Already have verse for today")
            return false // No necesita reintentar
        }
        
        // Obtener el token JWT de Keychain
        guard let jwtToken = getJWTToken() else {
            print("[DailyVerseFetchTask] No JWT token found")
            return true // Reintentar en 1 hora por si el usuario inicia sesión
        }
        
        // Obtener la API URL guardada
        guard let apiBaseUrl = getApiUrl() else {
            print("[DailyVerseFetchTask] No API URL found")
            return true // Reintentar en 1 hora
        }
        
        // Crear la URL
        guard let url = URL(string: "\(apiBaseUrl)/verse/today") else {
            throw NSError(domain: "DailyVerseFetchTask", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // Crear la petición
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15
        
        // Hacer la petición
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "DailyVerseFetchTask", code: 2, userInfo: [NSLocalizedDescriptionKey: "HTTP error"])
        }
        
        // Parsear la respuesta
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "DailyVerseFetchTask", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])
        }
        
        let verseData = (json["data"] as? [String: Any]) ?? json
        
        // Crear el objeto WidgetVerse
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
        
        // Convertir a JSON string
        let jsonData = try JSONSerialization.data(withJSONObject: widgetVerse)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw NSError(domain: "DailyVerseFetchTask", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to create JSON string"])
        }
        
        // Guardar en UserDefaults compartido
        guard let sharedDefaults = UserDefaults(suiteName: appGroupId) else {
            throw NSError(domain: "DailyVerseFetchTask", code: 5, userInfo: [NSLocalizedDescriptionKey: "App Group not configured"])
        }
        
        sharedDefaults.set(jsonString, forKey: widgetVerseKey)
        sharedDefaults.synchronize()
        
        // Actualizar widgets
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        print("[DailyVerseFetchTask] Verse saved and widgets updated for \(today)")
        return false // No necesita reintentar, se cargó exitosamente
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
        // Intentar obtener el token de UserDefaults (donde Flutter lo guarda)
        if let sharedDefaults = UserDefaults(suiteName: appGroupId),
           let token = sharedDefaults.string(forKey: "jwt_token") {
            return token
        }
        
        // También intentar obtenerlo desde UserDefaults estándar como fallback
        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            return token
        }
        
        return nil
    }
    
    private func getApiUrl() -> String? {
        // Leer la API URL guardada desde Flutter
        if let sharedDefaults = UserDefaults(suiteName: appGroupId),
           let apiUrl = sharedDefaults.string(forKey: "api_url") {
            return apiUrl
        }
        
        // Fallback a URL por defecto
        return "https://api.holyverso.com"
    }
}