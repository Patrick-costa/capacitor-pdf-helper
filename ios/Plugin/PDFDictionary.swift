// Modified UXMPDFKit PDFDictionary.swift

import Foundation;
import UIKit;

public protocol PDFObject {
    var type: CGPDFObjectType { get }
}

public class NestedLevel {
    static var depth = 0;
    static var maxDepth = 0;
    static let debug = false;
    static var _onlyAnnots: Int8 = 0;
}

fileprivate class PDFObjectParserContext {
    var keys: [UnsafePointer<Int8>] = [];
    
    init(keys: [UnsafePointer<Int8>]) {
        self.keys = keys;
    }
}

public func == (lhs: PDFDictionary, rhs: PDFDictionary) -> Bool {
    let rect1 = lhs.arrayForKey("Rect")?.rect;
    let rect2 = rhs.arrayForKey("Rect")?.rect;
    
    let keys1 = lhs.allKeys();
    let keys2 = rhs.allKeys();
    
    let t1 = lhs["T"] as? String;
    let t2 = rhs["T"] as? String;
    
    return rect1 == rect2 && keys1 == keys2 && t1 == t2;
}

public class PDFDictionary: PDFObject, Equatable {
    var dict: CGPDFDictionaryRef;
    
    lazy var attributes: [String:AnyObject] = {
        
        var context = PDFObjectParserContext(keys: []);
        CGPDFDictionaryApplyFunction(self.dict, self.getDictionaryObjects, &context);
        
        self.keys = context.keys;
        
        var attributes: [String:AnyObject] = [:];
        for key in self.keys {
            var r: Bool = false;
            guard let stringKey = String(validatingUTF8: key) else { continue; }

            // Exclude Annots on lower levels to prevent loop
            if(stringKey == "Annots" && NestedLevel.depth > 1) {
                attributes[stringKey] = PDFArray(arrayRef: nil);
                continue;
            }

            // OnlyAnnots option == 1: Exclude all except Annots on Page level,
            // and exclude all on level > 2 (ugly, I know)
            if NestedLevel._onlyAnnots == 1 {
                if ((NestedLevel.depth < 2 && stringKey != "Annots" ) ||
                    NestedLevel.depth > 2) {
                    continue
                }
            }

            // OnlyAnnots option == 2: Exclude all except Annots on Page level
            if NestedLevel._onlyAnnots == 2 {
                if (NestedLevel.depth < 2 && stringKey != "Annots") { continue }
                if (stringKey == "A") { continue }
            }
            
            // Exclude these keys:
            let excludedKeys: [String] = [
                "FontFile2",
                "ExtGState",
                "Font",
                "Dest",
                "Properties"
            ];
            if (excludedKeys.contains(stringKey) ||
                stringKey.lowercased().starts(with: "oc") ||
                stringKey.lowercased().starts(with: "xop")) {
                attributes[stringKey] = nil;
                continue;
            }
            
            guard let obj = self.pdfObjectForKey(key, &r) else { continue; }
            if(r == true) {
                NestedLevel.depth -= 1
                if(NestedLevel.debug) {
                    let tab = String(repeating: " ", count: NestedLevel.depth);
                    print("\(tab)<- \(NestedLevel.depth) - (D) <- \(stringKey)");
                }
            }
            else {
                if(NestedLevel.debug) {
                    let tab = String(repeating: " ", count: NestedLevel.depth);
                    print("\(tab)-- \(NestedLevel.depth) - (D) -- \(stringKey)");
                }
            }
            self.stringKeys.append(stringKey);
            attributes[stringKey] = obj;
        }
        
        return attributes;
    }()
    
    var keys: [UnsafePointer<Int8>] = [];
    var stringKeys: [String] = [];
    
    var isParent: Bool = false;
    
    public var type: CGPDFObjectType {
        return CGPDFObjectType.dictionary;
    }
    
    init(dictionaryRef: CGPDFDictionaryRef, keyName: String?, onlyAnnots: Int8? = nil) {
        NestedLevel.depth += 1;
        if(NestedLevel.debug && NestedLevel.depth > NestedLevel.maxDepth) {
            NestedLevel.maxDepth = NestedLevel.depth;
        }

        if onlyAnnots != nil {
            NestedLevel._onlyAnnots = onlyAnnots!;
        }
        
        dict = dictionaryRef;
        if(NestedLevel.debug) {
            let tab = String(repeating: " ", count: NestedLevel.depth);
            if(keyName != nil) {
                print("\(tab)-> \(NestedLevel.depth) - (D) -> \(keyName!)");
            }
            else {
                print("\(tab)-> \(NestedLevel.depth) - (D)");
            }
        }
        
        _ = self.attributes;
    }

    subscript(key: String) -> AnyObject? {
        return attributes[key];
    }
    
    func arrayForKey(_ key: String) -> PDFArray? {
        return attributes[key] as? PDFArray;
    }
    
    func stringForKey(_ key: String) -> String? {
        return attributes[key] as? String;
    }
    
    func allKeys() -> [String] {
        return stringKeys;
    }
    
    fileprivate func booleanFromKey(_ key: UnsafePointer<Int8>) -> Bool? {
        var boolObj: CGPDFBoolean = 0;
        if CGPDFDictionaryGetBoolean(dict, key, &boolObj) {
            return Int(boolObj) != 0;
        }
        return nil;
    }
    
    fileprivate func integerFromKey(_ key: UnsafePointer<Int8>) -> Int? {
        var intObj: CGPDFInteger = 0;
        if CGPDFDictionaryGetInteger(dict, key, &intObj) {
            return Int(intObj);
        }
        return nil;
    }
    
    fileprivate func realFromKey(_ key: UnsafePointer<Int8>) -> CGFloat? {
        var floatObj: CGPDFReal = 0;
        if CGPDFDictionaryGetNumber(dict, key, &floatObj) {
            return CGFloat(floatObj);
        }
        return nil
    }
    
    fileprivate func nameFromKey(_ key: UnsafePointer<Int8>) -> String? {
        var nameObj: UnsafePointer<Int8>? = nil;
        if CGPDFDictionaryGetName(dict, key, &nameObj) {
            if let dictionaryName = String(validatingUTF8: nameObj!) {
                return dictionaryName;
            }
        }
        return nil;
    }
    
    fileprivate func stringFromKey(_ key: UnsafePointer<Int8>) -> String? {
        var stringObj: CGPDFStringRef? = nil;
        if CGPDFDictionaryGetString(dict, key, &stringObj) {
            if let ref: CFString = CGPDFStringCopyTextString(stringObj!) {
                return ref as String;
            }
        }
        return nil;
    }
    
    fileprivate func arrayFromKey(_ key: UnsafePointer<Int8>) -> PDFArray? {
        var arrayObj: CGPDFArrayRef? = nil;
        guard let stringKey = String(validatingUTF8: key) else {
            if(NestedLevel.debug) { print("Array Key is not available") }
            return nil;
        }
        
        if CGPDFDictionaryGetArray(dict, key, &arrayObj) {
            if(NestedLevel.debug) {
                let tab = String(repeating: " ", count: NestedLevel.depth);
                print("\(tab)-- \(NestedLevel.depth) - \(stringKey): Array");
            }
            return PDFArray(arrayRef: arrayObj!);
        }
        return nil;
    }
    
    fileprivate func dictionaryFromKey(_ key: UnsafePointer<Int8>) -> PDFDictionary? {
        guard let stringKey = String(validatingUTF8: key) else {
            return nil;
        }

        let skippedKeys = ["Parent", "P"];
        
        if skippedKeys.contains(stringKey) {
            return nil;
        }
        
        var dictObj: CGPDFArrayRef? = nil;
        if CGPDFDictionaryGetDictionary(dict, key, &dictObj) {
            if(NestedLevel.debug) {
                let tab = String(repeating: " ", count: NestedLevel.depth);
                print("\(tab)-- \(NestedLevel.depth) - \(stringKey): Dict");
            }
            return PDFDictionary(dictionaryRef: dictObj!, keyName: stringKey);
        }
        return nil;
    }
    
    fileprivate func streamFromKey(_ key: UnsafePointer<Int8>) -> PDFDictionary? {
        guard let stringKey = String(validatingUTF8: key) else {
            return nil;
        }
        
        let skippedKeys = ["Parent", "P"];
        
        if skippedKeys.contains(stringKey) {
            return nil;
        }

        var streamObj: CGPDFArrayRef? = nil;
        if CGPDFDictionaryGetStream(self.dict, key, &streamObj) {
            if(NestedLevel.debug) {
                let tab = String(repeating: " ", count: NestedLevel.depth);
                print("\(tab)-- \(NestedLevel.depth) - \(stringKey): Stream");
            }
            let dictObj = CGPDFStreamGetDictionary(streamObj!);
            let newDict: PDFStream = PDFStream(dictionaryRef: dictObj!, keyName: stringKey);

            var format:CGPDFDataFormat  = .raw;
            var streamData:CFData? = nil;
            
            streamData = CGPDFStreamCopyData (streamObj!, &format);
            
            newDict.stream = streamData as Data?;
            return newDict;
        }
        return nil;
    }
    
    func pdfObjectForKey(_ key: UnsafePointer<Int8>, _ recursive: inout Bool) -> AnyObject? {
        var object: CGPDFObjectRef? = nil;
        if (CGPDFDictionaryGetObject(dict, key, &object) && object != nil) {
            let type = CGPDFObjectGetType(object!);
            switch type {
                case CGPDFObjectType.boolean: return booleanFromKey(key) as AnyObject?;
                case CGPDFObjectType.integer: return integerFromKey(key) as AnyObject?;
                case CGPDFObjectType.real: return realFromKey(key) as AnyObject?;
                case CGPDFObjectType.name: return nameFromKey(key) as AnyObject?;
                case CGPDFObjectType.string: return stringFromKey(key) as AnyObject?;
                case CGPDFObjectType.array: return arrayFromKey(key);
                case CGPDFObjectType.dictionary:
                    recursive = true;
                    return dictionaryFromKey(key);
                case CGPDFObjectType.stream:
                    recursive = true;
                    return streamFromKey(key);
                default:
                    break;
            }
        }
        
        return nil;
    }
    
    var getDictionaryObjects: CGPDFDictionaryApplierFunction = { (key, object, info) in
        let context = info!.assumingMemoryBound(to: PDFObjectParserContext.self).pointee;
        context.keys.append(key);
    }
    
    func description(_ level: Int = 0) -> String {
        var spacer = "";
        for _ in 0..<(level*2) { spacer += " "; }
        
        var string = "\n\(spacer){\n";
        for (key, value) in attributes {
            if let value = value as? PDFDictionary {
                string += "\(spacer)\(key) : \(value.description(level+1))";
            } else {
                string += "\(spacer)\(key) : \(value)\n";
            }
        }
        string += "\(spacer)}\n";
        return string;
    }
    
    var description: String {
        return description(0);
    }
}
