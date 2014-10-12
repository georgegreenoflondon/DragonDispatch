//
//  DRDispatchChain.swift
//  Dragon Dispatch
//
//  Created by George Green on 11/10/2014.
//  Copyright (c) 2014 The Swift Guru. All rights reserved.
//

import Foundation

/// This class allows you to chain together many asynchronous events. It works in a similar fashion to a serial dispatch queue
/// but provides clearer methods for chaining, and allows for a block to receive the result of a previous block, or for the chain to be
/// broken in certain circumstances.
/// This class manages an internal serial dispatch queue on which all blocks will be executed. If you need to update the UI from within
/// your chain, you will need to dispatch back to the main queue using DRDispatchMain().
public class DRDispatchChain {
    
    // MARK: Internal
    
    private typealias _DRDispatchChainBlock = ((_: Any?) -> Void)
    /// The queue used to dispatch blocks in the chain.
    private let _queue: DRDispatchQueue = DRDispatchQueue(type: .Serial, label: "DRDispatch.DRDispatchQueue.Internal")
    /// The array to hold the blocks to be executed.
    private var _blockQueue: [_DRDispatchChainBlock] = []
    /// Indicates if the chain has already started.
    public private(set) var hasStarted: Bool = false
    
    // MARK: - Object Lifecycle Methods
    
    /// Create a new dispatch chain.
    /// @param queue The dispatch queue to use for all blocks in the chain.
    public init(queue: DRDispatchQueue?) {
        if let theQueue = queue {
            _queue = theQueue
        }
    }
    
    /// Create a new disaptch chain.
    /// @returns A new DRDispatchChain object initialised and ready to use.
    public convenience init() {
        self.init(queue: nil)
    }
    
    // MARK: - Public Methods
    
    /// Dispatch a block to the chain. The block will be executed and its return value will be passed to the next block in the
    /// chain even if it is nil.
    /// @param block The block to be dispatched to the chain.
    /// @returns A reference to the chain so that more blocks may be added.
    public func first(block: DRDispatchChainBlock) -> DRDispatchChain {
        return then(block)
    }
    
    /// Dispatch a block to the chain. If the block returns nil, the chain will be broken. If the block returns anything other than nil,
    /// the next block in the chain will be executed and passed the result.
    /// @param block The block to be dispatched to decide if the chain should continue.
    /// @returns A reference to the chain so that more blocks may be added.
    public func firstIf(block: DRDispatchChainBlock) -> DRDispatchChain {
        return thenIf(block)
    }
    
    /// Dispatch a block to the chain. The block will be executed in turn and its return value will be passed to the next block in the
    /// chain even if it is nil.
    /// @param block The block to be dispatched to the chain.
    /// @returns A reference to the chain so that more blocks may be added.
    public func then(block: DRDispatchChainBlock) -> DRDispatchChain {
        // Wrap the block and add it to the queue
        let newBlock = { (obj: Any?) -> Void in
            // Call the block
            let returnObj = block(obj)
            // Remove the block from the queue
            let removedBlock = self._blockQueue.removeAtIndex(0)
            // Call to run the next block if there is one
            self._next(returnObj)
        }
        _blockQueue.append(newBlock)
        // Return
        return self
    }
    
    /// Dispatch a block to the chain. If the block returns nil, the chain will be broken. If the block returns anything other than nil,
    /// the next block in the chain will be executed and passed the result.
    /// @param block The block to be dispatched to decide if the chain should continue.
    /// @returns A reference to the chain so that more blocks may be added.
    public func thenIf(block: DRDispatchChainBlock) -> DRDispatchChain {
        // Wrap the block and add it to the queue
        let newBlock = { (obj: Any?) -> Void in
            // Define a function for cleaning up
            func cleanup() {
                var removedBlock = self._blockQueue.removeAtIndex(0)
            }
            // Call the block and see what it returns
            if let returnObj = block(obj) {
                // If it returned something, cleanup and start the next block
                cleanup()
                self._next(returnObj)
            } else {
                // If it returned nil, cleanup and break the chain
                cleanup()
                self._breakChain()
            }
        }
        _blockQueue.append(newBlock)
        // Return
        return self
    }
    
    /// Begin the chain. This call begins execution of the first block in the queue.
    public func begin() {
        // Check if the chain has already been started
        if hasStarted == false {
            // Set that the chain has now started
            hasStarted = true
            // Start the chain
            _next(nil)
        }
    }
    
    // MARK: - Internal Helpers
    
    /// Check if there is another block and disaptch it asynchronously to the queue.
    private func _next(obj: Any?) {
        // Check if there are any more blocks to dispatch
        if let nextBlock = _blockQueue.first {
            _queue.dispatchAsync {
                nextBlock(obj)
            }
        }
    }
    
    /// Break the chain
    private func _breakChain() {
        // Empty the blocks in the queue
        _blockQueue.removeAll(keepCapacity: false)
    }
    
}