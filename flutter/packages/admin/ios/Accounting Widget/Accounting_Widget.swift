import WidgetKit
import SwiftUI

struct AccountingEntry: TimelineEntry {
    let date: Date
    let image: UIImage?
}

struct AccountingProvider: TimelineProvider {
    private let userDefaults = UserDefaults(suiteName: "group.org.growerp.admin")

    func placeholder(in context: Context) -> AccountingEntry {
        AccountingEntry(date: Date(), image: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (AccountingEntry) -> Void) {
        completion(AccountingEntry(date: Date(), image: loadImage()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AccountingEntry>) -> Void) {
        let entry = AccountingEntry(date: Date(), image: loadImage())
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadImage() -> UIImage? {
        guard let imagePath = userDefaults?.string(forKey: "accounting_chart_image") else { return nil }
        return UIImage(contentsOfFile: imagePath)
    }
}

struct Accounting_WidgetEntryView: View {
    var entry: AccountingProvider.Entry

    var body: some View {
        if let image = entry.image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(8)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("Open GrowERP to load chart")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

struct Accounting_Widget: Widget {
    let kind: String = "AccountingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AccountingProvider()) { entry in
            Accounting_WidgetEntryView(entry: entry)
                .containerBackground(.white, for: .widget)
        }
        .configurationDisplayName("GrowERP Accounting")
        .description("Revenue and expense chart for the current year")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

#Preview(as: .systemMedium) {
    Accounting_Widget()
} timeline: {
    AccountingEntry(date: .now, image: nil)
}
