export interface PDFHelperPlugin {
    open(options: IOpenOptions): Promise<IPHDocumentInfo>;
  
    close(): Promise<any>;
  
    readPDFAnnotations(forcePdfId: string): Promise<IPHAnnotation[]>;
  
    getImageListFromResources(): Promise<IPHResourceImage[]>;
  
    getImageFromAnnotation(pidx: number, aidx: number): Promise<IPHImageMetadata>;
  
    getImageFromResources(pidx: number, keyname: string): Promise<IPHImageMetadata>;
  }
  
  export interface IPHResourceImage {
    pageIndex: number;
    keyName: string;
    metadata: any;
  }
  
  export interface IPHAnnotation {
    // TODO add to plugin!
    docFgId?: string;
    fgId: string;
    name: string;
    type: string;
    contents: string;
    pageIndex: number;
    annotationIndex: number;
    creationDate: string;
    modifyDate: string;
    hasImage: boolean;
    updated?: number;
  }
  
  export interface IPHImageMetadata {
    imageUri: string;
    mimeType: string;
  }
  
  export interface IPHDocumentInfo {
    pdfId: string;
    pageCount: number;
  }
  
  export interface IOpenOptions{
    url: string;
  }