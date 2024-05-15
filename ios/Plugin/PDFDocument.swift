import Foundation;
import PDFKit;

@available(iOS 11.0, *)
public class PDFDocument  {
    private let _document: CGPDFDocument!;
    public var documentURL: URL;
    public var autoGenerateFgId: Bool = true;
    private var _pdfkitDocInstance: PDFKit.PDFDocument;
    private var pages: [PDFPage] = [];
    public var pdfId: String = "";
    public var isPagesLoaded = false;
    
    public var numberOfPages: Int {
        get{
            return _document.numberOfPages;
        }
    }
    
    public var catalog: CGPDFDictionaryRef?{
        get{
            return _document.catalog;
        }
    }
    
    init(url: URL) throws {
        documentURL = url;
        
        do{
            let pdfDoc = PDFKit.PDFDocument(url: self.documentURL);
            if pdfDoc != nil {
                self._pdfkitDocInstance = pdfDoc!;
            }
            else {
                throw PDFHelperError.DocumentNotOpened;
            }
            
            _document = self._pdfkitDocInstance.documentRef;
            if(_document == nil){
                throw PDFHelperError.CGPDFInstanceNotAvailable;
            }
            let docInfo = PDFDictionary(dictionaryRef: _document!.info!, keyName: "Document");
            NestedLevel.depth -= 1;
            let pdfid = docInfo.stringForKey("fgId");
            if(pdfid != nil){
                pdfId = pdfid!;
            }
            else {
                let annots = loadOnlyAnnots();
                let docFgId = PDFUtils.getDocFgIdFromDictArray(annots);
                if docFgId != nil {
                    self.pdfId = docFgId!;
                }
            }
        } catch let error{
            throw error
        }
       
    }
    
    private func loadOnlyAnnots() -> [PDFDictionary] {
        var annotations: [PDFDictionary] = [];
        for i in 1..._document!.numberOfPages{
            let docPage = _document.page(at:i)!;
            let dict = PDFDictionary(dictionaryRef: docPage.dictionary!, keyName: "Page#\(i)", onlyAnnots: 1);
            
            NestedLevel.depth -= 1;
            NestedLevel._onlyAnnots = 0;
            
            if(dict.allKeys().contains("Annots")){
                if let annots = dict["Annots"] as? PDFArray {
                    for j in 0..<annots.count{
                        if let annDict = annots.array[j] as? PDFDictionary {
                            annotations.append(annDict);
                        }
                    }
                }
            }
        }
        return annotations;
    }
    
    public func loadPages() {
        self.pages.removeAll();
        for i in 1..._document!.numberOfPages{
            if(NestedLevel.debug) {
                NSLog("Page %i", i);
            }
            let page: PDFPage = PDFPage(page: _document.page(at: i)!, document: self, pageIndex: i);
            self.pages.append(page);
        }
        self.isPagesLoaded = true;
    }
    
    public func update(){
        _pdfkitDocInstance.write(to: self.documentURL);
    }
    
    public func getPDFKitDocumentInstance()->Any{
        return self._pdfkitDocInstance;
    }
    
    public func getPage(pageIndex: Int) throws -> PDFPage{
        if(pageIndex < 0 || pageIndex > numberOfPages){
            throw PDFHelperError.PageIndexNotFound;
        }
        return pages[pageIndex];
    }
}
