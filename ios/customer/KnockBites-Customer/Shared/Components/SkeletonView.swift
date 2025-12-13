//
//  SkeletonView.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

// MARK: - Skeleton Base
struct SkeletonView: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    @State private var isAnimating = false

    init(width: CGFloat? = nil, height: CGFloat, cornerRadius: CGFloat = CornerRadius.md) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.2),
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.2)
                    ],
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Menu Item Skeleton
struct MenuItemSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            SkeletonView(height: 160, cornerRadius: 0)

            // Content Section
            VStack(alignment: .leading, spacing: 8) {
                // Title
                SkeletonView(width: 130, height: 20, cornerRadius: 4)

                // Description
                VStack(alignment: .leading, spacing: 4) {
                    SkeletonView(height: 13, cornerRadius: 4)
                    SkeletonView(width: 110, height: 13, cornerRadius: 4)
                }

                // Tags
                HStack(spacing: 6) {
                    SkeletonView(width: 35, height: 16, cornerRadius: 4)
                    SkeletonView(width: 35, height: 16, cornerRadius: 4)
                }
                .frame(height: 20)

                // Price and Button
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        SkeletonView(width: 65, height: 18, cornerRadius: 4)
                        SkeletonView(width: 55, height: 11, cornerRadius: 4)
                    }
                    Spacer()
                    Circle()
                        .fill(Color.gray.opacity(0.25))
                        .frame(width: 40, height: 40)
                }
                .frame(height: 44)
            }
            .padding(12)
        }
        .background(Color.surface)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        )
    }
}

// MARK: - Order Item Skeleton
struct OrderItemSkeleton: View {
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Image
            SkeletonView(width: 80, height: 80, cornerRadius: CornerRadius.md)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Title
                SkeletonView(width: 150, height: 18, cornerRadius: CornerRadius.sm)

                // Subtitle
                SkeletonView(width: 100, height: 14, cornerRadius: CornerRadius.sm)

                Spacer()

                // Price
                SkeletonView(width: 60, height: 16, cornerRadius: CornerRadius.sm)
            }

            Spacer()
        }
        .frame(height: 80)
        .padding(Spacing.md)
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Category Chip Skeleton
struct CategoryChipSkeleton: View {
    var body: some View {
        SkeletonView(width: 100, height: 36, cornerRadius: CornerRadius.xl)
    }
}

// MARK: - Store Card Skeleton
struct StoreCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Image
            SkeletonView(height: 120, cornerRadius: CornerRadius.md)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Title
                SkeletonView(width: 140, height: 20, cornerRadius: CornerRadius.sm)

                // Address
                SkeletonView(height: 14, cornerRadius: CornerRadius.sm)
                SkeletonView(width: 120, height: 14, cornerRadius: CornerRadius.sm)

                // Distance and status
                HStack {
                    SkeletonView(width: 80, height: 12, cornerRadius: CornerRadius.sm)
                    Spacer()
                    SkeletonView(width: 60, height: 12, cornerRadius: CornerRadius.sm)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.bottom, Spacing.sm)
        }
        .background(Color.surface)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Order Card Skeleton
struct OrderCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                // Order number
                SkeletonView(width: 80, height: 16, cornerRadius: CornerRadius.sm)
                Spacer()
                // Date
                SkeletonView(width: 100, height: 14, cornerRadius: CornerRadius.sm)
            }

            // Status
            SkeletonView(width: 120, height: 20, cornerRadius: CornerRadius.sm)

            Divider()

            // Items
            VStack(alignment: .leading, spacing: Spacing.xs) {
                SkeletonView(width: 150, height: 14, cornerRadius: CornerRadius.sm)
                SkeletonView(width: 130, height: 14, cornerRadius: CornerRadius.sm)
            }

            HStack {
                // Total label
                SkeletonView(width: 60, height: 18, cornerRadius: CornerRadius.sm)
                Spacer()
                // Total amount
                SkeletonView(width: 70, height: 18, cornerRadius: CornerRadius.sm)
            }
        }
        .padding(Spacing.md)
        .background(Color.surface)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview("Menu Item Skeleton") {
    MenuItemSkeleton()
        .padding()
}

#Preview("Order Item Skeleton") {
    OrderItemSkeleton()
        .padding()
}

#Preview("Multiple Skeletons") {
    VStack(spacing: Spacing.md) {
        MenuItemSkeleton()
        OrderCardSkeleton()
        StoreCardSkeleton()
    }
    .padding()
    .background(Color.background)
}
