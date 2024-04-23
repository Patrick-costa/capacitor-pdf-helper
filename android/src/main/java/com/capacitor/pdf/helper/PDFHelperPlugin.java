package com.capacitor.pdf.helper;

import android.graphics.Bitmap;
import android.net.Uri;
import android.util.Log;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.getcapacitor.plugin.WebView;
import com.tom_roush.pdfbox.cos.COSDictionary;
import com.tom_roush.pdfbox.cos.COSName;
import com.tom_roush.pdfbox.cos.COSString;
import com.tom_roush.pdfbox.pdmodel.PDDocument;
import com.tom_roush.pdfbox.pdmodel.PDPage;
import com.tom_roush.pdfbox.pdmodel.PDResources;
import com.tom_roush.pdfbox.pdmodel.graphics.PDXObject;
import com.tom_roush.pdfbox.pdmodel.graphics.image.PDImageXObject;
import com.tom_roush.pdfbox.pdmodel.interactive.annotation.PDAnnotation;
import com.tom_roush.pdfbox.pdmodel.interactive.annotation.PDAppearanceDictionary;
import com.tom_roush.pdfbox.pdmodel.interactive.annotation.PDAppearanceStream;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.util.Iterator;
import java.util.List;
import java.util.UUID;

@CapacitorPlugin(name = "PDFHelper")
public class PDFHelperPlugin extends Plugin {

    private static final String TAG = "PDFHelper";
    private PDDocument _document = null;
    private String url = "";

    @PluginMethod
    public void open(PluginCall call) throws Exception {
        url = call.getString("url", "");
        String pdfId = null;

        if (url != null && url.contains("_capacitor_")) {
            url = url.replace("_capacitor_", "");
        }

        if (url != null && url.contains("file://")) {
            url = url.replace("file://", "");
        }

        try {
            pdfId = openPDFDocument(url);
        } catch (Exception e) {
            Log.d("errorOpenFunction", e.getMessage() != null ? e.getMessage() : "");
            throw new RuntimeException(e);
        }
        pdfId = pdfId == null ? "" : pdfId;
        if (_document != null) {
            JSObject ret = new JSObject();
            ret.put("pageCount", _document.getNumberOfPages());
            ret.put("pdfId", pdfId);
            call.resolve(ret);
        }
    }

    @PluginMethod
    public void readPDFAnnotations(PluginCall call) throws Exception {
        JSONArray resArray = new JSONArray();
        JSObject ret = new JSObject();
        JSONArray annots = getAllAnnotations();
        for (int i = 0; i < annots.length(); i++) {
            JSONObject annot = annots.getJSONObject(i);
            resArray.put(annot);
        }
        ret.put("annotations", resArray);
        call.resolve(ret);
    }

    @PluginMethod
    public void getImageListFromResources(PluginCall call) throws Exception {
        JSONArray resArray = getImageListFromResources();
        JSObject ret = new JSObject();
        ret.put("images", resArray);
        call.resolve(ret);
    }

    @PluginMethod
    public void getImageFromAnnotation(PluginCall call) throws Exception {
        int pageIdx = Integer.parseInt(call.getString("pidx"));
        int annotIdx =  Integer.parseInt(call.getString("aidx"));

        JSObject ret = getImageFromAnnotation(pageIdx, annotIdx);
        call.resolve(ret);
    }

    @PluginMethod
    public void close (PluginCall call) throws Exception {
        if(_document != null){
            _document.close();
            _document = null;
        }

        call.resolve(null);
    }

    private String openPDFDocument(String url) throws Exception {

        Uri uri = Uri.parse(url);
        File file = new File(uri.getPath());
        FileInputStream fileInputStream = new FileInputStream(file);
        _document = PDDocument.load(fileInputStream);
        if(_document != null){
            return _document.getDocumentInformation().getCustomMetadataValue("fgId");
        }
        return null;
    }

    private JSONArray getAllAnnotations() throws Exception {
        List<PDAnnotation> annots;
        JSONArray res = new JSONArray();

        if(_document == null)
            throw new Exception("Document " + url + " is not opened");

        int pagecnt = _document.getNumberOfPages();
        boolean docSavePending = false;

        for (int p = 0; p < pagecnt; p++) {
            PDPage page = _document.getPage(p);
            annots = page.getAnnotations();

            int ai = 0;
            for (Iterator<PDAnnotation> i = annots.iterator(); i.hasNext(); ) {
                PDAnnotation annotation = i.next();

                String type = annotation.getSubtype();
                if (type.toLowerCase().equals("link") || type.toLowerCase().equals("freetext")) {
                    if (annotation.getCOSObject().containsKey("fglink")) {
                        ai++;
                        continue;
                    }
                }

                COSString fgId = (COSString) annotation.getCOSObject().getItem("fgId");

                if (fgId == null) {
                    fgId = new COSString(UUID.randomUUID().toString());
                    annotation.getCOSObject().setItem("fgId", fgId);
                    docSavePending = true;
                }

                JSObject json = new JSObject();

                json.put("fgId", fgId.getString());
                json.put("name", annotation.getAnnotationName());
                json.put("type", type);

                String contents = annotation.getContents();
                json.put("contents", (contents == null) ? "" : contents);

                json.put("pageIndex", p+1);
                json.put("annotationIndex", ai);

                String modDate = annotation.getModifiedDate();
                COSString cosCDate = ((COSString) annotation.getCOSObject().getItem("CreationDate"));
                String cDate = (cosCDate == null) ? modDate : cosCDate.getString();
                json.put("creationDate", cDate);

                if (modDate != null) {
                    modDate = cDate;
                }

                json.put("modifyDate", modDate);

                json.put("hasImage", false);
                //--check images existance
                //--check Appeareance and it's stream
                PDAppearanceDictionary ap = annotation.getAppearance();
                if(ap !=null) {
                    PDAppearanceStream apStream = annotation.getNormalAppearanceStream();
                    PDResources apres = (apStream != null) ? annotation.getNormalAppearanceStream().getResources() : null;
                    if (apres != null ) {
                        for (COSName xObjName: apres.getXObjectNames()) {
                            PDXObject xImg = apres.getXObject(xObjName);
                            if (xImg instanceof PDImageXObject) {
                                json.put("hasImage", true);
                                break;
                            }
                        }
                    }
                }
                res.put(json);

                ai++;
            }
        }
        if(docSavePending) {
            _document.save(url);
        }

        return res;
    }

    private  JSONArray getImageListFromResources() throws Exception {
        JSONArray res = new JSONArray();

        if(_document == null)
            throw new Exception("Document " + url + " is not opened");

        int pagecnt = _document.getNumberOfPages();
        for (int p = 0; p < pagecnt; p++) {
            PDPage page = _document.getPage(p);
            PDResources resources = page.getResources();

            for (COSName xObjName: resources.getXObjectNames() ) {
                PDXObject xImg = resources.getXObject(xObjName);
                if(xImg != null && xImg instanceof  PDImageXObject){
                    JSONObject json = new JSONObject();
                    json.put("pageIndex", p+1);
                    json.put("keyName", xObjName.getName());
                    JSONObject metadata = new JSONObject();
                    for(COSName keyName : ((COSDictionary)xImg.getCOSObject()).keySet()){
                        String value = ((COSDictionary)xImg.getCOSObject()).getItem(keyName).toString();
                        metadata.put(keyName.getName(), value);
                    }
                    json.put("metadata", metadata);
                    res.put(json);
                }
            }
        }

        return res;
    }

    private JSObject getImageFromAnnotation(int pageIdx, int annotIdx) throws Exception {
        WebView webView = new WebView();

        if(_document == null)
            throw new Exception("Document " + url + " is not opened");

        PDAnnotation annot = _document.getPage(pageIdx-1).getAnnotations().get(annotIdx);

        PDAppearanceDictionary ap = annot.getAppearance();
        PDResources resources = null;
        if(ap !=null) {
            PDAppearanceStream apStream = annot.getNormalAppearanceStream();
            resources = (apStream != null) ? annot.getNormalAppearanceStream().getResources() : null;
        }
        if(resources != null){
            for (COSName xObjName: resources.getXObjectNames()) {
                PDXObject xImg = resources.getXObject(xObjName);

                if(xImg instanceof PDImageXObject){
                    File outputDir = webView.getActivity().getBaseContext().getCacheDir(); // context being the Activity pointer
                    String tmpFileName = UUID.randomUUID().toString();
                    File outputFile = File.createTempFile(tmpFileName, ".jpg", outputDir);
                    OutputStream outs = new FileOutputStream(outputFile);

                    Bitmap img = ((PDImageXObject)xImg).getImage();
                    img.compress(Bitmap.CompressFormat.JPEG, 90, outs);

                    // URI
                    JSObject json = new JSObject();
                    String oUrl = outputFile.toURI().toString().replaceFirst("file:/", "file:///");
                    json.put("imageUri", oUrl);

                    // Mime-type
                    Uri imgUri = Uri.fromFile(outputFile);
                    json.put("mimeType", "DEPOIS VEJO");

                    return json;
                }
            }
        }

        return new JSObject();
    }



}
