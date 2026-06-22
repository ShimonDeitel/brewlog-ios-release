import SwiftUI
import SwiftData

struct GridView: View {
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    // Form fields
    @State private var beansName = ""
    @State private var selectedMethod = ""
    @State private var grindSetting = ""
    @State private var doseGrams = ""
    @State private var yieldGrams = ""
    @State private var waterTemp = ""
    @State private var timeMinutes = ""
    @State private var timeSeconds = ""
    @State private var rating = 3
    @State private var notes = ""

    @State private var showBeanPicker = false
    @State private var showMethodPicker = false
    @State private var saved = false

    var computedRatio: String {
        guard let dose = Double(doseGrams), let yld = Double(yieldGrams), dose > 0 else { return "—" }
        return String(format: "1:%.1f", yld / dose)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        // Beans
                        BrewFieldCard(title: "Beans") {
                            HStack {
                                TextField("e.g. Ethiopia Yirgacheffe", text: $beansName)
                                    .autocorrectionDisabled()
                                if !appModel.beans.isEmpty {
                                    Button {
                                        showBeanPicker = true
                                    } label: {
                                        Image(systemName: "list.bullet")
                                            .foregroundStyle(Color.qmAccent)
                                    }
                                }
                            }
                        }

                        // Method
                        BrewFieldCard(title: "Method") {
                            Menu {
                                ForEach(appModel.methods, id: \.id) { m in
                                    Button(m.name) { selectedMethod = m.name }
                                }
                            } label: {
                                HStack {
                                    Text(selectedMethod.isEmpty ? "Select method..." : selectedMethod)
                                        .foregroundStyle(selectedMethod.isEmpty ? .tertiary : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .foregroundStyle(Color.qmAccent)
                                }
                            }
                        }

                        // Grind
                        BrewFieldCard(title: "Grind Setting") {
                            TextField("e.g. 18, Medium-Fine", text: $grindSetting)
                                .autocorrectionDisabled()
                        }

                        // Dose & Yield
                        HStack(spacing: 12) {
                            BrewFieldCard(title: "Dose (g)") {
                                TextField("18", text: $doseGrams)
                                    .keyboardType(.decimalPad)
                            }
                            BrewFieldCard(title: "Yield (g)") {
                                TextField("270", text: $yieldGrams)
                                    .keyboardType(.decimalPad)
                            }
                        }

                        // Ratio (computed)
                        HStack {
                            Text("Ratio")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(computedRatio)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.qmAccent)
                        }
                        .qmCard(cornerRadius: 14)
                        .padding(.horizontal, 20)

                        // Water temp
                        BrewFieldCard(title: "Water Temp (°C)") {
                            TextField("93", text: $waterTemp)
                                .keyboardType(.decimalPad)
                        }

                        // Time
                        BrewFieldCard(title: "Brew Time") {
                            HStack(spacing: 8) {
                                TextField("2", text: $timeMinutes)
                                    .keyboardType(.numberPad)
                                    .frame(width: 44)
                                Text("min")
                                    .foregroundStyle(.secondary)
                                TextField("30", text: $timeSeconds)
                                    .keyboardType(.numberPad)
                                    .frame(width: 44)
                                Text("sec")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Rating
                        BrewFieldCard(title: "Taste Rating") {
                            HStack(spacing: 16) {
                                ForEach(1...5, id: \.self) { i in
                                    Button {
                                        Haptics.tap()
                                        rating = i
                                    } label: {
                                        Image(systemName: i <= rating ? "circle.fill" : "circle")
                                            .foregroundStyle(i <= rating ? Color.qmAccent : Color.qmHair)
                                            .font(.title2)
                                    }
                                    .buttonStyle(.plain)
                                }
                                Spacer()
                                Text("\(rating)/5")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Notes
                        BrewFieldCard(title: "Notes (optional)") {
                            TextField("Tasting notes, observations...", text: $notes, axis: .vertical)
                                .lineLimit(3...6)
                        }

                        // Save button
                        Button {
                            saveBrew()
                        } label: {
                            Text(saved ? "Saved!" : "Save Brew")
                                .frame(maxWidth: .infinity)
                        }
                        .prominentButton()
                        .padding(.horizontal, 20)
                        .disabled(saved)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Log a Brew")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            .sheet(isPresented: $showBeanPicker) {
                BeanPickerSheet(selectedName: $beansName)
            }
            .onAppear {
                if let first = appModel.methods.first, selectedMethod.isEmpty {
                    selectedMethod = first.name
                }
            }
        }
    }

    private func saveBrew() {
        Haptics.success()
        let totalSeconds = (Int(timeMinutes) ?? 0) * 60 + (Int(timeSeconds) ?? 0)
        let entry = BrewEntry(
            beansName: beansName,
            methodName: selectedMethod.isEmpty ? "Pour Over" : selectedMethod,
            grindSetting: grindSetting,
            doseGrams: Double(doseGrams) ?? 0,
            yieldGrams: Double(yieldGrams) ?? 0,
            waterTemp: Double(waterTemp) ?? 93,
            timeSeconds: totalSeconds,
            rating: rating,
            notes: notes
        )
        appModel.addBrew(entry)
        saved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dismiss()
        }
    }
}

// MARK: - Supporting views

struct BrewFieldCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
        }
        .qmCard(cornerRadius: 14)
        .padding(.horizontal, 20)
    }
}

struct BeanPickerSheet: View {
    @Binding var selectedName: String
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                List(appModel.beans) { bean in
                    Button {
                        selectedName = bean.name
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(bean.name).foregroundStyle(.primary)
                            if !bean.roaster.isEmpty {
                                Text(bean.roaster).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Select Beans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
        }
    }
}
