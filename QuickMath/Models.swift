import SwiftUI
import SwiftData

// MARK: - SwiftData models

@Model
final class BrewBean {
    var id: UUID
    var name: String
    var roaster: String
    var roastDate: Date?

    init(name: String, roaster: String, roastDate: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.roaster = roaster
        self.roastDate = roastDate
    }
}

@Model
final class BrewMethod {
    var id: UUID
    var name: String

    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}

@Model
final class BrewEntry {
    var id: UUID
    var date: Date
    var beansName: String
    var methodName: String
    var grindSetting: String
    var doseGrams: Double
    var yieldGrams: Double
    var waterTemp: Double
    var timeSeconds: Int
    var rating: Int          // 1-5
    var notes: String

    init(
        date: Date = .now,
        beansName: String,
        methodName: String,
        grindSetting: String,
        doseGrams: Double,
        yieldGrams: Double,
        waterTemp: Double,
        timeSeconds: Int,
        rating: Int,
        notes: String = ""
    ) {
        self.id = UUID()
        self.date = date
        self.beansName = beansName
        self.methodName = methodName
        self.grindSetting = grindSetting
        self.doseGrams = doseGrams
        self.yieldGrams = yieldGrams
        self.waterTemp = waterTemp
        self.timeSeconds = timeSeconds
        self.rating = rating
        self.notes = notes
    }

    /// Brew ratio e.g. 1:15.3
    var ratio: Double {
        guard doseGrams > 0 else { return 0 }
        return yieldGrams / doseGrams
    }

    var timeFormatted: String {
        let m = timeSeconds / 60
        let s = timeSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - AppModel

@MainActor
final class AppModel: ObservableObject {
    let container: ModelContainer
    weak var store: Store?

    @Published private(set) var brews: [BrewEntry] = []
    @Published private(set) var beans: [BrewBean] = []
    @Published private(set) var methods: [BrewMethod] = []

    init(container: ModelContainer) {
        self.container = container
        reload()
    }

    static func makeContainer() -> ModelContainer {
        let schema = Schema([BrewEntry.self, BrewBean.self, BrewMethod.self])
        do {
            return try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)])
        } catch {
            return try! ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        }
    }

    func reload() {
        let ctx = container.mainContext
        brews = (try? ctx.fetch(FetchDescriptor<BrewEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)]))) ?? []
        beans = (try? ctx.fetch(FetchDescriptor<BrewBean>(sortBy: [SortDescriptor(\.name)]))) ?? []
        methods = (try? ctx.fetch(FetchDescriptor<BrewMethod>(sortBy: [SortDescriptor(\.name)]))) ?? []

        // seed default methods if none exist
        if methods.isEmpty {
            let defaults = ["Pour Over", "Espresso", "French Press", "AeroPress", "Chemex", "Cold Brew"]
            for name in defaults {
                ctx.insert(BrewMethod(name: name))
            }
            try? ctx.save()
            methods = (try? ctx.fetch(FetchDescriptor<BrewMethod>(sortBy: [SortDescriptor(\.name)]))) ?? []
        }
    }

    func refresh() { reload() }

    func addBrew(_ entry: BrewEntry) {
        container.mainContext.insert(entry)
        try? container.mainContext.save()
        reload()
    }

    func deleteBrew(_ entry: BrewEntry) {
        container.mainContext.delete(entry)
        try? container.mainContext.save()
        reload()
    }

    func addBean(_ bean: BrewBean) {
        container.mainContext.insert(bean)
        try? container.mainContext.save()
        reload()
    }

    /// Average rating for a specific bean name
    func averageRating(forBean name: String) -> Double {
        let filtered = brews.filter { $0.beansName == name }
        guard !filtered.isEmpty else { return 0 }
        return Double(filtered.map(\.rating).reduce(0, +)) / Double(filtered.count)
    }

    /// Average rating for a specific method name
    func averageRating(forMethod name: String) -> Double {
        let filtered = brews.filter { $0.methodName == name }
        guard !filtered.isEmpty else { return 0 }
        return Double(filtered.map(\.rating).reduce(0, +)) / Double(filtered.count)
    }

    /// Best-rated brew overall
    var bestBrew: BrewEntry? {
        brews.max(by: { $0.rating < $1.rating })
    }

    /// Suggested next adjustment based on last 3 brews
    var nextTweak: String {
        let recent = Array(brews.prefix(3))
        guard !recent.isEmpty else { return "Log your first brew to get suggestions." }
        let avgRating = Double(recent.map(\.rating).reduce(0, +)) / Double(recent.count)
        let avgRatio = recent.map(\.ratio).reduce(0, +) / Double(recent.count)
        let avgTime = recent.map(\.timeSeconds).reduce(0, +) / recent.count

        if avgRating >= 4 {
            return "Your recent brews are excellent! Try the same settings and note any variation."
        } else if avgRatio < 14 {
            return "Ratio \(String(format: "%.1f", avgRatio)):1 is strong — try using a bit more water or less dose."
        } else if avgRatio > 17 {
            return "Ratio \(String(format: "%.1f", avgRatio)):1 is thin — increase dose or reduce yield."
        } else if avgTime < 120 {
            return "Brew time \(avgTime)s is short — try a finer grind or slower pour."
        } else if avgTime > 300 {
            return "Brew time \(avgTime)s is long — try a coarser grind or faster pour."
        } else {
            return "Ratio and time look balanced. Experiment with grind size for the last few percent of flavour."
        }
    }

    func deleteAllData() {
        let ctx = container.mainContext
        brews.forEach { ctx.delete($0) }
        beans.forEach { ctx.delete($0) }
        methods.forEach { ctx.delete($0) }
        try? ctx.save()
        reload()
    }
}
