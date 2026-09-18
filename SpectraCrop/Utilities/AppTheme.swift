//  AppTheme.swift
//  SpectraCrop
//
//  Created by SpectraCrop Development Team
//  Copyright © 2026 SpectraCrop. All rights reserved.
//

import SwiftUI

// MARK: - App Color Theme

// Custom colors matching the plant graphics from the old app
extension Color {
    // Primary brand colors - defined with RGB values
    // These match the plant color scheme from the old Xamarin app
    static let primaryGreen = Color(red: 0.0/255.0, green: 160.0/255.0, blue: 100.0/255.0)
    static let primaryBlue = Color(red: 30.0/255.0, green: 144.0/255.0, blue: 255.0/255.0)
    static let primaryCyan = Color(red: 0.0/255.0, green: 180.0/255.0, blue: 200.0/255.0)
    static let primaryPurple = Color(red: 147.0/255.0, green: 50.0/255.0, blue: 200.0/255.0)
    static let primaryYellow = Color(red: 255.0/255.0, green: 200.0/255.0, blue: 0.0/255.0)
    static let primaryRed = Color(red: 220.0/255.0, green: 50.0/255.0, blue: 50.0/255.0)
    static let primaryGray = Color(red: 150.0/255.0, green: 150.0/255.0, blue: 150.0/255.0)
    
    // Semantic colors for light/dark mode
    // These adapt automatically based on the user's color scheme
    static let appBackground = Color(uiColor: .systemBackground)
    static let cardBackground = Color(uiColor: .secondarySystemBackground)
    static let textPrimary = Color(uiColor: .label)
    static let textSecondary = Color(uiColor: .secondaryLabel)
    
    // Quality indicator colors
    static let qualityGood = Color.green
    static let qualityPoor = Color.red
    static let qualityFair = Color.yellow
}

// Preview providers for Color extensions
#if DEBUG
struct ColorPreview: View {
    let color: Color
    let name: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Rectangle()
                .fill(color)
                .frame(height: 40)
            Text(name)
                .font(.caption)
        }
        .padding()
    }
}

#Preview {
    VStack {
        ColorPreview(color: .primaryGreen, name: "Primary Green")
        ColorPreview(color: .primaryBlue, name: "Primary Blue")
        ColorPreview(color: .qualityGood, name: "Quality Good")
    }
}
#endif

// MARK: - Haptic Feedback Utility

struct HapticFeedback {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Loading View Styles

struct LoadingView: View {
    let style: Style
    
    enum Style {
        case small
        case medium
        case large
    }
    
    var body: some View {
        Group {
            switch style {
            case .small:
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.small)
            case .medium:
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.regular)
            case .large:
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.large)
            }
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let image: Image?
    let title: String
    let message: String
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(title: String, message: String, image: Image? = nil, action: (() -> Void)? = nil, actionTitle: String? = nil) {
        self.image = image
        self.title = title
        self.message = message
        self.action = action
        self.actionTitle = actionTitle
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if let image = image {
                image
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                    .padding()
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            if let action = action, let actionTitle = actionTitle {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.primaryBlue.opacity(0.2), Color.primaryBlue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.primaryBlue.opacity(0.3), radius: 10, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.clear)
            .foregroundColor(Color.primaryBlue)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primaryBlue, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Liquid Glass Button Styles

struct GlassPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .blur(radius: configuration.isPressed ? 2 : 0)
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct GlassSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.thinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primaryBlue.opacity(0.5), lineWidth: 1)
                    )
            )
            .foregroundColor(Color.primaryBlue)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - View Modifiers

extension View {
    /// Adds a subtle shadow effect
    func cardShadow() -> some View {
        self
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /// Adds a stronger shadow effect
    func prominentShadow() -> some View {
        self
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    /// Adds a border with the app's primary color
    func primaryBorder(width: CGFloat = 1) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primaryBlue, lineWidth: width)
            )
    }
    
    /// Applies the standard card styling
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
            .cardShadow()
    }
    
    /// Applies liquid glass card styling with frosted glass effect
    func glassCardStyle() -> some View {
        self
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .prominentShadow()
    }
    
    /// Applies liquid glass effect with blur
    func glassMorphism() -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
    
    /// Adds a modern glow effect
    func glowEffect(color: Color = .primaryBlue, radius: CGFloat = 10) -> some View {
        self
            .shadow(color: color.opacity(0.3), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.2), radius: radius * 2, x: 0, y: 0)
    }
}
