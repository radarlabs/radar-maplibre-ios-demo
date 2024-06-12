//
//  radar_maplibre_demoApp.swift
//  radar-maplibre-demo
//
//

import SwiftUI

@main
struct radar_maplibre_demoApp: App {
    var body: some Scene {
        WindowGroup {
            MapView().ignoresSafeArea()
        }
    }
}
