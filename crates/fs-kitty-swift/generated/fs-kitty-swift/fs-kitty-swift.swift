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
public func async_divide(_ a: Int32, _ b: Int32) async throws -> Int32 {
    func onComplete(cbWrapperPtr: UnsafeMutableRawPointer?, rustFnRetVal: __swift_bridge__$ResultI32AndString) {
        let wrapper = Unmanaged<CbWrapper$async_divide>.fromOpaque(cbWrapperPtr!).takeRetainedValue()
        switch rustFnRetVal.tag { case __swift_bridge__$ResultI32AndString$ResultOk: wrapper.cb(.success(rustFnRetVal.payload.ok)) case __swift_bridge__$ResultI32AndString$ResultErr: wrapper.cb(.failure(RustString(ptr: rustFnRetVal.payload.err))) default: fatalError() }
    }

    return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Int32, Error>) in
        let callback = { rustFnRetVal in
            continuation.resume(with: rustFnRetVal)
        }

        let wrapper = CbWrapper$async_divide(cb: callback)
        let wrapperPtr = Unmanaged.passRetained(wrapper).toOpaque()

        __swift_bridge__$async_divide(wrapperPtr, onComplete, a, b)
    })
}
class CbWrapper$async_divide {
    var cb: (Result<Int32, Error>) -> ()

    public init(cb: @escaping (Result<Int32, Error>) -> ()) {
        self.cb = cb
    }
}
public func async_get_bytes(_ len: UInt) async -> RustVec<UInt8> {
    func onComplete(cbWrapperPtr: UnsafeMutableRawPointer?, rustFnRetVal: RustVec<UInt8>) {
        let wrapper = Unmanaged<CbWrapper$async_get_bytes>.fromOpaque(cbWrapperPtr!).takeRetainedValue()
        wrapper.cb(.success(RustVec(ptr: rustFnRetVal)))
    }

    return await withCheckedContinuation({ (continuation: CheckedContinuation<RustVec<UInt8>, Never>) in
        let callback = { rustFnRetVal in
            continuation.resume(with: rustFnRetVal)
        }

        let wrapper = CbWrapper$async_get_bytes(cb: callback)
        let wrapperPtr = Unmanaged.passRetained(wrapper).toOpaque()

        __swift_bridge__$async_get_bytes(wrapperPtr, onComplete, len)
    })
}
class CbWrapper$async_get_bytes {
    var cb: (Result<RustVec<UInt8>, Never>) -> ()

    public init(cb: @escaping (Result<RustVec<UInt8>, Never>) -> ()) {
        self.cb = cb
    }
}
public func async_read() async -> ReadResult {
    func onComplete(cbWrapperPtr: UnsafeMutableRawPointer?, rustFnRetVal: __swift_bridge__$ReadResult) {
        let wrapper = Unmanaged<CbWrapper$async_read>.fromOpaque(cbWrapperPtr!).takeRetainedValue()
        wrapper.cb(.success(rustFnRetVal.intoSwiftRepr()))
    }

    return await withCheckedContinuation({ (continuation: CheckedContinuation<ReadResult, Never>) in
        let callback = { rustFnRetVal in
            continuation.resume(with: rustFnRetVal)
        }

        let wrapper = CbWrapper$async_read(cb: callback)
        let wrapperPtr = Unmanaged.passRetained(wrapper).toOpaque()

        __swift_bridge__$async_read(wrapperPtr, onComplete)
    })
}
class CbWrapper$async_read {
    var cb: (Result<ReadResult, Never>) -> ()

    public init(cb: @escaping (Result<ReadResult, Never>) -> ()) {
        self.cb = cb
    }
}
public func async_read_dir() async -> ReadDirResult {
    func onComplete(cbWrapperPtr: UnsafeMutableRawPointer?, rustFnRetVal: __swift_bridge__$ReadDirResult) {
        let wrapper = Unmanaged<CbWrapper$async_read_dir>.fromOpaque(cbWrapperPtr!).takeRetainedValue()
        wrapper.cb(.success(rustFnRetVal.intoSwiftRepr()))
    }

    return await withCheckedContinuation({ (continuation: CheckedContinuation<ReadDirResult, Never>) in
        let callback = { rustFnRetVal in
            continuation.resume(with: rustFnRetVal)
        }

        let wrapper = CbWrapper$async_read_dir(cb: callback)
        let wrapperPtr = Unmanaged.passRetained(wrapper).toOpaque()

        __swift_bridge__$async_read_dir(wrapperPtr, onComplete)
    })
}
class CbWrapper$async_read_dir {
    var cb: (Result<ReadDirResult, Never>) -> ()

    public init(cb: @escaping (Result<ReadDirResult, Never>) -> ()) {
        self.cb = cb
    }
}
public func vfs_connect<GenericIntoRustString: IntoRustString>(_ addr: GenericIntoRustString) async throws -> () {
    func onComplete(cbWrapperPtr: UnsafeMutableRawPointer?, rustFnRetVal: UnsafeMutableRawPointer?) {
        let wrapper = Unmanaged<CbWrapper$vfs_connect>.fromOpaque(cbWrapperPtr!).takeRetainedValue()
        if rustFnRetVal == nil {
            wrapper.cb(.success(()))
        } else {
            wrapper.cb(.failure(RustString(ptr: rustFnRetVal!)))
        }
    }

    return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<(), Error>) in
        let callback = { rustFnRetVal in
            continuation.resume(with: rustFnRetVal)
        }

        let wrapper = CbWrapper$vfs_connect(cb: callback)
        let wrapperPtr = Unmanaged.passRetained(wrapper).toOpaque()

        __swift_bridge__$vfs_connect(wrapperPtr, onComplete, { let rustString = addr.intoRustString(); rustString.isOwned = false; return rustString.ptr }())
    })
}
class CbWrapper$vfs_connect {
    var cb: (Result<(), Error>) -> ()

    public init(cb: @escaping (Result<(), Error>) -> ()) {
        self.cb = cb
    }
}
public func vfs_ping() async throws -> RustString {
    func onComplete(cbWrapperPtr: UnsafeMutableRawPointer?, rustFnRetVal: __private__ResultPtrAndPtr) {
        let wrapper = Unmanaged<CbWrapper$vfs_ping>.fromOpaque(cbWrapperPtr!).takeRetainedValue()
        if rustFnRetVal.is_ok {
            wrapper.cb(.success(RustString(ptr: rustFnRetVal.ok_or_err!)))
        } else {
            wrapper.cb(.failure(RustString(ptr: rustFnRetVal.ok_or_err!)))
        }
    }

    return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<RustString, Error>) in
        let callback = { rustFnRetVal in
            continuation.resume(with: rustFnRetVal)
        }

        let wrapper = CbWrapper$vfs_ping(cb: callback)
        let wrapperPtr = Unmanaged.passRetained(wrapper).toOpaque()

        __swift_bridge__$vfs_ping(wrapperPtr, onComplete)
    })
}
class CbWrapper$vfs_ping {
    var cb: (Result<RustString, Error>) -> ()

    public init(cb: @escaping (Result<RustString, Error>) -> ()) {
        self.cb = cb
    }
}
public struct ReadResult {
    public var data: RustVec<UInt8>
    public var error: Int32

    public init(data: RustVec<UInt8>,error: Int32) {
        self.data = data
        self.error = error
    }

    @inline(__always)
    func intoFfiRepr() -> __swift_bridge__$ReadResult {
        { let val = self; return __swift_bridge__$ReadResult(data: { let val = val.data; val.isOwned = false; return val.ptr }(), error: val.error); }()
    }
}
extension __swift_bridge__$ReadResult {
    @inline(__always)
    func intoSwiftRepr() -> ReadResult {
        { let val = self; return ReadResult(data: RustVec(ptr: val.data), error: val.error); }()
    }
}
extension __swift_bridge__$Option$ReadResult {
    @inline(__always)
    func intoSwiftRepr() -> Optional<ReadResult> {
        if self.is_some {
            return self.val.intoSwiftRepr()
        } else {
            return nil
        }
    }

    @inline(__always)
    static func fromSwiftRepr(_ val: Optional<ReadResult>) -> __swift_bridge__$Option$ReadResult {
        if let v = val {
            return __swift_bridge__$Option$ReadResult(is_some: true, val: v.intoFfiRepr())
        } else {
            return __swift_bridge__$Option$ReadResult(is_some: false, val: __swift_bridge__$ReadResult())
        }
    }
}
public struct DirEntry {
    public var name: RustString
    public var item_id: UInt64

    public init(name: RustString,item_id: UInt64) {
        self.name = name
        self.item_id = item_id
    }

    @inline(__always)
    func intoFfiRepr() -> __swift_bridge__$DirEntry {
        { let val = self; return __swift_bridge__$DirEntry(name: { let rustString = val.name.intoRustString(); rustString.isOwned = false; return rustString.ptr }(), item_id: val.item_id); }()
    }
}
extension __swift_bridge__$DirEntry {
    @inline(__always)
    func intoSwiftRepr() -> DirEntry {
        { let val = self; return DirEntry(name: RustString(ptr: val.name), item_id: val.item_id); }()
    }
}
extension __swift_bridge__$Option$DirEntry {
    @inline(__always)
    func intoSwiftRepr() -> Optional<DirEntry> {
        if self.is_some {
            return self.val.intoSwiftRepr()
        } else {
            return nil
        }
    }

    @inline(__always)
    static func fromSwiftRepr(_ val: Optional<DirEntry>) -> __swift_bridge__$Option$DirEntry {
        if let v = val {
            return __swift_bridge__$Option$DirEntry(is_some: true, val: v.intoFfiRepr())
        } else {
            return __swift_bridge__$Option$DirEntry(is_some: false, val: __swift_bridge__$DirEntry())
        }
    }
}
public struct ReadDirResult {
    public var entries: RustVec<DirEntry>
    public var error: Int32

    public init(entries: RustVec<DirEntry>,error: Int32) {
        self.entries = entries
        self.error = error
    }

    @inline(__always)
    func intoFfiRepr() -> __swift_bridge__$ReadDirResult {
        { let val = self; return __swift_bridge__$ReadDirResult(entries: { let val = val.entries; val.isOwned = false; return val.ptr }(), error: val.error); }()
    }
}
extension __swift_bridge__$ReadDirResult {
    @inline(__always)
    func intoSwiftRepr() -> ReadDirResult {
        { let val = self; return ReadDirResult(entries: RustVec(ptr: val.entries), error: val.error); }()
    }
}
extension __swift_bridge__$Option$ReadDirResult {
    @inline(__always)
    func intoSwiftRepr() -> Optional<ReadDirResult> {
        if self.is_some {
            return self.val.intoSwiftRepr()
        } else {
            return nil
        }
    }

    @inline(__always)
    static func fromSwiftRepr(_ val: Optional<ReadDirResult>) -> __swift_bridge__$Option$ReadDirResult {
        if let v = val {
            return __swift_bridge__$Option$ReadDirResult(is_some: true, val: v.intoFfiRepr())
        } else {
            return __swift_bridge__$Option$ReadDirResult(is_some: false, val: __swift_bridge__$ReadDirResult())
        }
    }
}


