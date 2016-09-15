import Foundation.NSNotification
#if !COCOAPODS
import PromiseKit
#endif

/**
 To import the `NSNotificationCenter` category:

    use_frameworks!
    pod "PromiseKit/Foundation"

 Or `NSNotificationCenter` is one of the categories imported by the umbrella pod:

    use_frameworks!
    pod "PromiseKit"

 And then in your sources:

    import PromiseKit
*/

extension NSNotificationCenter {
    public class func once(name: String) -> NotificationPromise<[NSObject: AnyObject]> {
        return NSNotificationCenter.defaultCenter().once(name)
    }
    
    public func once(name: String) -> NotificationPromise<[NSObject: AnyObject]> {
        let (promise, fulfill, _) = NotificationPromise<[NSObject: AnyObject]>.go()
        let id = addObserverForName(name, object: nil, queue: nil, usingBlock: fulfill)
        promise.then(on: zalgo) { _ in self.removeObserver(id) }
        return promise
    }
}

public class NotificationPromise<T>: Promise<T> {
    private let (parentPromise, parentFulfill, parentReject) = Promise<NSNotification>.pendingPromise()
    
    public func asNotification() -> Promise<NSNotification> {
        return parentPromise
    }
    
    private class func go() -> (NotificationPromise<[NSObject: AnyObject]>, (NSNotification) -> Void, (ErrorType) -> Void) {
        var fulfill: (([NSObject: AnyObject]) -> Void)!
        var reject: ((ErrorType) -> Void)!
                let promise = NotificationPromise<[NSObject: AnyObject]> { f, r in
                    fulfill = f
                    reject = r
                }
        promise.parentPromise.then { fulfill($0.userInfo ?? [:]) }
        promise.parentPromise.error { reject($0) }
        return (promise, promise.parentFulfill, promise.parentReject)
    }
    
    private override init(@noescape resolvers: (fulfill: (T) -> Void, reject: (ErrorType) -> Void) throws -> Void) {
        super.init(resolvers: resolvers)
    }
}

extension NSNotificationCenter {
    public class func once(name: String, timeout: NSTimeInterval) -> Promise<[NSObject: AnyObject]> {
        return NSNotificationCenter.defaultCenter().once(name, timeout:timeout)
    }
    
    private func once(name: String, timeout: NSTimeInterval) -> Promise<[NSObject: AnyObject]> {
        let (promise, fulfill, reject) = NotificationPromise<[NSObject:AnyObject]>.go()
        let id = addObserverForName(name, object: nil, queue: nil, usingBlock: fulfill)
        after(timeout).then { reject(NSError(code: VVErrorCode.Network.rawValue)) }
        promise.always(on: zalgo) { _ in self.removeObserver(id) }
        return promise
    }
}
