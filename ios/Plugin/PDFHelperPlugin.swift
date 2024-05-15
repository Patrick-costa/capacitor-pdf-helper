import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(PDFHelperPlugin)
public class PDFHelperPlugin: CAPPlugin {
    private var _document: PDFDocument? = nil;
    private var pluginResult: CDVPluginResult? = nil;

    @objc func echo(_ call: CAPPluginCall) {
        let value = call.getString("value") ?? ""
    }

    @objc func open(_ call: CAPPluginCall) {
        
        if(_document != nil){
            _document = nil;
        }
        
        var fname = call.getString("url") ?? "";

        fname = fname.replacingOccurrences(of: "file://", with: "")
        
        let url: URL? = URL(fileURLWithPath: fname)
        
        do{
            _document = try PDFDocument(url: url!);
            let pdfId: String = _document!.pdfId;
            let pageCount: Int = _document!.numberOfPages;

            call.resolve([
                "pdfId": pdfId,
                "pageCount": pageCount
            ])
        } catch let error {
            call.reject(error.localizedDescription)
        }

    }

    @objc func close(_ call: CAPPluginCall) {

        if(_document != nil){
            _document = nil;
        }

    }

    @objc func readPDFAnnotations(_ call: CAPPluginCall) {

        if(_document?.isPagesLoaded == false) {
            _document?.loadPages();
        }

        // Workaround for documents with no annotations. Receive pdfId from JS code.
        let forcedPdfId: String = call.getString("forcedPdfId") ?? ""

        // Let's go
        let res:NSMutableArray = NSMutableArray();
        var docSavePendings: Bool = false;
        var annCnt = 0;
        
        do{
            try checkDocument();
            let pdfId = (_document!.pdfId != "") ? _document!.pdfId : forcedPdfId;

              for i in 0..<_document!.numberOfPages{
                let page = try _document!.getPage(pageIndex: i);
                for j in 0..<page.annotationCount{
                    let annot: PDFAnnotation = try page.getAnnotation(annotIdx: j);
                    
                    if((annot.annotationType.lowercased() == "link" || annot.annotationType.lowercased() == "freetext") && annot.fglink != nil) {
                        continue;
                    }

                    let fgId = UUID().uuidString;

                    if(annot.fgId == ""){
                        annot.fgId = fgId;
                        docSavePendings = true;
                    }

                    if(annot.docFgId == "" && pdfId != ""){
                        annot.docFgId = pdfId;
                        docSavePendings = true;
                    }

                    let contents = annot.contents;
                    let para:NSMutableDictionary = NSMutableDictionary();
                    let imageFound = annot.images.count > 0;

                    para.setValue(annot.fgId, forKey: "fgId");
                    para.setValue(annot.name, forKey: "name");
                    para.setValue(annot.annotationType, forKey: "type");
                    para.setValue(contents, forKey: "contents");
                    // Frontend counts pages beginning with 1
                    para.setValue(i + 1, forKey: "pageIndex");
                    para.setValue(j, forKey: "annotationIndex");
                    para.setValue(annot.creationDate, forKey: "creationDate");
                    para.setValue(annot.modifyDate, forKey: "modifyDate");
                    para.setValue(imageFound, forKey: "hasImage");

                    res.add(para);
                    annCnt += 1;

                }
              }

            if(docSavePendings){
                _document!.update();
                NSLog("PDF file updated");
            }

        call.resolve([
            "annotations": res,
        ])

       } catch let error {
           call.reject(error.localizedDescription)
        }
    }

    private func checkDocument() throws{
        if(_document == nil){
            throw PDFHelperError.DocumentNotOpened;
        }
    }

    
}
