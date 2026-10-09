//
//  AboutMeView.swift
//  SettleIt
//
//  Created by Mayukh Baidya on 21/07/25.
//

import SwiftUI

// Main View for your "About Me" page.
// You can embed this in a NavigationView in your app's settings.
struct AboutMayukhView: View {
    // Replace these with your actual social media URLs
    let twitterURL = URL(string: "https://x.com/mayukh_18")!
    let instagramURL = URL(string: "https://www.instagram.com/mayukh.baidya/")!

    var body: some View {
        ZStack {
            // Dark background color for the entire view
            Color(red: 0.1, green: 0.1, blue: 0.12).edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 30) {
                    
                    // --- HEADER ---
                    VStack(spacing: 30) {
                        Image("mayukh")
                             .resizable()
                             .aspectRatio(contentMode: .fill)
                             .frame(width: 100, height: 100)



                        Text("Hey, I'm Mayukh 👋")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)

                    // --- DESCRIPTION TEXT ---
                    VStack(alignment: .leading, spacing: 15) {
                        Text(
                            "I'm a 20-year-old developer based in Bangalore, India and the entire \"team\" behind this app is just me. I built Settld for a very simple reason: I was tired of the endless arguments with my friends about where to eat."
                        )
                        
                        Text(
                            "You know the drill; the negotiations would get more intense than a high-stakes match because, well, everyone was too lazy to travel far. Our hangouts were starting with debates, so I decided to let code play the fair mediator."
                        )
                        
                        Text(
                            "Settld ends that classic standoff. It finds a sweet spot so no one has to travel for ages. And let's be real, haven't we all, once in our life, walked into a restaurant, seen the prices, and immediately regretted it? Settld gives you the info you need to avoid that, so you can spend less time debating and more time actually enjoying good food and company."
                        )
                        
                        Text("Hope it helps you as much as it has helped my friends and me!")
                        
                        Text("- Mayukh")
                            .padding(.top, 5)

                    }
                    .font(.body)
                    .foregroundColor(Color(white: 0.85))
                    .lineSpacing(5)
                    
                    // --- SOCIAL LINKS ---
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Follow My Journey")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.bottom, 5)

                        SocialLinkView(
                            url: twitterURL,
                            icon: AnyView(TwitterIcon()),
                            text: "Twitter"
                        )
                        
                        SocialLinkView(
                            url: instagramURL,
                            icon: AnyView(InstagramIcon()),
                            text: "Instagram"
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// A reusable view for the social media link buttons.
struct SocialLinkView: View {
    let url: URL
    let icon: AnyView
    let text: String

    var body: some View {
        Link(destination: url) {
            HStack {
                icon // The custom icon view is placed here
                Text(text)
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(white: 0.15))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
}

// --- CUSTOM BRAND ICONS ---
// IMPORTANT: Add a "twitter_logo.png" or "twitter_logo.svg" to your Assets.xcassets
struct TwitterIcon: View {
    var body: some View {
        Image("twitter_logo") // This now refers to your custom image asset
             .resizable()
             .aspectRatio(contentMode: .fit)
             .frame(width: 24, height: 24)
    }
}

// IMPORTANT: Add an "instagram_logo.png" or "instagram_logo.svg" to your Assets.xcassets
struct InstagramIcon: View {
    var body: some View {
        Image("instagram_logo") // This now refers to your custom image asset
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 24)
    }
}


// --- PREVIEW ---
struct AboutMayukhView_Previews: PreviewProvider {
    static var previews: some View {
        AboutMayukhView()
    }
}

