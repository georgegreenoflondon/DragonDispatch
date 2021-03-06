//
//  DragonDispatchQueue.swift
//  Dragon Dispatch
//
//  Created by George Green on 26/09/2014.
//  Copyright (c) 2014 The Swift Guru. All rights reserved.
//

import Foundation

/// Compare two DRDispatchQueue objects. Two are equal if they represent the same underlying dispatch_queue_t.
public func == (left: DRDispatchQueue, right: DRDispatchQueue) -> Bool {
	return left._queue.isEqual(right._queue)
}

public func != (left: DRDispatchQueue, right: DRDispatchQueue) -> Bool {
	return !(left == right)
}

private let _mainQueue = DRDispatchQueue()
private let _lowPriorityQueue = DRDispatchQueue(priority: .Low)
private let _defaultPriorityQueue = DRDispatchQueue(priority: .Default)
private let _highPriorityQueue = DRDispatchQueue(priority: .High)
private let _backgroundPriorityQueue = DRDispatchQueue(priority: .Background)

private let _dragonConcurrentQueue = DRDispatchQueue(type: .Concurrent, label: "Dragon Dispatch Internal Queue")

/// DRDispatchQueue
/// This class represents a gcd dispatch queue on which blocks of code may be dispatched.
public class DRDispatchQueue {
	
	// MARK: - Private Variables
	
	/// The underlying dispatch_queue_t object that is represented by this object
	internal let _queue: dispatch_queue_t
	/// A dictionary of values that can be set on the queue object to be retreived later.
	private var _context: [String: AnyObject] = [:]
	/// Is this one of the global queues (including the main queue).
	private let _isGlobal: Bool = false
	
	// MARK: - Public Variables
	
	/// Set to true to enable internal console logs.
	var internalLoggingEnabled: Bool = false
	
	/// The label that was attached to the queue when it was created, or nil if no label was specified.
	public var label: String? {
		get {
			return String.stringWithUTF8String(dispatch_queue_get_label(_queue))
		}
	}
	/// The number of blocks remaining to be executed on the queue.
	private var _length: DRDispatchProtectedObject<UInt> = DRDispatchProtectedObject(object: 0)
	var length: UInt {
		get {
			return _length._protectedObject
		}
	}
	
    /// Indicates if the queue is currently paused.
    /// Cannot be set externally.
    public private(set) var isPaused: Bool = false
	
	/// The priority of the queue if this object represent a global queue. Otherwise nil.
	public let priority: DRQueuePriority?
	/// The type of the queue. Either .Serial or .Concurrent.
	public let type: DRQueueType?
	
	// MARK: - Class Methods
	
	public class func mainQueue() -> DRDispatchQueue {
		return _mainQueue
	}
	
	public class func globalQueueWithPriority(priority: DRQueuePriority) -> DRDispatchQueue {
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
	
	/// Creates a global queue object with the specified priority.
	/// @param priority The priority of the queue to create.
	private init(priority: DRQueuePriority) {
		_queue = dispatch_get_global_queue(priority.toConst(), 0)
		self.priority = priority
		self.type = .Concurrent
		_isGlobal = true
	}
	
	/// Create a queue to represent the main queue
	private init() {
		_queue = dispatch_get_main_queue()
		type = .Serial
		_isGlobal = true
	}
	
	/// Create a queue object that represents a dispatch queue with the specitied type.
	/// This will create a new underlying dispatch queue.
	/// @param type The type of queue to be created.
	/// @param label A string used to identify the queue.
	public init(type: DRQueueType, label: String = "Dragon Dispatch Queue") {
		_queue = dispatch_queue_create(label, type.toConst())
		self.type = type
	}
	
	/// Create a queue object that represents the specified dispatch queue.
	public init(queue: dispatch_queue_t) {
		_queue = queue
	}
	
	// MARK: - External Action Methods
	
	/// A convenience method for dispatchAsync.
	public func dispatch(block: DRDispatchBlock) {
		dispatchAsync(countedBlockFromBlock(block))
	}
	
	/// Executes the passed in block on this queue. Will not return until the block has been executed.
	/// @param block The block of code to be synchronously dispatched.
	public func dispatchSync(block: DRDispatchBlock) {
		dispatch_sync(_queue, countedBlockFromBlock(block))
	}
	
	private lazy var validIdentifiers: DRDispatchProtectedObject<DRCountedSet<String>> = DRDispatchProtectedObject<DRCountedSet<String>>(object: DRCountedSet())
    /// Executes the passed in block on this queue. Will return immediatly, and the block will be executed
    /// at some point in the future.
    /// @param block The block of code to be asynchronously dispatched.
	public func dispatchAsync(block: DRDispatchBlock, identifier: String? = nil) {
		if let blockIdentifier = identifier {
			validIdentifiers.with { (inout protectedObject: DRCountedSet<String>) -> Void in
				protectedObject.incrementValue(blockIdentifier)
			}
			_length.with { (inout length: UInt) -> Void in
				length = length + 1
			}
			dispatch_async(_queue, { () -> Void in
				var complete = self.validIdentifiers.with { (inout protectedObject: DRCountedSet<String>) -> Void in
					if protectedObject.countForValue(blockIdentifier) > 0 {
						block()
						self._length.with { (inout length: UInt) -> Void in
							length = length - 1
						}
						protectedObject.decrementValue(blockIdentifier)
					}
				}
			})
		} else {
			dispatch_async(_queue, countedBlockFromBlock(block))
		}
	}
	
	/// Prevent any blocks that were dispatched to this queue, via dispatchAsync(block, identifier), with a specific identifier from being executed.
	/// @param identifier The identifier for blocks to be prevented from being called.
	public func cancelDispatchWithIdentifier(identifier: String) {
		validIdentifiers.with { (inout protectedObject: DRCountedSet<String>) -> Void in
			// Get the number of blocks queued with the identifier
			let count = protectedObject.countForValue(identifier)
			// Decrement the count by that number
			self._length.with { (inout length: UInt) -> Void in
				length -= count
			}
			// Zero the count for the identifier so that they do not get executed
			protectedObject.zeroValue(identifier)
		}
	}
	
	/// Dispatches a block of code to the queue after a given time interval.
	/// @param timeInterval The time, in seconds, after which to dispatch the block.
	/// @param block The block of code to be dispatched.
	public func dispatchAfter(timeInterval: DRTimeInterval, block: DRDispatchBlock) {
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
	public func dispatchIterateSync(iterations: UInt, block: DRDispatchIterationBlock) {
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
	public func dispatchIterateAsync(iterations: UInt, block: DRDispatchIterationBlock) {
		_dragonConcurrentQueue.dispatchAsync { () -> Void in
			self.dispatchIterateSync(iterations, block)
		}
	}
	
	/// Temporarily stop the queue from starting execution of any new blocks.
	/// Any blocks that have been started will be allowed to finish.
	public func pause() {
		if isPaused == false {
			dispatch_suspend(_queue)
			isPaused = true
		}
	}
	
	/// Resume a queue that has been paused via the pause() method. The queue will once again be allowed to 
	/// begin execution of blocks.
	public func resume() {
		if isPaused == true {
			dispatch_resume(_queue)
			isPaused = false
		}
	}
	
	/// Dispatch a barrier block to the queue. This method should not be called on serial or global queues, doing so will return false and do nothing.
	/// A barrier block is not treated the same way as other blocks in the queue. When a barrier block is submitted to a concurrent queue (cannot be
	/// submitted to a serial queue), it will not be executed until all blocks dispatched to the queue prior to the barrier block have completed execution.
	/// In addition, any blocks submitted after the barrier block will not be executed until the barrier block has completed execution.
	/// @param block The block to execute after all previously submitted blocks and before any that are submitted after this call.
	/// @return true if the barrier block was successfully submitted, false if the queue is serial or global.
	/// @discussion This method is synchronous, it will not return until the barrier block has completed execution, are therefore until all the blocks
	/// submitted prior to the barrier block have completed execution too.
	public func barrierSync(block: DRDispatchBlock) -> Bool {
		if _isGlobal { return false }
		if let type = self.type {
			if type == DRQueueType.Serial { return false }
		}
		dispatch_barrier_sync(_queue, block)
		return true
	}
	
	/// Dispatch a barrier block to the queue. This method should not be called on serial or global queues, doing so will return false and do nothing.
	/// A barrier block is not treated the same way as other blocks in the queue. When a barrier block is submitted to a concurrent queue (cannot be
	/// submitted to a serial queue), it will not be executed until all blocks dispatched to the queue prior to the barrier block have completed execution.
	/// In addition, any blocks submitted after the barrier block will not be executed until the barrier block has completed execution.
	/// @param block The block to execute after all previously submitted blocks and before any that are submitted after this call.
	/// @return true if the barrier block was successfully submitted, false if the queue is serial or global.
	/// @discussion This method is asynchronous, it will return immediately and the barrier block will be submitted at some point in the future.
	public func barrierAsync(block: DRDispatchBlock) -> Bool {
		if _isGlobal { return false }
		if let type = self.type {
			if type == .Serial { return false }
		}
		dispatch_barrier_async(_queue, block)
		return true
	}
	
	// MARK: - Subscript access to context variables
	
	/// Access the context information for the queue.
	public subscript(key: String) -> AnyObject? {
		get {
			return _context[key]
		}
		set(newValue) {
			_context[key] = newValue
		}
	}
	
	// MARK: - Internal Helpers
	
	private func countedBlockFromBlock(block: DRDispatchBlock) -> DRDispatchBlock {
		_length.with { (inout length: UInt) -> Void in
			length = length + 1
		}
		return {
			block()
			self._length.with { (inout length: UInt) -> Void in
				length = length - 1
			}
		}
	}
	
}