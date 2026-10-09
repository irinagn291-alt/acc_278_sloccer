import SwiftUI

/// Settings edits sheet capacity, exports marks, and can rerun onboarding or erase the folio.
struct SettingsSheet: View {
    var session: SheetSession
    var dismissSheet: () -> Void

    @State private var capacityText = ""
    @State private var capacityError: String?
    @State private var confirmReset = false
    @State private var saving = false
    @FocusState private var capacityFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                if let notice = session.notice {
                    Section {
                        Text(notice)
                            .font(InkType.body())
                            .foregroundStyle(DesignTokens.ink)
                    }
                }
                Section("Sheet capacity") {
                    TextField("Strokes on a full sheet", text: $capacityText)
                        .keyboardType(.numberPad)
                        .font(InkType.body())
                        .focused($capacityFocused)
                    if let capacityError {
                        Text(capacityError)
                            .font(InkType.caption())
                            .foregroundStyle(DesignTokens.ink)
                    }
                    Button("Save capacity") {
                        capacityFocused = false
                        saveCapacity()
                    }
                    .buttonStyle(StrokePressStyle(loading: saving, enabled: saving == false && capacityError == nil))
                    .disabled(saving || capacityError != nil)
                }
                Section("Marks") {
                    if session.folio.rhumbs.isEmpty {
                        Text("There are no marks to export yet.")
                            .font(InkType.body())
                    } else {
                        ShareLink(item: exportText) {
                            Label("Export marks", systemImage: "square.and.arrow.up")
                                .font(InkType.body())
                                .frame(maxWidth: .infinity, minHeight: InkMeasure.steps(11), alignment: .leading)
                                .contentShape(Rectangle())
                        }
                    }
                }
                Section("Sheet") {
                    Button {
                        Task {
                            await session.reopenOnboarding()
                            dismissSheet()
                        }
                    } label: {
                        Label("Show the introduction again", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity, minHeight: InkMeasure.steps(11), alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    Button {
                        confirmReset = true
                    } label: {
                        Label("Erase every mark", systemImage: "trash")
                            .frame(maxWidth: .infinity, minHeight: InkMeasure.steps(11), alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .foregroundStyle(DesignTokens.ink)
                }
                Section("Contact") {
                    if let contactURL {
                        Link("Contact Inkwell", destination: contactURL)
                            .font(InkType.body())
                            .frame(minHeight: InkMeasure.steps(11))
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background {
                DesignTokens.bg.ignoresSafeArea()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismissSheet()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(DesignTokens.ink)
                            .frame(width: InkMeasure.steps(11), height: InkMeasure.steps(11))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(ChromePressStyle())
                    .accessibilityLabel("Close")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { capacityFocused = false }
                        .frame(minHeight: InkMeasure.steps(11))
                }
            }
            .onAppear {
                if capacityText.isEmpty {
                    capacityText = InkFormat.integer(session.folio.books.strokes)
                }
            }
            .onChange(of: capacityText) { _, newValue in
                let digits = newValue.filter(\.isNumber)
                if digits != newValue {
                    capacityText = digits
                    capacityError = "Use a whole number of strokes."
                    return
                }
                if digits.isEmpty {
                    capacityError = "Enter a capacity of at least 1 stroke."
                    return
                }
                guard let value = Int(digits), value >= 1 else {
                    capacityError = "Enter a capacity of at least 1 stroke."
                    return
                }
                capacityError = nil
            }
            .confirmationDialog(
                "Erase every mark?",
                isPresented: $confirmReset,
                titleVisibility: .visible
            ) {
                Button("Erase every mark", role: .destructive) {
                    Task { await session.resetAllData() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Every mark on this sheet will be erased.")
            }
        }
    }

    private var contactURL: URL? {
        URL(string: "https://inkwell-sheet.pro/contact-us")
    }

    private var exportText: String {
        session.folio.rhumbs.map { rhumb in
            switch rhumb {
            case .wet:
                return "Dip \(InkFormat.dayLabel(for: rhumb.dayKey))"
            case .stroke:
                return "Stroke \(InkFormat.dayLabel(for: rhumb.dayKey))"
            case .bleed:
                return "Bleed \(InkFormat.dayLabel(for: rhumb.dayKey))"
            case .fill:
                return "Fill \(InkFormat.dayLabel(for: rhumb.dayKey))"
            }
        }.joined(separator: "\n")
    }

    private func saveCapacity() {
        let digits = capacityText.filter(\.isNumber)
        guard let value = Int(digits), value >= 1 else {
            capacityError = "Enter a capacity of at least 1 stroke."
            return
        }
        capacityError = nil
        saving = true
        Task {
            let result = await session.setCapacity(strokes: value)
            if result.accepted == false {
                capacityError = "That capacity could not be saved."
            }
            saving = false
        }
    }
}
