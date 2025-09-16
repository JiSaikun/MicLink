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
    let context = getContext(this) as common.UIAbilityContext;
    this.audioSaveBasePath = context.filesDir + '/audio/';

    try {
      // 检查目录是否存在，不存在则创建
      if (!fs.accessSync(this.audioSaveBasePath)) {
        fs.mkdirSync(this.audioSaveBasePath);
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
    const now = new Date();
    this.audioFileTimestamp = now.getFullYear().toString() +
    (now.getMonth() + 1).toString().padStart(2, '0') +
    now.getDate().toString().padStart(2, '0') + '_' +
    now.getHours().toString().padStart(2, '0') +
    now.getMinutes().toString().padStart(2, '0') +
    now.getSeconds().toString().padStart(2, '0');

    try {
      // 创建三个音频文件 - 返回File对象而不是文件描述符
      this.pcmRawFile = fs.openSync(this.audioSaveBasePath + this.audioFileTimestamp + '_pcm_raw.pcm',
        fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      this.pcmProcessedFile = fs.openSync(this.audioSaveBasePath + this.audioFileTimestamp + '_pcm_processed.pcm',
        fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      this.wavFile = fs.openSync(this.audioSaveBasePath + this.audioFileTimestamp + '_audio.wav',
        fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);

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
      // 将Uint8Array转换为ArrayBuffer
      const arrayBuffer = new ArrayBuffer(data.length);
      const uint8Array = new Uint8Array(arrayBuffer);
      uint8Array.set(data);

      // 使用file.fd作为文件描述符
      fs.writeSync(file.fd, arrayBuffer);
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
  lookFilesList(): void {
    // 沙箱文件夹
    let context = getContext(this) as common.UIAbilityContext;
    let filesDir = context.filesDir;

    try {
      let files = fs.listFileSync(filesDir);
      this.fileList = files;

      for (let i = 0; i < files.length; i++) {
        console.log(`当前设备文件 name: ${files[i]}`);
      }

      // 如果有文件，自动选择第一个
      if (files.length > 0) {
        this.readFile(`${filesDir}/${files[0]}`);
      }
    } catch (error) {
      console.error('列出文件失败: ' + (error as BusinessError).message);
    }
  }

  readFile(filePath: string): void {
    try {
      // 检查文件是否存在
      if (!fs.accessSync(filePath)) {
        console.error('文件不存在: ' + filePath);
        return;
      }

      // 打开文件
      let file: fs.File = fs.openSync(filePath, fs.OpenMode.READ_ONLY);

      // 获取文件大小
      let fileStat: fs.Stat = fs.statSync(filePath);
      let fileSize: number = fileStat.size;

      // 定义接收读取数据的缓存
      let arrayBuffer: ArrayBuffer = new ArrayBuffer(fileSize > 4096 ? 4096 : fileSize);

      // 读取文件的内容，返回值是读取到的字节个数
      let num: number = fs.readSync(file.fd, arrayBuffer);

      // 打印读取到的文件数据
      let buf: buffer.Buffer = buffer.from(arrayBuffer, 0, num);

      // 显示文件内容的前缀（避免显示大量二进制数据）
      let contentPreview: string = buf.toString('hex').substring(0, 100) + '...';
      this.selectedFileContent = `文件: ${filePath}\n大小: ${fileSize}字节\n前${num}字节(十六进制): ${contentPreview}`;

      console.info('读取的文件内容: ' + contentPreview);

      // 关闭文件
      fs.closeSync(file.fd);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Failed to openSync / readSync. Code: ${err.code}, message: ${err.message}`);
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
    // 音频参数：44.1kHz采样率，16位，单声道，1秒时长
    const sampleRate = 44100;
    const bitsPerSample = 16;
    const channels = 1;
    const duration = 1.0; // 1秒

    // 计算PCM数据大小
    const pcmDataSize = Math.floor(sampleRate * duration * (bitsPerSample / 8) * channels);

    // WAV文件头大小（44字节）
    const headerSize = 44;
    const totalSize = headerSize + pcmDataSize;

    // 创建包含WAV头的完整音频数据
    const buffer = new ArrayBuffer(totalSize);
    const view = new DataView(buffer);

    // 写入WAV文件头
    // RIFF头
    this.writeString(view, 0, 'RIFF');
    view.setUint32(4, 36 + pcmDataSize, true); // 文件总长度-8
    this.writeString(view, 8, 'WAVE');

    // fmt子块
    this.writeString(view, 12, 'fmt ');
    view.setUint32(16, 16, true); // fmt块长度
    view.setUint16(20, 1, true); // 格式类别（PCM=1）
    view.setUint16(22, channels, true); // 声道数
    view.setUint32(24, sampleRate, true); // 采样率
    view.setUint32(28, sampleRate * channels * (bitsPerSample / 8), true); // 数据传输率
    view.setUint16(32, channels * (bitsPerSample / 8), true); // 数据块对齐单位
    view.setUint16(34, bitsPerSample, true); // 样本位数

    // data子块
    this.writeString(view, 36, 'data');
    view.setUint32(40, pcmDataSize, true); // PCM数据长度

    // 生成PCM数据（440Hz正弦波）
    let offset = headerSize;
    for (let i = 0; i < sampleRate * duration; i++) {
      const sample = Math.sin(2 * Math.PI * 440 * i / sampleRate);
      const amplitude = 32767 * sample; // 16位有符号整数范围
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
      // 初始化音频文件
      this.initAudioFiles();

      // 获取音频数据
      const audioData: ArrayBuffer = this.generateAudioData();

      // 模拟原始PCM数据（去掉WAV头）
      const pcmData = new Uint8Array(audioData.slice(44));

      // 写入原始PCM数据
      this.writeAudioData(pcmData, AudioDataType.PCM_RAW);

      // 模拟处理后的PCM数据（简单地将每个样本乘以0.8）
      const processedPcmData = new Uint8Array(pcmData.length);
      const pcmView = new DataView(audioData, 44);
      const processedView = new DataView(processedPcmData.buffer);

      for (let i = 0; i < pcmData.length / 2; i++) {
        const sample = pcmView.getInt16(i * 2, true);
        processedView.setInt16(i * 2, sample * 0.8, true);
      }

      // 写入处理后的PCM数据
      this.writeAudioData(processedPcmData, AudioDataType.PCM_PROCESSED);

      // 获取应用沙箱路径
      const filesDir = this.getFilesDir();
      this.filePath = filesDir + '/audio.wav';
      console.log('文件路径:', this.filePath);

      // 打开文件，如果不存在则创建
      const file: fs.File = fs.openSync(this.filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);

      // 直接使用ArrayBuffer写入，并指定选项
      const bytesWritten: number = fs.writeSync(file.fd, audioData);

      // 关闭文件
      fs.closeSync(file.fd);

      // 写入WAV文件数据
      this.writeAudioData(new Uint8Array(audioData), AudioDataType.WAV);

      // 关闭音频文件
      this.closeAudioFiles();

      console.log('音频数据已写入文件：' + this.filePath);
      console.log('写入字节数：' + bytesWritten);

      // 刷新文件列表
      this.lookFilesList();

      // 显示成功消息
      promptAction.showToast({
        message: `WAV音频已生成，共${bytesWritten}字节`,
        duration: 3000
      });
    } catch (error) {
      console.error('写入文件失败：' + (error as BusinessError).message);
      promptAction.showToast({
        message: '写入文件失败：' + (error as BusinessError).message,
        duration: 3000
      });
    }
  }

  // 播放音频
  async playAudio(): Promise<void> {
    if (!this.filePath) {
      promptAction.showToast({
        message: '请先生成音频文件',
        duration: 2000
      });
      return;
    }

    try {
      // 检查文件是否存在
      if (!fs.accessSync(this.filePath)) {
        promptAction.showToast({
          message: '音频文件不存在，请先生成',
          duration: 2000
        });
        return;
      }

      // 创建AVPlayer
      this.avPlayer = await media.createAVPlayer();

      // 设置监听器
      this.avPlayer.on('stateChange', (state: string) => {
        switch (state) {
          case 'idle':
            break;
          case 'prepared':
            this.avPlayer?.play();
            break;
          case 'playing':
            this.isPlaying = true;
            promptAction.showToast({
              message: '开始播放音频',
              duration: 2000
            });
            break;
          case 'paused':
            break;
          case 'completed':
            this.isPlaying = false;
            this.avPlayer?.release();
            this.avPlayer = null;
            promptAction.showToast({
              message: '播放完成',
              duration: 2000
            });
            break;
          case 'stopped':
            break;
          case 'error':
            this.isPlaying = false;
            promptAction.showToast({
              message: '播放出错',
              duration: 2000
            });
            break;
        }
      });

      // 使用文件描述符设置源
      let file: fs.File = fs.openSync(this.filePath, fs.OpenMode.READ_ONLY);
      // 注意：AVPlayer的fdSrc要求传入一个AVFileDescriptor对象，其中包含fd、offset、length
      let avFileDescriptor: media.AVFileDescriptor = {
        fd: file.fd,
        offset: 0,
        length: fs.statSync(this.filePath).size
      };
      this.avPlayer.fdSrc = avFileDescriptor;
      await this.avPlayer.prepare();

    } catch (error) {
      const err = error as BusinessError;
      console.error('播放失败：' + JSON.stringify(err));
      promptAction.showToast({
        message: '播放失败：' + err.message,
        duration: 3000
      });
    }
  }

  // 停止播放
  stopAudio(): void {
    if (this.avPlayer && this.isPlaying) {
      this.avPlayer.stop();
      this.avPlayer.release();
      this.avPlayer = null;
      this.isPlaying = false;
      promptAction.showToast({
        message: '已停止播放',
        duration: 2000
      });
    }
  }

  build() {
    Column() {
      Text('音频文件生成与试听')
        .fontSize(20)
        .margin(10)
        .fontWeight(FontWeight.Bold)

      Text('模拟音频处理流程，生成三种格式的音频文件')
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
        Text('文件列表:')
          .fontSize(16)
          .margin(10)
          .width('90%')
          .textAlign(TextAlign.Start)
          .fontWeight(FontWeight.Medium)

        Scroll() {
          Column() {
            ForEach(this.fileList, (file: string) => {
              Text(file)
                .fontSize(12)
                .margin(5)
                .width('90%')
                .textAlign(TextAlign.Start)
                .backgroundColor(0xF5F5F5)
                .padding(10)
                .borderRadius(5)
                .onClick(() => {
                  const filesDir = this.getFilesDir();
                  this.readFile(`${filesDir}/${file}`);
                })
            })
          }
        }
        .height(120)
        .width('90%')
        .margin(10)
      }

      if (this.selectedFileContent) {
        Text('文件内容预览:')
          .fontSize(16)
          .margin(10)
          .width('90%')
          .textAlign(TextAlign.Start)
          .fontWeight(FontWeight.Medium)

        Text(this.selectedFileContent)
          .fontSize(12)
          .margin(10)
          .width('90%')
          .textAlign(TextAlign.Start)
          .backgroundColor(0xF5F5F5)
          .padding(10)
          .borderRadius(5)
      }

      if (this.filePath) {
        if (!this.isPlaying) {
          Button('播放音频')
            .width('80%')
            .height(50)
            .margin(10)
            .backgroundColor(0x07c160)
            .fontColor(Color.White)
            .onClick(() => {
              this.playAudio();
            })
        } else {
          Button('停止播放')
            .width('80%')
            .height(50)
            .margin(10)
            .backgroundColor(0xee0a24)
            .fontColor(Color.White)
            .onClick(() => {
              this.stopAudio();
            })
        }

        Text('当前音频文件: ' + this.filePath)
          .fontSize(12)
          .margin(10)
          .textAlign(TextAlign.Start)
          .width('90%')
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .padding(10)
    .backgroundColor(0xf8f9fa)
  }
}