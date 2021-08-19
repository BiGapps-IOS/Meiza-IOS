//
//  Date+Meiza.swift
//  Meiza
//
//  Created by Denis Windover on 26/08/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import Foundation

extension Date {
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }

    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

extension Date{
    
    var formattedWeekDayString: String{
        get{
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE"
            let weekDay = dateFormatter.string(from: self)
            return weekDay
        }
    }
    
    var formattedHebrewWeekDayString: String{
        get{
            let dateFormatter = DateFormatter()
            dateFormatter.locale = .init(identifier: "he_IL")
            dateFormatter.dateFormat = "EEEE"
            let weekDay = dateFormatter.string(from: self)
            return weekDay
        }
    }
    
    var formattedHebrewYearString: String{
        get{
            let hebrew = Calendar(identifier: .hebrew)
            let formatter = DateFormatter()
            formatter.locale = .init(identifier: "he_IL")
            formatter.dateStyle = .long
            formatter.timeStyle = .none
            formatter.calendar = hebrew
            formatter.dateFormat = "yyyy"
            return formatter.string(from: self)
        }
    }
    
    var formattedHebrewMonthString: String{
        get{
            let hebrew = Calendar(identifier: .hebrew)
            let formatter = DateFormatter()
            formatter.locale = .init(identifier: "he_IL")
            formatter.dateStyle = .long
            formatter.timeStyle = .none
            formatter.calendar = hebrew
            formatter.dateFormat = "MMM"
            return formatter.string(from: self)
        }
    }
    
    var formattedHebrewDayString: String{
        get{
            let hebrew = Calendar(identifier: .hebrew)
            let formatter = DateFormatter()
            formatter.locale = .init(identifier: "he_IL")
            formatter.dateStyle = .long
            formatter.timeStyle = .none
            formatter.calendar = hebrew
            formatter.dateFormat = "dd"
            return formatter.string(from: self)
        }
    }
    
    var formattedHebrewString: String{
        get{
            let hebrew = Calendar(identifier: .hebrew)
            let formatter = DateFormatter()
            formatter.locale = .init(identifier: "he_IL")
            formatter.dateStyle = .long
            formatter.timeStyle = .none
            formatter.calendar = hebrew
            return formatter.string(from: self)
        }
    }
    
    var formattedTimeString: String{
        get{
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: self)
        }
    }
    
    var formattedExpDateString: String{
        get{
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            return formatter.string(from: self)
        }
    }
    
    var formattedDateString:String {
        get{
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM yyyy"
            return formatter.string(from: self)
        }
    }
    var formattedFullDateString:String {
        get{
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yy"
            return formatter.string(from: self)
        }
    }
    var formattedDateString2:String {
        get{
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm dd.MM.yyyy"
            return formatter.string(from: self)
        }
    }
    
    
    /// Returns the amount of years from another date
    var years:Int {
        return Calendar.current.dateComponents([.year], from: Date(), to: self).year ?? 0
    }
    /// Returns the amount of months from another date
    var months:Int {
        return Calendar.current.dateComponents([.month], from: Date(), to: self).month ?? 0
    }
    /// Returns the amount of weeks from another date
    var weeks:Int {
        return Calendar.current.dateComponents([.weekOfMonth], from: Date(), to: self).weekOfMonth ?? 0
    }
    /// Returns the amount of days from another date
    var days:Int {
        return Calendar.current.dateComponents([.day], from: Date(), to: self).day ?? 0
    }
    /// Returns the amount of hours from another date
    var hours:Int {
        return Calendar.current.dateComponents([.hour], from: self).hour ?? 0
    }
    /// Returns the amount of minutes from another date
    var minutes:Int {
        return Calendar.current.dateComponents([.minute], from: self).minute ?? 0
    }
    /// Returns the amount of seconds from another date
    var seconds:Int {
        return Calendar.current.dateComponents([.second], from: Date(), to: self).second ?? 0
    }
}
