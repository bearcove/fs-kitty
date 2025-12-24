public func add(_ a: Int32, _ b: Int32) -> Int32 {
    __swift_bridge__$add(a, b)
}
public func distance(_ a: Point, _ b: Point) -> Double {
    __swift_bridge__$distance(a.intoFfiRepr(), b.intoFfiRepr())
}
public struct Point {
    public var x: Double
    public var y: Double

    public init(x: Double,y: Double) {
        self.x = x
        self.y = y
    }

    @inline(__always)
    func intoFfiRepr() -> __swift_bridge__$Point {
        { let val = self; return __swift_bridge__$Point(x: val.x, y: val.y); }()
    }
}
extension __swift_bridge__$Point {
    @inline(__always)
    func intoSwiftRepr() -> Point {
        { let val = self; return Point(x: val.x, y: val.y); }()
    }
}
extension __swift_bridge__$Option$Point {
    @inline(__always)
    func intoSwiftRepr() -> Optional<Point> {
        if self.is_some {
            return self.val.intoSwiftRepr()
        } else {
            return nil
        }
    }

    @inline(__always)
    static func fromSwiftRepr(_ val: Optional<Point>) -> __swift_bridge__$Option$Point {
        if let v = val {
            return __swift_bridge__$Option$Point(is_some: true, val: v.intoFfiRepr())
        } else {
            return __swift_bridge__$Option$Point(is_some: false, val: __swift_bridge__$Point())
        }
    }
}


