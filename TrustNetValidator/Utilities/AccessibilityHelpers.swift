import SwiftUI

// MARK: - Accessibility Helpers

struct AccessibilityModifier: ViewModifier {
    let label: String
    let hint: String?
    let role: AccessibilityRole?
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .if(role != nil) { view in
                view.accessibilityRole(role!)
            }
    }
}

extension View {
    func accessibleView(
        label: String,
        hint: String? = nil,
        role: AccessibilityRole? = nil
    ) -> some View {
        modifier(AccessibilityModifier(label: label, hint: hint, role: role))
    }
}

// MARK: - Conditional View Modifier

extension View {
    @ViewBuilder
    func `if`<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Dynamic Type Support

struct AdaptiveStack<Content: View>: View {
    let preferredWidth: CGFloat = 300
    @Environment(\.sizeCategory) var sizeCategory
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        if sizeCategory.isAccessibilityCategory {
            VStack {
                content
            }
        } else {
            HStack {
                content
            }
        }
    }
}

// MARK: - Color Contrast Utilities

struct ContrastText: View {
    let text: String
    let isHighContrast: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Text(text)
            .foregroundColor(
                isHighContrast ?
                (colorScheme == .dark ? .white : .black) :
                .secondary
            )
    }
}

// MARK: - VoiceOver Support

struct AccessibleButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label
    let hint: String?
    
    var body: some View {
        Button(action: action) {
            label()
        }
        .accessibilityHint(hint ?? "")
    }
}

// MARK: - Font Scaling Support

struct ScalableText: View {
    let text: String
    let baseFont: Font
    
    @Environment(\.sizeCategory) var sizeCategory
    
    var body: some View {
        Text(text)
            .font(baseFont)
            .lineLimit(nil)
            .tracking(sizeCategory.isAccessibilityCategory ? 1.0 : 0.0)
    }
}

// MARK: - High Contrast Icons

struct AccessibleIcon: View {
    let systemName: String
    let size: CGFloat
    let isHighContrast: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: isHighContrast ? .bold : .semibold))
            .foregroundColor(
                isHighContrast ?
                (colorScheme == .dark ? .white : .black) :
                .blue
            )
    }
}

// MARK: - Touch Target Sizing

struct MinimumTouchTarget: ViewModifier {
    let minimumSize: CGFloat = 48 // Apple recommendation
    
    func body(content: Content) -> some View {
        content
            .frame(minHeight: minimumSize)
            .contentShape(Rectangle())
    }
}

extension View {
    func minimumTouchTarget() -> some View {
        modifier(MinimumTouchTarget())
    }
}

// MARK: - Focus Ring Support

struct AccessibleFocusRing: ViewModifier {
    @FocusState private var isFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isFocused ? Color.blue : Color.clear,
                        lineWidth: 2
                    )
            )
    }
}

extension View {
    func accessibleFocusRing() -> some View {
        modifier(AccessibleFocusRing())
    }
}

// MARK: - Reduced Motion Support

struct MotionAwareAnimation: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let animation: Animation
    let value: Any
    
    func body(content: Content) -> some View {
        if reduceMotion {
            content.animation(.none, value: value)
        } else {
            content.animation(animation, value: value)
        }
    }
}

extension View {
    func motionAwareAnimation(
        _ animation: Animation,
        value: Any
    ) -> some View {
        modifier(MotionAwareAnimation(animation: animation, value: value))
    }
}

// MARK: - Testing Accessibility

#if DEBUG
extension View {
    func debugAccessibility() -> some View {
        self
            .border(Color.red, width: 1)
            .accessibility(hint: "DEBUG: Touch target outlined")
    }
}
#endif
