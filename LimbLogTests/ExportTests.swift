import XCTest
import SwiftData
import PDFKit
@testable import LimbLog

@MainActor
final class ExportTests: XCTestCase {
    private func sampleContainer() throws -> ModelContainer {
        let schema = Schema([LimbProfile.self, LimbMeasurement.self, SymptomEntry.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        SampleData.insert(into: container.mainContext)
        return container
    }

    func testReportRendersWithSampleData() throws {
        let container = try sampleContainer()
        let context = container.mainContext
        let profile = try XCTUnwrap(try context.fetch(FetchDescriptor<LimbProfile>()).first)
        let measurements = try context.fetch(FetchDescriptor<LimbMeasurement>())
        let symptoms = try context.fetch(FetchDescriptor<SymptomEntry>())
        XCTAssertEqual(measurements.count, 20)

        let url = try ReportExporter.export(profile: profile, measurements: measurements, symptoms: symptoms, from: .distantPast)
        let document = try XCTUnwrap(PDFDocument(url: url))
        XCTAssertGreaterThanOrEqual(document.pageCount, 2)
        let text = (0..<document.pageCount).compactMap { document.page(at: $0)?.string }.joined()
        XCTAssertTrue(text.contains("Marta"))
        XCTAssertTrue(text.contains("Baseline volume"))
        XCTAssertTrue(text.contains("Latest vs other side"))
        XCTAssertTrue(text.contains("does not diagnose"))
    }

    func testMeasurementsCSVHasPointColumns() throws {
        let container = try sampleContainer()
        let context = container.mainContext
        let profile = try XCTUnwrap(try context.fetch(FetchDescriptor<LimbProfile>()).first)
        let measurements = try context.fetch(FetchDescriptor<LimbMeasurement>())
        let csv = CSVExporter.measurementsCSV(measurements, profile: profile)
        let lines = csv.split(separator: "\n")
        XCTAssertEqual(lines.count, 21)
        XCTAssertTrue(lines[0].contains("\"Wrist (cm)\""))
        XCTAssertTrue(lines[0].contains("\"volume_ml\""))
    }
}
