//
//  OperatingHoursView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct OperatingHoursView: View {
    @Environment(\.dismiss) var dismiss
    @State private var operatingHours: [DaySchedule] = DaySchedule.defaultSchedule()
    @State private var showSaveConfirmation = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Info Banner
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.brandPrimary)
                        Text("Set your store's operating hours for each day of the week")
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)
                    }
                    .padding()
                    .background(Color.brandPrimary.opacity(0.1))
                    .cornerRadius(CornerRadius.md)
                    .padding(.horizontal)

                    // Days Schedule
                    VStack(spacing: Spacing.md) {
                        ForEach($operatingHours) { $schedule in
                            DayScheduleRow(schedule: $schedule)
                        }
                    }
                    .padding(.horizontal)

                    // Quick Actions
                    VStack(spacing: Spacing.sm) {
                        Button(action: {
                            // Apply weekday hours to all weekdays
                            applyWeekdayHours()
                        }) {
                            HStack {
                                Image(systemName: "calendar")
                                Text("Apply to All Weekdays")
                                Spacer()
                            }
                            .padding()
                            .background(Color.surface)
                            .foregroundColor(.brandPrimary)
                            .cornerRadius(CornerRadius.md)
                        }

                        Button(action: {
                            // Close all days
                            closeAllDays()
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Close All Days")
                                Spacer()
                            }
                            .padding()
                            .background(Color.surface)
                            .foregroundColor(.error)
                            .cornerRadius(CornerRadius.md)
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 100)
                }
                .padding(.vertical)
            }
            .navigationTitle("Operating Hours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        showSaveConfirmation = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            dismiss()
                        }
                    }
                    .fontWeight(.bold)
                }
            }
            .alert("Operating Hours Updated", isPresented: $showSaveConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your store's operating hours have been successfully updated.")
            }
        }
    }

    private func applyWeekdayHours() {
        let mondaySchedule = operatingHours[0]
        for index in 1..<5 {
            operatingHours[index].isOpen = mondaySchedule.isOpen
            operatingHours[index].openTime = mondaySchedule.openTime
            operatingHours[index].closeTime = mondaySchedule.closeTime
        }
    }

    private func closeAllDays() {
        for index in 0..<operatingHours.count {
            operatingHours[index].isOpen = false
        }
    }
}

// MARK: - Day Schedule Row
struct DayScheduleRow: View {
    @Binding var schedule: DaySchedule

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text(schedule.dayName)
                    .font(AppFonts.headline)
                    .frame(width: 100, alignment: .leading)

                Spacer()

                Toggle("", isOn: $schedule.isOpen)
                    .labelsHidden()

                Text(schedule.isOpen ? "Open" : "Closed")
                    .font(AppFonts.subheadline)
                    .foregroundColor(schedule.isOpen ? .success : .error)
                    .frame(width: 60, alignment: .trailing)
            }

            if schedule.isOpen {
                HStack(spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Opens")
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)

                        DatePicker("", selection: $schedule.openTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                    }

                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)
                        .font(.caption)

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Closes")
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)

                        DatePicker("", selection: $schedule.closeTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, Spacing.sm)
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppShadow.sm, radius: 2, y: 1)
    }
}

// MARK: - Day Schedule Model
struct DaySchedule: Identifiable {
    let id = UUID()
    let dayName: String
    var isOpen: Bool
    var openTime: Date
    var closeTime: Date

    static func defaultSchedule() -> [DaySchedule] {
        let calendar = Calendar.current
        let openTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        let closeTime = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()

        return [
            DaySchedule(dayName: "Monday", isOpen: true, openTime: openTime, closeTime: closeTime),
            DaySchedule(dayName: "Tuesday", isOpen: true, openTime: openTime, closeTime: closeTime),
            DaySchedule(dayName: "Wednesday", isOpen: true, openTime: openTime, closeTime: closeTime),
            DaySchedule(dayName: "Thursday", isOpen: true, openTime: openTime, closeTime: closeTime),
            DaySchedule(dayName: "Friday", isOpen: true, openTime: openTime, closeTime: closeTime),
            DaySchedule(dayName: "Saturday", isOpen: true, openTime: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date(), closeTime: calendar.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()),
            DaySchedule(dayName: "Sunday", isOpen: false, openTime: openTime, closeTime: closeTime)
        ]
    }

    var formattedHours: String {
        guard isOpen else { return "Closed" }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        return "\(formatter.string(from: openTime)) - \(formatter.string(from: closeTime))"
    }
}

#Preview {
    OperatingHoursView()
}
