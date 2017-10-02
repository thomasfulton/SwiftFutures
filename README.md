# SwiftFutures
A lightweight futures implementation in Swift. This makes asynchronous operations in Swift easier and more functional. Inspired by the Future and Try classes in Scala.

## Tutorial

Copy the files into your project -- eventually this will be versioned and available on CocoaPods, but not yet.

You use Futures like this:

```
struct MyError: Error {}

let future = Future {
    let response = makeNetworkingRequest()
    if let response = response {
        return .success(response)
    } else {
        return .error(MyError())
    }
}
```
The initializer returns immediately while the blocking operation runs in its own thread. The blocking operation must return an enum of type `Try<_,Error>` which represents a success or failure of the asynchronous operation, and contains the response if successful or an `Error` object if unsuccessful. The `Future` can now be stored or passed around. Whether immediately or at some later time, you can get the result:

```
future.onComplete { (result) in
    switch (result) {
    case .success(let response):
        // Handle response.
    case .failure(let error):
        // Handle error. 
    }
}

```

If the onComplete listener is set before the operation completes, it will be called when it completes. If the operation has completed, it will be called immediately. `onComplete` blocks can be run on a provided `DispatchQueue` or on the initializer's queue.

## TODOs

Release this on CocoaPods.
