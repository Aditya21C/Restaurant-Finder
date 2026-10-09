//
//  NotificationManager.swift
//  SettleIt
//
//  Created by Mayukh Baidya on 28/07/25.
//

import UserNotifications

class NotificationManager {
    
    static let shared = NotificationManager()
    private init() {}

    func requestAuthorizationAndSchedule() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("🔴 Authorization error: \(error.localizedDescription)")
                return
            }
            
            if granted {
                print("✅ Authorization granted! Scheduling a new batch of notifications...")
                // If permission is granted, schedule the batch of unique notifications.
                self.scheduleBatchOfNotifications()
            } else {
                print("🔴 Authorization denied.")
            }
        }
    }

    /// Schedules a batch of unique, non-repeating notifications for several weeks into the future.
    private func scheduleBatchOfNotifications() {
        // First, clear ALL previously scheduled notifications to start fresh.
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("Cleared all old notifications.")
        
        let messages = [
            (title: "time for a food adventure 😊", body: "don’t know where to eat? I know you know where to tap"),
            (title: "hungry? let's decide!", body: "your group is one tap away from deciding"),
            (title: "weekend plans loading...", body: "the weekend’s here. make a plan asap!"),
            (title: "settle the great food debate", body: "still arguing where to eat? let Settld help!"),
            (title: "one sided love hurts 💔", body: "but come on, what are friends for? cheer up, decide on a restaurant!"),
            (title: "stop arguing, stop arguing 😞", body: "Settld it with Settld"),
            (title: "do you know why your crush isn't texting you right now?", body: "even idk, but you can use Settld as an excuse to meet up 😎"),
            (title: "you'll forever be stuck in the group chat phase😔", body: "plan an impromptu meetup with Settld"),
            (title: "hey", body: "we've got you covered for the weekend, btw"),
            (title: "🍕🍔", body: "your mouth's watering, your eyes are on this text, your fingers should know where to tap"),
            (title: "hi", body: "which restaurant?"),
            (title: "that “I’m fine” in group chat = lie 😅", body: "decisions are easy with this app"),
            (title: "date night dilemma? 🌹", body: "pick the spot with a tap and focus on the rest."),
            (title: "when the chat goes quiet 🤐", body: "jump back in—your next meal is waiting."),
            (title: "is this a sign from the universe ✨?", body: "gather the crew and end the “where to eat” drama."),
            (title: "your stomach just texted, unlike your crush 🥲", body: "it’s demanding lunch plans for the weekend"),
            (title: "crush left you on read? 📩", body: "double text back over dinner and see the magic unfold"),
            (title: "still no reply from your crush? 😶", body: "distract your heart with tacos or pizza"),
            (title: "ghosted again? 😩", body: "plan a hangout with your friends—food always answers back."),
            (title: "when “hey” gets you nothing… 🥲", body: "hey, let’s pick dinner with everyone who’s actually talking"),
            (title: "your friends ghosting again? 😖", body: "break the silence—pick a spot"),
            (title: "debate still on hold even after 100 hours of pointless texting? 🛑", body: "why are you still reading this after 100 hours of pointless texting?"),
            (title: "When “anywhere is fine” says nothing… 🙄", body: "make the call and get moving."),
            (title: "still waiting for replies? ⏰", body: "a leader is one who knows the way, goes the way, and shows the way"),
            (title: "no one’s deciding? 🤷", body: "one tap ends it"),
            (title: "echoes in the group chat… 🔊", body: "silence is golden, I know, but food is better"),
            (title: "the nation wants to know 🔊", body: "when will you guys ever come to a conclusion?"),
        ]
        
        let calendar = Calendar.current
        let today = Date()
        
        // Schedule notifications for the next 8 weeks. This provides 2 months of unique notifications.
        for weekOffset in 0..<8 {
            guard let targetDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: today) else { continue }
            
            // Days of the week to schedule (Friday, Saturday, Sunday)
            let daysToSchedule = [6, 7, 1] // Fri, Sat, Sun
            
            for day in daysToSchedule {
                var dateComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear, .hour, .minute, .second], from: targetDate)
                dateComponents.weekday = day
                // MARK: - Test Time Change
                dateComponents.hour = 19
                dateComponents.minute = 0
                
                // This check prevents scheduling a notification for a day that has already passed in the current week.
                if let finalDate = calendar.date(from: dateComponents), finalDate < Date() {
                    continue
                }

                guard let randomMessage = messages.randomElement() else { continue }

                let content = UNMutableNotificationContent()
                content.title = randomMessage.title
                content.body = randomMessage.body
                content.sound = .default

                // This trigger is for a SPECIFIC date and does NOT repeat.
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                
                // Create a unique identifier based on the exact date.
                let identifier = "settld-reminder-\(day)-\(weekOffset)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("🔴 Error scheduling for \(identifier): \(error.localizedDescription)")
                    }
                }
            }
        }
        print("✅ Successfully scheduled a new batch of unique weekly notifications for the next 8 weeks.")
    }
}
