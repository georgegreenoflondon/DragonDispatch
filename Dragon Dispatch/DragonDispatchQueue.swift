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
private let _lowPriorityQueue = DRDispatchQueue(queue: dispatch_get_global_queue(DRQueuePriority.Low.toConst(), 0))
private let _defaultPriorityQueue = DRDispatchQueue(queue: dispatch_get_global_queue(DRQueuePriority.Default.toConst(), 0))
private let _highPriorityQueue = DRDispatchQueue(queue: dispatch_get_global_queue(DRQueuePriority.High.toConst(), 0))
private let _backgroundPriorityQueue = DRDispatchQueue(queue: dispatch_get_global_queue(DRQueuePriority.Background.toConst(), 0))

private let _dragonConcurrentQueue = DRDispatchQueue(type: .Concurrent, label: "Dragon Dispatch Internal Queue")

/// DRDispatchQueue
/// This class represents a gcd dispatch queue on which blocks of code may be dispatched.
class DRDispatchQueue {
	
	// MARK: - Private Variables
	
	/// The underlying dispatch_queue_t object that is represented by this object
	internal let _queue: dispatch_queue_t
	/// A dictionary of values that can be set on the queue object to be retreived later.
	private var _context: [String: AnyObject] = [:]
	
	// MARK: - Public Variables
	
	/// The label that was attached to the queue when it was created, or nil if no label was specified.
	var label: String? {
		get {
			return String.stringWithUTF8String(dispatch_queue_get_label(_queue))
		}
	}
	
	private var _isPaused: Bool = false
	/// Used to check if the queue is currently paused.
	var isPaused: Bool {
		get {
			return _isPaused
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
	/// @param block The block of code to be synchronously dispatched.
	func dispatchSync(block: DRDispatchBlock) {
		dispatch_sync(_queue, block)
	}
	
	/// Executes the passed in block on this queue. Will return immediatly, and the block will be executed
	/// at some point in the future.
	/// @param block The block of code to be asynchronously dispatched.
	private lazy var validIdentifiers: DRCountedSet<String> = DRCountedSet()
	func dispatchAsync(block: DRDispatchBlock, identifier: String? = nil) {
		if let blockIdentifier = identifier {
			validIdentifiers.incrementValue(blockIdentifier)
			dispatch_async(_queue, { () -> Void in
				if self.validIdentifiers.countForValue(blockIdentifier) > 0 {
					block()
					self.validIdentifiers.decrementValue(blockIdentifier)
				}
			})
		} else {
			dispatch_async(_queue, block)
		}
	}
	
	/// Prevent any blocks that were dispatched to this queue, via dispatchAsync(block, identifier), with a specific identifier from being executed.
	/// @param identifier The identifier for blocks to be prevented from being called.
	func cancelDispatchWithIdentifier(identifier: String) {
		validIdentifiers.zeroValue(identifier)
	}
	
	/// Dispatches a block of code to the queue after a given time interval.
	/// @param timeInterval The time, in seconds, after which to dispatch the block.
	/// @param block The block of code to be dispatched.
	func dispatchAfter(timeInterval: DRTimeInterval, block: DRDispatchBlock) {
		let time = dispatchTimeFromTimeInterval(timeInterval)
		dispatch_after(time, _queue, block)
	}
	
	/// Dispatches a block of code the specified number of time onto the queue.
	/// If the queue is serial the block will be executed the specified number of times one after the other,
	/// if the queue is concurrent they may all be executed at the same time.
	/// The block will be passed an index parameter specifying which iteration it is. 0..<iterations
	/// This method will not return until all iterations of the block of code have been executed.
	/// @param The number of times to execute the block.
	/// @param block The block of code to be executed.
	func dispatchIterateSync(iterations: UInt, block: DRDispatchIterationBlock) {
		dispatch_apply(iterations, _queue, block)
	}
	
	/// Dispatches a block of code the specified number of time onto the queue.
	/// If the queue is serial the block will be executed the specified number of times one after the other,
	/// if the queue is concurrent they may all be executed at the same time, therefore the code must be
	/// re-entrant safe. (It must be ok for it to be executed multiple times at the same time!)
	/// The block will be passed an index parameter specifying which iteration it is. 0..<iterations
	/// This method will return immediately, and the block will be executed the specified number of times
	/// at some point in the future.
	/// @param The number of times to execute the block.
	/// @param block The block of code to be executed.
	func dispatchIterateAsync(iterations: UInt, block: DRDispatchIterationBlock) {
		_dragonConcurrentQueue.dispatchAsync { () -> Void in
			self.dispatchIterateSync(iterations, block)
		}
	}
	
	/// Temporarily stop the queue from starting execution of any new blocks.
	/// Any blocks that have been started will be allowed to finish.
	func pause() {
		if _isPaused == false {
			dispatch_suspend(_queue)
			_isPaused = true
		}
	}
	
	/// Resume a queue that has been paused via the pause() method. The queue will once again be allowed to 
	/// begin execution of blocks.
	func resume() {
		if _isPaused == true {
			dispatch_resume(_queue)
			_isPaused = false
		}
	}
	
	// MARK: - Subscript access to context variables
	
	/// Access the context information for the queue.
	subscript(key: String) -> AnyObject? {
		get {
			return _context[key]
		}
		set(newValue) {
			_context[key] = newValue
		}
	}
	
}