import { registerPlugin } from '@capacitor/core';

import type { PDFHelperPlugin } from './definitions';

const PDFHelper = registerPlugin<PDFHelperPlugin>('PDFHelper', {
  web: () => import('./web').then(m => new m.PDFHelperWeb()),
});

export * from './definitions';
export { PDFHelper };
