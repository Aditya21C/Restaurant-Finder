import SwiftUI

// MARK: - Main Onboarding View
struct OnboardingView: View {
    let onComplete: () -> Void
    
    private let pages: [OnboardingPage] = [
        .init(imageName: "no_bg_appicon", isSystemImage: false, title: "Settld", description: "Makes group plans effortless."),
        .init(imageName: "location.fill.viewfinder", isSystemImage: true, title: "Smart Group Meetups", description: "Let our algorithm find restaurants that are convenient for everyone in your group."),
        .init(imageName: "car.2.fill", isSystemImage: true, title: "See Travel Time for All", description: "Instantly view how far each friend has to travel; no more guesswork required."),
        .init(imageName: "building.2.crop.circle", isSystemImage: true, title: "Explore Destinations", description: "Preview restaurants, cafes and more with Apple’s Look Around and explore routes with detailed directions."),
        .init(imageName: "magnifyingglass.circle.fill", isSystemImage: true, title: "Search Anything", description: "Find malls, movie theatres, hotels and much more in any city—even without GPS sharing.")
    ]

    @State private var currentPage = 0
    @State private var isButtonVisible = false
    @State private var isPageContentVisible = true

    var body: some View {
        ZStack {
            animatedBackground.ignoresSafeArea()
            ParticleView().opacity(0.5)
            
            VStack {
                Spacer()
                
                ZStack {
                    if isPageContentVisible {
                        OnBoardPageView(
                            page: pages[currentPage],
                            onAnimationComplete: {
                                withAnimation(.easeIn(duration: 0.4)) {
                                    isButtonVisible = true
                                }
                            }
                        )
                        .id(currentPage)
                        .transition(.premiumPage)
                    }
                }
                
                Spacer()
                Spacer()

                VStack(spacing: 20) {
                    pageIndicator
                    actionButton
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            isPageContentVisible = true
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Subviews
    private var pageIndicator: some View {
        HStack(spacing: 12) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule()
                    .fill(.white.opacity(currentPage == index ? 1 : 0.3))
                    .frame(width: currentPage == index ? 24 : 8, height: 8)
            }
        }
        .animation(.smooth(duration: 0.5), value: currentPage)
    }
    
    @ViewBuilder
    private var actionButton: some View {
        if isButtonVisible {
            Button(action: handleButtonTap) {
                Text(currentPage == pages.count - 1 ? "Get Started!" : "Continue")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.teal, Color.cyan, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .overlay(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear, .white.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .teal.opacity(0.4), radius: 15, y: 5)
                        .overlay(ShimmerOverlay())
                    )
            }
            .transition(.scale.combined(with: .opacity))
            .scaleEffect(isButtonVisible ? 1 : 0.95)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isButtonVisible)
        } else {
            Capsule().fill(.clear).frame(height: 50)
        }
    }
    
    private var animatedBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#1a1a2e"),
                    Color(hex: "#16213e"),
                    Color(hex: "#0f3460")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            RadialGradient(
                colors: [Color.white.opacity(0.05), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 500
            )
            .blendMode(.screen)
            
            MovingBlob(color: Color(hex: "#e94560").opacity(0.6))
            MovingBlob(color: Color(hex: "#0f3460").opacity(0.6))
        }
    }
    
    // MARK: - Logic
    private func handleButtonTap() {
        let animationDuration = 0.4
        if currentPage < pages.count - 1 {
            isButtonVisible = false
            withAnimation(.easeInOut(duration: animationDuration)) {
                isPageContentVisible = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                currentPage += 1
                isPageContentVisible = true
            }
        } else {
            onComplete()
        }
    }
}

struct ShimmerOverlay: View {
    @State private var shimmerX: CGFloat = -180

    var body: some View {
        GeometryReader { geo in
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0), .white.opacity(0.6), .white.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: geo.size.width) // match the button width
                .offset(x: shimmerX)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5)
                        .delay(0.5)
                        .repeatForever(autoreverses: false)) {
                        shimmerX = geo.size.width + 180 // travel fully across
                    }
                }
        }
        .clipShape(Capsule()) // ensure shimmer stays inside button
    }
}


// MARK: - OnBoardPageView
struct OnBoardPageView: View {
    let page: OnboardingPage
    let onAnimationComplete: () -> Void
    
    @State private var displayedDescription: String = ""
    @State private var animationTimer: Timer?
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)
    
    @State private var isAnimating = false
    @State private var dragAmount = CGSize.zero

    var body: some View {
        VStack(spacing: 24) {
            iconView
                .scaleEffect(isAnimating ? 1 : 0.8)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2), value: isAnimating)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                    .opacity(isAnimating ? 1 : 0)
                    .animation(.easeOut.delay(0.3), value: isAnimating)

                Text(displayedDescription)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(height: 100, alignment: .top)
                    .opacity(isAnimating ? 1 : 0)
                    .animation(.easeOut.delay(0.4), value: isAnimating)
            }
        }
        .multilineTextAlignment(.center)
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 35, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 35)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 30, y: 10)
        )
        .offset(x: dragAmount.width * 0.3, y: dragAmount.height * 0.3)
        .rotation3DEffect(.degrees(Double(dragAmount.width) / 15), axis: (x: 0, y: -1, z: 0))
        .rotation3DEffect(.degrees(Double(dragAmount.height) / 15), axis: (x: 1, y: 0, z: 0))
        .gesture(
            DragGesture()
                .onChanged { dragAmount = $0.translation }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        dragAmount = .zero
                    }
                }
        )
        .onAppear(perform: setup)
        .onDisappear {
            animationTimer?.invalidate()
        }
    }
    
    @ViewBuilder
    private var iconView: some View {
        Group {
            if page.isSystemImage {
                Image(systemName: page.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.teal)
            } else {
                Image(page.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
            }
        }
        .padding(30)
        .background(
            ZStack {
                Circle()
                    .fill(Color.teal.opacity(0.2))
                    .blur(radius: 20)
                    .scaleEffect(isAnimating ? 1.2 : 1)
                    .animation(.easeInOut(duration: 2).repeatForever(), value: isAnimating)
                
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        )
        .shadow(color: .teal.opacity(0.4), radius: 25)
    }
    
    private func setup() {
        isAnimating = true
        animateText()
    }
    
    private func animateText() {
        animationTimer?.invalidate()
        displayedDescription = ""
        let characters = Array(page.description)
        var index = 0
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            guard index < characters.count else {
                timer.invalidate(); onAnimationComplete(); return
            }
            displayedDescription.append(characters[index])
            hapticGenerator.impactOccurred()
            index += 1
        }
    }
}

// MARK: - Premium Page Transition
extension AnyTransition {
    static var premiumPage: AnyTransition {
        .asymmetric(
            insertion: .modifier(active: PremiumPageModifier(progress: 0), identity: PremiumPageModifier(progress: 1)),
            removal: .modifier(active: PremiumPageModifier(progress: 0), identity: PremiumPageModifier(progress: 1))
        )
    }
}

struct PremiumPageModifier: ViewModifier {
    var progress: Double
    func body(content: Content) -> some View {
        content
            .opacity(progress)
            .scaleEffect(0.9 + progress * 0.1)
            .blur(radius: (1 - progress) * 6)
    }
}

// MARK: - Moving Blob
struct MovingBlob: View {
    @State private var xOffset: CGFloat = .random(in: -200...200)
    @State private var yOffset: CGFloat = .random(in: -200...200)
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 350, height: 350)
            .blur(radius: 100)
            .offset(x: xOffset, y: yOffset)
            .onAppear {
                withAnimation(.easeInOut(duration: 20).repeatForever(autoreverses: true)) {
                    xOffset = .random(in: -200...200)
                    yOffset = .random(in: -200...200)
                }
            }
    }
}

// MARK: - Particle System
struct Particle: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var size: Double
    var opacity: Double
    var speed: Double
}

struct ParticleView: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                for particle in particles {
                    let frame = CGRect(x: particle.x, y: particle.y, width: particle.size, height: particle.size)
                    context.fill(Path(ellipseIn: frame), with: .color(.white.opacity(max(0, particle.opacity))))
                }
            }
            .onChange(of: timeline.date) { _ in
                updateParticles()
            }
        }
        .onAppear(perform: setupParticles)
    }
    
    private func setupParticles() {
        particles = (1...40).map { _ in createParticle() }
    }
    
    private func updateParticles() {
        for i in particles.indices {
            particles[i].y -= particles[i].speed
            particles[i].opacity -= 0.003
            if particles[i].y < -particles[i].size {
                particles[i] = createParticle()
            }
        }
    }
    
    private func createParticle() -> Particle {
        let size = UIScreen.main.bounds
        return Particle(
            x: .random(in: 0...size.width),
            y: size.height + .random(in: 0...50),
            size: .random(in: 2...7),
            opacity: .random(in: 0.3...1),
            speed: .random(in: 0.5...2.5)
        )
    }
}

// MARK: - Supporting Code
struct OnboardingPage {
    let id = UUID()
    let imageName: String, isSystemImage: Bool, title: String, description: String
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0; Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Preview
#Preview {
    OnboardingView(onComplete: { print("Onboarding Completed!") })
        .preferredColorScheme(.dark)
}
