import Foundation;

internal class PDFUtils {
    static func getSubitemFromDictionary(dict: PDFDictionary?, keysNames: [String]) -> AnyObject?{
        var res: AnyObject? = nil;
        
        let keyName:String = keysNames[0];
        
        for dictKey in dict!.allKeys(){
            let obj: AnyObject? = dict![dictKey];
            
            if (obj is PDFDictionary){
                res = getSubitemFromDictionary(dict: (obj as! PDFDictionary), keysNames: keysNames);
                if (res != nil){
                    return res;
                }
            }
            
            if (keyName == dictKey){
                res = obj;
                if (keysNames.count > 1){
                    res = getSubitemFromDictionary(dict: (obj as! PDFDictionary), keysNames: [keysNames[1]]);
                    if (res != nil){
                        return res;
                    }
                }
                return obj;
            }
        }
        
        return res;
    }
    
    //TODO Create PDFImage and PDFStream classes
    static func getImagesAsArray(xObjDict: PDFDictionary?) -> [PDFStream]{
        var res: [PDFStream] = [];
        
        for dictKey in xObjDict!.allKeys(){
            let obj: AnyObject? = xObjDict![dictKey];
            if (obj is PDFDictionary){
                if(((obj as! PDFDictionary)["Subtype"] as? String) == "Image"){
                    res.append(obj as! PDFStream);
                }
            }
        }
        
        return res;
    }
    
    static func getDocFgIdFromDictArray(_ annots: [PDFDictionary]) -> String? {
        for i in 0..<annots.count {
            if annots[i].allKeys().contains("docFgId") {
                let value = annots[i].stringForKey("docFgId");
                if (value != "") {
                    return value;
                }
            }
        }
        return nil;
    }

}
