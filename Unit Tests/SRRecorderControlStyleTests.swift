//
//  SRRecorderControlStyleTests.swift
//  Unit Tests
//
//  Created by Ilya Kulakov on 5/21/19.
//

import XCTest

import ShortcutRecorder


class SRRecorderControlStyleTests: XCTestCase {
    func testTemplateIdentifier() {
        let style = RecorderControlStyle(identifier: "sr-test")
        var prefixes = style.makeLookupPrefixes()

        func testAndRemove(_ p: String) {
            if let i = prefixes.index(of: p) {
                prefixes.remove(at: i)
            }
            else {
                XCTFail("Missing \(p)")
            }
        }

        testAndRemove("sr-test")
        testAndRemove("sr-test-acc")
        testAndRemove("sr-test-blue")
        testAndRemove("sr-test-blue-acc")
        testAndRemove("sr-test-graphite")
        testAndRemove("sr-test-graphite-acc")

        testAndRemove("sr-test-aqua")
        testAndRemove("sr-test-aqua-acc")
        testAndRemove("sr-test-aqua-blue")
        testAndRemove("sr-test-aqua-blue-acc")
        testAndRemove("sr-test-aqua-graphite")
        testAndRemove("sr-test-aqua-graphite-acc")

        testAndRemove("sr-test-darkaqua")
        testAndRemove("sr-test-darkaqua-acc")
        testAndRemove("sr-test-darkaqua-blue")
        testAndRemove("sr-test-darkaqua-blue-acc")
        testAndRemove("sr-test-darkaqua-graphite")
        testAndRemove("sr-test-darkaqua-graphite-acc")

        testAndRemove("sr-test-vibrantlight")
        testAndRemove("sr-test-vibrantlight-acc")
        testAndRemove("sr-test-vibrantlight-blue")
        testAndRemove("sr-test-vibrantlight-blue-acc")
        testAndRemove("sr-test-vibrantlight-graphite")
        testAndRemove("sr-test-vibrantlight-graphite-acc")

        testAndRemove("sr-test-vibrantdark")
        testAndRemove("sr-test-vibrantdark-acc")
        testAndRemove("sr-test-vibrantdark-blue")
        testAndRemove("sr-test-vibrantdark-blue-acc")
        testAndRemove("sr-test-vibrantdark-graphite")
        testAndRemove("sr-test-vibrantdark-graphite-acc")

        XCTAssertTrue(prefixes.isEmpty)
    }

    func testConcreteLookupIdentifier() {
        let style = RecorderControlStyle(identifier: "sr-test-")
        var prefixes = style.makeLookupPrefixes()
        XCTAssertEqual(prefixes.count, 1)
        XCTAssertEqual(prefixes[0], "sr-test")
    }
}
