import Foundation

/// A type-safe, thread-safe class which represents the result of an asynchronous operation that may complete at some future point. Construct it with an asynchronous, blocking operation that returns a `Try`. Attach `onComplete` blocks which will be called immediately if the operation has finished or after the operation has finished if not. Requires two generic parameters: the type of a successful result and an `Error` subclass for a failure.
final class Future<T,E: Error> {

    /// A semaphore to ensure that each `onComplete block` is called exactly once.
    private let onCompleteSemaphore = DispatchSemaphore(value: 1)

    /// A semaphore to block `getResult()` until the asynchronous operation finishes.
    private let getResultSemaphore = DispatchSemaphore(value: 0)

    /// The `DispatchQueue` on which to call the `onComplete` blocks.
    private let onCompleteQueue: DispatchQueue

    /// Creates a new `Future` to run the given operation. The `Future` is created immediately while the operation runs in the background. The operation must return a `Try<T,E>`. It should be a `.success(T)` if the operation succeeded, and a `.failure(E)` if the operation failed.
    ///
    /// - Parameters:
    ///   - onCompleteQueue: The queue to run the `Future`'s `onComplete` blocks on. Defaults to the queue that the `Future` was constructed on.
    ///   - operation: The operation to run. Runs in the background, so can be a blocking operation. Must return a `Try` with the same generic type as the `Future`.
    init(onCompleteQueue: DispatchQueue = OperationQueue.current?.underlyingQueue ?? DispatchQueue.global(), operation: @escaping () -> Try<T,E>) {
        self.onCompleteQueue = onCompleteQueue

        DispatchQueue(label: "com.coupgon.future.init").async {
            let result: Try<T,E> = operation()

            self.onCompleteSemaphore.wait()

            self.result = result
            self.hasCompleted = true

            self.getResultSemaphore.signal()

            while !self.onCompleteBlocks.isEmpty {
                self.onCompleteQueue.sync {
                    self.onCompleteBlocks.removeFirst()(result)
                }
            }

            self.onCompleteSemaphore.signal()
        }
    }

    /// The result, if the operation has completed; `nil` otherwise.
    private(set) var result: Try<T,E>?

    /// Gets the result of the operation synchronously. NOTE: this is a blocking operation, so only run it when nested in the operation of another `Future` or when in a background thread. If the provided operation does not return, this may never return.
    ///
    /// - Returns: The result of the operation.
    func getResult() -> Try<T,E> {
        if let result = result {
            return result
        } else {
            getResultSemaphore.wait()
            return getResult()
        }
    }

    /// Whether the operation has completed.
    private(set) var hasCompleted: Bool = false

    /// The blocks to call upon completion of the operation.
    private var onCompleteBlocks: [(Try<T,E>) -> Void] = []

    /// Adds a block which *may* be called with the result of the operation at some point in the future. If the operation has completed, will be called immediately. If the operation has not completed, will be called upon completion. If the operation does not complete, the block will not be called. Multiple onComplete blocks can be added to the `Future`, and they will be called in the order in which they are added. The blocks are called upon the `DispatchQueue` that the `Future` is initialized with, or the `DispatchQueue` the `Future` is initialized *on* by default if no `DispatchQueue` is provided.
    ///
    /// - Parameter block: The block to call upon completion of the future operation.
    func onComplete(block: @escaping (Try<T,E>) -> Void) {
        DispatchQueue(label: "com.coupgon.future.on_complete").async {
            self.onCompleteSemaphore.wait()

            if let result = self.result {
                self.onCompleteQueue.sync {
                    block(result)
                }
            } else {
                self.onCompleteBlocks.append(block)
            }

            self.onCompleteSemaphore.signal()
        }
    }
}
