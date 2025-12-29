import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { promptAction } from '@kit.ArkUI';
import { BusinessError } from '@ohos.base';
import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 上传响应接口
export interface UploadResponse {
  data: string;
  message: string;
  statusCode: number;
}

// 上传配置接口
export interface UploadConfig {
  uploadToken: string;               // 上传令牌
  serverUrl?: string;                // 服务器地址
  autoDeleteAfterUpload?: boolean;   // 上传后是否自动删除
}

// 上传进度回调
export type UploadProgressCallback = (progress: number, total: number, currentFile: string) => void;

/**
 * 图片上传工具类
 * 简化接口，专注于图片上传功能
 */
export class ImageUploader {
  private context: common.UIAbilityContext;
  private config: UploadConfig;

  // 默认配置
  private static DEFAULT_CONFIG: UploadConfig = {
    uploadToken: '',  // 这个必须有，但会被传入的config覆盖
    serverUrl: 'http://att.miclink.net/api/upload',
    autoDeleteAfterUpload: false
  };

  /**
   * 构造函数
   * @param context 应用上下文
   * @param config 上传配置
   */
  constructor(context: common.UIAbilityContext, config: UploadConfig) {
    this.context = context;
    // 创建一个有明确类型的新对象
    const mergedConfig: UploadConfig = {
      uploadToken: config.uploadToken,
      serverUrl: config.serverUrl !== undefined ? config.serverUrl : ImageUploader.DEFAULT_CONFIG.serverUrl,
      autoDeleteAfterUpload: config.autoDeleteAfterUpload !== undefined ? config.autoDeleteAfterUpload : ImageUploader.DEFAULT_CONFIG.autoDeleteAfterUpload
    };
    this.config = mergedConfig;
  }

  /**
   * 更新上传配置
   */
  updateConfig(config: Partial<UploadConfig>): void {
    // 创建一个有明确类型的新对象
    const newConfig: UploadConfig = {
      uploadToken: config.uploadToken !== undefined ? config.uploadToken : this.config.uploadToken,
      serverUrl: config.serverUrl !== undefined ? config.serverUrl : this.config.serverUrl,
      autoDeleteAfterUpload: config.autoDeleteAfterUpload !== undefined ? config.autoDeleteAfterUpload : this.config.autoDeleteAfterUpload
    };
    this.config = newConfig;
  }

  /**
   * 检查文件是否存在
   */
  private checkFileExists(filePath: string): boolean {
    try {
      return fs.accessSync(filePath);
    } catch (error) {
      return false;
    }
  }

  /**
   * 获取文件Content-Type
   */
  private getContentType(filePath: string): string {
    const ext = filePath.split('.').pop()?.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/*';
    }
  }

  /**
   * 从文件路径提取文件名
   */
  private getFileName(filePath: string, customName?: string): string {
    if (customName) return customName;
    return filePath.split('/').pop() || `image_${Date.now()}`;
  }

  /**
   * 删除本地文件
   */
  private deleteLocalFile(filePath: string): boolean {
    try {
      if (fs.accessSync(filePath)) {
        fs.unlinkSync(filePath);
        console.info(`已删除本地文件: ${filePath}`);
        return true;
      }
      return false;
    } catch (error) {
      const err = error as BusinessError;
      console.warn('删除本地文件失败:', err.message);
      return false;
    }
  }

  /**
   * 上传单个图片文件
   * @param filePath 沙箱文件路径
   * @param customName 自定义文件名（可选）
   * @returns 上传响应结果
   */
  async uploadImage(filePath: string, customName?: string): Promise<UploadResponse | null> {
    // 检查文件是否存在
    if (!this.checkFileExists(filePath)) {
      console.error(`图片文件不存在: ${filePath}`);
      // promptAction.showToast({
      //   message: '图片文件不存在',
      //   duration: 2000
      // });
      return null;
    }

    const fileName = this.getFileName(filePath, customName);
    const contentType = this.getContentType(filePath);

    const httpRequest = http.createHttp();
    const requestUrl = `${this.config.serverUrl}?key=${encodeURIComponent(this.config.uploadToken!)}&name=${encodeURIComponent(fileName)}`;

    const requestOptions: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'multipart/form-data'
      },
      multiFormDataList: [
        {
          name: "file",
          contentType: contentType,
          filePath: filePath,
          remoteFileName: fileName
        }
      ],
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: 30000,
      readTimeout: 60000
    };

    return new Promise((resolve, reject) => {
      httpRequest.request(
        requestUrl,
        requestOptions,
        (err: BusinessError, data: http.HttpResponse) => {
          httpRequest.destroy();

          if (err) {
            console.error('上传图片失败:', err);
            reject(err);
            return;
          }

          try {
            let responseData: UploadResponse;
            if (typeof data.result === 'string') {
              responseData = JSON.parse(data.result);
            } else {
              responseData = data.result as UploadResponse;
            }

            if (data.responseCode === 200) {
              console.info(`图片上传成功: ${fileName}`, responseData);
              console.error(JSON.stringify(responseData.data))
             let data= AppStorage.get('dstPath_imgs')as string[]
              if (responseData.statusCode==200){
                data.push(responseData.data)
              }
              // 上传成功后删除本地文件（如果配置了）
              if (this.config.autoDeleteAfterUpload) {
                this.deleteLocalFile(filePath);
              }

              resolve(responseData);
            } else {
              console.error(`图片上传失败: ${fileName}`, responseData);
              reject(new Error(responseData.message || '上传失败'));
            }
          } catch (parseError) {
            console.error('解析响应失败:', parseError);
            reject(new Error('解析服务器响应失败'));
          }
        }
      );
    });
  }

  /**
   * 批量上传图片
   * @param filePaths 沙箱文件路径数组
   * @param onProgress 进度回调（可选）
   * @returns 上传结果数组
   */
  async uploadImages(
    filePaths: string[],
    onProgress?: UploadProgressCallback
  ): Promise<(UploadResponse | null)[]> {
    const results: (UploadResponse | null)[] = [];

    for (let i = 0; i < filePaths.length; i++) {
      const filePath = filePaths[i];

      try {
        // 调用进度回调
        if (onProgress) {
          onProgress(i + 1, filePaths.length, filePath);
        }

        const result = await this.uploadImage(filePath);
        results.push(result);
      } catch (error) {
        console.error(`上传图片失败: ${filePath}`, error);
        results.push(null);
      }
    }

    // 显示上传结果总结
    const successCount = results.filter(r => r !== null).length;
    const failCount = results.length - successCount;

    if (failCount === 0) {
      hilog.info(0,'tag',`已成功上传 ${successCount} 张图片`,)
      // promptAction.showToast({
      //   message: `已成功上传 ${successCount} 张图片`,
      //   duration: 2000
      // });
    } else {
      // promptAction.showToast({
      //   message: `上传完成：成功 ${successCount} 张，失败 ${failCount} 张`,
      //   duration: 3000
      // });
      hilog.info(0,'tag',`上传完成：成功 ${successCount} 张，失败 ${failCount} 张`,)

    }

    return results;
  }
}