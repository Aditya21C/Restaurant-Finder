//
//  CustomTabBarView.swift
//  Settld
//
//  Created by Mayukh Baidya on 08/07/25.
//

import SwiftUI

// MARK: - Tab Enum
/// Defines the cases for the tab bar. Placing it in the same file
/// keeps the component self-contained.
enum Tab: String, CaseIterable {
    case home = "house.fill"
    case add = "plus.circle.fill" // This is the action button
    case search = "magnifyingglass.circle.fill"
    case settings = "gear.circle.fill"
}

// MARK: - Custom Tab Bar View
struct CustomTabBarView: View {
    @Binding var selectedTab: Tab
    var animationNamespace: Namespace.ID
    
    /// A closure that is called when the user taps the '+' button.
    let onAddButtonTapped: () -> Void
    
    private var tabItems: [Tab] {
        Tab.allCases
    }
    
    var body: some View {
        HStack {
            ForEach(tabItems, id: \.self) { tab in
                Spacer()
                Button(action: {
                    // If the 'add' button is tapped, perform the dedicated action.
                    // Otherwise, switch the selected tab with an animation.
                    if tab == .add {
                        onAddButtonTapped()
                    } else {
                        withAnimation(.spring()) {
                            self.selectedTab = tab
                        }
                    }
                }) {
                    tabButtonView(for: tab)
                }
                Spacer()
            }
        }
        .padding(.horizontal)
        .frame(height: 70)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.black)
                .shadow(radius: 5)
        )
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
    
    /// Helper function to build the visual content for each tab button.
    @ViewBuilder
    private func tabButtonView(for tab: Tab) -> some View {
        VStack {
            ZStack {
                // The background highlight should only show for selectable tabs
                if selectedTab == tab && tab != .add {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .scaleEffect(1.2)
                }
                
                Image(systemName: tab.rawValue)
                    .font(tab == .add ? .system(size: 38, weight: .bold) : .system(size: 22, weight: .semibold))
                    .foregroundStyle(selectedTab == tab && tab != .add ? .white : .gray)
                    .scaleEffect(selectedTab == tab && tab != .add ? 1.2 : 1.0)
                    .rotation3DEffect(.degrees(selectedTab == tab && tab != .add ? 360 : 0), axis: (x: 0.0, y: 1.0, z: 0.0))
            }
            .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.1), value: selectedTab)
            
            // The indicator dot should only show for selectable tabs
            if selectedTab == tab && tab != .add {
                Circle()
                    .matchedGeometryEffect(id: "indicator", in: animationNamespace)
                    .frame(width: 6, height: 6)
                    .foregroundStyle(.white)
                    .offset(y: 4)
            }
        }
        .padding()
    }
}


// MARK: - Preview
struct CustomTabBarView_Previews: PreviewProvider {
    // A simple wrapper view is needed to hold the state for the preview
    struct PreviewWrapper: View {
        @State private var selectedTab: Tab = .home
        @Namespace private var animationNamespace

        var body: some View {
            ZStack {
                // Background color for better visibility
                Color.gray.opacity(0.2).ignoresSafeArea()
                
                VStack {
                    Spacer()
                    CustomTabBarView(
                        selectedTab: $selectedTab,
                        animationNamespace: animationNamespace,
                        onAddButtonTapped: {
                            print("Add button was tapped in preview.")
                        }
                    )
                }
            }
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
