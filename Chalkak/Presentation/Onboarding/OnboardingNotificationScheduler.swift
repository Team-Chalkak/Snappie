//
//  OnboardingNotificationScheduler.swift
//  Chalkak
//
//  Created by bishoe01 on 6/6/26.
//

import Foundation
import UserNotifications

enum OnboardingNotificationSchedulePolicy {
    static let notificationTitle = "오늘 하루, 담고 있나요? 📸"
    static let notificationBody = "Snappie에서 지금 이 순간도 기록해보세요!"

    private static let eveningCutoffHour = 18
    private static let maxNotificationCount = 24
    private static let notificationIntervalHours = 2
    private static let quietHourEnd = 8 // 00:00~08:00 알림 제외

    static func scheduledDates(
        from startDate: Date,
        calendar: Calendar = .current
    ) -> [Date] {
        let endDate = scheduleEndDate(from: startDate, calendar: calendar)
        var dates: [Date] = []
        var nextDate = calendar.date(byAdding: .hour, value: notificationIntervalHours, to: startDate)

        while let date = nextDate,
              date <= endDate,
              dates.count < maxNotificationCount
        {
            if calendar.component(.hour, from: date) >= quietHourEnd {
                dates.append(date)
            }
            nextDate = calendar.date(byAdding: .hour, value: notificationIntervalHours, to: date)
        }

        return dates
    }

    private static func scheduleEndDate(
        from startDate: Date,
        calendar: Calendar
    ) -> Date {
        let hour = calendar.component(.hour, from: startDate)

        if hour >= eveningCutoffHour,
           let nextDaySameTime = calendar.date(byAdding: .day, value: 1, to: startDate)
        {
            return nextDaySameTime
        }

        return calendar.startOfDay(for: startDate).addingTimeInterval(24 * 60 * 60 - 1)
    }
}

final class OnboardingNotificationScheduler {
    static let shared = OnboardingNotificationScheduler()

    private static let maxScheduledNotificationCount = 24

    private let notificationCenter: UNUserNotificationCenter
    private let calendar: Calendar

    init(
        notificationCenter: UNUserNotificationCenter = .current(),
        calendar: Calendar = .current
    ) {
        self.notificationCenter = notificationCenter
        self.calendar = calendar
    }

    func requestAuthorizationAndSchedule(completion: @escaping () -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] isGranted, _ in
            if isGranted {
                self?.scheduleHourlyNotifications(from: Date())
            }

            DispatchQueue.main.async {
                completion()
            }
        }
    }

    private func scheduleHourlyNotifications(from startDate: Date) {
        let dates = OnboardingNotificationSchedulePolicy.scheduledDates(
            from: startDate,
            calendar: calendar
        )
        let identifiers = (0 ..< Self.maxScheduledNotificationCount).map(notificationIdentifier)

        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)

        for (index, date) in dates.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = OnboardingNotificationSchedulePolicy.notificationTitle
            content.body = OnboardingNotificationSchedulePolicy.notificationBody
            content.sound = .default

            let dateComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: date
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: notificationIdentifier(for: index),
                content: content,
                trigger: trigger
            )

            notificationCenter.add(request)
        }
    }

    private func notificationIdentifier(for index: Int) -> String {
        "onboarding.daily-memory.\(index)"
    }
}
