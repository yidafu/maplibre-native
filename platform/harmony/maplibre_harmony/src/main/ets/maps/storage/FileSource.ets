/**
 * FileSource - 文件源类
 */
export class FileSource {
  private static instance: FileSource | null = null;
  private context: any;

  private constructor(context: any) {
    this.context = context;
  }

  /**
   * 获取FileSource实例（单例模式）
   */
  public static getInstance(context: any): FileSource {
    if (!FileSource.instance) {
      FileSource.instance = new FileSource(context);
    }
    return FileSource.instance;
  }

  /**
   * 获取上下文
   */
  public getContext(): any {
    return this.context;
  }

  /**
   * 设置上下文
   */
  public setContext(context: any): void {
    this.context = context;
  }
}
