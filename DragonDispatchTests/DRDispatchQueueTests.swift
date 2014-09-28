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
		XCTAssert(queue1 == queue2, "Two global queues, with the same priority, should be the self same object.")
		// Different objects, same underlying queue
		let queue3 = DRDispatchQueue.globalQueueWithPriority(.High)
		let queue4 = DRDispatchQueue(queue: dispatch_get_global_queue(DRQueuePriority.High.toConst(), 0))
		XCTAssert(queue3 == queue4, "Share the same underlying global queue object, should be the same.")
		// A custom queue
		let queue = dispatch_queue_create("test queue", DISPATCH_QUEUE_CONCURRENT)
		let queue5 = DRDispatchQueue(queue: queue)
		let queue6 = DRDispatchQueue(queue: queue)
		XCTAssert(queue5 == queue6, "Share the same underlying global queue object, should be the same.")
		// Main queue
		let main1 = DRDispatchQueue.mainQueue()
		let main2 = DRDispatchQueue.mainQueue()
		XCTAssert(main1 == main2, "There is only one main queue.")
		let main3 = DRDispatchQueue(queue: dispatch_get_main_queue())
		XCTAssert(main2 == main3, "There is only one main queue.")
	}
	
	/// Test two queues that should not be equal
	func testInvalidEquality() {
		// Global queues
		let queue1 = DRDispatchQueue.globalQueueWithPriority(.Low)
		let queue2 = DRDispatchQueue.globalQueueWithPriority(.Default)
		XCTAssert(queue1 != queue2, "Two different priority queues should be different.")
		// Custom queues
		let queueA = dispatch_queue_create("test queue a", DISPATCH_QUEUE_CONCURRENT)
		let queueB = dispatch_queue_create("test queue b", DISPATCH_QUEUE_SERIAL)
		let queue3 = DRDispatchQueue(queue: queueA)
		let queue4 = DRDispatchQueue(queue: queueB)
		XCTAssert(queue3 != queue4, "Different underlying queues, should not be equal.")
	}
	
	/// Test setting and getting context values
	func testContext() {
		// String
		let queue = DRDispatchQueue.mainQueue()
		queue["name"] = "Phillip"
		if let name = queue["name"] as? String {
			XCTAssert(name == "Phillip", "The value should be the same as the value that was set.")
		}
		// Int
		queue["age"] = 5
		if let age = queue["age"] as? Int {
			XCTAssert(age == 5, "The value should be the same as the value that was set.")
		}
	}
	
	/// Check the priority and type of queues
	func testPriorityAndType() {
		// Low
		var queue = DRDispatchQueue.globalQueueWithPriority(.Low)
		XCTAssert(queue.priority == DRQueuePriority.Low, "Priority is set incorrectly")
		XCTAssert(queue.type == DRQueueType.Concurrent, "All global queues are concurent.")
		// Default
		queue = DRDispatchQueue.globalQueueWithPriority(.Default)
		XCTAssert(queue.priority == DRQueuePriority.Default, "Priority is set incorrectly")
		XCTAssert(queue.type == DRQueueType.Concurrent, "All global queues are concurent.")
		// High
		queue = DRDispatchQueue.globalQueueWithPriority(.High)
		XCTAssert(queue.priority == DRQueuePriority.High, "Priority is set incorrectly")
		XCTAssert(queue.type == DRQueueType.Concurrent, "All global queues are concurent.")
		// Background
		queue = DRDispatchQueue.globalQueueWithPriority(.Background)
		XCTAssert(queue.priority == DRQueuePriority.Background, "Priority is set incorrectly")
		XCTAssert(queue.type == DRQueueType.Concurrent, "All global queues are concurent.")
		// Main
		queue = DRDispatchQueue.mainQueue()
		XCTAssert(queue.priority == nil, "Main queue does not have a priority.")
		XCTAssert(queue.type == DRQueueType.Serial, "Main queue is serial.")
		// Custom - Serial
		queue = DRDispatchQueue(type: DRQueueType.Serial, label: "test queue - serial")
		XCTAssert(queue.priority == nil, "Custom queues do not have a priority.")
		XCTAssert(queue.type == DRQueueType.Serial, "Should be serial.")
		// Custom - Concurrent
		queue = DRDispatchQueue(type: DRQueueType.Concurrent, label: "test queue - concurrent")
		XCTAssert(queue.priority == nil, "Custom queues do not have a priority.")
		XCTAssert(queue.type == DRQueueType.Concurrent, "Should be concurrent.")
		// Custom
		queue = DRDispatchQueue(queue: dispatch_queue_create("test queue - custom", DISPATCH_QUEUE_SERIAL))
		XCTAssert(queue.priority == nil, "Custom queues do not have a priority.")
		XCTAssert(queue.type == nil, "Custom queues do not know their type.")
	}
	
	/// Test asynchronous concurrent
	func testAsyncConcurrent() {
		// dispatch(block)
		let queue = DRDispatchQueue.globalQueueWithPriority(.Default)
		let expectation = expectationWithDescription("Connection did complete")
		var canComplete = false
		queue.dispatch { () -> Void in
			if canComplete == true {
				expectation.fulfill()
			}
		}
		canComplete = true
		waitForExpectationsWithTimeout(1, handler: nil)
		// dispatch(block)
		let expectation2 = expectationWithDescription("Connection did complete")
		var canComplete2 = false
		queue.dispatchAsync { () -> Void in
			if canComplete2 == true {
				expectation2.fulfill()
			}
		}
		canComplete2 = true
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testAsyncConLots() {
		let queue = DRDispatchQueue(type: .Concurrent)
		var expectations = [XCTestExpectation]()
		for i in 0...10 {
			expectations.append(expectationWithDescription("expectation: \(i)"))
			var canComplete = false
			queue.dispatchAsync {
				if canComplete == true {
					expectations.last!.fulfill()
				}
			}
			canComplete = true
		}
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	/// Test asynchronous serial
	
	func testAsyncSerial() {
		let queue = DRDispatchQueue(type: .Serial)
		var canComplete: Bool = false
		let expectation = expectationWithDescription("Serial queue expectation.")
		var lastCompleted: Int = -1
		for i: Int in 0...10 {
			queue.dispatchAsync {
				XCTAssert(lastCompleted == i - 1, "Should be running in order.")
				lastCompleted = i
			}
		}
		queue.dispatchAsync {
			if lastCompleted == 10 && canComplete == true {
				expectation.fulfill()
			}
		}
		canComplete = true
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	/// Test sync
	func testSync() {
		// Serial
		let queue = DRDispatchQueue(type: .Serial)
		var canComplete = false
		queue.dispatchSync { () -> Void in
			canComplete = true
		}
		XCTAssert(canComplete == true, "dispatchSync(block) should not return until the block has been executed.")
		// Concurrent
		let queue2 = DRDispatchQueue(type: .Concurrent)
		var canComplete2 = false
		queue2.dispatchSync { () -> Void in
			canComplete2 = true
		}
		XCTAssert(canComplete2 == true, "dispatchSync(block) should not return until the block has been executed.")
	}
	
	/// Test dispatch after
	var testDispatchAfterCanComplete = false
	func testDispatchAfter() {
		let queue = DRDispatchQueue(type: .Concurrent)
		let expectation = expectationWithDescription("Dispatch after expectation.")
		queue.dispatchAfter(1) { () -> Void in
			self.testDispatchAfterCanComplete = true
			expectation.fulfill()
		}
		NSTimer.scheduledTimerWithTimeInterval(0.9, target: self, selector: "timerFired", userInfo: nil, repeats: false)
		waitForExpectationsWithTimeout(1.1, handler: nil)
	}
	
	func timerFired() {
		XCTAssert(testDispatchAfterCanComplete == false, "The block should not have been executed yet.")
	}
	
	/// Test cancelling an asynchronously dispatched block
	func testCancel() {
		let queue = DRDispatchQueue(type: .Serial)
		let expectation = expectationWithDescription("First block should never have been called.")
		var canComplete = true
		queue.dispatchAsync({ () -> Void in
			canComplete = false
		}, identifier: "cancelMe")
		queue.dispatch { () -> Void in
			if canComplete == true {
				expectation.fulfill()
			}
		}
		queue.cancelDispatchWithIdentifier("cancelMe")
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	/// Test serial iteration
	func testSerialIteration() {
		let queue = DRDispatchQueue(type: .Serial)
		var current: UInt = 0
		queue.dispatchIterateSync(10) { (index: UInt) -> Void in
			XCTAssert(current == index, "Iterations should be dispatched in order.")
			current += 1
		}
		XCTAssert(current == 10, "All iterations should now be complete.")
	}
	
	/// Test concurrent iteration
	func testConcurrentIteration() {
		let queue = DRDispatchQueue(type: .Concurrent)
		var current: DRDispatchProtectedObject<UInt> = DRDispatchProtectedObject<UInt>(object: 0)
		queue.dispatchIterateSync(10) { (index: UInt) -> Void in
			var complete = current.with { (inout protectedObject: UInt) -> Void in
				protectedObject += 1
			}
		}
		current.with { (inout protectedObject: UInt) -> Void in
			println("*** \(protectedObject)")
			XCTAssert(protectedObject == 10, "All iterations should now be complete.")
		}
	}
	
	/// Test serial asynchronous iteration
	func testSerialAsyncIteration() {
		let queue = DRDispatchQueue(type: .Serial)
		var current: UInt = 0
		let expectation = expectationWithDescription("Async iteration expectation.")
		queue.dispatchIterateAsync(10) { (index: UInt) -> Void in
			XCTAssert(current == index, "Iterations should be dispatched in order.")
			current += 1
			if current == 10 {
				expectation.fulfill()
			}
		}
		waitForExpectationsWithTimeout(1, handler: nil)
	}

	/// Test concurrent asynchronous iteration
	func testConcurrentAsyncIteration() {
		let queue = DRDispatchQueue(type: .Serial)
		var current: UInt = 0
		let expectation = expectationWithDescription("Async iteration expectation.")
		queue.dispatchIterateAsync(10) { (index: UInt) -> Void in
			current += 1
			if current == 10 {
				expectation.fulfill()
			}
		}
		waitForExpectationsWithTimeout(1, handler: nil)
	}

}
