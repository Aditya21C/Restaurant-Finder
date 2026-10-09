import SwiftUI
import RevenueCat

struct SubscriptionStatusView: View {
    @EnvironmentObject private var subManager: SubscriptionManager
    @State private var showManageSubError = false

    var body: some View {
        VStack(spacing: 25) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    .linearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Premium Access")
                .font(.largeTitle)
                .fontWeight(.bold)

            switch subManager.state {
            
            case .subscribed:
                if let details = subManager.details {
                    SubscriptionDetailsCard(details: details, showError: $showManageSubError)
                } else {
                    // This can show briefly while details are being parsed after a refresh.
                    ProgressView()
                }

            case .notSubscribed:
                VStack {
                    Text("You are not subscribed to Premium.")
                        .font(.headline)
                    Text("Unlock all features by subscribing.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
            case .loading:
                // This will show if the view appears before the initial launch check is complete.
                ProgressView()
                
            case .error(let message):
                VStack(spacing: 10) {
                    Image(systemName: "wifi.slash")
                        .font(.title)
                        .foregroundColor(.gray)
                    Text("Connection Error")
                        .font(.headline)
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            // FIX: Call the check with gentleRefresh: true
            // This ensures the data is refreshed without resetting the main navigation stack.
            Task {
                await subManager.checkSubscriptionStatus(gentleRefresh: true)
            }
        }
        .alert(
            "Could Not Open",
            isPresented: $showManageSubError
        ) {
            Button("OK") {}
        } message: {
            Text("We couldn't open the App Store's subscription page. Please check your connection and try again.")
        }
    }
}

// Helper View for UI clarity
struct SubscriptionDetailsCard: View {
    let details: SubscriptionDetails
    @Binding var showError: Bool
    
    var body: some View {
        VStack {
            // Details Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(details.planName)
                        .font(.title2.bold())
                    Spacer()
                    Text("ACTIVE")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green.gradient)
                        .clipShape(Capsule())
                }
                
                Divider()
                
                Text(details.expirationText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, y: 3)
            
            // Manage Button
            Button {
                Task {
                    do {
                        try await Purchases.shared.showManageSubscriptions()
                    } catch {
                        print("Error showing manage subscriptions: \(error)")
                        self.showError = true
                    }
                }
            } label: {
                Text("Manage Subscription")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.gradient)
                    .cornerRadius(10)
            }
        }
    }
}


#Preview {
    // For the preview to work, you'll need a mock SubscriptionManager
    // and to define the SubscriptionDetails struct if it's not in this file.
    SubscriptionStatusView()
        .environmentObject(SubscriptionManager())
}
