/**
 * 本地麦克风管理
 */
import { audio } from '@kit.AudioKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { http } from '@kit.NetworkKit';
import { promptAction } from '@kit.ArkUI';

const TAG = 'AudioRecorderManager';

interface Options {
  offset?: number;
  length?: number;
}

interface UploadResponse {
  data: string;
  message: string;
  statusCode: number;
}

export class AudioRecorderManager {
  private audioCapturer: audio.AudioCapturer | undefined = undefined;
  private file: fs.File | undefined = undefined;
  private filePath: string = '';
  private bufferSize: number = 0;
  private isRecording: boolean = false;
  private context: common.UIAbilityContext | null = null;
  private uploadToken: string = '';
  // 音频配置
  private readonly audioConfig: audio.AudioStreamInfo = {
    samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
    channels: audio.AudioChannel.CHANNEL_1,
    sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
    encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
  };
  // 采集器配置
  private readonly capturerConfig: audio.AudioCapturerInfo = {
    source: audio.SourceType.SOURCE_TYPE_MIC,
    capturerFlags: 0
  };

  constructor(context: common.UIAbilityContext, uploadToken: string = 'miclink') {
    this.context = context;
    this.uploadToken = uploadToken;
  }

  /**
   * 设置上传令牌
   */
  setUploadToken(token: string): void {
    this.uploadToken = token;
  }

  /**
   * 请求麦克风权限
   */
  private async requestMicrophonePermission(): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const permissions: Array<Permissions> = ['ohos.permission.MICROPHONE'];
      const grantStatus = await atManager.requestPermissionsFromUser(
        this.context as common.Context,
        permissions
      );

      if (grantStatus.authResults[0] === 0) {
        console.log(`${TAG}: 麦克风权限获取成功`);
        return true;
      } else {
        console.error(`${TAG}: 麦克风权限被拒绝`);
        promptAction.showToast({
          message: '麦克风权限被拒绝，无法录音',
          duration: 3000
        });
        return false;
      }
    } catch (err) {
      console.error(`${TAG}: 请求麦克风权限失败:`, (err as BusinessError).message);
      promptAction.showToast({
        message: '请求麦克风权限失败',
        duration: 3000
      });
      return false;
    }
  }

  /**
   * 初始化录音参数
   */
  private async initRecordingParams(): Promise<void> {
    if (!this.context) {
      throw new Error('未获取到上下文');
    }

    // 生成唯一的录音文件名
    const timestamp = Date.now();
    const path = this.context.cacheDir;
    this.filePath = `${path}/recording_${timestamp}.pcm`;

    // 创建录音文件
    try {
      this.file = fs.openSync(this.filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      this.bufferSize = 0;
      console.log(`${TAG}: 录音文件创建成功: ${this.filePath}`);
    } catch (error) {
      console.error(`${TAG}: 创建录音文件失败:`, error);
      throw new Error('创建录音文件失败');
    }
  }

  /**
   * 初始化录音器
   */
  private async initAudioCapturer(): Promise<void> {
    const audioStreamInfo: audio.AudioStreamInfo = {
      samplingRate: this.audioConfig.samplingRate,
      channels: this.audioConfig.channels,
      sampleFormat: this.audioConfig.sampleFormat,
      encodingType: this.audioConfig.encodingType
    };

    const audioCapturerInfo: audio.AudioCapturerInfo = {
      source: this.capturerConfig.source,
      capturerFlags: this.capturerConfig.capturerFlags
    };

    const audioCapturerOptions: audio.AudioCapturerOptions = {
      streamInfo: audioStreamInfo,
      capturerInfo: audioCapturerInfo
    };

    return new Promise((resolve, reject) => {
      audio.createAudioCapturer(audioCapturerOptions, (err, capturer) => {
        if (err) {
          console.error(`${TAG}: 创建AudioCapturer失败, code: ${err.code}, message: ${err.message}`);
          reject(err);
          return;
        }

        this.audioCapturer = capturer;

        // 设置数据读取回调
        this.audioCapturer.on('readData', (buffer: ArrayBuffer) => {
          if (this.file) {
            const options: Options = {
              offset: this.bufferSize,
              length: buffer.byteLength
            };
            try {
              fs.writeSync(this.file.fd, buffer, options);
              this.bufferSize += buffer.byteLength;
            } catch (writeError) {
              console.error(`${TAG}: 写入录音数据失败:`, writeError);
            }
          }
        });

        console.info(`${TAG}: AudioCapturer创建成功`);
        resolve();
      });
    });
  }

  /**
   * 开始录音（自动检查权限和初始化）
   */
  async startRecording(): Promise<boolean> {
    try {
      // 检查是否已在录音
      if (this.isRecording) {
        console.warn(`${TAG}: 录音已在进行中`);
        promptAction.showToast({
          message: '录音已在进行中',
          duration: 2000
        });
        return false;
      }

      // 请求权限
      const hasPermission = await this.requestMicrophonePermission();
      if (!hasPermission) {
        return false;
      }

      // 初始化录音参数
      await this.initRecordingParams();

      // 初始化录音器
      await this.initAudioCapturer();

      // 检查录音器状态
      if (!this.audioCapturer) {
        throw new Error('录音器初始化失败');
      }

      const stateGroup = [
        audio.AudioState.STATE_PREPARED,
        audio.AudioState.STATE_PAUSED,
        audio.AudioState.STATE_STOPPED
      ];

      if (stateGroup.indexOf(this.audioCapturer.state.valueOf()) === -1) {
        console.error(`${TAG}: 录音器状态异常: ${this.audioCapturer.state}`);
        return false;
      }

      // 开始录音
      return new Promise((resolve) => {
        this.audioCapturer!.start((err: BusinessError) => {
          if (err) {
            console.error(`${TAG}: 开始录音失败:`, err);
            promptAction.showToast({
              message: '开始录音失败',
              duration: 3000
            });
            resolve(false);
          } else {
            this.isRecording = true;
            console.info(`${TAG}: 录音开始成功`);
            promptAction.showToast({
              message: '录音开始',
              duration: 1000
            });
            resolve(true);
          }
        });
      });
    } catch (error) {
      console.error(`${TAG}: 开始录音过程失败:`, error);
      promptAction.showToast({
        message: '开始录音失败',
        duration: 3000
      });
      return false;
    }
  }

  /**
   * 停止录音
   */
  async stopRecording(): Promise<boolean> {
    if (!this.audioCapturer || !this.isRecording) {
      console.warn(`${TAG}: 没有正在进行的录音`);
      return false;
    }

    // 检查状态
    if (this.audioCapturer.state.valueOf() !== audio.AudioState.STATE_RUNNING &&
      this.audioCapturer.state.valueOf() !== audio.AudioState.STATE_PAUSED) {
      console.warn(`${TAG}: 录音器不在运行或暂停状态`);
      return false;
    }

    return new Promise((resolve) => {
      this.audioCapturer!.stop((err: BusinessError) => {
        if (err) {
          console.error(`${TAG}: 停止录音失败:`, err);
          promptAction.showToast({
            message: '停止录音失败',
            duration: 3000
          });
          resolve(false);
        } else {
          this.isRecording = false;
          console.info(`${TAG}: 录音停止成功`);
          promptAction.showToast({
            message: '录音停止',
            duration: 1000
          });
          resolve(true);
        }
      });
    });
  }

  /**
   * 上传录音文件
   */
  async uploadRecording(filename?: string): Promise<UploadResponse | null> {
    if (!this.filePath || !fs.accessSync(this.filePath)) {
      console.error(`${TAG}: 录音文件不存在`);
      promptAction.showToast({
        message: '录音文件不存在',
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
          remoteFileName: filename || `recording_${Date.now()}.pcm`
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
            console.error(`${TAG}: 上传录音文件失败:`, err);
            promptAction.showToast({
              message: '上传录音文件失败',
              duration: 3000
            });
            reject(err);
            return;
          }

          try {
            console.info(`${TAG}: 上传响应状态码:`, data.responseCode);

            let responseData: UploadResponse;
            if (typeof data.result === 'string') {
              responseData = JSON.parse(data.result);
            } else {
              responseData = data.result as UploadResponse;
            }

            if (data.responseCode === 200) {
              console.info(`${TAG}: 上传成功:`, responseData);
              // promptAction.showToast({
              //   message: '录音上传成功',
              //   duration: 2000
              // });
              resolve(responseData);
            } else {
              console.error(`${TAG}: 上传失败:`, responseData);
              // promptAction.showToast({
              //   message: responseData.message || '上传失败',
              //   duration: 3000
              // });
              reject(new Error(responseData.message || '上传失败'));
            }
          } catch (parseError) {
            console.error(`${TAG}: 解析响应失败:`, parseError);
            reject(new Error('解析服务器响应失败'));
          }
        }
      );
    });
  }

  /**
   * 删除本地录音文件
   */
  private deleteLocalRecording(): boolean {
    try {
      if (this.file) {
        fs.closeSync(this.file);
        this.file = undefined;
      }

      if (this.filePath && fs.accessSync(this.filePath)) {
        fs.unlinkSync(this.filePath);
        console.info(`${TAG}: 本地录音文件已删除: ${this.filePath}`);
        this.filePath = '';
        return true;
      }
      return false;
    } catch (error) {
      console.warn(`${TAG}: 删除本地录音文件失败:`, error);
      return false;
    }
  }

  /**
   * 停止并上传录音（一步完成）
   */
  async stopAndUploadRecording(customFilename?: string): Promise<UploadResponse | null> {
    // 停止录音
    const stopSuccess = await this.stopRecording();
    if (!stopSuccess) {
      return null;
    }

    // 生成文件名：如果提供了自定义名称，使用它；否则使用当前时间
    let filename: string;
    if (customFilename) {
      filename = customFilename;
    } else {
      const now = new Date();
      const year = now.getFullYear();
      const month = String(now.getMonth() + 1).padStart(2, '0');
      const day = String(now.getDate()).padStart(2, '0');
      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      const currentTime = `${year}${month}${day}_${hours}${minutes}${seconds}`;
      filename = `recording_${currentTime}.pcm`;
    }

    // 上传录音文件
    let uploadResult: UploadResponse | null = null;
    try {
      uploadResult = await this.uploadRecording(filename);
    } catch (error) {
      console.error(`${TAG}: 上传录音文件过程中出错:`, error);
    }

    // 无论上传成功与否，都删除本地文件
    this.deleteLocalRecording();

    return uploadResult;
  }

  /**
   * 释放录音资源
   */
  async release(): Promise<boolean> {
    // 如果正在录音，先停止
    if (this.isRecording) {
      await this.stopRecording();
    }

    // 释放录音器资源
    if (this.audioCapturer) {
      // 检查状态
      if (this.audioCapturer.state.valueOf() !== audio.AudioState.STATE_RELEASED &&
        this.audioCapturer.state.valueOf() !== audio.AudioState.STATE_NEW) {
        return new Promise((resolve) => {
          this.audioCapturer!.release((err: BusinessError) => {
            if (err) {
              console.error(`${TAG}: 释放录音器资源失败:`, err);
              resolve(false);
            } else {
              console.info(`${TAG}: 录音器资源释放成功`);
              this.audioCapturer = undefined;
              resolve(true);
            }
          });
        });
      }
    }

    // 删除本地文件
    this.deleteLocalRecording();

    return true;
  }

  /**
   * 获取录音状态
   */
  getRecordingStatus(): boolean {
    return this.isRecording;
  }

  /**
   * 获取录音文件路径
   */
  getRecordingFilePath(): string {
    return this.filePath;
  }

  /**
   * 获取录音时长（估算）
   */
  getRecordingDuration(): number {
    if (!this.bufferSize) {
      return 0;
    }

    // 估算录音时长：数据大小 / (采样率 * 通道数 * 位深度/8)
    const bytesPerSecond = (this.audioConfig.samplingRate *
      (this.audioConfig.channels + 1) * // CHANNEL_1对应值1
      16 / 8); // SAMPLE_FORMAT_S16LE表示16位

    return Math.round(this.bufferSize / bytesPerSecond);
  }
}
