//
//  CalendarAlert.swift
//  Meiza
//
//  Created by Denis Windover on 12/07/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import RxAnimated

class CalendarAlert: AlertVC {
    
    
    @IBOutlet weak var calendarView: CalendarView!
    @IBOutlet weak var btnNextMonth: UIButton!{
        didSet{ btnNextMonth.backgroundColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var btnPreviuosMonth: UIButton!{
        didSet{ btnPreviuosMonth.backgroundColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var btnOk: UIButton!{
        didSet{ btnOk.backgroundColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var btnCancel: UIButton!
    
    var deliveryType: String!
    var _startDate: Date?
    var _endDate: Date?
    var selectedDate = BehaviorRelay<String?>(value: nil)
    var dates = [Week.Time]()
    
    var actionDate: (String?)->() = { _ in }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectedDate.map({ $0 == nil }).bind(to: btnOk.rx.animated.fade(duration: 0.5).isHidden).disposed(by: disposeBag)
        
        
        btnNextMonth.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.calendarView.goToNextMonth()
        }).disposed(by: disposeBag)
        
        btnPreviuosMonth.rx.tap.subscribe(onNext: { [weak self] _ in
             self?.calendarView.goToPreviousMonth()
        }).disposed(by: disposeBag)
        
        btnOk.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss{
                self?.actionDate(self?.selectedDate.value)
            }
        }).disposed(by: disposeBag)
        
        btnCancel.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss{
                self?.actionDate(nil)
            }
        }).disposed(by: disposeBag)
        
        configureUI()
        
    }
    
    private func configureUI(){
        
        dates = deliveryType == "pickup" ? AppData.shared.shop.pickupTimes.sorted(by: { $0.date < $1.date }) : AppData.shared.shop.deliveryTimes.sorted(by: { $0.date < $1.date })
        
        if dates.count == 0 {
            self.dismiss(completion: nil)
            SHOW_TOAST("לא הוגדרו ימים להזמנה!".localized)
            return
        }
        
        _startDate = Date(timeIntervalSince1970: dates[0].date)
        _endDate = Date(timeIntervalSince1970: dates.last!.date)
        
        calendarView.myDates = dates
        
        let style = CalendarView.Style()
        
        style.cellShape                = .bevel(8.0)
        style.cellColorDefault         = UIColor.clear
        style.cellColorToday           = UIColor(red:1.00, green:0.84, blue:0.64, alpha:1.00)
        style.cellSelectedBorderColor  = AppData.shared.mainColor
        style.cellEventColor           = UIColor(red:1.00, green:0.63, blue:0.24, alpha:1.00)
        style.headerTextColor          = UIColor.gray
        
        style.cellTextColorDefault     = AppData.shared.mainColor
        style.cellTextColorToday       = AppData.shared.mainColor
        style.cellTextColorWeekend     = AppData.shared.mainColor
        style.cellColorOutOfRange      = .lightGray
            
        style.headerBackgroundColor    = UIColor.white
        style.weekdaysBackgroundColor  = UIColor.white
        style.firstWeekday             = .sunday
        
        style.locale                   = Locale(identifier: "he_IL")
        
        style.cellFont = UIFont(name: "Heebo-Regular", size: 20.0) ?? UIFont.systemFont(ofSize: 20.0)
        style.headerFont = UIFont(name: "Heebo-Regular", size: 20.0) ?? UIFont.systemFont(ofSize: 20.0)
        style.weekdaysFont = UIFont(name: "Heebo-Regular", size: 14.0) ?? UIFont.systemFont(ofSize: 14.0)
        
        calendarView.style = style
        
        calendarView.dataSource = self
        calendarView.delegate = self
        calendarView.forceLtr = false
        calendarView.direction = .horizontal
        calendarView.multipleSelectionEnable = false
//        calendarView.marksWeekends = true
        
        calendarView.backgroundColor = UIColor(red: 252/255, green: 252/255, blue: 252/255, alpha: 1.0)
        
    }

}

extension CalendarAlert: CalendarViewDataSource {
    
      func startDate() -> Date {
          return _startDate ?? Date()
      }
      
      func endDate() -> Date {
          return _endDate ?? Date()
      }
    
}

extension CalendarAlert: CalendarViewDelegate {
    
    func calendar(_ calendar: CalendarView, didSelectDate date : Date, withEvents events: [CalendarEvent]) {
        
        if let _selectedDate = dates.map({ Date(timeIntervalSince1970: $0.date).formattedFullDateString }).first(where: { $0 == calendar.selectedDates[0].formattedFullDateString }) {
            selectedDate.accept(_selectedDate)
        }
    }
    
    func calendar(_ calendar: CalendarView, didDeselectDate date: Date) {
        selectedDate.accept(nil)
    }
    
    func calendar(_ calendar: CalendarView, didScrollToMonth date : Date) {
        print(self.calendarView.selectedDates)
    }
    
    
}
