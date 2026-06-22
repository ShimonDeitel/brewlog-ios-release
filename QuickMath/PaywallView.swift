import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    let benefits: [(icon: String, text: String)] = [
        ("chart.line.uptrend.xyaxis", "Trend charts linking grind, ratio and time to your ratings"),
        ("lightbulb", "Suggested next tweak based on your last few brews"),
        ("star.fill", "Per-bean and per-method history with best settings pinned")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 28) {
                            // Icon
                            Image(systemName: "drop.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(Color.qmAccent)
                                .padding(.top, 20)

                            // Title block
                            VStack(spacing: 6) {
                                Text("BrewLog Pro")
                                    .font(.title.weight(.bold))
                                Text("$0.99 / month. Auto-renews until you cancel.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }

                            // Benefit rows
                            VStack(spacing: 16) {
                                ForEach(benefits, id: \.text) { benefit in
                                    HStack(alignment: .top, spacing: 14) {
                                        Image(systemName: benefit.icon)
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(Color.qmAccent)
                                            .frame(width: 24)
                                        Text(benefit.text)
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                    }
                                }
                            }
                            .qmCard()
                            .padding(.horizontal, 20)

                            // Price disclosure
                            Text("BrewLog Pro is \(store.displayPrice)/month, billed monthly. Subscription automatically renews unless cancelled at least 24 hours before the end of the current period. Manage or cancel at any time in your Apple ID account settings.")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)

                            // Links
                            HStack(spacing: 20) {
                                Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                                    .font(.caption)
                                    .foregroundStyle(Color.qmAccent)
                                Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/brewlog-site/privacy.html")!)
                                    .font(.caption)
                                    .foregroundStyle(Color.qmAccent)
                            }
                        }
                        .padding(.bottom, 24)
                    }

                    // Action buttons pinned at bottom
                    VStack(spacing: 12) {
                        Button {
                            Task {
                                Haptics.tap()
                                await store.purchase()
                            }
                        } label: {
                            Group {
                                if store.purchaseInFlight {
                                    ProgressView()
                                } else {
                                    Text("Unlock Pro — \(store.displayPrice)/mo")
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .prominentButton()
                        .disabled(store.purchaseInFlight)
                        .padding(.horizontal, 20)

                        Button {
                            Task { await store.restore() }
                        } label: {
                            Text("Restore Purchase")
                                .frame(maxWidth: .infinity)
                        }
                        .softButton()
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
            .onChange(of: store.isPro) { _, newValue in
                if newValue { dismiss() }
            }
        }
    }
}
