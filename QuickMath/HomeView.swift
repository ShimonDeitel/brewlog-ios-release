import SwiftUI

struct HomeView: View {
    var forceScreen: String? = nil

    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showSettings = false
    @State private var showLog = false
    @State private var showInsights = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 24) {
                        // Header stats row
                        HStack(spacing: 12) {
                            MetricTile(
                                value: "\(appModel.brews.count)",
                                label: "Brews Logged"
                            )
                            MetricTile(
                                value: appModel.brews.isEmpty ? "—" : String(format: "%.1f", Double(appModel.brews.prefix(5).map(\.rating).reduce(0, +)) / Double(min(appModel.brews.count, 5))),
                                label: "Avg Rating"
                            )
                            MetricTile(
                                value: appModel.bestBrew.map { "\($0.rating)/5" } ?? "—",
                                label: "Best Brew"
                            )
                        }
                        .padding(.horizontal, 20)

                        // Log a brew CTA
                        Button {
                            Haptics.tap()
                            showLog = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                Text("Log a Brew")
                                    .font(.headline.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .prominentButton()
                        .padding(.horizontal, 20)

                        // Pro insights tile
                        Button {
                            Haptics.tap()
                            if store.isPro {
                                showInsights = true
                            } else {
                                showPaywall = true
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "chart.line.uptrend.xyaxis")
                                            .foregroundStyle(Color.qmAccent)
                                        Text("Insights & Trends")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                    }
                                    Text("Charts, suggestions & per-bean history")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if !store.isPro {
                                    Text("Pro")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.qmAccent, in: Capsule())
                                }
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .qmCard()
                        .padding(.horizontal, 20)

                        // Recent brews
                        if !appModel.brews.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Brews")
                                    .font(.title3.weight(.semibold))
                                    .padding(.horizontal, 20)

                                ForEach(appModel.brews.prefix(10)) { brew in
                                    BrewRowView(brew: brew)
                                        .padding(.horizontal, 20)
                                }
                            }
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "drop.circle")
                                    .font(.system(size: 48))
                                    .foregroundStyle(Color.qmAccent)
                                Text("No brews yet")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Text("Tap "Log a Brew" to dial in your first cup.")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(40)
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("BrewLog")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.qmAccent)
                    }
                }
            }
            .sheet(isPresented: $showLog, onDismiss: { appModel.refresh() }) {
                GridView()
            }
            .sheet(isPresented: $showInsights) {
                InsightsView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .onAppear {
            if forceScreen == "paywall" { showPaywall = true }
            else if forceScreen == "insights" { showInsights = true }
            else if forceScreen == "log" { showLog = true }
        }
    }
}

struct BrewRowView: View {
    let brew: BrewEntry

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(brew.beansName.isEmpty ? "Unknown beans" : brew.beansName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(brew.methodName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text("Grind \(brew.grindSetting)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(brew.timeFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                RatingDotsView(rating: brew.rating)
                Text(brew.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .qmCard(cornerRadius: 14)
    }
}

struct RatingDotsView: View {
    let rating: Int
    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { i in
                Circle()
                    .fill(i <= rating ? Color.qmAccent : Color.qmHair)
                    .frame(width: 7, height: 7)
            }
        }
    }
}
