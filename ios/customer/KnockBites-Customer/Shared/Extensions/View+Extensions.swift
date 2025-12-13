//
//  View+Extensions.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

extension View {
    // MARK: - Hide Keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
