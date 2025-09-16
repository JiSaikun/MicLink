import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { promptAction } from '@kit.ArkUI';
import { BusinessError } from '@ohos.base';
import { SmartMouseAudioProcessor } from './SmartMouseAudioProcessor';

// 音频数据类型枚举
enum AudioDataType {
  PCM_RAW, // 原始PCM数据(对应decryptedData)
  PCM_PROCESSED, // 处理后的PCM数据(对应audioData)
  WAV // WAV格式数据
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
  // 私有属性（接收数组类型）
  private decryptedData: Uint8Array[]; // 改为数组类型
  private processedData: Int16Array[]; // 改为数组类型
  private context: common.UIAbilityContext;
  // 文件描述符集合
  private pcmRawFile: fs.File | null = null;
  private pcmProcessedFile: fs.File | null = null;
  private wavFile: fs.File | null = null;
  private audioProcessor: SmartMouseAudioProcessor = new SmartMouseAudioProcessor();

  /**
   * 构造函数：接收音频数据数组并写入文件
   * @param decryptedData 原始PCM数据数组
   * @param processedData 处理后的PCM数据数组
   * @param context 应用上下文
   */
  constructor(
    decryptedData: Uint8Array[],
    processedData: Int16Array[],
    context: common.UIAbilityContext
  ) {
    // 初始化实例属性
    this.decryptedData = decryptedData;
    this.processedData = processedData;
    this.context = context;

    // 初始化并写入音频文件
    this.initAndWriteAudioFiles();
  }

  /**
   * 初始化并写入所有音频文件
   */
  private initAndWriteAudioFiles(): void {
    try {
      // 1. 初始化基础信息
      this.initAudioSaveDir();
      this.generateTimestamp();
      this.initAudioFiles();

      if (!this.enableAudioSave) {
        throw new Error('音频保存功能已禁用');
      }

      // 2. 合并数据并写入对应文件
      const mergedRawData = this.mergeUint8Arrays(this.decryptedData);
      this.writeAudioData(mergedRawData, AudioDataType.PCM_RAW);

      const mergedProcessedData = this.mergeInt16Arrays(this.processedData);
      this.writeProcessedAudioData(mergedProcessedData);
      this.writeWavFile(mergedProcessedData);

      // 3. 完成操作
      this.closeAudioFiles();
      promptAction.showToast({
        message: `音频文件已保存: ${this.audioFileTimestamp}`,
        duration: 3000
      });

    } catch (error) {
      console.error('音频文件处理失败: ' + (error as BusinessError).message);
      promptAction.showToast({
        message: '音频保存失败: ' + (error as BusinessError).message,
        duration: 3000
      });
      this.closeAudioFiles();
    }
  }

  /**
   * 合并Uint8Array数组
   */
  private mergeUint8Arrays(arrays: Uint8Array[]): Uint8Array {
    const totalLength = arrays.reduce((len, arr) => len + arr.length, 0);
    const merged = new Uint8Array(totalLength);
    let offset = 0;
    arrays.forEach(arr => {
      merged.set(arr, offset);
      offset += arr.length;
    });
    return merged;
  }

  /**
   * 合并Int16Array数组
   */
  private mergeInt16Arrays(arrays: Int16Array[]): Int16Array {
    const totalLength = arrays.reduce((len, arr) => len + arr.length, 0);
    const merged = new Int16Array(totalLength);
    let offset = 0;
    arrays.forEach(arr => {
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
    const filesDir = this.getFilesDir();
    this.audioSaveBasePath = `${filesDir}/audio/`;
    console.log('***************************************************************************************************************',
      this.audioSaveBasePath)

    // 确保目录存在
    if (!fs.accessSync(this.audioSaveBasePath)) {
      fs.mkdirSync(this.audioSaveBasePath, true);
    }
  }

  /**
   * 生成时间戳作为文件名的一部分
   */
  private generateTimestamp(): void {
    const pad = (num: number) => num.toString().padStart(2, '0');
    const now = new Date();
    this.audioFileTimestamp = `${now.getFullYear()}${pad(now.getMonth() +
      1)}${pad(now.getDate())}_${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`;
  }

  /**
   * 初始化音频文件
   */
  private initAudioFiles(): void {
    if (!this.enableAudioSave) {
      return;
    }

    try {
      // 创建三个音频文件
      this.pcmRawFile = fs.openSync(
        `${this.audioSaveBasePath}${this.audioFileTimestamp}_pcm_raw.pcm`,
        fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE
      );
      this.pcmProcessedFile = fs.openSync(
        `${this.audioSaveBasePath}${this.audioFileTimestamp}_pcm_processed.pcm`,
        fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE
      );
      this.wavFile = fs.openSync(
        `${this.audioSaveBasePath}${this.audioFileTimestamp}_audio.wav`,
        fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE
      );

      console.info('音频文件初始化成功');
    } catch (error) {
      console.error('音频文件初始化失败: ' + (error as BusinessError).message);
      this.closeAudioFiles();
      this.enableAudioSave = false;
    }
  }

  /**
   * 写入处理后的音频数据
   */
  private writeProcessedAudioData(mergedData: Int16Array): void {
    // 将Int16Array转换为Uint8Array
    const processedBytes = this.audioProcessor.int16ArrayToBytes(mergedData);
    this.writeAudioData(processedBytes, AudioDataType.PCM_PROCESSED);
  }

  /**
   * 生成并写入WAV文件
   */
  private writeWavFile(mergedData: Int16Array): void {
    const wavData = this.generateWavFromProcessedPcm(mergedData);
    this.writeAudioData(new Uint8Array(wavData), AudioDataType.WAV);

    // 记录WAV文件路径
    this.filePath = `${this.audioSaveBasePath}${this.audioFileTimestamp}_audio.wav`;
  }

  /**
   * 基于处理后的PCM数据生成WAV格式数据
   */
  private generateWavFromProcessedPcm(processedData: Int16Array): ArrayBuffer {
    const sampleRate = 16000; // 假设采样率为16000Hz
    const bitsPerSample = 16;
    const channels = 1;
    const pcmDataSize = processedData.length * (bitsPerSample / 8);
    const headerSize = 44;
    const totalSize = headerSize + pcmDataSize;

    const buffer = new ArrayBuffer(totalSize);
    const view = new DataView(buffer);

    // 写入WAV头
    this.writeString(view, 0, 'RIFF');
    view.setUint32(4, 36 + pcmDataSize, true);
    this.writeString(view, 8, 'WAVE');
    this.writeString(view, 12, 'fmt ');
    view.setUint32(16, 16, true);
    view.setUint16(20, 1, true);
    view.setUint16(22, channels, true);
    view.setUint32(24, sampleRate, true);
    view.setUint32(28, sampleRate * channels * (bitsPerSample / 8), true);
    view.setUint16(32, channels * (bitsPerSample / 8), true);
    view.setUint16(34, bitsPerSample, true);
    this.writeString(view, 36, 'data');
    view.setUint32(40, pcmDataSize, true);

    // 写入PCM数据
    let offset = headerSize;
    for (let i = 0; i < processedData.length; i++) {
      view.setInt16(offset, processedData[i], true);
      offset += 2;
    }

    return buffer;
  }

  /**
   * 辅助函数：写入字符串到DataView
   */
  private writeString(view: DataView, offset: number, string: string): void {
    for (let i = 0; i < string.length; i++) {
      view.setUint8(offset + i, string.charCodeAt(i));
    }
  }

  /**
   * 写入音频数据到文件
   */
  private writeAudioData(data: Uint8Array, dataType: AudioDataType): void {
    if (!this.enableAudioSave) {
      return;
    }

    let file: fs.File | null = null;
    switch (dataType) {
      case AudioDataType.PCM_RAW:
        file = this.pcmRawFile;
        break;
      case AudioDataType.PCM_PROCESSED:
        file = this.pcmProcessedFile;
        break;
      case AudioDataType.WAV:
        file = this.wavFile;
        break;
    }

    if (file === null) {
      return;
    }

    try {
      fs.writeSync(file.fd, data.buffer);
      console.info(`已写入${AudioDataType[dataType]}数据: ${data.length}字节`);
    } catch (error) {
      console.error(`音频数据写入失败(${AudioDataType[dataType]}): ` + (error as BusinessError).message);
    }
  }

  /**
   * 关闭音频文件
   */
  public closeAudioFiles(): void {
    if (!this.enableAudioSave) {
      return;
    }

    [this.pcmRawFile, this.pcmProcessedFile, this.wavFile].forEach(file => {
      if (file !== null) {
        try {
          fs.closeSync(file.fd);
        } catch (error) {
          console.error('关闭文件失败: ' + (error as BusinessError).message);
        }
      }
    });

    this.pcmRawFile = null;
    this.pcmProcessedFile = null;
    this.wavFile = null;
    console.info('音频文件已关闭');
  }

  /**
   * 删除文件
   */
  public deleteFile(filename: string): void {
    try {
      const filePath = `${this.audioSaveBasePath}${filename}`;

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
      console.error('删除文件失败: ' + (error as BusinessError).message);
      promptAction.showToast({
        message: '删除文件失败: ' + (error as BusinessError).message,
        duration: 3000
      });
    }
  }


  /**
   * 获取当前保存的音频文件列表
   */
  // public async getAudioFileList() {
  //   const context = getContext(this) as common.UIAbilityContext;
  //   const targetDir = `${context.filesDir}/audio/`;
  //
  //   try {
  //     if (fs.accessSync(targetDir)) {
  //       let files = fs.listFileSync(targetDir);
  //       this.fileList = files.filter(file => file.endsWith('.wav') || file.endsWith('.pcm'));
  //
  //       if (this.fileList.length > 0 && !this.selectedFile) {
  //         this.selectedFile = this.fileList[0];
  //       }
  //     } else {
  //       this.fileList = [];
  //     }
  //   } catch (error) {
  //     console.error('列出文件失败: ' + (error as BusinessError).message);
  //     this.fileList = [];
  //   }
  // }
}
