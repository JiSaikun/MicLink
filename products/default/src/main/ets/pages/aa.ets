import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { promptAction } from '@kit.ArkUI';
import media from '@ohos.multimedia.media';
import { BusinessError } from '@ohos.base';
import buffer from '@ohos.buffer';

// 音频数据类型枚举
enum AudioDataType {
  PCM_RAW,       // 原始PCM数据
  PCM_PROCESSED, // 处理后的PCM数据
  WAV            // WAV格式数据
}

@Entry
@Component
struct Index {
  @State isPlaying: boolean = false;
  @State avPlayer: media.AVPlayer | null = null;
  @State filePath: string = '';
  @State fileList: string[] = [];
  @State selectedFileContent: string = '';
  @State audioSaveBasePath: string = '';
  @State audioFileTimestamp: string = '';
  @State enableAudioSave: boolean = true;
  @State selectedFile: string = '';
  @State showFileContent: boolean = false;
  @State exportProgress: number = 0;
  @State isExporting: boolean = false;
  @State exportMessage: string = '';

  // 文件描述符集合
  private pcmRawFile: fs.File | null = null;
  private pcmProcessedFile: fs.File | null = null;
  private wavFile: fs.File | null = null;

  aboutToAppear(): void {
    this.lookFilesList();
    this.initAudioSavePath();
  }
  // 初始化音频保存路径
  initAudioSavePath(): void {
    const context = getContext(this) as common.UIAbilityContext;
    this.audioSaveBasePath = `${context.filesDir}/audio/`;

    try {
      // 检查目录是否存在，不存在则创建
      if (!fs.accessSync(this.audioSaveBasePath)) {
        fs.mkdirSync(this.audioSaveBasePath, true); // 支持递归创建
        console.info('音频保存路径创建成功: ' + this.audioSaveBasePath);
      }
    } catch (error) {
      console.error('音频保存路径创建失败: ' + (error as BusinessError).message);
      this.enableAudioSave = false;
    }
  }

  // 初始化音频文件
  initAudioFiles(): void {
    if (!this.enableAudioSave) return;

    // 生成时间戳
    const pad = (num: number) => num.toString().padStart(2, '0');
    const now = new Date();
    this.audioFileTimestamp = `${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}_${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`;

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

  // 写入音频数据
  writeAudioData(data: Uint8Array, dataType: AudioDataType): void {
    if (!this.enableAudioSave) return;

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

    if (file === null) return;

    try {
      fs.writeSync(file.fd, data.buffer);
    } catch (error) {
      console.error('音频数据写入失败: ' + (error as BusinessError).message);
    }
  }

  // 关闭音频文件
  closeAudioFiles(): void {
    if (!this.enableAudioSave) return;

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

  // 查看文件列表
  lookFilesList(): void {
    const context = getContext(this) as common.UIAbilityContext;
    const targetDir = `${context.filesDir}/audio/`;

    try {
      if (fs.accessSync(targetDir)) {
        let files = fs.listFileSync(targetDir);
        this.fileList = files.filter(file => file.endsWith('.wav') || file.endsWith('.pcm'));

        if (this.fileList.length > 0 && !this.selectedFile) {
          this.selectedFile = this.fileList[0];
        }
      } else {
        this.fileList = [];
      }
    } catch (error) {
      console.error('列出文件失败: ' + (error as BusinessError).message);
      this.fileList = [];
    }
  }

  // 读取文件内容
  readFile(filename: string): void {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const filePath = `${context.filesDir}/audio/${filename}`;

      if (!fs.accessSync(filePath)) {
        throw new Error(`文件不存在: ${filePath}`);
      }

      const file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
      const fileStat = fs.statSync(filePath);
      const fileSize = fileStat.size;
      const bufferSize = Math.min(fileSize, 4096);
      const arrayBuffer = new ArrayBuffer(bufferSize);
      const bytesRead = fs.readSync(file.fd, arrayBuffer);
      const buf = buffer.from(arrayBuffer, 0, bytesRead);
      const contentPreview = buf.toString('hex').substring(0, 100) + '...';

      this.selectedFileContent = `文件: ${filename}\n大小: ${fileSize}字节\n前${bytesRead}字节(十六进制): ${contentPreview}`;
      console.info(`读取文件成功: ${filename}`);

      fs.closeSync(file.fd);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`读取文件失败: ${err.message}`);
      this.selectedFileContent = `读取文件失败: ${err.message}`;
    }
  }

  // 获取应用文件目录
  getFilesDir(): string {
    const context = getContext(this) as common.UIAbilityContext;
    return context.filesDir;
  }

  // 生成示例音频数据（WAV格式）
  generateAudioData(): ArrayBuffer {
    const sampleRate = 44100;
    const bitsPerSample = 16;
    const channels = 1;
    const duration = 1.0;
    const pcmDataSize = Math.floor(sampleRate * duration * (bitsPerSample / 8) * channels);
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

    // 生成440Hz正弦波PCM数据
    let offset = headerSize;
    for (let i = 0; i < sampleRate * duration; i++) {
      const sample = Math.sin(2 * Math.PI * 440 * i / sampleRate);
      const amplitude = 32767 * sample;
      view.setInt16(offset, amplitude, true);
      offset += 2;
    }

    return buffer;
  }

  // 辅助函数：写入字符串到DataView
  writeString(view: DataView, offset: number, string: string): void {
    for (let i = 0; i < string.length; i++) {
      view.setUint8(offset + i, string.charCodeAt(i));
    }
  }

  // 写入音频数据到文件
  writeAudioToFile(): void {
    try {
      this.initAudioFiles();
      if (!this.enableAudioSave) throw new Error('音频保存功能已禁用');

      const audioData = this.generateAudioData();
      const pcmData = new Uint8Array(audioData.slice(44));

      // 写入原始PCM
      this.writeAudioData(pcmData, AudioDataType.PCM_RAW);

      // 写入处理后的PCM（音量降低）
      const processedPcmData = new Uint8Array(pcmData.length);
      const pcmView = new DataView(audioData, 44);
      const processedView = new DataView(processedPcmData.buffer);
      for (let i = 0; i < pcmData.length / 2; i++) {
        const sample = pcmView.getInt16(i * 2, true);
        processedView.setInt16(i * 2, Math.floor(sample * 0.8), true);
      }
      this.writeAudioData(processedPcmData, AudioDataType.PCM_PROCESSED);

      // 写入WAV文件
      const filesDir = this.getFilesDir();
      this.filePath = `${filesDir}/audio/${this.audioFileTimestamp}_audio.wav`;
      const file = fs.openSync(this.filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      const bytesWritten = fs.writeSync(file.fd, audioData);
      fs.closeSync(file.fd);

      // 写入WAV数据到专用文件
      this.writeAudioData(new Uint8Array(audioData), AudioDataType.WAV);
      this.closeAudioFiles();

      // 刷新文件列表并提示
      this.lookFilesList();
      console.info(`音频生成成功: ${this.filePath}, 大小: ${bytesWritten}字节`);
      promptAction.showToast({
        message: `WAV音频已生成（${bytesWritten}字节）`,
        duration: 3000
      });
    } catch (error) {
      console.error('写入文件失败：' + (error as BusinessError).message);
      promptAction.showToast({
        message: '音频生成失败：' + (error as BusinessError).message,
        duration: 3000
      });
    }
  }

  // 删除文件
  deleteFile(filename: string): void {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const filePath = `${context.filesDir}/audio/${filename}`;

      if (fs.accessSync(filePath)) {
        fs.unlinkSync(filePath);
        promptAction.showToast({
          message: `已删除文件: ${filename}`,
          duration: 2000
        });

        this.lookFilesList();
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
  build() {
    Column() {
      Text('音频文件生成与管理')
        .fontSize(20)
        .margin(10)
        .fontWeight(FontWeight.Bold)

      Text('生成、管理和导出音频文件')
        .fontSize(14)
        .margin(10)
        .width('90%')
        .textAlign(TextAlign.Center)

      Button('生成WAV音频文件')
        .width('80%')
        .height(50)
        .margin(10)
        .backgroundColor(0x317aff)
        .fontColor(Color.White)
        .onClick(() => {
          this.writeAudioToFile();
        })

      if (this.fileList.length > 0) {
        Text('音频文件列表:')
          .fontSize(16)
          .margin(10)
          .width('90%')
          .textAlign(TextAlign.Start)
          .fontWeight(FontWeight.Medium)

        Scroll() {
          Column() {
            ForEach(this.fileList, (file: string) => {
              Row() {
                Text(file)
                  .fontSize(12)
                  .margin(5)
                  .width('60%')
                  .textAlign(TextAlign.Start)

                Button('查看')
                  .width(60)
                  .height(30)
                  .fontSize(10)
                  .backgroundColor(0x317aff)
                  .fontColor(Color.White)
                  .onClick(() => {
                    this.readFile(file);
                    this.selectedFile = file;
                    this.showFileContent = true;
                  })

                Button('导出')
                  .width(60)
                  .height(30)
                  .fontSize(10)
                  .backgroundColor(0x07c160)
                  .fontColor(Color.White)
                  .onClick(() => {
                  })
                Button('删除')
                  .width(60)
                  .height(30)
                  .fontSize(10)
                  .backgroundColor(0xee0a24)
                  .fontColor(Color.White)
                  .onClick(() => {
                    this.deleteFile(file);
                  })
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .padding(10)
              .backgroundColor(0xF5F5F5)
              .borderRadius(5)
              .margin({ bottom: 5 })
            })
          }
        }
        .height(200)
        .width('90%')
        .margin(10)
      } else {
        Text('没有音频文件，请先生成')
          .fontSize(14)
          .margin(20)
          .fontColor(0x999999)
      }

      if (this.isExporting) {
        Text('导出中...')
          .fontSize(14)
          .margin(5)

        Text(this.exportMessage)
          .fontSize(12)
          .margin(5)
          .width('90%')
          .textAlign(TextAlign.Center)

        Progress({ value: this.exportProgress, total: 100 })
          .width('80%')
          .height(10)
          .margin(10)
      }

      if (this.showFileContent && this.selectedFileContent) {
        Text('文件内容预览:')
          .fontSize(16)
          .margin(10)
          .width('90%')
          .textAlign(TextAlign.Start)
          .fontWeight(FontWeight.Medium)

        Scroll() {
          Text(this.selectedFileContent)
            .fontSize(12)
            .margin(10)
            .width('90%')
            .textAlign(TextAlign.Start)
        }
        .height(120)
        .width('90%')
        .backgroundColor(0xF5F5F5)
        .padding(10)
        .borderRadius(5)

        Button('关闭预览')
          .width('40%')
          .height(40)
          .margin(10)
          .onClick(() => {
            this.showFileContent = false;
          })
      }

      Text('说明: 生成的音频文件保存在应用沙箱内，导出文件可在文件管理中找到')
        .fontSize(12)
        .margin(20)
        .fontColor(0x666666)
        .width('90%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .padding(10)
    .backgroundColor(0xf8f9fa)
  }
}
