import Foundation

/// Represents the result of an operation that may either succeed or fail. Takes two generic types: one for the result of a success, and one `Error` subtype to represent a failure.
enum Try<T,E: Error>: CustomDebugStringConvertible {

    /// Represents the success of an operation with an associated result.
    case success(T)
    /// Represents the failure of an operation with an associated `Error`.
    case failure(E)

    var debugDescription: String {
        switch self {
        case .success(let t):
            return "Success(\(t))"
        case .failure(let error):
            return "Failure(\(error)"
        }
    }
}
