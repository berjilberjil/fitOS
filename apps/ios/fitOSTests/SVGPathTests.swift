import XCTest
import CoreGraphics
@testable import fitOS

final class SVGPathTests: XCTestCase {

    func testEmptyPath_isEmpty() {
        let p = SVGPath.cgPath(from: "")
        XCTAssertTrue(p.isEmpty || p.boundingBoxOfPath.isNull || p.boundingBoxOfPath.isEmpty
                      || p.boundingBox == .null || p.boundingBox.isNull)
    }

    func testSimpleMoveLine() {
        let p = SVGPath.cgPath(from: "M10 10 L20 20")
        let box = p.boundingBoxOfPath
        XCTAssertFalse(box.isNull)
        XCTAssertEqual(box.minX, 10, accuracy: 0.01)
        XCTAssertEqual(box.minY, 10, accuracy: 0.01)
        XCTAssertEqual(box.maxX, 20, accuracy: 0.01)
        XCTAssertEqual(box.maxY, 20, accuracy: 0.01)
    }

    func testRelativeCommands() {
        let p = SVGPath.cgPath(from: "M0 0 l10 0 l0 10")
        let box = p.boundingBoxOfPath
        XCTAssertEqual(box.width, 10, accuracy: 0.5)
        XCTAssertEqual(box.height, 10, accuracy: 0.5)
    }

    func testHorizontalVertical() {
        let p = SVGPath.cgPath(from: "M0 0 H50 V30 Z")
        let box = p.boundingBoxOfPath
        XCTAssertEqual(box.maxX, 50, accuracy: 0.01)
        XCTAssertEqual(box.maxY, 30, accuracy: 0.01)
    }

    func testClosePath() {
        let p = SVGPath.cgPath(from: "M0 0 L10 0 L10 10 Z")
        XCTAssertFalse(p.boundingBoxOfPath.isNull)
    }

    func testCubicBezier() {
        let p = SVGPath.cgPath(from: "M0 0 C10 20 30 20 40 0")
        let box = p.boundingBoxOfPath
        XCTAssertGreaterThan(box.width, 0)
    }

    func testSVGOPackedDecimals() {
        // "15.12.11" = 15.12 then .11 — classic SVGO packing
        let p = SVGPath.cgPath(from: "M15.12.11 L20 20")
        let box = p.boundingBoxOfPath
        XCTAssertFalse(box.isNull)
        XCTAssertEqual(box.minX, 15.12, accuracy: 0.01)
        XCTAssertEqual(box.minY, 0.11, accuracy: 0.01)
    }

    func testLeadingDotNumber() {
        let p = SVGPath.cgPath(from: "M.5 .5 L10 10")
        let box = p.boundingBoxOfPath
        XCTAssertEqual(box.minX, 0.5, accuracy: 0.01)
        XCTAssertEqual(box.minY, 0.5, accuracy: 0.01)
    }

    func testNegativeAndScientific() {
        let p = SVGPath.cgPath(from: "M-10 1e1 L0 0")
        let box = p.boundingBoxOfPath
        XCTAssertEqual(box.minX, -10, accuracy: 0.01)
        XCTAssertEqual(box.maxY, 10, accuracy: 0.01)
    }

    func testArc_doesNotCrash() {
        // Elliptical arc A rx ry x-axis-rotation large-arc sweep x y
        let p = SVGPath.cgPath(from: "M10 10 A 5 5 0 0 1 20 20")
        XCTAssertFalse(p.boundingBoxOfPath.isNull || p.boundingBoxOfPath.width < 0)
    }

    func testMultipleSubpaths() {
        let p = SVGPath.cgPath(from: "M0 0 L5 5 M10 10 L15 15")
        let box = p.boundingBoxOfPath
        XCTAssertEqual(box.minX, 0, accuracy: 0.5)
        XCTAssertEqual(box.maxX, 15, accuracy: 0.5)
    }
}
