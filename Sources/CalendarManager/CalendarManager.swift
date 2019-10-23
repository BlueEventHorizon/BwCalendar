import Foundation
import EventKit // Create, view, and edit calendar and reminder events.

// https://developer.apple.com/documentation/eventkit

public final class CalendarManager {
    public static let shared = CalendarManager()
    private init() {}

    lazy private var eventStore: EKEventStore = { return EKEventStore() }()
    lazy private var defaultCalendar = { return eventStore.defaultCalendarForNewEvents }()
    lazy public private(set) var calendars: [EKCalendar] = { return [EKCalendar]() }()

    // 認証ステータスを取得
    public func authorize(completion: ((_ result: Bool) -> Void)? ) {
        guard InfoPlistUtil.calendarsUsageDescription != nil else {
            logger.fatal("No info.plist property for Calendar")
            return
        }

        // 認証ステータスを取得
        let status = EKEventStore.authorizationStatus(for: .event)

        switch status {
        case .notDetermined:
            // 未決定なのでOSダイアログを表示
            eventStore.requestAccess(to: .event, completion: { (granted, _) in
                completion?(granted)
            })

        case .denied:
            logger.debug("denied")
            completion?(false)

        case .authorized:
            logger.debug("authorized")
            completion?(true)

        case .restricted:
            logger.debug("restricted")
            completion?(false)
        @unknown default:
            logger.error("no switch case")
        }
    }

    public func getCalendarType( type: EKSourceType) {

    }

    public func getCalendars() -> [EKCalendar] {
        guard self.calendars.isEmpty else { return self.calendars }

        self.calendars = eventStore.calendars(for: .event)
                for calendar in self.calendars
                {
                    logger.info("カレンダー名： \(calendar.title)")
                    logger.info("カレンダーID： \(calendar.calendarIdentifier)")
                    logger.info("カレンダーソース名： \(calendar.source.title)")
                    logger.info("カレンダーソースID： \(calendar.source.sourceIdentifier)")
        
                    // calendar.color
                }
        return self.calendars
    }

    public func getEvents(from calendars: [EKCalendar]) -> [EKEvent] {
        // 検索条件を準備
        let startDate = Date()
        let endDate = Date(timeIntervalSinceNow: 3600*24*365)
        // 検索するためのクエリー的なものを用意
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        // イベントを検索
        let events = eventStore.events(matching: predicate)
        for event in events
        {
            if let _title = event.title
            {
                logger.info("タイトル：\(_title)")
            }
            logger.info("期間：\(event.startDate.string(dateFormat: FormatterType.std.rawValue)) - \(event.endDate.string(dateFormat: FormatterType.std.rawValue))")
            if event.isAllDay
            {
                logger.info("全日")
            }
        }
        return events
    }

    public func addEvent(title: String, start: Date, end: Date? = nil) {
        let defaultCalendar = eventStore.defaultCalendarForNewEvents
        // イベントを作成して情報をセット
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = start
        event.endDate = end ?? Calendar.standard.date(byAdding: .hour, value: 2, to: start)
        event.calendar = defaultCalendar
        // イベントの登録
        do {
            try eventStore.save(event, span: .thisEvent)
        } catch let error {
            logger.error(error.localizedDescription)
        }
    }
}
