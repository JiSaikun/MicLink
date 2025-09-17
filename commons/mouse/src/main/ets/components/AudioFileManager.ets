import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { promptAction } from '@kit.ArkUI';
import { BusinessError } from '@ohos.base';
import { SmartMouseAudioProcessor } from './SmartMouseAudioProcessor';

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
  // 文件描述符
  private pcmFile: fs.File | null = null;
  private audioProcessor: SmartMouseAudioProcessor = new SmartMouseAudioProcessor();

  /**
   * 构造函数：只接收原始PCM数据数组
   * @param rawData 原始PCM数据数组(Int16Array)
   * @param context 应用上下文
   */
  constructor(
    rawData: Int16Array[],
    context: common.UIAbilityContext
  ) {
    // 初始化实例属性
    this.rawData = rawData;
    this.context = context;

    // 初始化并写入音频文件
    this.initAndWriteAudioFile();
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

      // 3. 完成操作
      this.closeAudioFile();
      promptAction.showToast({
        message: `音频文件已保存: ${this.audioFileTimestamp}`,
        duration: 3000
      });

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
   * 删除文件
   */
  public deleteFile(filename: string): void {
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
    }
  }
}