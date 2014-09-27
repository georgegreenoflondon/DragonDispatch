//
//  DragonDispatch.swift
//  Dragon Dispatch
//
//  Created by George Green on 26/09/2014.
//  Copyright (c) 2014 The Swift Guru. All rights reserved.
//

import Foundation

typealias DRDispatchBlock = (() -> Void)
typealias DRDispatchIterationBlock = ((index: UInt) -> Void)
typealias DRTimeInterval = NSTimeInterval

/// The priority of a global concurrent queue.
enum DRQueuePriority {
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
enum DRQueueType {
	/// A serial queue will execute all blocks dispatch to it one after another.
	/// It will wait for the first block to complete and then execute the second one after it and so on...
	/// Guarantees that all blocks dispatched will be executed in the order that they are dispatched.
	case Serial
	/// A concurrent will potentially run multiple blocks at the same time. 
	/// Blocks dispatched to a concurrent queue are guaranteed to be started in the order that they are dispatched,
	/// but they will not necessarily finish in the same order.
	case Concurrent
	
	func toConst() -> dispatch_queue_attr_t {
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
func DRDispatchAsync(block : DRDispatchBlock, priority: DRQueuePriority = .Default) -> DRDispatchQueue {
	let queue = DRDispatchQueue.globalQueueWithPriority(priority)
	queue.dispatchAsync(block)
	return queue
}

/// Dispatch a block of code for execution on the specified priority global concurrent queue.
/// Returns once execution of the block has completed.
/// @returns A reference to the queue that the block of code was executed on.
func DRDispatchSync(block: DRDispatchBlock, priority: DRQueuePriority = .Default) -> DRDispatchQueue {
	let queue = DRDispatchQueue.globalQueueWithPriority(priority)
	queue.dispatchSync(block)
	return queue
}
