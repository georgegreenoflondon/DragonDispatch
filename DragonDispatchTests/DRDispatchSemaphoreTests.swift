//
//  DRDispatchSemaphoreTests.swift
//  Dragon Dispatch
//
//  Created by George Green on 05/10/2014.
//  Copyright (c) 2014 The Swift Guru. All rights reserved.
//

import Foundation
import XCTest

class DRDispatchSemaphoreTests : XCTestCase {
	
	/// 
	func testSemaphore() {
		let semaphore = DRDispatchSemaphore()
		XCTAssert(semaphore.maxEntrants == 1, "The deafult value should be 1.")
		let queue = DRDispatchQueue.globalQueueWithPriority(.High)
		var isInProtectedCode: Bool = false
		for _ in 0..<100 {
			queue.dispatch {
				semaphore.execute {
					XCTAssert(isInProtectedCode == false, "The semaphore should force the code to wait until this assertion is true.")
					isInProtectedCode = true
					var j = 0
					j = j + 1
					isInProtectedCode = false
				}
				return
			}
		}
	}
	
}