import Foundation
import RevenueCat
import Combine

// A state enum to represent all possible subscription states.
enum SubscriptionState {
    case loading
    case subscribed
    case notSubscribed
    case error(String)
}

// A simple struct to hold the subscription details we want to display.
struct SubscriptionDetails {
    let planName: String
    let expirationText: String
}

@MainActor
class SubscriptionManager: NSObject, ObservableObject, PurchasesDelegate {
    private let entitlementID = "Premium"

    @Published var state: SubscriptionState = .loading
    @Published var details: SubscriptionDetails?

    override init() {
        super.init()
        Purchases.shared.delegate = self
        // This is the initial launch check, so it should show the full loading screen.
        // We call it with the default gentleRefresh: false.
        Task {
            await checkSubscriptionStatus()
        }
    }
    
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        updateSubscriptionStatus(with: customerInfo)
    }

    // --- FIX: Added 'gentleRefresh' parameter ---
    // This allows sub-views to refresh data without triggering the global loading state.
    func checkSubscriptionStatus(gentleRefresh: Bool = false) async {
        // Only set the global state to .loading if it's NOT a gentle refresh.
        // This prevents the main ContentView from tearing down the UI during a background refresh.
        if !gentleRefresh {
            self.state = .loading
        }
        
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateSubscriptionStatus(with: customerInfo)
        } catch {
            print("Error fetching customer info: \(error.localizedDescription)")
            self.state = .error("Could not connect to server. Please check your internet connection.")
        }
    }

    private func updateSubscriptionStatus(with customerInfo: CustomerInfo?) {
        let isSubscribed = customerInfo?.entitlements[entitlementID]?.isActive == true

        if isSubscribed {
            self.state = .subscribed
            parseDetails(from: customerInfo)
        } else {
            self.state = .notSubscribed
            self.details = nil
        }
    }
    
    private func parseDetails(from customerInfo: CustomerInfo?) {
        guard let entitlement = customerInfo?.entitlements[entitlementID], entitlement.isActive else {
            self.details = nil
            return
        }
        
        let planName: String
        if entitlement.periodType == .trial {
            planName = "Free Trial"
        } else if entitlement.productIdentifier.contains("monthly") {
            planName = "Monthly Plan"
        } else if entitlement.productIdentifier.contains("annual") {
            planName = "Annual Plan"
        } else {
            planName = "Premium Plan"
        }

        let expirationText: String
        if let expirationDate = entitlement.expirationDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            
            if entitlement.willRenew {
                expirationText = "Renews on \(formatter.string(from: expirationDate))"
            } else {
                expirationText = "Expires on \(formatter.string(from: expirationDate))"
            }
        } else {
            expirationText = "No expiration date"
        }
        
        self.details = SubscriptionDetails(planName: planName, expirationText: expirationText)
    }
}
