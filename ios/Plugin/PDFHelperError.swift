import Foundation

enum PDFHelperError: Error{
    case FileNotFound;
    case CGPDFInstanceNotAvailable;
    case PageIndexNotFound
    case AnnotationIndexNotFound;
    case FileSaveException;
    case DocumentNotOpened;
}
