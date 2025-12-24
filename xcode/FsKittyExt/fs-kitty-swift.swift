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
public func vfs_disconnect() {
    __swift_bridge__$vfs_disconnect()
}
public func vfs_ping() throws -> RustString {
    try { let val = __swift_bridge__$vfs_ping(); if val.is_ok { return RustString(ptr: val.ok_or_err!) } else { throw RustString(ptr: val.ok_or_err!) } }()
}
public func vfs_lookup<GenericIntoRustString: IntoRustString>(_ parent_id: UInt64, _ name: GenericIntoRustString) throws -> FfiLookupResult {
    try { let val = __swift_bridge__$vfs_lookup(parent_id, { let rustString = name.intoRustString(); rustString.isOwned = false; return rustString.ptr }()); switch val.tag { case __swift_bridge__$ResultFfiLookupResultAndString$ResultOk: return val.payload.ok.intoSwiftRepr() case __swift_bridge__$ResultFfiLookupResultAndString$ResultErr: throw RustString(ptr: val.payload.err) default: fatalError() } }()
}
public func vfs_get_attributes(_ item_id: UInt64) throws -> FfiItemAttributes {
    try { let val = __swift_bridge__$vfs_get_attributes(item_id); switch val.tag { case __swift_bridge__$ResultFfiItemAttributesAndString$ResultOk: return val.payload.ok.intoSwiftRepr() case __swift_bridge__$ResultFfiItemAttributesAndString$ResultErr: throw RustString(ptr: val.payload.err) default: fatalError() } }()
}
public func vfs_read_dir(_ item_id: UInt64, _ cursor: UInt64) throws -> FfiReadDirResult {
    try { let val = __swift_bridge__$vfs_read_dir(item_id, cursor); switch val.tag { case __swift_bridge__$ResultFfiReadDirResultAndString$ResultOk: return val.payload.ok.intoSwiftRepr() case __swift_bridge__$ResultFfiReadDirResultAndString$ResultErr: throw RustString(ptr: val.payload.err) default: fatalError() } }()
}
public func vfs_read(_ item_id: UInt64, _ offset: UInt64, _ len: UInt64) throws -> FfiReadResult {
    try { let val = __swift_bridge__$vfs_read(item_id, offset, len); switch val.tag { case __swift_bridge__$ResultFfiReadResultAndString$ResultOk: return val.payload.ok.intoSwiftRepr() case __swift_bridge__$ResultFfiReadResultAndString$ResultErr: throw RustString(ptr: val.payload.err) default: fatalError() } }()
}
public func vfs_write(_ item_id: UInt64, _ offset: UInt64, _ data: RustVec<UInt8>) throws -> FfiWriteResult {
    try { let val = __swift_bridge__$vfs_write(item_id, offset, { let val = data; val.isOwned = false; return val.ptr }()); switch val.tag { case __swift_bridge__$ResultFfiWriteResultAndString$ResultOk: return val.payload.ok.intoSwiftRepr() case __swift_bridge__$ResultFfiWriteResultAndString$ResultErr: throw RustString(ptr: val.payload.err) default: fatalError() } }()
}
public func vfs_create<GenericIntoRustString: IntoRustString>(_ parent_id: UInt64, _ name: GenericIntoRustString, _ item_type: UInt8) throws -> FfiCreateResult {
    try { let val = __swift_bridge__$vfs_create(parent_id, { let rustString = name.intoRustString(); rustString.isOwned = false; return rustString.ptr }(), item_type); switch val.tag { case __swift_bridge__$ResultFfiCreateResultAndString$ResultOk: return val.payload.ok.intoSwiftRepr() case __swift_bridge__$ResultFfiCreateResultAndString$ResultErr: throw RustString(ptr: val.payload.err) default: fatalError() } }()
}
public func vfs_delete(_ item_id: UInt64) throws -> FfiVfsResult {
    try { let val = __swift_bridge__$vfs_delete(item_id); switch val.tag { case __swift_bridge__$ResultFfiVfsResultAndString$ResultOk: return val.payload.ok.intoSwiftRepr() case __swift_bridge__$ResultFfiVfsResultAndString$ResultErr: throw RustString(ptr: val.payload.err) default: fatalError() } }()
}
public func vfs_rename<GenericIntoRustString: IntoRustString>(_ item_id: UInt64, _ new_parent_id: UInt64, _ new_name: GenericIntoRustString) throws -> FfiVfsResult {
    try { let val = __swift_bridge__$vfs_rename(item_id, new_parent_id, { let rustString = new_name.intoRustString(); rustString.isOwned = false; return rustString.ptr }()); switch val.tag { case __swift_bridge__$ResultFfiVfsResultAndString$ResultOk: return val.payload.ok.intoSwiftRepr() case __swift_bridge__$ResultFfiVfsResultAndString$ResultErr: throw RustString(ptr: val.payload.err) default: fatalError() } }()
}
public struct FfiLookupResult {
    public var item_id: UInt64
    public var item_type: UInt8
    public var error: Int32

    public init(item_id: UInt64,item_type: UInt8,error: Int32) {
        self.item_id = item_id
        self.item_type = item_type
        self.error = error
    }

    @inline(__always)
    func intoFfiRepr() -> __swift_bridge__$FfiLookupResult {
        { let val = self; return __swift_bridge__$FfiLookupResult(item_id: val.item_id, item_type: val.item_type, error: val.error); }()
    }
}
extension __swift_bridge__$FfiLookupResult {
    @inline(__always)
    func intoSwiftRepr() -> FfiLookupResult {
        { let val = self; return FfiLookupResult(item_id: val.item_id, item_type: val.item_type, error: val.error); }()
    }
}
extension __swift_bridge__$Option$FfiLookupResult {
    @inline(__always)
    func intoSwiftRepr() -> Optional<FfiLookupResult> {
        if self.is_some {
            return self.val.intoSwiftRepr()
        } else {
            return nil
        }
    }

    @inline(__always)
    static func fromSwiftRepr(_ val: Optional<FfiLookupResult>) -> __swift_bridge__$Option$FfiLookupResult {
        if let v = val {
            return __swift_bridge__$Option$FfiLookupResult(is_some: true, val: v.intoFfiRepr())
        } else {
            return __swift_bridge__$Option$FfiLookupResult(is_some: false, val: __swift_bridge__$FfiLookupResult())
        }
    }
}
public struct FfiItemAttributes {
    public var item_id: UInt64
    public var item_type: UInt8
    public var size: UInt64
    public var modified_time: UInt64
    public var created_time: UInt64
    public var error: Int32

    public init(item_id: UInt64,item_type: UInt8,size: UInt64,modified_time: UInt64,created_time: UInt64,error: Int32) {
        self.item_id = item_id
        self.item_type = item_type
        self.size = size
        self.modified_time = modified_time
        self.created_time = created_time
        self.error = error
    }

    @inline(__always)
    func intoFfiRepr() -> __swift_bridge__$FfiItemAttributes {
        { let val = self; return __swift_bridge__$FfiItemAttributes(item_id: val.item_id, item_type: val.item_type, size: val.size, modified_time: val.modified_time, created_time: val.created_time, error: val.error); }()
    }
}
extension __swift_bridge__$FfiItemAttributes {
    @inline(__always)
    func intoSwiftRepr() -> FfiItemAttributes {
        { let val = self; return FfiItemAttributes(item_id: val.item_id, item_type: val.item_type, size: val.size, modified_time: val.modified_time, created_time: val.created_time, error: val.error); }()
    }
}
extension __swift_bridge__$Option$FfiItemAttributes {
    @inline(__always)
    func intoSwiftRepr() -> Optional<FfiItemAttributes> {
        if self.is_some {
            return self.val.intoSwiftRepr()
        } else {
            return nil
        }
    }

    @inline(__always)
    static func fromSwiftRepr(_ val: Optional<FfiItemAttributes>) -> __swift_bridge__$Option$FfiItemAttributes {
        if let v = val {
            return __swift_bridge__$Option$FfiItemAttributes(is_some: true, val: v.intoFfiRepr())
        } else {
            return __swift_bridge__$Option$FfiItemAttributes(is_some: false, val: __swift_bridge__$FfiItemAttributes())
        }
    }
}
public struct FfiDirEntry {
    public var name: RustString
    public var item_id: UInt64
    public var item_type: UInt8

    public init(name: RustString,item_id: UInt64,item_type: UInt8) {
        self.name = name
        self.item_id = item_id
        self.item_type = item_type
    }

    @inline(__always)
    func intoFfiRepr() -> __swift_bridge__$FfiDirEntry {
        { let val = self; return __swift_bridge__$FfiDirEntry(name: { let rustString = val.name.intoRustString(); rustString.isOwned = false; return rustString.ptr }(), item_id: val.item_id, item_type: val.item_type); }()
    }
}
extension __swift_bridge__$FfiDirEntry {
    @inline(__always)
    func intoSwiftRepr() -> FfiDirEntry {
        { let val = self; return FfiDirEntry(name: RustString(ptr: val.name), item_id: val.item_id, item_type: val.item_type); }()
    }
}
extension __swift_bridge__$Option$FfiDirEntry {
    @inline(__always)
    func intoSwiftRepr() -> Optional<FfiDirEntry> {
        if self.is_some {
            return self.val.intoSwiftRepr()
        } else {
            return nil
        }
    }

    @inline(__always)
    static func fromSwiftRepr(_ val: Optional<FfiDirEntry>) -> __swift_bridge__$Option$FfiDirEntry {
        if let v = val {
            return __swift_bridge__$Option$FfiDirEntry(is_some: true, val: v.intoFfiRepr())
        } else {
            return __swift_bridge__$Option$FfiDirEntry(is_some: false, val: __swift_bridge__$FfiDirEntry())
        }
    }
}
public struct FfiReadDirResult {
    public var entries: RustVec<FfiDirEntry>
    public var next_cursor: UInt64
    public var error: Int32

    public init(entries: RustVec<FfiDirEntry>,next_cursor: UInt64,error: Int32) {
        self.entries = entries
        self.next_cursor = next_cursor
        self.error = error
    }

    @inline(__always)
    func intoFfiRepr() -> __swift_bridge__$FfiReadDirResult {
        { let val = self; return __swift_bridge__$FfiReadDirResult(entries: { let val = val.entries; val.isOwned = false; return val.ptr }(), next_cursor: val.next_cursor, error: val.error); }()
    }
}
extension __swift_bridge__$FfiReadDirResult {
    @inline(__always)
    func intoSwiftRepr() -> FfiReadDirResult {
        { let val = self; return FfiReadDirResult(entries: RustVec(ptr: val.entries), next_cursor: val.next_cursor, error: val.error); }()
    }
}
extension __swift_bridge__$Option$FfiReadDirResult {
    @inline(__always)
    func intoSwiftRepr() -> Optional<FfiReadDirResult> {
        if self.is_some {
            return self.val.intoSwiftRepr()
        } else {
            return nil
        }
    }

    @inline(__always)
    static func fromSwiftRepr(_ val: Optional<FfiReadDirResult>) -> __swift_bridge__$Option$FfiReadDirResult {
        if let v = val {
            return __swift_bridge__$Option$FfiReadDirResult(is_some: true, val: v.intoFfiRepr())
        } else {
            return __swift_bridge__$Option$FfiReadDirResult(is_some: false, val: __swift_bridge__$FfiReadDirResult())
        }
    }
}
public struct FfiReadResult {
    public var data: RustVec<UInt8>
    public var error: Int32

    public init(data: RustVec<UInt8>,error: Int32) {
        self.data = data
        self.error = error
    }

    @inline(__always)
    func intoFfiRepr() -> __swift_bridge__$FfiReadResult {
        { let val = self; return __swift_bridge__$FfiReadResult(data: { let val = val.data; val.isOwned = false; return val.ptr }(), error: val.error); }()
    }
}
extension __swift_bridge__$FfiReadResult {
    @inline(__always)
    func intoSwiftRepr() -> FfiReadResult {
        { let val = self; return FfiReadResult(data: RustVec(ptr: val.data), error: val.error); }()
    }
}
extension __swift_bridge__$Option$FfiReadResult {
    @inline(__always)
    func intoSwiftRepr() -> Optional<FfiReadResult> {
        if self.is_some {
            return self.val.intoSwiftRepr()
        } else {
            return nil
        }
    }

    @inline(__always)
    static func fromSwiftRepr(_ val: Optional<FfiReadResult>) -> __swift_bridge__$Option$FfiReadResult {
        if let v = val {
            return __swift_bridge__$Option$FfiReadResult(is_some: true, val: v.intoFfiRepr())
        } else {
            return __swift_bridge__$Option$FfiReadResult(is_some: false, val: __swift_bridge__$FfiReadResult())
        }
    }
}
public struct FfiWriteResult {
    public var bytes_written: UInt64
    public var error: Int32

    public init(bytes_written: UInt64,error: Int32) {
        self.bytes_written = bytes_written
        self.error = error
    }

    @inline(__always)
    func intoFfiRepr() -> __swift_bridge__$FfiWriteResult {
        { let val = self; return __swift_bridge__$FfiWriteResult(bytes_written: val.bytes_written, error: val.error); }()
    }
}
extension __swift_bridge__$FfiWriteResult {
    @inline(__always)
    func intoSwiftRepr() -> FfiWriteResult {
        { let val = self; return FfiWriteResult(bytes_written: val.bytes_written, error: val.error); }()
    }
}
extension __swift_bridge__$Option$FfiWriteResult {
    @inline(__always)
    func intoSwiftRepr() -> Optional<FfiWriteResult> {
        if self.is_some {
            return self.val.intoSwiftRepr()
        } else {
            return nil
        }
    }

    @inline(__always)
    static func fromSwiftRepr(_ val: Optional<FfiWriteResult>) -> __swift_bridge__$Option$FfiWriteResult {
        if let v = val {
            return __swift_bridge__$Option$FfiWriteResult(is_some: true, val: v.intoFfiRepr())
        } else {
            return __swift_bridge__$Option$FfiWriteResult(is_some: false, val: __swift_bridge__$FfiWriteResult())
        }
    }
}
public struct FfiCreateResult {
    public var item_id: UInt64
    public var error: Int32

    public init(item_id: UInt64,error: Int32) {
        self.item_id = item_id
        self.error = error
    }

    @inline(__always)
    func intoFfiRepr() -> __swift_bridge__$FfiCreateResult {
        { let val = self; return __swift_bridge__$FfiCreateResult(item_id: val.item_id, error: val.error); }()
    }
}
extension __swift_bridge__$FfiCreateResult {
    @inline(__always)
    func intoSwiftRepr() -> FfiCreateResult {
        { let val = self; return FfiCreateResult(item_id: val.item_id, error: val.error); }()
    }
}
extension __swift_bridge__$Option$FfiCreateResult {
    @inline(__always)
    func intoSwiftRepr() -> Optional<FfiCreateResult> {
        if self.is_some {
            return self.val.intoSwiftRepr()
        } else {
            return nil
        }
    }

    @inline(__always)
    static func fromSwiftRepr(_ val: Optional<FfiCreateResult>) -> __swift_bridge__$Option$FfiCreateResult {
        if let v = val {
            return __swift_bridge__$Option$FfiCreateResult(is_some: true, val: v.intoFfiRepr())
        } else {
            return __swift_bridge__$Option$FfiCreateResult(is_some: false, val: __swift_bridge__$FfiCreateResult())
        }
    }
}
public struct FfiVfsResult {
    public var error: Int32

    public init(error: Int32) {
        self.error = error
    }

    @inline(__always)
    func intoFfiRepr() -> __swift_bridge__$FfiVfsResult {
        { let val = self; return __swift_bridge__$FfiVfsResult(error: val.error); }()
    }
}
extension __swift_bridge__$FfiVfsResult {
    @inline(__always)
    func intoSwiftRepr() -> FfiVfsResult {
        { let val = self; return FfiVfsResult(error: val.error); }()
    }
}
extension __swift_bridge__$Option$FfiVfsResult {
    @inline(__always)
    func intoSwiftRepr() -> Optional<FfiVfsResult> {
        if self.is_some {
            return self.val.intoSwiftRepr()
        } else {
            return nil
        }
    }

    @inline(__always)
    static func fromSwiftRepr(_ val: Optional<FfiVfsResult>) -> __swift_bridge__$Option$FfiVfsResult {
        if let v = val {
            return __swift_bridge__$Option$FfiVfsResult(is_some: true, val: v.intoFfiRepr())
        } else {
            return __swift_bridge__$Option$FfiVfsResult(is_some: false, val: __swift_bridge__$FfiVfsResult())
        }
    }
}


