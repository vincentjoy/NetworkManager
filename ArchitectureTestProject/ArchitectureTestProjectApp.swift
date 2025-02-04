//
//  ArchitectureTestProjectApp.swift
//  ArchitectureTestProject
//
//  Created by Vincent Joy on 04/02/25.
//

import SwiftUI

@main
struct ArchitectureTestProjectApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
