#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

// Define the plugin using the CAP_PLUGIN Macro, and
// each method the plugin supports using the CAP_PLUGIN_METHOD macro.
CAP_PLUGIN(PDFHelperPlugin, "PDFHelper",
           CAP_PLUGIN_METHOD(echo, CAPPluginReturnPromise);
            CAP_PLUGIN_METHOD(open, CAPPluginReturnPromise);
            CAP_PLUGIN_METHOD(close, CAPPluginReturnPromise);
            CAP_PLUGIN_METHOD(readPDFAnnotations, CAPPluginReturnPromise);
            CAP_PLUGIN_METHOD(getImageFromAnnotation, CAPPluginReturnPromise);
)
