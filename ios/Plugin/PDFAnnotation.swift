import Foundation;
import PDFKit;

@available(iOS 11.0, *)
public class PDFAnnotation {
    public var name: String = "";
    public var contents: String = "";
    public var annotationType: String = "";
    public var creationDate: String = "";
    public var modifyDate: String = "";
    public var appearance: PDFDictionary? = nil;
    private var _fgId: String = "";
    private var _docFgId: String = "";
    public var images: [PDFStream] = [];
    private var _document: PDFDocument;
    private var _parent: PDFPage;
    private var _index: Int = 0;
    private var _dict: PDFDictionary;
    private var _fglink: String?;
    
    init(dict: PDFDictionary, document: PDFDocument, parentPage: PDFPage, index: Int){
        _document = document;
        _parent = parentPage;
        _index = index;
        _dict = dict;
        self.name = (_dict["NM"] as? String) != nil ? (_dict["NM"] as! String) : "";
        self.contents = (_dict["Contents"] as? String) != nil ? (_dict["Contents"] as! String) : "";
        self.creationDate = (_dict["CreationDate"] as? String) != nil ? (_dict["CreationDate"] as! String) : "";
        self.modifyDate = (_dict["M"] as? String) != nil ? (_dict["M"] as! String) : "";
        if(self.creationDate == "") { self.creationDate = self.modifyDate; }
        if(self.modifyDate == "") { self.modifyDate = self.creationDate; }
        self.annotationType = (_dict["Subtype"] as? String) != nil ? (_dict["Subtype"] as! String) : "UnknownType";
        self._fgId = (_dict["fgId"] as? String) != nil ? (_dict["fgId"] as! String) : "";
        self._docFgId = (_dict["docFgId"] as? String) != nil ? (_dict["docFgId"] as! String) : "";
        self._fglink = (_dict["fglink"] as? String) != nil ? (_dict["fglink"] as! String) : nil;
        let ap = (_dict["AP"] as? PDFDictionary);
        if(ap != nil){
            self.appearance = PDFUtils.getSubitemFromDictionary(dict: (_dict["AP"] as? PDFDictionary), keysNames: ["N"]) as? PDFDictionary;
            if self.appearance != nil {
                let xObjDict = PDFUtils.getSubitemFromDictionary(dict: self.appearance, keysNames: ["XObject"]) as? PDFDictionary;
                if(xObjDict != nil) { self.images = PDFUtils.getImagesAsArray(xObjDict: xObjDict); }
            }
        }
    }
    
    public var document: PDFDocument{
        get{
            return _document;
        }
    }
    
    public var parent: PDFPage{
        get{
            return _parent;
        }
    }
    
    public var fgId: String{
        get{
            return self._fgId;
        }
        set{
            self._fgId = newValue;
            self.setCustomValue(key:"fgId", value: newValue);
        }
    }

    public var docFgId: String{
        get{
            return self._docFgId;
        }
        set{
            self._docFgId = newValue;
            self.setCustomValue(key:"docFgId", value: newValue);
        }
    }

    public var fglink: String? {
        get{
            return self._fglink;
        }
    }
    
    private func setCustomValue(key: String, value: Any){
        let doc:PDFKit.PDFDocument? = _document.getPDFKitDocumentInstance() as? PDFKit.PDFDocument;
        let page:PDFKit.PDFPage? = doc?.page(at: _parent.pageIndex - 1);
        let nkey:PDFAnnotationKey = PDFAnnotationKey(rawValue: key);
        page?.annotations[self._index].setValue(value, forAnnotationKey: nkey);
    }
}
