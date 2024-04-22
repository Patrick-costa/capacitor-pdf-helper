import { WebPlugin } from '@capacitor/core';

import type { PDFHelperPlugin } from './definitions';

export class PDFHelperWeb extends WebPlugin implements PDFHelperPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
