//
//  File.swift
//  Dragon Dispatch
//
//  Created by George Green on 12/10/2014.
//  Copyright (c) 2014 The Swift Guru. All rights reserved.
//

import Foundation
import XCTest

class DRDispatchChainTests {
    
    /// Test that the chain is running events as expected.
    func testChain() {
        let chain = DRDispatchChain()
        chain.first { (_: Any?) -> Any? in
            var i = 0
            i = i + 1
            return "Hello world"
            }.then { (result: String) -> Any? in
                XCTAssert(result == "Hello world", "The string should have been passed in from the first block.")
                return nil
            }.thenIf { (result: Any?) -> Any? in
                XCTAssert(result == nil, "nil should have been passed in from the previous block.")
                return true
            }.thenIf { (result: Any?) -> Any? in
                XCTAssert(result == true, "true should have been passed in from the previous block.")
                return nil
            }.then { (result: Any?) -> Any? in
                XCTAssert(true == false, "This should never have been called.")
        }
        chain.begin()
    }
    
    /// Test that the firstIf chain method works.
    func testFirstIf() {
        let chain = DRDispatchChain()
        chain.firstIf { (_: Any?) -> Any? in
            return nil
            }.then { (obj: Any?) -> Any? in
                XCTAssert(true == false, "This should never have been called.")
        }
    }
    
}