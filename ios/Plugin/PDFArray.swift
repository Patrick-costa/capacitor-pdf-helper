// Modified UXMPDF PDFArray.swift

import Foundation;
import UIKit;

public class PDFArray: PDFObject {
    fileprivate var arr: CGPDFArrayRef? = nil;
    public var array: [AnyObject] = [];
    
    public required init(arrayRef: CGPDFArrayRef?) {
        if(arrayRef != nil) {
            self.arr = arrayRef!;
            array = copyAsArray();
        }
    }
    
    public var type: CGPDFObjectType {
        return CGPDFObjectType.array;
    }
    
    var count: Int {
        return array.count;
    }
    
    func pdfMin<T : Comparable> (a: T, b: T) -> T {
        if a > b {
            return b;
        }
        return a;
    }
    
    var rect: CGRect? {
        if array.count != 4 {
            return nil;
        }
        
        for entry in array {
            guard let _ = entry as? CGFloat else {
                return nil;
            }
        }
        
        let x0 = array[0] as! CGFloat;
        let y0 = array[1] as! CGFloat;
        let x1 = array[2] as! CGFloat;
        let y1 = array[3] as! CGFloat;
        
        return CGRect(
            x: pdfMin(a: x0, b: x1),
            y: pdfMin(a: y0, b: y1),
            width: abs(x1-x0),
            height: abs(y1-y0))
    }
    
    func pdfObjectAtIndex(_ index: Int, _ recursive: inout Bool) -> AnyObject? {
        var object: CGPDFObjectRef? = nil;
        if CGPDFArrayGetObject(arr!, index, &object) {
            let type = CGPDFObjectGetType(object!);
            switch type {
            case CGPDFObjectType.boolean: return booleanAtIndex(index) as AnyObject?;
            case CGPDFObjectType.integer: return intAtIndex(index) as AnyObject?;
            case CGPDFObjectType.real: return realAtIndex(index) as AnyObject?;
            case CGPDFObjectType.name: return nameAtIndex(index) as AnyObject?;
            case CGPDFObjectType.string: return stringAtIndex(index) as AnyObject?;
            case CGPDFObjectType.array: return arrayAtIndex(index);
            case CGPDFObjectType.dictionary:
                recursive = true;
                return dictionaryAtIndex(index);
            case CGPDFObjectType.stream:
                recursive = true;
                return streamAtIndex(index);
            default:
                break;
            }
        }
        
        return nil;
    }
    
    func dictionaryAtIndex(_ index: Int) -> PDFDictionary? {
        var dictionary: CGPDFDictionaryRef? = nil;
        if CGPDFArrayGetDictionary(arr!, index, &dictionary) {
            return PDFDictionary(dictionaryRef: dictionary!, keyName: "[\(index)]");
        }
        return nil;
    }
    
    func arrayAtIndex(_ index: Int) -> PDFArray? {
        var array: CGPDFArrayRef? = nil;
        if CGPDFArrayGetArray(arr!, index, &array) {
            return PDFArray(arrayRef: array!);
        }
        return nil;
    }
    
    func stringAtIndex(_ index: Int) -> String? {
        var string: CGPDFStringRef? = nil;
        if CGPDFArrayGetString(arr!, index, &string) {
            if let ref: CFString = CGPDFStringCopyTextString(string!) {
                return ref as String;
            }
        }
        return nil;
    }
    
    func nameAtIndex(_ index: Int) -> String? {
        var name: UnsafePointer<Int8>? = nil;
        if CGPDFArrayGetName(arr!, index, &name) {
            if let dictionaryName = String(validatingUTF8: name!) {
                return dictionaryName;
            }
        }
        return nil;
    }
    
    func intAtIndex(_ index: Int) -> Int? {
        var intObj: CGPDFInteger = 0;
        if CGPDFArrayGetInteger(arr!, index, &intObj) {
            return Int(intObj);
        }
        return nil;
    }
    
    func realAtIndex(_ index: Int) -> CGFloat? {
        var realObj: CGPDFReal = 0.0;
        if CGPDFArrayGetNumber(arr!, index, &realObj) {
            return CGFloat(realObj);
        }
        return nil;
    }
    
    func booleanAtIndex(_ index: Int) -> Bool? {
        var boolObj: CGPDFBoolean = 0;
        if CGPDFArrayGetBoolean(arr!, index, &boolObj) {
            return Int(boolObj) != 0;
        }
        return nil;
    }
    
    func streamAtIndex(_ index: Int) -> PDFDictionary? {
        var stream: CGPDFStreamRef? = nil;
        if CGPDFArrayGetStream(arr!, index, &stream) {
            let dictionaryRef = CGPDFStreamGetDictionary(stream!);
            
            return PDFDictionary(dictionaryRef: dictionaryRef!, keyName: nil);
        }
        return nil;
    }
    
    func copyAsArray() -> [AnyObject] {
        var temp: [AnyObject] = [];
        let count = CGPDFArrayGetCount(arr!);
        
        for i in stride(from: 0, to: count, by: 1) {
            var r = false;
            guard let obj = pdfObjectAtIndex(i, &r) else { continue; }
            if (r == true) {
                NestedLevel.depth -= 1;
                if(NestedLevel.debug) {
                    let tab = String(repeating: " ", count: NestedLevel.depth);
                    print("\(tab)<- \(NestedLevel.depth) (A) <- Index: \(i)");
                }
            }
            temp.append(obj);
        }
        
        return temp;
    }
}

extension PDFArray: NSCopying {
    public func copy(with zone: NSZone?) -> Any {
        return Swift.type(of: self).init(arrayRef: arr);
    }
}

extension PDFArray: Sequence {
    public func makeIterator() -> AnyIterator<AnyObject> {
        var nextIndex = array.count - 1;
        
        return AnyIterator {
            if nextIndex < 0 {
                return nil;
            }
            let obj = self.array[nextIndex];
            nextIndex = nextIndex - 1;
            return obj;
        }
    }
}
