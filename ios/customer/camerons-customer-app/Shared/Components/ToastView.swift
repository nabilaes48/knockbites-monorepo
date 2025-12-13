//
//  ToastView.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI
import Combine

// MARK: - Toast Model
struct Toast: Equatable {
    let id = UUID()
    let message: String
    let icon: String?
    let type: ToastType

    enum ToastType {
        case success
        case error
        case info
        case warning

        var backgroundColor: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .info: return .blue
            case .warning: return .orange
            }
        }
    }

    static func == (lhs: Toast, rhs: Toast) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast Manager
@MainActor
class ToastManager: ObservableObject {
    static let shared = ToastManager()

    @Published var currentToast: Toast?

    private init() {}

    func show(_ message: String, icon: String? = nil, type: Toast.ToastType = .success) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            currentToast = Toast(message: message, icon: icon, type: type)
        }

        // Auto-dismiss after 2.5 seconds
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            dismiss()
        }
    }

    func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentToast = nil
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    let toast: Toast
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            if let icon = toast.icon {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
            }

            Text(toast.message)
                .font(AppFonts.subheadline)
                .fontWeight(.medium)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            Capsule()
                .fill(toast.type.backgroundColor)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, Spacing.md)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Toast Modifier
struct ToastModifier: ViewModifier {
    @ObservedObject var toastManager = ToastManager.shared

    func body(content: Content) -> some View {
        ZStack {
            content

            VStack {
                if let toast = toastManager.currentToast {
                    ToastView(toast: toast) {
                        toastManager.dismiss()
                    }
                    .padding(.top, 50)

                    Spacer()
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: toastManager.currentToast)
        }
    }
}

extension View {
    func withToast() -> some View {
        modifier(ToastModifier())
    }
}

#Preview {
    VStack {
        Button("Show Success") {
            ToastManager.shared.show("Added to cart!", icon: "checkmark.circle.fill", type: .success)
        }

        Button("Show Error") {
            ToastManager.shared.show("Something went wrong", icon: "exclamationmark.triangle.fill", type: .error)
        }

        Button("Show Info") {
            ToastManager.shared.show("Item updated", icon: "info.circle.fill", type: .info)
        }
    }
    .withToast()
}
