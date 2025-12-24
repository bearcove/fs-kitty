import BridgeHeaders

public func add(_ a: Int32, _ b: Int32) -> Int32 {
    __swift_bridge__$add(a, b)
}
public func async_add(_ a: Int32, _ b: Int32) async -> Int32 {
    func onComplete(cbWrapperPtr: UnsafeMutableRawPointer?, rustFnRetVal: Int32) {
        let wrapper = Unmanaged<CbWrapper$async_add>.fromOpaque(cbWrapperPtr!).takeRetainedValue()
        wrapper.cb(.success(rustFnRetVal))
    }

    return await withCheckedContinuation({ (continuation: CheckedContinuation<Int32, Never>) in
        let callback = { rustFnRetVal in
            continuation.resume(with: rustFnRetVal)
        }

        let wrapper = CbWrapper$async_add(cb: callback)
        let wrapperPtr = Unmanaged.passRetained(wrapper).toOpaque()

        __swift_bridge__$async_add(wrapperPtr, onComplete, a, b)
    })
}
class CbWrapper$async_add {
    var cb: (Result<Int32, Never>) -> ()

    public init(cb: @escaping (Result<Int32, Never>) -> ()) {
        self.cb = cb
    }
}
public func async_greet<GenericIntoRustString: IntoRustString>(_ name: GenericIntoRustString) async -> RustString {
    func onComplete(cbWrapperPtr: UnsafeMutableRawPointer?, rustFnRetVal: UnsafeMutableRawPointer?) {
        let wrapper = Unmanaged<CbWrapper$async_greet>.fromOpaque(cbWrapperPtr!).takeRetainedValue()
        wrapper.cb(.success(RustString(ptr: rustFnRetVal!)))
    }

    return await withCheckedContinuation({ (continuation: CheckedContinuation<RustString, Never>) in
        let callback = { rustFnRetVal in
            continuation.resume(with: rustFnRetVal)
        }

        let wrapper = CbWrapper$async_greet(cb: callback)
        let wrapperPtr = Unmanaged.passRetained(wrapper).toOpaque()

        __swift_bridge__$async_greet(wrapperPtr, onComplete, { let rustString = name.intoRustString(); rustString.isOwned = false; return rustString.ptr }())
    })
}
class CbWrapper$async_greet {
    var cb: (Result<RustString, Never>) -> ()

    public init(cb: @escaping (Result<RustString, Never>) -> ()) {
        self.cb = cb
    }
}
public func vfs_connect<GenericIntoRustString: IntoRustString>(_ addr: GenericIntoRustString) throws -> () {
    try { let val = __swift_bridge__$vfs_connect({ let rustString = addr.intoRustString(); rustString.isOwned = false; return rustString.ptr }()); if val != nil { throw RustString(ptr: val!) } else { return } }()
}
public func vfs_ping() throws -> RustString {
    try { let val = __swift_bridge__$vfs_ping(); if val.is_ok { return RustString(ptr: val.ok_or_err!) } else { throw RustString(ptr: val.ok_or_err!) } }()
}


