//
//  UserDefaultService.swift
//  Tracker
//
//  Created by Владислав on 18.11.2025.
//
import Foundation

final class UserDefaultsService {
    static let shared = UserDefaultsService()
    private let defaults = UserDefaults.standard

    private init() {}

    private enum Key {
        static let someKey = "someKey"
    }

    var isSomeKeyCompleted: Bool {
        get { defaults.bool(forKey: Key.someKey) }
        set { defaults.set(newValue, forKey: Key.someKey) }
    }
}
