import { audio } from '@kit.AudioKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { http } from '@kit.NetworkKit';

const TAG = 'OnlineAudioPlayerClass';

// 播放状态枚举
export enum PlaybackState {
  IDLE = 'idle',
  LOADING = 'loading',
  PREPARED = 'prepared',
  PLAYING = 'playing',
  PAUSED = 'paused',
  STOPPED = 'stopped',
  ERROR = 'error'
}

// 播放器配置接口
export interface AudioPlayerConfig {
  url: string;
  samplingRate?: audio.AudioSamplingRate;
  channels?: audio.AudioChannel;
  sampleFormat?: audio.AudioSampleFormat;
  encodingType?: audio.AudioEncodingType;
  usage?: audio.StreamUsage;
  bufferSize?: number; // 可选：自定义缓冲区大小
}

// 播放器事件回调接口
export interface AudioPlayerEvents {
  onStateChange?: (state: PlaybackState) => void;
  onProgress?: (currentOffset: number, totalSize: number) => void;
  onError?: (error: BusinessError | string) => void;
  onLoadingStart?: () => void;
  onLoadingComplete?: () => void;
  onPlaybackEnd?: () => void;
}

// 在线音频播放器类
export class OnlineAudioPlayer {
  // 音频配置
  private audioStreamInfo: audio.AudioStreamInfo;
  private audioRendererInfo: audio.AudioRendererInfo;
  private audioRendererOptions: audio.AudioRendererOptions;

  // 音频数据
  private audioDataBuffer: ArrayBuffer | null = null;
  private currentBufferOffset: number = 0;
  private audioUrl: string;

  // 播放器状态
  private state: PlaybackState = PlaybackState.IDLE;
  private audioRenderer: audio.AudioRenderer | null = null;

  // 事件回调
  private events: AudioPlayerEvents;

  // 配置
  private config: AudioPlayerConfig;

  constructor(config: AudioPlayerConfig, events?: AudioPlayerEvents) {
    this.config = config;
    this.audioUrl = config.url;

    // 初始化音频配置
    this.audioStreamInfo = {
      samplingRate: config.samplingRate || audio.AudioSamplingRate.SAMPLE_RATE_16000,
      channels: config.channels || audio.AudioChannel.CHANNEL_1,
      sampleFormat: config.sampleFormat || audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
      encodingType: config.encodingType || audio.AudioEncodingType.ENCODING_TYPE_RAW
    };

    this.audioRendererInfo = {
      usage: config.usage || audio.StreamUsage.STREAM_USAGE_MUSIC,
      rendererFlags: 0
    };

    this.audioRendererOptions = {
      streamInfo: this.audioStreamInfo,
      rendererInfo: this.audioRendererInfo
    };

    this.events = events || {};

    console.info(`${TAG}: 播放器初始化完成，URL: ${this.audioUrl}`);
  }

  // 私有方法：更新状态并触发回调
  private setState(newState: PlaybackState): void {
    const oldState = this.state;
    this.state = newState;
    console.info(`${TAG}: 状态变更 ${oldState} -> ${newState}`);

    if (this.events.onStateChange) {
      this.events.onStateChange(newState);
    }
  }

  // 私有方法：触发错误回调
  private triggerError(error: BusinessError | string): void {
    console.error(`${TAG}: 发生错误: ${error}`);
    this.setState(PlaybackState.ERROR);

    if (this.events.onError) {
      this.events.onError(error);
    }
  }

  // 私有方法：触发进度回调
  private triggerProgress(): void {
    if (this.events.onProgress && this.audioDataBuffer) {
      this.events.onProgress(this.currentBufferOffset, this.audioDataBuffer.byteLength);
    }
  }

  // 从网络加载音频数据
  public async load(): Promise<boolean> {
    try {
      if (this.state === PlaybackState.LOADING) {
        console.info(`${TAG}: 已经在加载中`);
        return false;
      }

      this.setState(PlaybackState.LOADING);

      if (this.events.onLoadingStart) {
        this.events.onLoadingStart();
      }

      console.info(`${TAG}: 开始从网络加载音频: ${this.audioUrl}`);

      const request: http.HttpRequest = http.createHttp();
      const response = await request.request(this.audioUrl, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        connectTimeout: 60000,
        readTimeout: 60000
      });

      request.destroy();

      if (response.responseCode === http.ResponseCode.OK) {
        this.audioDataBuffer = response.result as ArrayBuffer;
        this.currentBufferOffset = 0;

        console.info(`${TAG}: 音频加载成功，大小: ${this.audioDataBuffer.byteLength} 字节`);

        if (this.events.onLoadingComplete) {
          this.events.onLoadingComplete();
        }

        this.setState(PlaybackState.PREPARED);
        return true;
      } else {
        const errorMsg = `HTTP状态码: ${response.responseCode}`;
        this.triggerError(errorMsg);
        return false;
      }
    } catch (error) {
      this.triggerError(error as BusinessError);
      return false;
    }
  }

  // 初始化音频渲染器
  private async initRenderer(): Promise<boolean> {
    try {
      if (!this.audioDataBuffer) {
        console.error(`${TAG}: 音频数据未加载，无法初始化渲染器`);
        return false;
      }

      return new Promise<boolean>((resolve) => {
        audio.createAudioRenderer(this.audioRendererOptions, (err: BusinessError, renderer: audio.AudioRenderer) => {
          if (err) {
            console.error(`${TAG}: 创建AudioRenderer失败: ${err.message}`);
            this.triggerError(err);
            resolve(false);
            return;
          }

          this.audioRenderer = renderer;

          // 设置数据写入回调
          this.audioRenderer.on('writeData', this.writeDataCallback.bind(this));

          console.info(`${TAG}: AudioRenderer初始化成功`);
          resolve(true);
        });
      });
    } catch (error) {
      this.triggerError(error as BusinessError);
      return false;
    }
  }

  // 数据写入回调函数
  private writeDataCallback(buffer: ArrayBuffer): audio.AudioDataCallbackResult {
    if (!this.audioDataBuffer) {
      console.error(`${TAG}: 音频数据未加载`);
      // 用静音数据填充缓冲区
      new Uint8Array(buffer).fill(0);
      return audio.AudioDataCallbackResult.VALID;
    }

    const bytesRemaining = this.audioDataBuffer.byteLength - this.currentBufferOffset;
    const bytesToCopy = Math.min(buffer.byteLength, bytesRemaining);

    // 复制数据到音频缓冲区
    const destView = new Uint8Array(buffer);
    const srcView = new Uint8Array(this.audioDataBuffer);

    destView.set(srcView.subarray(this.currentBufferOffset, this.currentBufferOffset + bytesToCopy));
    this.currentBufferOffset += bytesToCopy;

    // 触发进度更新
    this.triggerProgress();

    // 如果数据不足，填充静音并检测播放结束
    if (bytesToCopy < buffer.byteLength) {
      destView.fill(0, bytesToCopy);

      if (bytesRemaining <= bytesToCopy) {
        console.info(`${TAG}: 音频播放完毕`);
        this.onPlaybackEnd();
      }
    }

    return audio.AudioDataCallbackResult.VALID;
  }

  // 播放结束处理
  private async onPlaybackEnd(): Promise<void> {
    this.setState(PlaybackState.STOPPED);

    if (this.events.onPlaybackEnd) {
      this.events.onPlaybackEnd();
    }

    // 延迟释放资源
    setTimeout(async () => {
      await this.release();
    }, 100);
  }

  // 开始播放
  public async play(): Promise<boolean> {
    try {
      // 检查状态
      if (this.state === PlaybackState.PLAYING) {
        console.info(`${TAG}: 已经在播放中`);
        return true;
      }

      // 如果没有数据，先加载
      if (!this.audioDataBuffer && this.state !== PlaybackState.LOADING) {
        const loaded = await this.load();
        if (!loaded) {
          return false;
        }
      }

      // 如果正在加载，等待
      if (this.state === PlaybackState.LOADING) {
        console.info(`${TAG}: 正在加载音频，请稍后...`);
        return false;
      }

      // 如果渲染器不存在或已释放，重新初始化
      if (!this.audioRenderer) {
        const initSuccess = await this.initRenderer();
        if (!initSuccess) {
          return false;
        }
      }

      // 检查渲染器状态
      const state = this.audioRenderer!.state.valueOf();
      const validStates = [
        audio.AudioState.STATE_PREPARED,
        audio.AudioState.STATE_PAUSED,
        audio.AudioState.STATE_STOPPED
      ];

      if (validStates.indexOf(state) === -1) {
        console.error(`${TAG}: 当前状态无法开始播放，状态为: ${state}`);

        // 尝试重新初始化
        await this.release();
        const initSuccess = await this.initRenderer();
        if (!initSuccess) {
          return false;
        }
      }

      // 如果播放完毕，重置偏移量
      if (this.currentBufferOffset >= (this.audioDataBuffer?.byteLength || 0)) {
        this.currentBufferOffset = 0;
      }

      return new Promise<boolean>((resolve) => {
        this.audioRenderer!.start((err: BusinessError) => {
          if (err) {
            console.error(`${TAG}: 开始播放失败: ${err.message}`);
            this.triggerError(err);
            resolve(false);
          } else {
            this.setState(PlaybackState.PLAYING);
            console.info(`${TAG}: 开始播放成功`);
            resolve(true);
          }
        });
      });
    } catch (error) {
      this.triggerError(error as BusinessError);
      return false;
    }
  }

  // 暂停播放
  public async pause(): Promise<boolean> {
    try {
      if (!this.audioRenderer) {
        console.error(`${TAG}: AudioRenderer未初始化`);
        return false;
      }

      if (this.audioRenderer.state.valueOf() !== audio.AudioState.STATE_RUNNING) {
        console.info(`${TAG}: 播放器未运行，无需暂停`);
        return true;
      }

      return new Promise<boolean>((resolve) => {
        this.audioRenderer!.pause((err: BusinessError) => {
          if (err) {
            console.error(`${TAG}: 暂停失败: ${err.message}`);
            this.triggerError(err);
            resolve(false);
          } else {
            this.setState(PlaybackState.PAUSED);
            console.info(`${TAG}: 已暂停`);
            resolve(true);
          }
        });
      });
    } catch (error) {
      this.triggerError(error as BusinessError);
      return false;
    }
  }

  // 停止播放
  public async stop(): Promise<boolean> {
    try {
      if (!this.audioRenderer) {
        console.info(`${TAG}: AudioRenderer未初始化`);
        return true;
      }

      const state = this.audioRenderer.state.valueOf();
      if (state !== audio.AudioState.STATE_RUNNING && state !== audio.AudioState.STATE_PAUSED) {
        console.info(`${TAG}: 播放器未运行或暂停，无需停止`);
        return true;
      }

      return new Promise<boolean>((resolve) => {
        this.audioRenderer!.stop((err: BusinessError) => {
          if (err) {
            console.error(`${TAG}: 停止失败: ${err.message}`);
            this.triggerError(err);
            resolve(false);
          } else {
            this.setState(PlaybackState.STOPPED);
            console.info(`${TAG}: 已停止`);
            resolve(true);
          }
        });
      });
    } catch (error) {
      this.triggerError(error as BusinessError);
      return false;
    }
  }

  // 停止并释放资源
  public async stopAndRelease(): Promise<boolean> {
    const stopped = await this.stop();
    if (stopped) {
      await this.release();
    }
    return stopped;
  }

  // 释放资源
  public async release(): Promise<boolean> {
    try {
      if (!this.audioRenderer) {
        console.info(`${TAG}: AudioRenderer未初始化，无需释放`);
        this.setState(PlaybackState.IDLE);
        return true;
      }

      if (this.audioRenderer.state.valueOf() === audio.AudioState.STATE_RELEASED) {
        console.info(`${TAG}: 资源已释放`);
        this.audioRenderer = null;
        this.setState(PlaybackState.IDLE);
        return true;
      }

      return new Promise<boolean>((resolve) => {
        this.audioRenderer!.release((err: BusinessError) => {
          if (err) {
            console.error(`${TAG}: 释放失败: ${err.message}`);
            this.triggerError(err);
            resolve(false);
          } else {
            this.audioRenderer = null;
            this.audioDataBuffer = null;
            this.currentBufferOffset = 0;
            this.setState(PlaybackState.IDLE);
            console.info(`${TAG}: 资源已释放`);
            resolve(true);
          }
        });
      });
    } catch (error) {
      this.triggerError(error as BusinessError);
      return false;
    }
  }

  // 跳转到指定位置（基于字节位置）
  public seek(position: number): boolean {
    if (!this.audioDataBuffer) {
      console.error(`${TAG}: 音频数据未加载`);
      return false;
    }

    // 确保位置在有效范围内
    const validPosition = Math.max(0, Math.min(position, this.audioDataBuffer.byteLength));
    this.currentBufferOffset = validPosition;

    console.info(`${TAG}: 跳转到位置 ${validPosition}/${this.audioDataBuffer.byteLength}`);
    this.triggerProgress();

    return true;
  }

  // 跳转到百分比位置
  public seekToPercent(percent: number): boolean {
    if (!this.audioDataBuffer) {
      console.error(`${TAG}: 音频数据未加载`);
      return false;
    }

    const position = Math.floor(this.audioDataBuffer.byteLength * (percent / 100));
    return this.seek(position);
  }

  // 获取当前播放状态
  public getState(): PlaybackState {
    return this.state;
  }

  // 获取当前播放进度（百分比）
  public getProgress(): number {
    if (!this.audioDataBuffer || this.audioDataBuffer.byteLength === 0) {
      return 0;
    }

    return (this.currentBufferOffset / this.audioDataBuffer.byteLength) * 100;
  }

  // 获取音频时长（基于采样率和格式估算）
  public getDuration(): number {
    if (!this.audioDataBuffer) {
      return 0;
    }

    // 计算音频时长（秒）
    // 对于S16LE格式，每个采样点2字节，单声道
    const bytesPerSample = 2; // S16LE = 2字节
    const sampleRate = this.audioStreamInfo.samplingRate;
    const totalSamples = this.audioDataBuffer.byteLength / bytesPerSample;

    return totalSamples / sampleRate;
  }

  // 获取音频数据大小
  public getAudioSize(): number {
    return this.audioDataBuffer ? this.audioDataBuffer.byteLength : 0;
  }

  // 是否正在播放
  public isPlaying(): boolean {
    return this.state === PlaybackState.PLAYING;
  }

  // 是否已加载
  public isLoaded(): boolean {
    return this.audioDataBuffer !== null;
  }

  // 重新加载音频
  public async reload(): Promise<boolean> {
    await this.release();
    return await this.load();
  }
}
