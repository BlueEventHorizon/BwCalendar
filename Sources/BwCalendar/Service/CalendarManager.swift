//
//  CalendarManager.swift
//  BwTools
//
//  Created by k2moons on 2018/07/24.
//  Copyright (c) 2018 k2moons. All rights reserved.
//

import EventKit // Create, view, and edit calendar and reminder events.
import BwTools
import InfoPlistKeys

// https://developer.apple.com/documentation/eventkit

public protocol CalendarManagerProtocol {
    func authorize(completion: ((_ result: Bool) -> Void)?)
    func getCalendarType(type: EKSourceType)
    func getCalendars() -> [EKCalendar]
    func getEvents(from calendars: [EKCalendar], startDate: Date, endDate: Date) -> [EKEvent]
    func addEvent(title: String, start: Date, end: Date?)

    func getEvents(day: Date, from calendars: [EKCalendar]) -> [EKEvent]
    func getEvents(month: Date, from calendars: [EKCalendar]) -> [EKEvent]
}

public final class CalendarManager: CalendarManagerProtocol {
    public static let shared = CalendarManager()

    private let nlUtil: NaturalLanguageUtil = NaturalLanguageUtil()

    private init() {}

    private lazy var eventStore: EKEventStore = { EKEventStore() }()
    private lazy var defaultCalendar = { eventStore.defaultCalendarForNewEvents }()
    public private(set) lazy var calendars: [EKCalendar] = { [EKCalendar]() }()

    // 認証ステータスを取得
    public func authorize(completion: ((_ result: Bool) -> Void)?) {
        guard InfoPlistKeys.calendarsUsageDescription.getValue() != nil else {
            log.error("No info.plist property for Calendar", instance: self)
            return
        }

        // 認証ステータスを取得
        let status = EKEventStore.authorizationStatus(for: .event)

        switch status {
            case .notDetermined:
                // 未決定なのでOSダイアログを表示
                eventStore.requestAccess(to: .event, completion: { granted, _ in
                    completion?(granted)
                })

            case .denied:
                log.debug("denied")
                completion?(false)

            case .authorized:
                log.debug("authorized")
                completion?(true)

            case .restricted:
                log.debug("restricted")
                completion?(false)
            @unknown default:
                log.error("no switch case")
        }
    }

    public func getCalendarType(type: EKSourceType) {}

    // カレンダーの種別を取得します
    public func getCalendars() -> [EKCalendar] {
        guard self.calendars.isEmpty else { return self.calendars }

        self.calendars = eventStore.calendars(for: .event)

        #if false

            for calendar in self.calendars {
                log.info("カレンダー = \(calendar.source.title) - \(calendar.title), タイトル = \(calendar.title), ID = \(calendar.calendarIdentifier), ソース名 = \(calendar.source.title), ソースID = \(calendar.source.sourceIdentifier)")
                // calendar.cgColor
            }

        #endif

        return self.calendars
    }

    // カレンダーのイベント（項目）を取得します
    public func getEvents(from calendars: [EKCalendar], startDate: Date, endDate: Date) -> [EKEvent] {
        // 検索するためのクエリー的なものを用意
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        // イベントを検索
        let events = eventStore.events(matching: predicate)

        #if false

            for event in events {
                let eventIdentifier = event.eventIdentifier ?? ""
                let title = event.title ?? "タイトルなし"
                let period = event.endDate.timeIntervalSince1970 - event.startDate.timeIntervalSince1970
                let hour: Double = round(period * 100 / 3600.0) / 100

                log.info("eventIdentifier = \(eventIdentifier)", instance: self)
                log.info("\(title) : \(hour) : \(event.isAllDay ? "全日" : "")", instance: self)
                log.info(event.availability, instance: self)
                log.info("\(event.isDetached ? "repeating event" : "")", instance: self)
                log.info(event.status, instance: self)
                log.info("birthdayContactIdentifier = \(event.birthdayContactIdentifier)", instance: self)
            }

        #endif

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
        } catch {
            print(error)
        }
    }

    /// １日のイベントを抽出する
    /// - Parameters:
    ///   - day: 抽出する日付
    ///   - calendars: カレンダー
    /// - Returns: イベント配列
    public func getEvents(day: Date, from calendars: [EKCalendar]) -> [EKEvent] {
        let startDate = day.fixed(hour: 0, minute: 0, second: 0)
        let endDate = day.fixed(hour: 23, minute: 59, second: 59)

        return getEvents(from: calendars, startDate: startDate, endDate: endDate)
    }

    /// その月のイベントを抽出する
    /// - Parameters:
    ///   - month: 抽出する月
    ///   - calendars: カレンダー
    /// - Returns: イベント配列
    public func getEvents(month: Date, from calendars: [EKCalendar]) -> [EKEvent] {
        /// monthの最初
        let startDate = month.fixed(day: 1, hour: 0, minute: 0, second: 0)
        /// monthの最後
        let endDate = startDate.shift(month: 1).fixed(day: 1, hour: 0, minute: 0, second: 0).shift(second: -1)

        return getEvents(from: calendars, startDate: startDate, endDate: endDate)
    }

    /// NaturalLanguageUtilを使ってキーワードを抽出する、つもりだったが、形態素ではだめかも
    /// - Returns: キーワード：頻出度
    public func getKeywords() -> [String: Double] {
        var keywordsSet: Set<String> = Set()
        var keywords: [String: Double] = [String: Double]()
        let today = Date()

        // １週間
        let oneWeekAgo = today.shift(day: -7).fixed(hour: 0, minute: 0, second: 0)
        let todaysEnd = today.shift(day: 1).fixed(hour: 0, minute: 0, second: 0).shift(second: -1)

        let weekEvents = getEvents(from: calendars, startDate: oneWeekAgo, endDate: todaysEnd)

        // １ヶ月
        let oneMonthAgo = today.shift(month: -1).fixed(hour: 0, minute: 0, second: 0)
        let oneMonthEvents = getEvents(from: calendars, startDate: oneMonthAgo, endDate: oneWeekAgo.shift(second: -1))

        // ３ヶ月
        let threeMonthAgo = today.shift(month: -3).fixed(hour: 0, minute: 0, second: 0)
        let threeMonthEvents = getEvents(from: calendars, startDate: threeMonthAgo, endDate: oneMonthAgo.shift(second: -1))

        let joinedEvents = getEvents(from: calendars, startDate: threeMonthAgo, endDate: todaysEnd)

        // キーワード抽出

        for event in joinedEvents {
            guard let tite = event.title else {
                continue
            }

            let tokens = nlUtil.tokenizeWithWord(text: tite, minLength: 2)
            for token in tokens {
                keywordsSet.insert(token)
            }
        }

        print(keywordsSet)

        // 頻出度

        // 長さ

        return keywords
    }

    public func test() {
        let keywords = getKeywords()
        print(keywords)
    }
}
