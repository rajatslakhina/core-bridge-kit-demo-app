//
//  DemoApp.swift
//  CoreBridge Demo
//
//  The host app. It owns the content; the library owns the boundary.
//

import SwiftUI
import CoreBridge

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            CoreBridgeInspectorView(script: DemoScript.narration)
        }
    }
}

/// The compiled-in payload the simulated core streams back.
///
/// It lives in the app, not in `CoreBridge`, on purpose: a boundary library has
/// no business shipping content. `SimulatedCore.Script.tokens(_:)` splits this
/// into one frame per word, which is the shape a real inference core produces —
/// and the shape that makes backpressure visible when the view is slower than
/// the producer.
enum DemoScript {
    static let narration = SimulatedCore.Script.tokens(
        """
        A shared native core buys you one implementation for two platforms. \
        It also buys you a line where async, typed errors, cancellation and \
        Sendable all stop working. Watch the credits: this core may only run \
        two tokens ahead of this view, because that is all the window allows. \
        Now flip a fault switch and run it again.
        """
    )
}
