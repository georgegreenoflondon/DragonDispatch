//
//  DragonDispatchQueue.swift
//  Dragon Dispatch
//
//  Created by George Green on 26/09/2014.
//  Copyright (c) 2014 The Swift Guru. All rights reserved.
//

import Foundation

/// Compare two DRDispatchQueue objects. Two are equal if they represent the same underlying dispatch_queue_t.
func == (left: DRDispatchQueue, right: DRDispatchQueue) -> Bool {
	return left._queue.isEqual(right._queue)
}

private let _mainQueue = DRDispatchQueue(queue: dispatch_get_main_queue())
private let _lowPriorityQueue = DRDispatchQueue.globalQueueWithPriority(.Low)
private let _defaultPriorityQueue = DRDispatchQueue.globalQueueWithPriority(.Default)
private let _highPriorityQueue = DRDispatchQueue.globalQueueWithPriority(.High)
private let _backgroundPriorityQueue = DRDispatchQueue.globalQueueWithPriority(.Background)

/// DRDispatchQueue
/// This class represents a gcd dispatch queue on which blocks of code may be dispatched.
class DRDispatchQueue {
	
	// MARK: - Private Variables
	
	/// The underlying dispatch_queue_t object that is represented by this object
	private let _queue: dispatch_queue_t
	
	// MARK: - Public Variables
	var label: String? {
		get {
			return String.stringWithUTF8String(dispatch_queue_get_label(_queue))
		}
	}
	
	/// The priority of the queue if this object represent a global queue. Otherwise nil.
	let priority: DRQueuePriority?
	/// The type of the queue. Either .Serial or .Concurrent.
	let type: DRQueueType?
	
	// MARK: - Class Methods
	
	class func mainQueue() -> DRDispatchQueue {
		return _mainQueue
	}
	
	class func globalQueueWithPriority(priority: DRQueuePriority) -> DRDispatchQueue {
		switch priority {
		case .Low:
			return _lowPriorityQueue
		case .High:
			return _highPriorityQueue
		case .Background:
			return _backgroundPriorityQueue
		case .Default:
			return _defaultPriorityQueue
		}
	}
	
	// MARK: - Convienence Initialisers
	
	
	// MARK: - Object Lifecycle Methods
	
	/// Create a queue object that represents a dispatch queue with the specitied type.
	/// This will create a new underlying dispatch queue.
	/// @param type The type of queue to be created.
	/// @param label A string used to identify the queue.
	init(type: DRQueueType, label: String = "Dragon Dispatch Queue") {
		_queue = dispatch_queue_create(label, type.toConst())
		self.type = type
	}
	
	/// Create a queue object that represents the specified dispatch queue.
	init(queue: dispatch_queue_t) {
		_queue = queue
	}
	
	// MARK: - External Action Methods
	
	/// A convenience method for dispatchAsync.
	func dispatch(block: DRDispatchBlock) {
		dispatchAsync(block)
	}
	
	/// Executes the passed in block on this queue. Will not return until the block has been executed.
	func dispatchSync(block: DRDispatchBlock) {
		dispatch_sync(_queue, block)
	}
	
	/// Executes the passed in block on this queue. Will return immediatly, and the block will be executed
	/// at some point in the future.
	func dispatchAsync(block: DRDispatchBlock) {
		dispatch_async(_queue, block)
	}
	
}