//
//  HapticManager.swift
//  FoniaWatch Rehab
//
//  Envoltorio fino sobre el motor háptico del Apple Watch.
//

import WatchKit

enum Haptic {
    static func tap()      { WKInterfaceDevice.current().play(.click) }
    static func success()  { WKInterfaceDevice.current().play(.success) }
    static func warn()     { WKInterfaceDevice.current().play(.retry) }
    static func stop()     { WKInterfaceDevice.current().play(.failure) }
    static func beat()     { WKInterfaceDevice.current().play(.start) }
    static func notify()   { WKInterfaceDevice.current().play(.notification) }
}
