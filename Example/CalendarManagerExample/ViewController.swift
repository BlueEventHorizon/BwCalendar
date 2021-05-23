//
//  ViewController.swift
//  CalendarManagerExample
//
//  Created byk2moons on 2019/09/18.
//  Copyright © 2019 moons. All rights reserved.
//

import UIKit
import BwCalendar
import BwTools

class ViewController: UIViewController {

    @IBOutlet weak var year: UITextField!
    @IBOutlet weak var month: UITextField!
    @IBOutlet weak var day: UITextField!
    
    @IBAction func pushed(_ sender: Any) {
        if let date = Date(dateString: "\(year.text ?? "2019")-\(month.text ?? "01")-\(day.text ?? "21") 00:00:00", dateFormat: FormatterType.std.rawValue){
            CalendarManager.shared.addEvent(title: "テスト登録", start: date)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let today = Date()
        year.text = String(today.year)
        month.text = String(today.month)
        day.text = String(today.day)
        
        CalendarManager.shared.authorize { _ in
            _ = CalendarManager.shared.getEvents(day: Date(), from: CalendarManager.shared.getCalendars())
        }
    }
}

