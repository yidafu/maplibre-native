import { Context } from '@kit.AbilityKit';

/**
 * FileSource - 文件源类
 */
export class FileSource {
  private static instance: FileSource | null = null;
  private context: Context | null = null;

  private constructor(context: Context) {
    this.context = context;
  }

  /**
   * 获取FileSource实例（单例模式）
   */
  public static getInstance(context: Context): FileSource {
    if (!FileSource.instance) {
      FileSource.instance = new FileSource(context);
    }
    return FileSource.instance;
  }

  /**
   * 获取上下文
   */
  public getContext(): Context | null {
    return this.context;
  }

  /**
   * 设置上下文
   */
  public setContext(context: Context): void {
    this.context = context;
  }
}
