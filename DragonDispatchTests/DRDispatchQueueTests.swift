//
//  DRDispatchQueueTests.swift
//  Dragon Dispatch
//
//  Created by George Green on 28/09/2014.
//  Copyright (c) 2014 The Swift Guru. All rights reserved.
//

import Foundation
import XCTest

class DRDispatchQueueTests : XCTestCase {
	
	/// Test two queues that should be the same
	func testValidEquality() {
		// Self same objects
		let queue1 = DRDispatchQueue.globalQueueWithPriority(.Low)
		let queue2 = DRDispatchQueue.globalQueueWithPriority(.Low)
		XCTAssert(queue1 == queue2, "Two global queues should be the self same object.")
		// Different objects, same underlying queue
		let queue3 = DRDispatchQueue.globalQueueWithPriority(.High)
		let queue4 = DRDispatchQueue(queue: dispatch_get_global_queue(DRQueuePriority.High.toConst(), 0))
		XCTAssert(queue3 == queue4, "Share the same underlying global queue object, should be the same.")
		// A custom queue
		let queue = dispatch_queue_create("test queue", DISPATCH_QUEUE_CONCURRENT)
		let queue5 = DRDispatchQueue(queue: queue)
		let queue6 = DRDispatchQueue(queue: queue)
		XCTAssert(queue5 == queue6, "Share the same underlying global queue object, should be the same.")
	}
	
}