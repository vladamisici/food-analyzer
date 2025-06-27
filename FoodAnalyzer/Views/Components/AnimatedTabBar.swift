import SwiftUI

struct AnimatedTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [TabItem]
    @Namespace private var namespace
    @State private var bounceTab: Int? = nil
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { index in
                TabButton(
                    item: tabs[index],
                    isSelected: selectedTab == index,
                    namespace: namespace,
                    onTap: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = index
                            bounceTab = index
                        }
                        HapticManager.shared.impact(.light)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            bounceTab = nil
                        }
                    }
                )
                .scaleEffect(bounceTab == index ? 1.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: bounceTab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.theme.surface)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        )
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

struct TabButton: View {
    let item: TabItem
    let isSelected: Bool
    let namespace: Namespace.ID
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? item.selectedIcon : item.icon)
                    .font(.system(size: 20))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(isSelected ? .white : .theme.textSecondary)
                    .rotationEffect(.degrees(isSelected ? 360 : 0))
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isSelected)
                
                if isSelected {
                    Text(item.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                }
            }
            .padding(.horizontal, isSelected ? 20 : 12)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.theme.primary, Color.theme.accent]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .matchedGeometryEffect(id: "tab", in: namespace)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct TabItem {
    let title: String
    let icon: String
    let selectedIcon: String
}

struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    @State private var showLabels = false
    
    let tabs = [
        TabItem(title: "Analyze", icon: "camera", selectedIcon: "camera.fill"),
        TabItem(title: "History", icon: "clock", selectedIcon: "clock.fill"),
        TabItem(title: "Goals", icon: "target", selectedIcon: "target"),
        TabItem(title: "Profile", icon: "person", selectedIcon: "person.fill")
    ]
    
    var body: some View {
        VStack {
            Spacer()
            
            AnimatedTabBar(selectedTab: $selectedTab, tabs: tabs)
        }
    }
}

struct MorphingTabBar: View {
    @Binding var selectedTab: Int
    @State private var indicatorOffset: CGFloat = 0
    @State private var indicatorWidth: CGFloat = 0
    
    let tabs = ["Analyze", "History", "Goals", "Profile"]
    let icons = ["camera.fill", "clock.fill", "target", "person.fill"]
    
    var body: some View {
        GeometryReader { geometry in
            let tabWidth = geometry.size.width / CGFloat(tabs.count)
            
            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    HStack(spacing: 0) {
                        ForEach(tabs.indices, id: \.self) { index in
                            VStack(spacing: 4) {
                                Image(systemName: icons[index])
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedTab == index ? .theme.primary : .gray)
                                    .scaleEffect(selectedTab == index ? 1.2 : 1.0)
                                    .offset(y: selectedTab == index ? -5 : 0)
                                
                                Text(tabs[index])
                                    .font(.caption)
                                    .foregroundColor(selectedTab == index ? .theme.primary : .gray)
                                    .opacity(selectedTab == index ? 1 : 0.7)
                            }
                            .frame(width: tabWidth)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    selectedTab = index
                                    indicatorOffset = CGFloat(index) * tabWidth
                                }
                            }
                        }
                    }
                    
                    Capsule()
                        .fill(Color.theme.primary)
                        .frame(width: 40, height: 4)
                        .offset(x: indicatorOffset - (geometry.size.width / 2) + 20)
                }
                .padding(.vertical, 8)
                .background(
                    Color.theme.surface
                        .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
                )
            }
            .onAppear {
                indicatorOffset = CGFloat(selectedTab) * tabWidth
            }
        }
        .frame(height: 70)
    }
}

#Preview {
    VStack {
        Spacer()
        
        FloatingTabBar(selectedTab: .constant(0))
        
        MorphingTabBar(selectedTab: .constant(1))
            .padding(.top, 20)
    }
    .background(Color.theme.background)
}