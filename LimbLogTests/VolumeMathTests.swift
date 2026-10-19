import XCTest
@testable import LimbLog

@MainActor
final class VolumeMathTests: XCTestCase {
    func testCylinderVolumeMatchesFormula() {
        // Constant circumference C over height h is a cylinder: V = h C² / (4π).
        let c = 25.0, h = 40.0
        let series = [(distanceCm: 0.0, circumferenceCm: c), (distanceCm: 40.0, circumferenceCm: c)]
        XCTAssertEqual(VolumeMath.frustumVolume(series), h * c * c / (4 * Double.pi), accuracy: 0.001)
    }

    func testSegmentsSumAndOrderDoesNotMatter() {
        let a = [(distanceCm: 0.0, circumferenceCm: 16.0), (distanceCm: 10.0, circumferenceCm: 22.0), (distanceCm: 20.0, circumferenceCm: 25.0)]
        let shuffled = [a[2], a[0], a[1]]
        XCTAssertEqual(VolumeMath.frustumVolume(a), VolumeMath.frustumVolume(shuffled), accuracy: 0.0001)
        let first = VolumeMath.frustumVolume([a[0], a[1]]), second = VolumeMath.frustumVolume([a[1], a[2]])
        XCTAssertEqual(VolumeMath.frustumVolume(a), first + second, accuracy: 0.0001)
    }

    func testSinglePointHasNoVolume() {
        XCTAssertEqual(VolumeMath.frustumVolume([(distanceCm: 0, circumferenceCm: 20)]), 0)
    }

    func testPercentDifference() {
        XCTAssertEqual(VolumeMath.percentDifference(affected: 2300, other: 2000)!, 15, accuracy: 0.0001)
        XCTAssertNil(VolumeMath.percentDifference(affected: 100, other: 0))
    }

    func testPartnerPicksClosestOtherSideWithinWindow() {
        let profile = LimbProfile(name: "T", limbType: .arm, affectedSide: .right)
        let day: TimeInterval = 86_400
        let base = Date.now
        let affected = LimbMeasurement(profile: profile, side: .right, date: base)
        let near = LimbMeasurement(profile: profile, side: .left, date: base.addingTimeInterval(day))
        let far = LimbMeasurement(profile: profile, side: .left, date: base.addingTimeInterval(10 * day))
        let sameSide = LimbMeasurement(profile: profile, side: .right, date: base.addingTimeInterval(0.5 * day))
        let partner = VolumeMath.partner(for: affected, in: [affected, near, far, sameSide], otherSide: .left)
        XCTAssertEqual(partner?.id, near.id)
        XCTAssertNil(VolumeMath.partner(for: affected, in: [affected, far], otherSide: .left))
    }

    func testSummaryBaselineLatestAndChange() {
        let profile = LimbProfile(name: "T", limbType: .arm, affectedSide: .right)
        let day: TimeInterval = 86_400
        let base = Date.now.addingTimeInterval(-20 * day)
        func m(_ side: Side, _ offset: Double, _ c: Double) -> LimbMeasurement {
            let x = LimbMeasurement(profile: profile, side: side, date: base.addingTimeInterval(offset * day))
            x.values = [0: c, 10: c, 20: c]
            return x
        }
        let all = [m(.right, 0, 26), m(.left, 0, 24), m(.right, 14, 25), m(.left, 14, 24)]
        let s = VolumeMath.summary(profile: profile, measurements: all, from: .distantPast)
        XCTAssertEqual(s.affectedCount, 2)
        XCTAssertLessThan(s.changeML!, 0)
        XCTAssertEqual(s.latestPercentVsOther!, (25.0 * 25.0 / (24.0 * 24.0) - 1) * 100, accuracy: 0.01)
        XCTAssertEqual(s.baselinePercentVsOther!, (26.0 * 26.0 / (24.0 * 24.0) - 1) * 100, accuracy: 0.01)
    }

    func testUnitsRoundTrip() {
        XCTAssertEqual(LengthUnit.inch.toCm(10), 25.4, accuracy: 0.0001)
        XCTAssertEqual(LengthUnit.inch.display(cm: 25.4), 10, accuracy: 0.0001)
        XCTAssertEqual(Formatters.volume(2340.4), "2,340 mL")
        XCTAssertEqual(Formatters.percent(-3.26), "−3.3%")
    }
}
