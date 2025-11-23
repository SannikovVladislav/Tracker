//
//  Tracker.swift
//  Tracker
//
//  Created by Владислав on 11.10.2025.
//
import UIKit

struct  Tracker {
    let id: UUID
    let name: String
    let color: UIColor
    let emoji: String
    let schedule: [Weekday]
}

enum Weekday: Int, CaseIterable, Codable {
    case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday
    
    var fullName: String {
        switch self {
        case .sunday: LocalizedStrings.sundayFull
        case .monday: LocalizedStrings.mondayFull
        case .tuesday: LocalizedStrings.tuesdayFull
        case .wednesday: LocalizedStrings.wednesdayFull
        case .thursday: LocalizedStrings.thursdayFull
        case .friday: LocalizedStrings.fridayFull
        case .saturday: LocalizedStrings.saturdayFull
        }
    }
    
    var shortName: String {
        switch self {
        case .sunday: LocalizedStrings.sundayShort
        case .monday: LocalizedStrings.mondayShort
        case .tuesday: LocalizedStrings.tuesdayShort
        case .wednesday: LocalizedStrings.wednesdayShort
        case .thursday: LocalizedStrings.thursdayShort
        case .friday: LocalizedStrings.fridayShort
        case .saturday: LocalizedStrings.saturdayShort
        }
    }
}

