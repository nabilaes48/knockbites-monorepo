//
//  AlertPresenter.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code - Unified Alert/Toast Handling
//

import SwiftUI

// MARK: - Toast Message Model

struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let type: ToastType

    enum ToastType {
        case success
        case error
        case info
        case warning

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            }
        }

        var color: Color {
            switch self {
            case .success: return .success
            case .error: return .error
            case .info: return .info
            case .warning: return .warning
            }
        }
    }

    static func success(_ message: String) -> ToastMessage {
        ToastMessage(message: message, type: .success)
    }

    static func error(_ message: String) -> ToastMessage {
        ToastMessage(message: message, type: .error)
    }

    static func info(_ message: String) -> ToastMessage {
        ToastMessage(message: message, type: .info)
    }

    static func warning(_ message: String) -> ToastMessage {
        ToastMessage(message: message, type: .warning)
    }
}

// MARK: - Toast View

struct ToastView: View {
    let toast: ToastMessage
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: toast.type.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(toast.type.color)

            Text(toast.message)
                .font(AppFonts.subheadline)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.leading)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(Spacing.lg)
        .background(Color.surface)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        .padding(.horizontal, Spacing.lg)
    }
}

// MARK: - Alert Modifier for AppError

struct AppErrorAlertModifier: ViewModifier {
    @Binding var error: AppError?
    var onRetry: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .alert(
                error?.title ?? "Error",
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                )
            ) {
                Button("OK") {
                    error = nil
                }
                if onRetry != nil {
                    Button("Retry") {
                        error = nil
                        onRetry?()
                    }
                }
            } message: {
                if let error = error {
                    Text(error.userMessage)
                }
            }
    }
}

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @Binding var toast: ToastMessage?
    let duration: TimeInterval

    func body(content: Content) -> some View {
        ZStack {
            content

            if let toast = toast {
                VStack {
                    ToastView(toast: toast) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            self.toast = nil
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                self.toast = nil
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.top, Spacing.xl)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: toast)
    }
}

// MARK: - View Extensions

extension View {
    /// Presents an alert for AppError with optional retry action
    func appErrorAlert(error: Binding<AppError?>, onRetry: (() -> Void)? = nil) -> some View {
        modifier(AppErrorAlertModifier(error: error, onRetry: onRetry))
    }

    /// Presents a toast message that auto-dismisses
    func toast(_ toast: Binding<ToastMessage?>, duration: TimeInterval = 3.0) -> some View {
        modifier(ToastModifier(toast: toast, duration: duration))
    }
}

// MARK: - Previews

#Preview("Toast Success") {
    ZStack {
        Color.surface.ignoresSafeArea()

        VStack {
            ToastView(toast: .success("Order updated successfully!")) {}
            ToastView(toast: .error("Failed to save changes")) {}
            ToastView(toast: .info("New orders available")) {}
            ToastView(toast: .warning("Low inventory warning")) {}
        }
        .padding()
    }
}
