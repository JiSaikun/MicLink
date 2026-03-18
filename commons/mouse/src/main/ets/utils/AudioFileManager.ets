import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { promptAction } from '@kit.ArkUI';
import { BusinessError } from '@ohos.base';
import { http } from '@kit.NetworkKit';
import { SmartMouseAudioProcessor } from './SmartMouseAudioProcessor';
import { webview } from '@kit.ArkWeb';
import { WebSocket_serverUrl } from 'config';
import { Communication } from '../components/Communication';
import { inputMessageModel } from './AudioWebSocketHandler'

// 上传响应接口
interface UploadResponse {
  data: string;
  message: string;
  statusCode: number;
}

export class AudioFileManager {
  // 公共属性
  public isPlaying: boolean = false;
  public filePath: string = '';
  public fileList: string[] = [];
  public selectedFileContent: string = '';
  public audioSaveBasePath: string = '';
  public audioFileTimestamp: string = '';
  public enableAudioSave: boolean = true;
  public selectedFile: string = '';
  public showFileContent: boolean = false;
  public exportProgress: number = 0;
  public isExporting: boolean = false;
  public exportMessage: string = '';
  // 私有属性
  private rawData: Int16Array[]; // 原始PCM数据数组
  private context: common.UIAbilityContext;
  private uploadToken: string = 'miclink'; // 默认上传令牌
  private autoUpload: boolean = true; // 是否自动上传
  private autoDeleteAfterUpload: boolean = true; // 上传后是否自动删除本地文件
  // 文件描述符
  private pcmFile: fs.File | null = null;
  private audioProcessor: SmartMouseAudioProcessor = new SmartMouseAudioProcessor();
  private webViewController: webview.WebviewController
  private inputMessage: inputMessageModel

  /**
   * 构造函数
   * @param rawData 原始PCM数据数组(Int16Array)
   * @param context 应用上下文
   * @param uploadToken 上传令牌，默认'miclink'
   * @param autoUpload 是否自动上传，默认true
   * @param autoDeleteAfterUpload 上传后是否自动删除本地文件，默认true
   */
  constructor(
    rawData: Int16Array[],
    context: common.UIAbilityContext,
    webViewController: webview.WebviewController,
    inputMessage: inputMessageModel,
    uploadToken: string = 'miclink',
    autoUpload: boolean = true,
    autoDeleteAfterUpload: boolean = true
  ) {
    // 初始化实例属性
    this.rawData = rawData;
    this.context = context;
    this.uploadToken = uploadToken;
    this.autoUpload = autoUpload;
    this.autoDeleteAfterUpload = autoDeleteAfterUpload;
    this.webViewController = webViewController
    this.inputMessage = inputMessage
    // 初始化并写入音频文件
    this.initAndWriteAudioFile();
  }

  /**
   * 设置上传令牌
   */
  setUploadToken(token: string): void {
    this.uploadToken = token;
  }

  /**
   * 设置自动上传选项
   */
  setAutoUploadOptions(autoUpload: boolean, autoDeleteAfterUpload: boolean = true): void {
    this.autoUpload = autoUpload;
    this.autoDeleteAfterUpload = autoDeleteAfterUpload;
  }

  /**
   * 初始化并写入PCM音频文件
   */
  private initAndWriteAudioFile(): void {
    try {
      // 1. 初始化基础信息
      this.initAudioSaveDir();
      this.generateTimestamp();
      this.initAudioFile();

      if (!this.enableAudioSave) {
        throw new Error('音频保存功能已禁用');
      }

      // 2. 合并数据并写入文件
      const mergedRawData: Int16Array = this.mergeInt16Arrays(this.rawData);
      this.writePcmData(mergedRawData);

      // 3. 完成文件写入操作
      this.closeAudioFile();

      // // 显示文件保存成功提示
      // promptAction.showToast({
      //   message: `音频文件已保存: ${this.audioFileTimestamp}`,
      //   duration: 2000
      // });

      // 4. 如果启用了自动上传，则上传文件
      if (this.autoUpload) {
        this.autoUploadFile();
      }

    } catch (error) {
      const err = error as BusinessError;
      console.error('音频文件处理失败: ' + err.message);
      promptAction.showToast({
        message: '音频保存失败: ' + err.message,
        duration: 3000
      });
      this.closeAudioFile();
    }
  }

  /**
   * 自动上传文件
   */
  private async autoUploadFile(): Promise<void> {
    try {
      // 显示上传开始提示
      // promptAction.showToast({
      //   message: '开始上传音频文件...',
      //   duration: 2000
      // });

      console.info('开始自动上传音频文件...');

      // 上传文件
      const uploadResult = await this.uploadRecording();

      if (uploadResult) {
        console.warn('音频文件上传成功:', JSON.stringify(uploadResult.data));
        // 构建JS代码字符串
        const jsCode = `getRecordingText('${AppStorage.get('getRecordingText')}', '${uploadResult.data}')`;
        console.warn("执行JS代码: " + jsCode);
        this.webViewController.runJavaScript(jsCode).then((result: string) => {
          console.warn("JS执行成功，返回值: " + result);
        }).catch((error: Error) => {
          console.warn("JS执行失败: " + error.message);
        });

        // 显示上传成功提示
        // promptAction.showToast({
        //   message: '音频文件上传成功',
        //   duration: 2000
        // });

        // 如果设置了上传后删除本地文件，则删除
        if (this.autoDeleteAfterUpload) {
          const deleteSuccess = this.deleteLocalFile();
          if (deleteSuccess) {
            console.info('已删除本地音频文件');
            // 不显示删除提示，避免干扰用户体验
          }
        }
      } else {
        console.warn('音频文件上传失败');
        // 上传失败时保留本地文件，以便重试
        promptAction.showToast({
          message: '音频文件上传失败，已保留本地文件',
          duration: 3000
        });
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error('自动上传过程失败:', err.message);

      // 上传失败时保留本地文件，以便重试
      promptAction.showToast({
        message: '上传失败，已保留本地文件',
        duration: 3000
      });
    }
  }

  /**
   * 删除本地文件
   */
  private deleteLocalFile(): boolean {
    try {
      const filePath = `${this.audioSaveBasePath}${this.audioFileTimestamp}.pcm`;

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
   * 合并Int16Array数组
   */
  private mergeInt16Arrays(arrays: Int16Array[]): Int16Array {
    const totalLength: number = arrays.reduce((len: number, arr: Int16Array) => len + arr.length, 0);
    const merged: Int16Array = new Int16Array(totalLength);
    let offset: number = 0;
    arrays.forEach((arr: Int16Array) => {
      merged.set(arr, offset);
      offset += arr.length;
    });
    return merged;
  }

  /**
   * 获取应用文件目录
   */
  private getFilesDir(): string {
    return this.context.filesDir;
  }

  /**
   * 初始化音频保存目录
   */
  private initAudioSaveDir(): void {
    const filesDir: string = this.getFilesDir();
    this.audioSaveBasePath = `${filesDir}/audio/`;
    console.log('音频保存路径:', this.audioSaveBasePath);

    // 确保目录存在
    if (!fs.accessSync(this.audioSaveBasePath)) {
      fs.mkdirSync(this.audioSaveBasePath, true);
    }
  }

  /**
   * 生成时间戳作为文件名的一部分
   */
  private generateTimestamp(): void {
    const pad = (num: number): string => num.toString().padStart(2, '0');
    const now: Date = new Date();
    this.audioFileTimestamp = `${now.getFullYear()}${pad(now.getMonth() +
      1)}${pad(now.getDate())}_${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`;
  }

  /**
   * 初始化音频文件
   */
  private initAudioFile(): void {
    if (!this.enableAudioSave) {
      return;
    }

    try {
      // 创建一个PCM文件
      this.pcmFile = fs.openSync(
        `${this.audioSaveBasePath}${this.audioFileTimestamp}.pcm`,
        fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE
      );

      console.info('音频文件初始化成功');
    } catch (error) {
      const err = error as BusinessError;
      console.error('音频文件初始化失败: ' + err.message);
      this.closeAudioFile();
      this.enableAudioSave = false;
    }
  }

  /**
   * 写入PCM数据
   */
  private writePcmData(mergedData: Int16Array): void {
    // 将Int16Array转换为Uint8Array
    const pcmBytes: Uint8Array = this.audioProcessor.int16ArrayToBytes(mergedData);
    this.writeAudioData(pcmBytes);

    // 记录PCM文件路径
    this.filePath = `${this.audioSaveBasePath}${this.audioFileTimestamp}.pcm`;
  }

  /**
   * 写入音频数据到文件
   */
  private writeAudioData(data: Uint8Array): void {
    if (!this.enableAudioSave || this.pcmFile === null) {
      return;
    }

    try {
      fs.writeSync(this.pcmFile.fd, data.buffer);
      console.info(`已写入PCM数据: ${data.length}字节`);
    } catch (error) {
      const err = error as BusinessError;
      console.error('音频数据写入失败: ' + err.message);
    }
  }

  /**
   * 关闭音频文件
   */
  private closeAudioFile(): void {
    if (!this.enableAudioSave || this.pcmFile === null) {
      return;
    }

    try {
      fs.closeSync(this.pcmFile.fd);
      console.info('音频文件已关闭');
    } catch (error) {
      const err = error as BusinessError;
      console.error('关闭文件失败: ' + err.message);
    }

    this.pcmFile = null;
  }

  /**
   * 上传音频文件到服务器
   * @param filename 可选的自定义文件名
   * @returns 上传响应数据
   */
  async uploadRecording(filename?: string): Promise<UploadResponse | null> {
    if (!this.filePath || !fs.accessSync(this.filePath)) {
      console.error('音频文件不存在');
      promptAction.showToast({
        message: '音频文件不存在',
        duration: 3000
      });
      return null;
    }

    const httpRequest = http.createHttp();
    const requestUrl = `http://att.miclink.net/api/upload?key=${encodeURIComponent(this.uploadToken)}${filename ?
      `&name=${encodeURIComponent(filename)}` : ''}`;

    const requestOptions: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'multipart/form-data'
      },
      multiFormDataList: [
        {
          name: "file",
          contentType: 'audio/pcm',
          filePath: this.filePath,
          remoteFileName: filename || `${this.audioFileTimestamp}.pcm`
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
          // 清理HTTP资源
          httpRequest.destroy();

          if (err) {
            console.error('上传音频文件失败:', err);
            promptAction.showToast({
              message: '上传音频文件失败',
              duration: 3000
            });
            reject(err);
            return;
          }

          try {
            console.info('上传响应状态码:', data.responseCode);

            let responseData: UploadResponse;
            if (typeof data.result === 'string') {
              responseData = JSON.parse(data.result);
            } else {
              responseData = data.result as UploadResponse;
            }

            if (data.responseCode === 200) {
              console.info('上传成功:', responseData);
              resolve(responseData);
            } else {
              console.error('上传失败:', responseData);
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
   * 手动上传文件（用于重试或手动触发）
   * @param customFilename 自定义文件名
   * @param deleteAfterUpload 上传后是否删除本地文件
   * @returns 上传响应数据
   */
  async manualUploadFile(customFilename?: string, deleteAfterUpload: boolean = true): Promise<UploadResponse | null> {
    let uploadResult: UploadResponse | null = null;

    try {
      // 检查文件是否存在
      if (!fs.accessSync(this.filePath)) {
        console.error('音频文件不存在，无法上传');
        promptAction.showToast({
          message: '音频文件不存在，无法上传',
          duration: 3000
        });
        return null;
      }

      // 生成文件名：如果提供了自定义名称，使用它；否则使用当前时间戳
      let filename: string;
      if (customFilename) {
        filename = customFilename;
      } else {
        // 确保文件名有.pcm扩展名
        filename = `${this.audioFileTimestamp}.pcm`;
      }

      // 显示上传开始提示
      promptAction.showToast({
        message: '开始上传音频文件...',
        duration: 2000
      });

      // 上传音频文件
      uploadResult = await this.uploadRecording(filename);

      if (uploadResult) {
        console.info('手动上传成功:', uploadResult);

        // 显示上传成功提示
        promptAction.showToast({
          message: '音频文件上传成功',
          duration: 2000
        });

        // 如果设置了上传后删除，则删除本地文件
        if (deleteAfterUpload) {
          const deleteSuccess = this.deleteLocalFile();
          if (deleteSuccess) {
            console.info('已删除本地音频文件');
          }
        }
      }
    } catch (error) {
      console.error('手动上传音频文件失败:', error);
      promptAction.showToast({
        message: '上传失败',
        duration: 3000
      });
    }

    return uploadResult;
  }

  /**
   * 删除文件（公开方法）
   * @param filename 文件名
   * @returns 删除是否成功
   */
  public deleteFile(filename: string): boolean {
    try {
      const filePath: string = `${this.audioSaveBasePath}${filename}`;

      if (fs.accessSync(filePath)) {
        fs.unlinkSync(filePath);
        promptAction.showToast({
          message: `已删除文件: ${filename}`,
          duration: 2000
        });
        if (this.selectedFile === filename) {
          this.selectedFile = '';
          this.selectedFileContent = '';
        }
        return true;
      } else {
        throw new Error(`文件不存在: ${filePath}`);
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error('删除文件失败: ' + err.message);
      promptAction.showToast({
        message: '删除文件失败: ' + err.message,
        duration: 3000
      });
      return false;
    }
  }

  /**
   * 获取音频文件路径
   * @returns 当前音频文件路径
   */
  public getAudioFilePath(): string {
    return this.filePath;
  }

  /**
   * 获取音频文件名
   * @returns 当前音频文件名
   */
  public getAudioFileName(): string {
    return `${this.audioFileTimestamp}.pcm`;
  }

  /**
   * 获取上传令牌
   * @returns 当前上传令牌
   */
  public getUploadToken(): string {
    return this.uploadToken;
  }

  /**
   * 检查文件是否存在
   * @returns 文件是否存在
   */
  public fileExists(): boolean {
    if (!this.filePath) {
      return false;
    }

    try {
      return fs.accessSync(this.filePath);
    } catch (error) {
      return false;
    }
  }
}