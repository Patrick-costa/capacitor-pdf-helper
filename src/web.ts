import { WebPlugin } from '@capacitor/core';

import type { IOpenOptions, IPHAnnotation, IPHDocumentInfo, IPHImageMetadata, IPHResourceImage, PDFHelperPlugin } from './definitions';

export class PDFHelperWeb extends WebPlugin implements PDFHelperPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }

  open(options: IOpenOptions): Promise<IPHDocumentInfo> {
    let ret: any = options;
    return ret;
  }

  close(): Promise<any> {
    let ret: any;
    return ret;
  }

  readPDFAnnotations(options: IOpenOptions): Promise<IPHAnnotation[]> {
    let ret: any = options;
    return ret;
  }

  getImageFromAnnotation(pidx: number, aidx: number): Promise<IPHImageMetadata> {
    let ret: any = pidx + aidx;
    return ret;
  }

  getImageFromResources(pidx: number, keyname: string): Promise<IPHImageMetadata> {
    let ret: any = {
      pidx: pidx,
      keyname: keyname
    }
    return ret;
  }

  getImageListFromResources(): Promise<IPHResourceImage[]> {
    let ret: any;
    return ret;
  }
}
