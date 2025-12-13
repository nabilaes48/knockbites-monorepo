//
//  ExportViewModel.swift
//  knockbites-Bussiness-app
//
//  Extracted from ExportOptionsView.swift during Phase 3 cleanup
//

import SwiftUI
import Combine

@MainActor
class ExportViewModel: ObservableObject {
    @Published var isExporting = false
}
