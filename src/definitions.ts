export interface PDFHelperPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
