//
//  DRDispatchGroupTests.swift
//  Dragon Dispatch
//
//  Created by George Green on 01/10/2014.
//  Copyright (c) 2014 The Swift Guru. All rights reserved.
//

import Foundation
import XCTest

class DRDispatchGroupTests : XCTestCase {
	
	/// Group with a default queue
	
	func testWait() {
		let group = DRDispatchGroup()
		var valid1 = false
		var valid2 = false
		group.addBlock {
			valid1 = true
		}
		group.addBlock {
			valid2 = true
		}
		group.wait()
		XCTAssert(valid1 == true && valid2 == true, "Should both ve valid by the time the wait returns.")
	}
	
	func testNotify() {
		let group = DRDispatchGroup()
		var valid1 = false
		var valid2 = false
		group.addBlock {
			valid1 = true
		}
		group.addBlock {
			valid2 = true
		}
		group.notify {
			XCTAssert(valid1 == true, "Notify should not get called until the block before was called.")
			XCTAssert(valid2 == true, "Should not have been set to true yet.")
		}
	}
	
}