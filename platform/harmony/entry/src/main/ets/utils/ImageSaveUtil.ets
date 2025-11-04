/**
 * 图片保存工具类
 * 使用 PhotoViewPicker 保存截图到相册，无需权限声明
 */

import { BusinessError } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import { image } from '@kit.ImageKit';
import picker from '@ohos.file.picker';

export class ImageSaveUtil {
  private static readonly TAG: string = 'ImageSaveUtil';

  /**
   * 使用 PhotoViewPicker 保存 PixelMap 到相册
   * 此方法会拉起系统相册选择器，让用户选择保存位置
   * 无需在 module.json5 中声明权限
   * 
   * @param pixelMap 要保存的图片
   * @param fileName 文件名（不含扩展名）
   * @returns 保存结果
   */
  static async savePixelMapToGalleryWithPicker(
    pixelMap: image.PixelMap,
    fileName?: string
  ): Promise<SaveImageResult> {
    try {
      // 1. 生成文件名
      const timestamp = new Date().getTime();
      const finalFileName = fileName ? `${fileName}.jpg` : `maplibre_snapshot_${timestamp}.jpg`;

      // 2. 创建 PhotoViewPicker 实例
      const photoPicker = new picker.PhotoViewPicker();

      // 3. 配置保存选项
      const photoSaveOptions: picker.PhotoSaveOptions = {
        newFileNames: [finalFileName]
      };

      // 4. 拉起系统相册保存界面，用户选择保存位置
      const photoSaveResult: Array<string> = await photoPicker.save(photoSaveOptions);

      if (!photoSaveResult || photoSaveResult.length === 0) {
        return {
          success: false,
          message: '用户取消保存或保存失败'
        };
      }

      const uri = photoSaveResult[0];
      console.info(`${ImageSaveUtil.TAG} User selected save location: ${uri}`);

      // 5. 将 PixelMap 打包为 JPEG
      const imagePackerApi = image.createImagePacker();
      const packOptions: image.PackingOption = {
        format: 'image/jpeg',
        quality: 95
      };
      const imageData = await imagePackerApi.packing(pixelMap, packOptions);

      // 6. 打开文件并写入数据
      const file = await fs.open(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      await fs.write(file.fd, imageData);
      await fs.close(file.fd);

      console.info(`${ImageSaveUtil.TAG} Image saved to gallery successfully: ${uri}`);

      return {
        success: true,
        message: '保存成功',
        uri: uri
      };
    } catch (err) {
      const error = err as BusinessError;
      console.error(`${ImageSaveUtil.TAG} Failed to save image to gallery: ${JSON.stringify(error)}`);
      
      // 用户取消操作的错误码
      if (error.code === 13900042) {
        return {
          success: false,
          message: '用户取消保存',
          error: error
        };
      }
      
      return {
        success: false,
        message: `保存失败: ${error.message || '未知错误'}`,
        error: error
      };
    }
  }
}

/**
 * 图片保存结果
 */
export interface SaveImageResult {
  // 是否保存成功
  success: boolean;

  // 提示消息
  message: string;

  // 保存的图片 URI（如果成功）
  uri?: string;

  // 错误信息（如果失败）
  error?: BusinessError;
}

