import Foundation
import UserNotifications

class NotificationHandler: ObservableObject {
    func askPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("Access granted!")
                completion(true)
            } else if let error = error {
                print("Permission error: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    // Enviar notificación
    func sendNotification(date: Date, type: String, timeInterval: Double = 10, title: String, body: String, completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                var trigger: UNNotificationTrigger?
                
                if type == "date" {
                    let dateComponents = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute], from: date)
                    trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                } else if type == "time" {
                    trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
                }
                
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = UNNotificationSound.default
                
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("Notification scheduled")
                        completion(true)
                    }
                }
            } else {
                // Si no está autorizado, pedir permiso
                self.askPermission { granted in
                    if granted {
                        self.sendNotification(date: date, type: type, timeInterval: timeInterval, title: title, body: body, completion: completion)
                    } else {
                        completion(false)
                    }
                }
            }
        }
    }
}
