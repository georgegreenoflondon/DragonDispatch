//
//  DRDispatchQueueTests.swift
//  Dragon Dispatch
//
//  Created by George Green on 27/09/2014.
//  Copyright (c) 2014 The Swift Guru. All rights reserved.
//

import Foundation
import XCTest

class DRDispatchQueueTests : XCTestCase {
	
	/// Test the equality of two queues that should be the same.
	func testEqulity1() {
		let queue1 = DRDispatchQueue.globalQueueWithPriority(.High)
		let queue2 = DRDispatchQueue.globalQueueWithPriority(.High)
		XCTAssert(queue1 == queue2, "Two global queues of the same priority should be equal.")
	}
	
}