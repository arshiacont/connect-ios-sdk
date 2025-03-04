/*
 *  Copyright (c) 2018 Zendesk. All rights reserved.
 *
 *  By downloading or using the Zendesk Mobile SDK, You agree to the Zendesk Master
 *  Subscription Agreement https://www.zendesk.com/company/customers-partners/master-subscription-agreement and Application Developer and API License
 *  Agreement https://www.zendesk.com/company/customers-partners/application-developer-api-license-agreement and
 *  acknowledge that such terms govern Your use of and access to the Mobile SDK.
 *
 */

import Foundation

/// Used to represent whether a request was successful or encountered an error.
///
/// - success: The request and all post processing operations were successful resulting in the serialization of the
///            provided associated value.
///
/// - failure: The request encountered an error resulting in a failure. The associated values are the original data
///            provided by the server as well as the error that caused the failure.
enum Result<Value> {
    case success(Value, URLResponse?)
    case failure(Error)

    /// Returns `true` if the result is a success, `false` otherwise.
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    /// Returns `true` if the result is a failure, `false` otherwise.
    var isFailure: Bool {
        return !isSuccess
    }

    /// Returns the associated value if the result is a success, `nil` otherwise.
    var value: Value? {
        switch self {
        case .success(let value, _):
            return value
        case .failure:
            return nil
        }
    }

    /// Returns the associated error value if the result is a failure, `nil` otherwise.
    var error: Error? {
        switch self {
        case .success:
            return nil
        case let .failure(error):
            return error
        }
    }

    var response: URLResponse? {
        switch self {
        case let .success(_, resposne):
            return resposne
        default:
            return nil
        }
    }
}

// MARK: - CustomStringConvertible

extension Result: CustomStringConvertible {
    /// The textual representation used when written to an output stream, which includes whether the result was a
    /// success or failure.
    var description: String {
        switch self {
        case .success:
            return "SUCCESS"
        case .failure:
            return "FAILURE"
        }
    }
}

// MARK: - CustomDebugStringConvertible

extension Result: CustomDebugStringConvertible {
    /// The debug textual representation used when written to an output stream, which includes whether the result was a
    /// success or failure in addition to the value or error.
    var debugDescription: String {
        switch self {
        case let .success(value):
            return "SUCCESS: \(value)"
        case let .failure(error):
            return "FAILURE: \(error)"
        }
    }
}

// MARK: - Functional APIs

extension Result {
    /// Creates a `Result` instance from the result of a closure.
    ///
    /// A failure result is created when the closure throws, and a success result is created when the closure
    /// succeeds without throwing an error.
    ///
    ///     func someString() throws -> String { ... }
    ///
    ///     let result = Result(value: {
    ///         return try someString()
    ///     })
    ///
    ///     // The type of result is Result<String>
    ///
    /// The trailing closure syntax is also supported:
    ///
    ///     let result = Result { try someString() }
    ///
    /// - parameter value: The closure to execute and create the result for.
    init(value: () throws -> Value, response: URLResponse) {
        do {
            self = try .success(value(), response)
        } catch {
            self = .failure(error)
        }
    }

    /// Returns the success value, or throws the failure error.
    ///
    ///     let possibleString: Result<String> = .success("success")
    ///     try print(possibleString.unwrap())
    ///     // Prints "success"
    ///
    ///     let noString: Result<String> = .failure(error)
    ///     try print(noString.unwrap())
    ///     // Throws error
    func unwrap() throws -> Value {
        switch self {
        case .success(let value, _):
            return value
        case let .failure(error):
            throw error
        }
    }

    /// Evaluates the specified closure when the `Result` is a success, passing the unwrapped value as a parameter.
    ///
    /// Use the `map` method with a closure that does not throw. For example:
    ///
    ///     let possibleData: Result<Data> = .success(Data())
    ///     let possibleInt = possibleData.map { $0.count }
    ///     try print(possibleInt.unwrap())
    ///     // Prints "0"
    ///
    ///     let noData: Result<Data> = .failure(error)
    ///     let noInt = noData.map { $0.count }
    ///     try print(noInt.unwrap())
    ///     // Throws error
    ///
    /// - parameter transform: A closure that takes the success value of the `Result` instance.
    ///
    /// - returns: A `Result` containing the result of the given closure. If this instance is a failure, returns the
    ///            same failure.
    func map<T>(_ transform: (Value) -> T) -> Result<T> {
        switch self {
        case let .success(value, response):
            return .success(transform(value), response)
        case let .failure(error):
            return .failure(error)
        }
    }

    /// Evaluates the specified closure when the `Result` is a success, passing the unwrapped value as a parameter.
    ///
    /// Use the `flatMap` method with a closure that may throw an error. For example:
    ///
    ///     let possibleData: Result<Data> = .success(Data(...))
    ///     let possibleObject = possibleData.flatMap {
    ///         try JSONSerialization.jsonObject(with: $0)
    ///     }
    ///
    /// - parameter transform: A closure that takes the success value of the instance.
    ///
    /// - returns: A `Result` containing the result of the given closure. If this instance is a failure, returns the
    ///            same failure.
    func flatMap<T>(_ transform: (Value) throws -> T) -> Result<T> {
        switch self {
        case let .success(value, response):
            do {
                return try .success(transform(value), response)
            } catch {
                return .failure(error)
            }
        case let .failure(error):
            return .failure(error)
        }
    }

    /// Evaluates the specified closure when the `Result` is a failure, passing the unwrapped error as a parameter.
    ///
    /// Use the `mapError` function with a closure that does not throw. For example:
    ///
    ///     let possibleData: Result<Data> = .failure(someError)
    ///     let withMyError: Result<Data> = possibleData.mapError { MyError.error($0) }
    ///
    /// - Parameter transform: A closure that takes the error of the instance.
    /// - Returns: A `Result` instance containing the result of the transform. If this instance is a success, returns
    ///            the same instance.
    func mapError<T: Error>(_ transform: (Error) -> T) -> Result {
        switch self {
        case let .failure(error):
            return .failure(transform(error))
        case .success:
            return self
        }
    }

    /// Evaluates the specified closure when the `Result` is a failure, passing the unwrapped error as a parameter.
    ///
    /// Use the `flatMapError` function with a closure that may throw an error. For example:
    ///
    ///     let possibleData: Result<Data> = .success(Data(...))
    ///     let possibleObject = possibleData.flatMapError {
    ///         try someFailableFunction(taking: $0)
    ///     }
    ///
    /// - Parameter transform: A throwing closure that takes the error of the instance.
    ///
    /// - Returns: A `Result` instance containing the result of the transform. If this instance is a success, returns
    ///            the same instance.
    func flatMapError<T: Error>(_ transform: (Error) throws -> T) -> Result {
        switch self {
        case let .failure(error):
            do {
                return try .failure(transform(error))
            } catch {
                return .failure(error)
            }
        case .success:
            return self
        }
    }

    /// Evaluates the specified closure when the `Result` is a success, passing the unwrapped value as a parameter.
    ///
    /// Use the `withValue` function to evaluate the passed closure without modifying the `Result` instance.
    ///
    /// - Parameter closure: A closure that takes the success value of this instance.
    /// - Returns: This `Result` instance, unmodified.
    @discardableResult
    func withValue(_ closure: (Value, URLResponse?) -> Void) -> Result {
        if case let .success(value, response) = self { closure(value, response) }

        return self
    }

    /// Evaluates the specified closure when the `Result` is a failure, passing the unwrapped error as a parameter.
    ///
    /// Use the `withError` function to evaluate the passed closure without modifying the `Result` instance.
    ///
    /// - Parameter closure: A closure that takes the success value of this instance.
    /// - Returns: This `Result` instance, unmodified.
    @discardableResult
    func withError(_ closure: (Error) -> Void) -> Result {
        if case let .failure(error) = self { closure(error) }

        return self
    }

    /// Evaluates the specified closure when the `Result` is a success.
    ///
    /// Use the `ifSuccess` function to evaluate the passed closure without modifying the `Result` instance.
    ///
    /// - Parameter closure: A `Void` closure.
    /// - Returns: This `Result` instance, unmodified.
    @discardableResult
    func ifSuccess(_ closure: () -> Void) -> Result {
        if isSuccess { closure() }

        return self
    }

    /// Evaluates the specified closure when the `Result` is a failure.
    ///
    /// Use the `ifFailure` function to evaluate the passed closure without modifying the `Result` instance.
    ///
    /// - Parameter closure: A `Void` closure.
    /// - Returns: This `Result` instance, unmodified.
    @discardableResult
    func ifFailure(_ closure: () -> Void) -> Result {
        if isFailure { closure() }

        return self
    }
}
