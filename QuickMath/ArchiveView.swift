import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 24) {

                        // Suggested tweak
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(Color.qmAccent)
                                Text("Next Adjustment")
                                    .font(.headline)
                            }
                            Text(appModel.nextTweak)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .qmCard()
                        .padding(.horizontal, 20)

                        // Rating trend chart
                        if appModel.brews.count >= 2 {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Rating Trend")
                                    .font(.headline)
                                    .padding(.horizontal, 20)

                                Chart {
                                    ForEach(Array(appModel.brews.prefix(20).reversed().enumerated()), id: \.offset) { idx, brew in
                                        LineMark(
                                            x: .value("Brew", idx + 1),
                                            y: .value("Rating", brew.rating)
                                        )
                                        .foregroundStyle(Color.qmAccent)
                                        PointMark(
                                            x: .value("Brew", idx + 1),
                                            y: .value("Rating", brew.rating)
                                        )
                                        .foregroundStyle(Color.qmAccent)
                                    }
                                }
                                .chartYScale(domain: 1...5)
                                .chartXAxisLabel("Recent Brews")
                                .chartYAxisLabel("Rating")
                                .frame(height: 160)
                                .padding(.horizontal, 20)
                            }
                        }

                        // Grind vs Rating scatter
                        if appModel.brews.count >= 3 {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Ratio vs Rating")
                                    .font(.headline)
                                    .padding(.horizontal, 20)

                                Chart {
                                    ForEach(appModel.brews.prefix(30)) { brew in
                                        PointMark(
                                            x: .value("Ratio", brew.ratio),
                                            y: .value("Rating", brew.rating)
                                        )
                                        .foregroundStyle(Color.qmAccent.opacity(0.7))
                                    }
                                }
                                .chartXAxisLabel("Brew Ratio (1:x)")
                                .chartYScale(domain: 1...5)
                                .chartYAxisLabel("Rating")
                                .frame(height: 160)
                                .padding(.horizontal, 20)
                            }
                        }

                        // Per-bean history
                        if !appModel.beans.isEmpty || !appModel.brews.isEmpty {
                            let beanNames = Array(Set(appModel.brews.map(\.beansName))).sorted()
                            if !beanNames.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Per-Bean Summary")
                                        .font(.headline)
                                        .padding(.horizontal, 20)

                                    ForEach(beanNames, id: \.self) { name in
                                        let beanBrews = appModel.brews.filter { $0.beansName == name }
                                        let avgRating = appModel.averageRating(forBean: name)
                                        let best = beanBrews.max(by: { $0.rating < $1.rating })

                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text(name.isEmpty ? "Unknown Beans" : name)
                                                    .font(.subheadline.weight(.semibold))
                                                Spacer()
                                                RatingDotsView(rating: Int(avgRating.rounded()))
                                            }
                                            if let best = best {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "star.fill")
                                                        .font(.caption)
                                                        .foregroundStyle(Color.qmAccent)
                                                    Text("Best: Grind \(best.grindSetting), Ratio \(String(format: "1:%.1f", best.ratio)), \(best.timeFormatted)")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            Text("\(beanBrews.count) brew\(beanBrews.count == 1 ? "" : "s")")
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                        .qmCard(cornerRadius: 14)
                                        .padding(.horizontal, 20)
                                    }
                                }
                            }
                        }

                        // Per-method history
                        let methodNames = Array(Set(appModel.brews.map(\.methodName))).sorted()
                        if !methodNames.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Per-Method Summary")
                                    .font(.headline)
                                    .padding(.horizontal, 20)

                                ForEach(methodNames, id: \.self) { name in
                                    let methodBrews = appModel.brews.filter { $0.methodName == name }
                                    let avgRating = appModel.averageRating(forMethod: name)
                                    let best = methodBrews.max(by: { $0.rating < $1.rating })

                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(name)
                                                .font(.subheadline.weight(.semibold))
                                            Spacer()
                                            RatingDotsView(rating: Int(avgRating.rounded()))
                                        }
                                        if let best = best {
                                            Text("Best: Grind \(best.grindSetting), \(best.beansName)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Text("\(methodBrews.count) brew\(methodBrews.count == 1 ? "" : "s")")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .qmCard(cornerRadius: 14)
                                    .padding(.horizontal, 20)
                                }
                            }
                        }

                        if appModel.brews.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "chart.xyaxis.line")
                                    .font(.system(size: 48))
                                    .foregroundStyle(Color.qmAccent)
                                Text("No data yet")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Text("Log some brews to see trends and insights.")
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
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
        }
    }
}
