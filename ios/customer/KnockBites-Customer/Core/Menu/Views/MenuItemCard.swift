//
//  MenuItemCard.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct MenuItemCard: View {
    let item: MenuItem
    var onQuickAdd: (() -> Void)?
    @EnvironmentObject var favoritesViewModel: FavoritesViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel

    private var hasWarning: Bool {
        profileViewModel.hasCompatibilityIssue(with: item)
    }

    var body: some View {
        // Menu item card with FIXED sizing to prevent overlap
        // Card width is calculated to fit exactly in grid column
        // Image is constrained to prevent stretching the card
        let screenWidth = UIScreen.main.bounds.width
        let cardWidth = (screenWidth - 44) / 2 // 16px edge padding + 12px column spacing = 44px total

        return VStack(alignment: .leading, spacing: 0) {
            // Image with Favorite Button
            ZStack(alignment: .topTrailing) {
                // Image - FIXED width to prevent card stretching
                AsyncImage(url: URL(string: item.imageURL)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.15))
                            .overlay(
                                SkeletonView(height: 160, cornerRadius: 0)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .transition(.opacity.combined(with: .scale(scale: 1.05)))
                    case .failure:
                        // Gradient placeholder with item monogram
                        ZStack {
                            // Gradient background based on item category
                            LinearGradient(
                                gradient: Gradient(colors: gradientColors(for: item)),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )

                            VStack(spacing: 8) {
                                // Item monogram (first letter)
                                Text(String(item.name.prefix(1)).uppercased())
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.white)

                                // Food icon
                                Image(systemName: "fork.knife")
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    @unknown default:
                        Color.gray.opacity(0.15)
                    }
                }
                .frame(width: cardWidth, height: 160)
                .clipped()
                .animation(.easeInOut(duration: 0.3), value: item.imageURL)

                // Overlay buttons
                HStack(spacing: 8) {
                    // Warning Badge
                    if hasWarning {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 32, height: 32)

                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                    }

                    // Favorite Button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            favoritesViewModel.toggleFavorite(item)
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.4))
                                .frame(width: 36, height: 36)

                            Image(systemName: favoritesViewModel.isFavorite(item.id) ? "heart.fill" : "heart")
                                .font(.system(size: 16))
                                .foregroundColor(favoritesViewModel.isFavorite(item.id) ? .red : .white)
                        }
                    }
                }
                .padding(12)
            }

            // Content Section
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(height: 20, alignment: .leading)

                // Description
                Text(item.description)
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
                    .frame(height: 34, alignment: .top)

                // Dietary Tags
                HStack(spacing: 6) {
                    if !item.dietaryInfo.isEmpty {
                        ForEach(Array(item.dietaryInfo.prefix(2)), id: \.self) { tag in
                            HStack(spacing: 3) {
                                Image(systemName: tag.icon)
                                    .font(.system(size: 9))
                            }
                            .foregroundColor(colorForTag(tag))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(colorForTag(tag).opacity(0.12))
                            .cornerRadius(4)
                        }

                        // Show count badge if more than 2 tags
                        if item.dietaryInfo.count > 2 {
                            Text("+\(item.dietaryInfo.count - 2)")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.textSecondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.gray.opacity(0.15))
                                .cornerRadius(4)
                        }
                    }
                }
                .frame(height: 20, alignment: .leading)

                // Bottom Section: Price and Add Button
                HStack(alignment: .center, spacing: 0) {
                    // Price and Time
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.formattedPrice)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.brandPrimary)

                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                            Text("\(item.prepTime) min")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    // Add Button
                    if let onQuickAdd = onQuickAdd {
                        Button(action: onQuickAdd) {
                            ZStack {
                                Circle()
                                    .fill(Color.brandPrimary)
                                    .frame(width: 40, height: 40)

                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .frame(height: 44)
            }
            .padding(12)
        }
        .frame(width: cardWidth) // FIXED width prevents card from stretching
        .background(Color.surface)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        )
    }

    private func colorForTag(_ tag: DietaryTag) -> Color {
        switch tag {
        case .vegetarian, .vegan: return .green
        case .glutenFree: return .orange
        case .dairyFree: return .blue
        case .nutFree: return .brown
        case .spicy: return .red
        case .keto: return .purple
        }
    }

    private func gradientColors(for item: MenuItem) -> [Color] {
        // Generate colors based on category ID for consistency
        let categoryHash = item.categoryId.hashValue
        let colorSets: [[Color]] = [
            [Color(red: 0.95, green: 0.35, blue: 0.24), Color(red: 0.96, green: 0.56, blue: 0.24)], // Red-Orange
            [Color(red: 0.35, green: 0.67, blue: 0.95), Color(red: 0.45, green: 0.82, blue: 0.95)], // Blue
            [Color(red: 0.67, green: 0.35, blue: 0.95), Color(red: 0.82, green: 0.45, blue: 0.95)], // Purple
            [Color(red: 0.35, green: 0.95, blue: 0.67), Color(red: 0.45, green: 0.95, blue: 0.82)], // Green
            [Color(red: 0.95, green: 0.67, blue: 0.35), Color(red: 0.95, green: 0.82, blue: 0.45)], // Orange-Yellow
            [Color(red: 0.95, green: 0.35, blue: 0.67), Color(red: 0.95, green: 0.45, blue: 0.82)]  // Pink
        ]

        return colorSets[abs(categoryHash) % colorSets.count]
    }
}

// MARK: - Dietary Badge
struct DietaryBadge: View {
    let tag: DietaryTag
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: tag.icon)
            if !compact {
                Text(tag.rawValue)
            }
        }
        .font(.system(size: compact ? 10 : 11))
        .foregroundColor(colorForTag(tag))
        .padding(.horizontal, compact ? 4 : 6)
        .padding(.vertical, compact ? 2 : 4)
        .background(colorForTag(tag).opacity(0.15))
        .cornerRadius(4)
    }

    private func colorForTag(_ tag: DietaryTag) -> Color {
        switch tag {
        case .vegetarian, .vegan: return .green
        case .glutenFree: return .orange
        case .dairyFree: return .blue
        case .nutFree: return .brown
        case .spicy: return .red
        case .keto: return .purple
        }
    }
}

#Preview {
    ScrollView {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
            ForEach(MockDataService.shared.getMenuItems().prefix(4)) { item in
                MenuItemCard(item: item, onQuickAdd: {})
            }
        }
        .padding()
    }
}
