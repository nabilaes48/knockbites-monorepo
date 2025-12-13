//
//  AppError.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code - Unified Error Handling
//

import Foundation

/// A unified error type that provides user-friendly error messages.
/// All ViewModels should map errors to this type for consistent error presentation.
enum AppError: Error, LocalizedError, Identifiable {
    case network(underlying: Error?)
    case supabase(message: String)
    case validation(message: String)
    case notFound(resource: String)
    case unauthorized
    case serverError
    case unknown(underlying: Error?)

    var id: String {
        switch self {
        case .network: return "network"
        case .supabase(let message): return "supabase-\(message)"
        case .validation(let message): return "validation-\(message)"
        case .notFound(let resource): return "notFound-\(resource)"
        case .unauthorized: return "unauthorized"
        case .serverError: return "serverError"
        case .unknown: return "unknown"
        }
    }

    /// User-friendly error message for display
    var userMessage: String {
        switch self {
        case .network:
            return "Unable to connect. Please check your internet connection and try again."
        case .supabase(let message):
            return mapSupabaseMessage(message)
        case .validation(let message):
            return message
        case .notFound(let resource):
            return "The requested \(resource) could not be found."
        case .unauthorized:
            return "You don't have permission to perform this action."
        case .serverError:
            return "Something went wrong on our end. Please try again later."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }

    /// Error title for alerts
    var title: String {
        switch self {
        case .network:
            return "Connection Error"
        case .supabase:
            return "Database Error"
        case .validation:
            return "Invalid Input"
        case .notFound:
            return "Not Found"
        case .unauthorized:
            return "Access Denied"
        case .serverError:
            return "Server Error"
        case .unknown:
            return "Error"
        }
    }

    var errorDescription: String? {
        userMessage
    }

    /// Maps common Supabase error messages to user-friendly versions
    private func mapSupabaseMessage(_ message: String) -> String {
        let lowercased = message.lowercased()

        if lowercased.contains("network") || lowercased.contains("connection") {
            return "Unable to connect to the server. Please check your connection."
        }

        if lowercased.contains("permission") || lowercased.contains("rls") || lowercased.contains("policy") {
            return "You don't have permission to access this data."
        }

        if lowercased.contains("not found") || lowercased.contains("no rows") {
            return "The requested data could not be found."
        }

        if lowercased.contains("duplicate") || lowercased.contains("unique") {
            return "This item already exists."
        }

        if lowercased.contains("invalid") || lowercased.contains("malformed") {
            return "The data provided is invalid. Please check your input."
        }

        // For unrecognized errors, provide generic message
        return "A database error occurred. Please try again."
    }

    /// Factory method to create AppError from any Error
    static func from(_ error: Error) -> AppError {
        // Check if it's already an AppError
        if let appError = error as? AppError {
            return appError
        }

        let message = error.localizedDescription.lowercased()

        // Network errors
        if message.contains("network") ||
           message.contains("internet") ||
           message.contains("offline") ||
           message.contains("connection") ||
           message.contains("timed out") {
            return .network(underlying: error)
        }

        // Permission errors
        if message.contains("permission") ||
           message.contains("unauthorized") ||
           message.contains("forbidden") ||
           message.contains("access denied") {
            return .unauthorized
        }

        // Not found errors
        if message.contains("not found") ||
           message.contains("no rows") ||
           message.contains("missing") {
            return .notFound(resource: "data")
        }

        // Server errors
        if message.contains("server error") ||
           message.contains("500") ||
           message.contains("internal error") {
            return .serverError
        }

        // Supabase-specific
        if message.contains("supabase") ||
           message.contains("postgrest") ||
           message.contains("postgres") {
            return .supabase(message: error.localizedDescription)
        }

        return .unknown(underlying: error)
    }
}
