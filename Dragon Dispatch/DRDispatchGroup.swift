//
//  DRDispatchGroup.swift
//  Dragon Dispatch
//
//  Created by George Green on 27/09/2014.
//  Copyright (c) 2014 The Swift Guru. All rights reserved.
//

import Foundation

/// Adds the block on the right to the group on the left, for dispatch to the groups default queue.
public func += (left: DRDispatchGroup, right: DRDispatchBlock) {
	left.addBlock(right)
}

/// Dispatch groups are used to watch for completion of a number of blocks that have been dispatched for
/// execution on a dispatch queue. It has the benefit of being able to watch blocks across multiple queues to check
/// when they have completed.
public class DRDispatchGroup {
	
	// MARK: - Private Varialbles
	
	/// The underlying dispatch group object.
	private let _group: dispatch_group_t = dispatch_group_create()
	
	// MARK: - Public Variables
	
	private var _defaultQueue: DRDispatchQueue
	/// The default queue to which blocks will be dispatched if another queue is not explicitly specified in a call
	/// to addBlock(block, queue).
	public var defaultQueue: DRDispatchQueue {
		get {
			return _defaultQueue
		}
	}
	/// The number of blocks that have been added to the group and have not yet completed.
	private var _count: DRDispatchProtectedObject<UInt> = DRDispatchProtectedObject(object: 0)
	public var count: UInt {
		get {
			return _count._protectedObject
		}
	}
	
	// MARK: - Object Lifecycle Methods
	
	/// Create a new dispatch group.
	/// @param defaultQueue An optional parameter to specify the queue that blocks submitted to this group will be
	/// dispatched to, if not explicitly specified in the call to addBlock(block, queue). Defaults to the default priority
	/// global concurrent queue.
	public init(defaultQueue: DRDispatchQueue = DRDispatchQueue.globalQueueWithPriority(.Default)) {
		// Keep hold of the default queue
		_defaultQueue = defaultQueue
	}
	
	/// MARK: - Public Action Methods
	
	/// Adds a block to the group. The block will be executed asynchronously on the specified queue.
	/// @param block The block of code to be associated with the group.
	/// @param queue The dispatch queue on which the block should be asynchronously dispatched.
	public func addBlock(block: DRDispatchBlock, queue: DRDispatchQueue? = nil) {
		if let dispatchQueue = queue {
			dispatch_group_async(_group, dispatchQueue._queue, block)
		} else {
			dispatch_group_async(_group, _defaultQueue._queue, block)
		}
	}
	
	/// Call this method to synchronously wait for all of the blocks that have been submitted to this group to complete.
	/// This method will not return until all previously submitted blocks have completed tehir execution.
	/// @param timeout An optional parameter to specify how long to wait for the blocks to complete. Defaults to nil, to
	/// specify to wait indefinately.
	/// @return true if all blocks completed before the timeout, false if the timeout was reached before all blocks were
	/// completed.
	/// @discussion This method only waits for the completion of blocks added to the group, via addBlock(block, queue),
	/// prior to calling this method.
	public func wait(timeout: DRTimeInterval? = nil) -> Bool {
		let waitTime = dispatchTimeFromTimeInterval(timeout)
		return dispatch_group_wait(_group, waitTime) == 0
	}
	
	/// Specify a block of code to be dispatched to a queue after all blocks that have been previously submitted
	/// to this group have completed.
	/// @param notifyBlock The block the be called once all blocks in the group have completed.
	/// @param queue The queue on which to dispatch the notifyBlock
	/// @discussion notifyBlock will be called after block submitted to the group, via addBlock(block, queue), prior to
	/// calling this method have completed. You may add more blocks after this call but they may not have completed
	/// when this notify block is called. This method can be called again if more blocks are submitted to the group.
	public func notify(notifyBlock: DRDispatchBlock, queue: DRDispatchQueue? = nil) {
		if let dispatchQueue = queue {
			dispatch_group_notify(_group, dispatchQueue._queue, notifyBlock)
		} else {
			dispatch_group_notify(_group, _defaultQueue._queue, notifyBlock)
		}
	}
	
	// MARK: - Internal Helpers
	
	public func countedBlockFromBlock(block: DRDispatchBlock) -> DRDispatchBlock {
		_count.with { (inout count: UInt) -> Void in
			count = count + 1
		}
		return {
			block()
			self._count.with { (inout count: UInt) -> Void in
				count = count - 1
			}
		}
	}
	
}