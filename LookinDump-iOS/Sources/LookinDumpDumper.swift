import Foundation
import ObjectiveC.runtime
import UIKit

@objc(LookinDumpDumper)
public final class LookinDumpDumper: NSObject {
    private typealias ObjectGetter = @convention(c) (NSObject, Selector) -> Unmanaged<AnyObject>?
    private typealias ClassGetter = @convention(c) (NSObject, Selector) -> AnyClass?
    private typealias BoolGetter = @convention(c) (NSObject, Selector) -> Bool
    private typealias Int8Getter = @convention(c) (NSObject, Selector) -> Int8
    private typealias UInt8Getter = @convention(c) (NSObject, Selector) -> UInt8
    private typealias Int16Getter = @convention(c) (NSObject, Selector) -> Int16
    private typealias UInt16Getter = @convention(c) (NSObject, Selector) -> UInt16
    private typealias Int32Getter = @convention(c) (NSObject, Selector) -> Int32
    private typealias UInt32Getter = @convention(c) (NSObject, Selector) -> UInt32
    private typealias LongGetter = @convention(c) (NSObject, Selector) -> CLong
    private typealias UnsignedLongGetter = @convention(c) (NSObject, Selector) -> CUnsignedLong
    private typealias Int64Getter = @convention(c) (NSObject, Selector) -> Int64
    private typealias UInt64Getter = @convention(c) (NSObject, Selector) -> UInt64
    private typealias FloatGetter = @convention(c) (NSObject, Selector) -> Float
    private typealias DoubleGetter = @convention(c) (NSObject, Selector) -> Double
    private typealias CGRectGetter = @convention(c) (NSObject, Selector) -> CGRect
    private typealias CGPointGetter = @convention(c) (NSObject, Selector) -> CGPoint
    private typealias CGSizeGetter = @convention(c) (NSObject, Selector) -> CGSize
    private typealias CGVectorGetter = @convention(c) (NSObject, Selector) -> CGVector
    private typealias CGAffineTransformGetter = @convention(c) (NSObject, Selector) -> CGAffineTransform
    private typealias UIEdgeInsetsGetter = @convention(c) (NSObject, Selector) -> UIEdgeInsets
    private typealias NSRangeGetter = @convention(c) (NSObject, Selector) -> NSRange

    @objc(lookinDumpForObject:selectorName:)
    public static func lookinDump(object: NSObject, selectorName: NSString) -> NSString {
        guard let path = propertyPath(from: selectorName as String) else {
            return "<invalid lookin dump selector>" as NSString
        }
        guard let value = reflectedValue(at: ArraySlice(path), in: object) else {
            return "<nil>" as NSString
        }
        return dumpString(value) as NSString
    }

    private static func propertyPath(from selectorName: String) -> [String]? {
        let prefix = "lkdump__"
        guard selectorName.hasPrefix(prefix) else { return nil }
        let nsSelectorName = selectorName as NSString
        let prefixLength = (prefix as NSString).length
        guard nsSelectorName.length > prefixLength else { return nil }
        let path = nsSelectorName.substring(from: prefixLength)
            .components(separatedBy: "__")
            .filter { !$0.isEmpty }
        return path.isEmpty ? nil : path
    }

    private static func reflectedValue(at path: ArraySlice<String>, in value: Any) -> Any? {
        guard let key = path.first else { return unwrap(value) }
        guard let unwrapped = unwrap(value) else { return nil }
        let mirror = Mirror(reflecting: unwrapped)
        if let child = child(named: key, in: mirror) {
            return reflectedValue(at: path.dropFirst(), in: child.value)
        }
        guard let getterValue = objectGetterValue(named: key, in: unwrapped) else { return nil }
        return reflectedValue(at: path.dropFirst(), in: getterValue)
    }

    private static func child(named key: String, in mirror: Mirror) -> Mirror.Child? {
        if let child = mirror.children.first(where: { $0.label == key }) {
            return child
        }
        guard let superclassMirror = mirror.superclassMirror else { return nil }
        return child(named: key, in: superclassMirror)
    }

    private static func unwrap(_ value: Any) -> Any? {
        let mirror = Mirror(reflecting: value)
        guard mirror.displayStyle == .optional else { return value }
        return mirror.children.first?.value
    }

    private static func dumpString(_ value: Any) -> String {
        guard let unwrapped = unwrap(value) else { return "<nil>" }
        return String(describing: unwrapped)
    }

    private static func objectGetterValue(named key: String, in value: Any) -> Any? {
        guard !key.contains(":") else { return nil }
        guard let object = value as? NSObject else { return nil }
        let selector = NSSelectorFromString(key)
        guard object.responds(to: selector),
              let method = instanceMethod(selector, object: object),
              method_getNumberOfArguments(method) == 2 else {
            return nil
        }
        return objcGetterValue(selector, method: method, object: object)
    }

    private static func instanceMethod(_ selector: Selector, object: NSObject) -> Method? {
        var currentClass: AnyClass? = type(of: object)
        while let candidate = currentClass {
            if let method = class_getInstanceMethod(candidate, selector) {
                return method
            }
            currentClass = class_getSuperclass(candidate)
        }
        return nil
    }

    private static func objcGetterValue(_ selector: Selector, method: Method, object: NSObject) -> Any? {
        let encoding = normalizedReturnTypeEncoding(method)
        switch encoding {
        case let value where value.hasPrefix("@"):
            let getter = implementation(method, as: ObjectGetter.self)
            let result = getter(object, selector)
            return result?.takeUnretainedValue()
        case "#":
            return implementation(method, as: ClassGetter.self)(object, selector)
        case "B":
            return NSNumber(value: implementation(method, as: BoolGetter.self)(object, selector))
        case "c":
            return NSNumber(value: implementation(method, as: Int8Getter.self)(object, selector))
        case "C":
            return NSNumber(value: implementation(method, as: UInt8Getter.self)(object, selector))
        case "s":
            return NSNumber(value: implementation(method, as: Int16Getter.self)(object, selector))
        case "S":
            return NSNumber(value: implementation(method, as: UInt16Getter.self)(object, selector))
        case "i":
            return NSNumber(value: implementation(method, as: Int32Getter.self)(object, selector))
        case "I":
            return NSNumber(value: implementation(method, as: UInt32Getter.self)(object, selector))
        case "l":
            return NSNumber(value: implementation(method, as: LongGetter.self)(object, selector))
        case "L":
            return NSNumber(value: implementation(method, as: UnsignedLongGetter.self)(object, selector))
        case "q":
            return NSNumber(value: implementation(method, as: Int64Getter.self)(object, selector))
        case "Q":
            return NSNumber(value: implementation(method, as: UInt64Getter.self)(object, selector))
        case "f":
            return NSNumber(value: implementation(method, as: FloatGetter.self)(object, selector))
        case "d":
            return NSNumber(value: implementation(method, as: DoubleGetter.self)(object, selector))
        case let value where value.hasPrefix("{CGRect="):
            return NSValue(cgRect: implementation(method, as: CGRectGetter.self)(object, selector))
        case let value where value.hasPrefix("{CGPoint="):
            return NSValue(cgPoint: implementation(method, as: CGPointGetter.self)(object, selector))
        case let value where value.hasPrefix("{CGSize="):
            return NSValue(cgSize: implementation(method, as: CGSizeGetter.self)(object, selector))
        case let value where value.hasPrefix("{CGVector="):
            return NSValue(cgVector: implementation(method, as: CGVectorGetter.self)(object, selector))
        case let value where value.hasPrefix("{CGAffineTransform="):
            return NSValue(cgAffineTransform: implementation(method, as: CGAffineTransformGetter.self)(object, selector))
        case let value where value.hasPrefix("{UIEdgeInsets="):
            return NSValue(uiEdgeInsets: implementation(method, as: UIEdgeInsetsGetter.self)(object, selector))
        case let value where value.hasPrefix("{_NSRange=") || value.hasPrefix("{NSRange="):
            return NSValue(range: implementation(method, as: NSRangeGetter.self)(object, selector))
        default:
            return nil
        }
    }

    private static func normalizedReturnTypeEncoding(_ method: Method) -> String {
        let returnType = method_copyReturnType(method)
        defer { free(returnType) }
        let qualifiers = Set("rnNoORV")
        let encoding = String(cString: returnType)
        return String(encoding.drop { qualifiers.contains($0) })
    }

    private static func implementation<T>(_ method: Method, as type: T.Type) -> T {
        unsafeBitCast(method_getImplementation(method), to: type)
    }
}
