import Foundation;
import PDFKit;

@available(iOS 11.0, *)
public class PDFPage{
    private var _page: CGPDFPage;
    private var _dict: PDFDictionary? = nil;
    private var _document: PDFDocument;
    public var pageIndex: Int = 0;
    private var annotations: [PDFAnnotation] = [];
    
    init(page: CGPDFPage, document: PDFDocument, pageIndex: Int){
        _page = page;
        _document = document;
        self.pageIndex = pageIndex;
        _dict = PDFDictionary(dictionaryRef: self._page.dictionary!, keyName: "Page#\(pageIndex)", onlyAnnots: 2);
        NestedLevel.depth -= 1;
        NestedLevel._onlyAnnots = 0;
        
        if(_dict!.allKeys().contains("Annots")){
            if let annots = _dict!["Annots"] as? PDFArray {
                for i in 0..<annots.count{
                    if let annDict = annots.array[i] as? PDFDictionary {
                        let annot: PDFAnnotation = PDFAnnotation(dict: annDict, document: _document, parentPage: self, index: i);
                        annotations.append(annot);
                    }
                }
            }
        }
    }
    
    public var dictionary: PDFDictionary?{
        get{
            return _dict!;
        }
    }
    
    public var document: PDFDocument{
        get{
            return _document;
        }
    }
    
    var resources: PDFDictionary?{
        get{
            return (dictionary?["Resources"] as! PDFDictionary);
        }
    }
    
    var images: PDFDictionary?{
        get{
            return (PDFUtils.getSubitemFromDictionary(dict: resources, keysNames: ["XObject"]) as! PDFDictionary?);
        }
    }
    
    var annotationCount: Int {
        return annotations.count;
    }
    
    public func getAnnotation(annotIdx: Int) throws -> PDFAnnotation{
        if(annotIdx < 0 || annotIdx > annotations.count){
            throw PDFHelperError.AnnotationIndexNotFound;
        }
        return annotations[annotIdx];
    }
}
