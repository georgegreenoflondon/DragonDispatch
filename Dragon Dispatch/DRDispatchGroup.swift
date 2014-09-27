//
//  DRDispatchGroup.swift
//  Dragon Dispatch
//
//  Created by George Green on 27/09/2014.
//  Copyright (c) 2014 The Swift Guru. All rights reserved.
//

import Foundation

/// Dispatch groups are used to watch for completion of a number of blocks that have been dispatched for
/// execution on a dispatch queue.
class DRDispatchGroup {
	
	// MARK: - Private Varialbles
	
	/// The underlying dispatch group object.
	private let _group: dispatch_group_t = dispatch_group_create()
	
	// MARK: - Object Lifecycle Methods
	
	/// Create a new dispatch group
	init() {
		
	}
	
	/// MARK: - Public Action Methods
	
	/// Adds a block to the group. The block will be executed asynchronously on the specified queue.
	/// @param block The block of code to be associated with the group.
	/// @param queue The dispatch queue on which the block should be asynchronously dispatched.
	func addBlock(block: DRDispatchBlock, queue: DRDispatchQueue) {
		dispatch_group_async(_group, queue._queue, block)
	}
	
	/// Call this method to synchronously wait for all of the blocks that have been submitted to this group to complete.
	/// This method will not return until all previously submitted blocks have completed tehir execution.
	/// @param timeout An optional parameter to specify how long to wait for the blocks to complete. Defaults to nil, to
	/// specify to wait indefinately.
	/// @return true if all blocks completed before the timeout, false if the timeout was reached before all blocks were
	/// completed.
	/// @discussion This method only waits for the completion of blocks added to the group, via addBlock(block, queue),
	/// prior to calling this method.
	func wait(timeout: DRTimeInterval? = nil) -> Bool {
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
	func notify(notifyBlock: DRDispatchBlock, queue: DRDispatchQueue) {
		dispatch_group_notify(_group, queue._queue, notifyBlock)
	}
	
}