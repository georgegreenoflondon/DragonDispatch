//
//  DragonDispatch.swift
//  Dragon Dispatch
//
//  Created by George Green on 26/09/2014.
//  Copyright (c) 2014 The Swift Guru. All rights reserved.
//

import Foundation

public typealias DRDispatchBlock = (() -> Void)
public typealias DRDispatchIterationBlock = ((index: UInt) -> Void)
public typealias DRTimeInterval = NSTimeInterval
public typealias DRDispatchChainBlock = ((_: Any?) -> Any?)

/// The priority of a global concurrent queue.
public enum DRQueuePriority {
	case Low
	case Default
	case High
	case Background
	
	func toConst() -> dispatch_queue_priority_t {
		switch self {
		case .Low:
			return DISPATCH_QUEUE_PRIORITY_LOW
		case .High:
			return DISPATCH_QUEUE_PRIORITY_HIGH
		case .Background:
			return DISPATCH_QUEUE_PRIORITY_BACKGROUND
		default:
			return DISPATCH_QUEUE_PRIORITY_DEFAULT
		}
	}
}

/// The type of a dispatch queue.
public enum DRQueueType {
	/// A serial queue will execute all blocks dispatch to it one after another.
	/// It will wait for the first block to complete and then execute the second one after it and so on...
	/// Guarantees that all blocks dispatched will be executed in the order that they are dispatched.
	case Serial
	/// A concurrent will potentially run multiple blocks at the same time. 
	/// Blocks dispatched to a concurrent queue are guaranteed to be started in the order that they are dispatched,
	/// but they will not necessarily finish in the same order.
	case Concurrent
	
	func toConst() -> dispatch_queue_attr_t! {
		switch self {
			case .Serial:
				return DISPATCH_QUEUE_SERIAL
			case .Concurrent:
				return DISPATCH_QUEUE_CONCURRENT
		}
	}
}

/// Dispatch a block of code for execution on the specifed priority global concurrent queue.
/// Returns immediately and the block will be executed at some point in the future.
/// @returns A reference to the queue that the block will be executed on.
public func DRDispatchAsync(block : DRDispatchBlock, priority: DRQueuePriority = .Default) -> DRDispatchQueue {
	let queue = DRDispatchQueue.globalQueueWithPriority(priority)
	queue.dispatchAsync(block)
	return queue
}

/// Dispatch a block of code for execution on the specified priority global concurrent queue.
/// Returns once execution of the block has completed.
/// @returns A reference to the queue that the block of code was executed on.
public func DRDispatchSync(block: DRDispatchBlock, priority: DRQueuePriority = .Default) -> DRDispatchQueue {
	let queue = DRDispatchQueue.globalQueueWithPriority(priority)
	queue.dispatchSync(block)
	return queue
}

/// Dispatch a block of code to be executed on the main queue.
/// @param block The block of code to be executed.
/// @param synchronously If true this method will not return until the block of code has been executed. If false this method
/// will return immediately and block will be executed on the main queue at some point in the future. Defaults to true.
/// @warning If you call this method from the main queue with synchronously == true, it will block the main queue.
public func DRDispatchMain(block: DRDispatchBlock, synchronously: Bool = true) {
	if synchronously {
		DRDispatchQueue.mainQueue().dispatchSync(block)
	} else {
		DRDispatchQueue.mainQueue().dispatchAsync(block)
	}
}

/// Dispatch a block of code for execution on the specified priority global queue after a specified time interval.
/// Returns immediately and the block will be executed at some point in the future.
/// @param timeInterval The time after which the block should be dispatched.
/// @param block The block of code to be executed after the time interval.
/// @param priority The priority of the global queue to which the block should be dispatched.
/// @return The queue to which the block will be dispatched.
public func DRDispatchAfter(timeInterval: DRTimeInterval, block: DRDispatchBlock, priority: DRQueuePriority = .Default) -> DRDispatchQueue {
	let queue = DRDispatchQueue.globalQueueWithPriority(priority)
	queue.dispatchAfter(timeInterval, block: block)
	return queue
}

// MARK: - Internal Helpers

internal func dispatchTimeFromTimeInterval(timeInterval: DRTimeInterval?) -> dispatch_time_t	{
	if timeInterval == nil { return DISPATCH_TIME_FOREVER }
	return dispatch_time(DISPATCH_TIME_NOW, (Int64)(timeInterval! * DRTimeInterval(NSEC_PER_SEC)));
}

// MARK: - Dispatch Once

public typealias DRDispatchOnceToken = dispatch_once_t

public func DRDispatchOnce(block: DRDispatchBlock, inout token: DRDispatchOnceToken) {
	dispatch_once(&token, block)
}

// MARK: - Queue safe logging

let logQueue = DRDispatchQueue(type: .Serial, label: "DRDispatch.LoggingQueue")
/// Log to the console using the standard println() function.
/// Sometimes when using println() on multiple queues the logs get jumbled together, this function uses a serial queue to ensure that logs
/// do not get jumbled up and get printed in the that they are called.
/// @param logString The string to be printed to the console.
public func DRDispatchLog(logString: String) {
	logQueue.dispatchAsync {
		println(logString)
	}
}
