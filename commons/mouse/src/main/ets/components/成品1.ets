import { webSocket } from '@kit.NetworkKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { BusinessError } from '@kit.BasicServicesKit';
// import { inputMethodEngine } from '@kit.IMEKit';
import { getModelInfoModel } from 'config'
import { Communication } from './Communication'
import { _translate } from '../viewmodel/UserViewModel'
import { translate_Params, translate_Response } from '../model/MouseInfoModel'
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import { promptAction } from '@kit.ArkUI';
import { Float_Window } from 'float_window';

// 定义日志消息接口
interface logMessageModel {
  "start": boolean,
  "clientId": string,
  "ptt": string,
  "serialNo": string,
  "phrases": string,
  "format": string,
  "apiKey": string,
  "language": string,
  "end": boolean,
  "rate": string,
  "deviceNo": string,
  "content": string
}

export interface inputMessageModel {
  start: boolean
  "clientId": string,
  "ptt": string,
  "serialNo": string,
  "phrases": string,
  "format": string,
  "apiKey": string,
  "language": string,
  "end": boolean,
  "rate": string,
  "deviceNo": string,
  content: string
}

interface res_moudel {
  "data": res_data_moudel
  "message": string,
  "status": number
}

interface res_data_moudel {
  "btype": boolean,
  "clientId": string
  "sn": string
  "text": string
  "type": string
}

export class AudioWebSocketHandler {
  public isConnected: boolean = false;
  private ws: webSocket.WebSocket | null = null;
  private serverUrl: string = "ws://asr.miclink.net/ws";
  private audioData: Int16Array[] = []
  private state: number = 0 //0:语音输入
  private wending: boolean = false //语音数据不再变化
  private inputMessage: inputMessageModel = {
    start: false,
    "clientId": '',
    "ptt": '',
    "serialNo": '',
    "phrases": '',
    "format": '',
    "apiKey": '',
    "language": '',
    "end": false,
    "rate": '',
    "deviceNo": '',
    content: ''
  }
  private sendIntervalId: number | null = null;
  private isSending: boolean = false;
  private pendingChunks: Int16Array[][] = [];

  // 配置常量
  private readonly MAX_CHUNK_SIZE = 1024 * 16; // 16KB 每片
  private readonly MAX_FRAME_SIZE = 1024; // 最大帧大小
  private readonly SEND_DELAY_MS = 10; // 发送延迟
  private readonly FRAME_DELAY_MS = 0; // 帧间延迟

  // Base64编码表，用于自定义Base64编码实现
  private base64Chars: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  constructor(serverUrl: string, audioData: Int16Array[], state: number, inputMessage: inputMessageModel) {
    this.serverUrl = serverUrl;
    this.audioData = audioData;
    this.state = state;
    this.inputMessage = inputMessage;
    AppStorage.setOrCreate('voiceInputText', '')
    AppStorage.setOrCreate('linshi', '')
    AppStorage.setOrCreate('voiceTranslationText', {
      transText: '',
      text: ''
    })
    this.wending = false
    this.isSending = false;
  }

  public connect(): void {
    try {
      // 添加连接状态检查
      if (this.ws && this.isConnected) {
        console.warn('WebSocket已经连接');
        return;
      }

      console.log('*************************进入webSocket连接************************');

      // 清理之前的连接
      this.disconnect();

      this.ws = webSocket.createWebSocket();

      this.ws.on('open', (err: BusinessError, value: Object) => {
        if (!err) {
          this.isConnected = true;
          console.log("连接已打开，状态:" + JSON.stringify(value));
          console.log('*******************************语音数据长度：', this.audioData.length);

          // 使用安全的数据发送方式
          this.startSafeAudioSending();
        } else {
          console.error("连接错误:" + JSON.stringify(err));
        }
      });

      this.ws.on('message', (err: BusinessError, value: string | ArrayBuffer) => {
        if (!err) {
          let message: string;
          if (typeof value === 'string') {
            message = value;
          } else {
            message = this.arrayBufferToString(value);
          }
          console.log("收到消息，内容:" + message);
          this.handleWebSocketMessage(message);
        } else {
          console.error("消息错误:" + JSON.stringify(err));
        }
      });

      this.ws.on('close', (err: BusinessError, value: webSocket.CloseResult) => {
        this.isConnected = false;
        this.cleanupSendInterval();
        console.log(`连接已关闭，状态码: ${value.code}, 原因: ${value.reason}`);
      });

      this.ws.on('error', (err: BusinessError) => {
        console.error("发生错误: " + err.message);
        this.cleanupSendInterval();
      });

      console.warn('正在连接到服务器...')
      this.ws.connect(this.serverUrl, (err: BusinessError, value: boolean) => {
        if (!err) {
          console.warn("连接成功");
        } else {
          console.error("连接失败。错误信息:" + err.message);
          this.cleanupSendInterval();
        }
      });
    } catch (error) {
      console.error('连接异常:', error);
      this.cleanupSendInterval();
    }
  }

  private handleWebSocketMessage(message: string): void {
    try {
      let res: res_moudel = JSON.parse(message);

      if (res.status === 200 && this.state === 0 && (res.data.type === 'LAST' || res.data.type === "FIN")) {
        if (AppStorage.get('isAI_assistant')) {
          if (this.wending) {
            AppStorage.setOrCreate('voiceInputText', res.data.text);
            return;
          } else {
            AppStorage.setOrCreate('linshi', res.data.text);
          }
        } else {
          if (res.data.text.length > (AppStorage.get('voiceInputText') as string).length) {
            AppStorage.setOrCreate('voiceInputText', res.data.text);
          }
        }
      }

      if (res.status === 200 && (res.data.type === 'LAST' || res.data.type === "FIN")) {
        let audioToText_res: string = res.data.text;
        if (!audioToText_res) {
          return;
        }
        this.handleTextResult(audioToText_res);
      } else {
        console.error('响应异常:', res.message);
      }
    } catch (error) {
      console.error('处理WebSocket消息异常:', error);
    }
  }

  private handleTextResult(text: string): void {
    try {
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();

      systemPasteboard.setData(pasteData)
        .then(() => {
          console.info('文本已复制到剪贴板: ' + text);
          this.processClipboardText(text, systemPasteboard);
        })
        .catch((err: BusinessError) => {
          console.error('复制失败: ' + err.message);
        });
    } catch (error) {
      console.error('复制操作异常: ' + error);
    }
  }

  private processClipboardText(text: string, systemPasteboard: pasteboard.SystemPasteboard): void {
    let atManager = abilityAccessCtrl.createAtManager();
    try {
      atManager.requestPermissionsFromUser(AppStorage.get('context'), ['ohos.permission.READ_PASTEBOARD']);
    } catch (err) {
      console.error(`权限申请失败: ${err.code}, ${err.message}`);
    }

    systemPasteboard.getData().then((pasteData: pasteboard.PasteData) => {
      console.log('剪贴板记录数量:', pasteData.getRecordCount());
      let clipboardText: string = pasteData.getPrimaryText();

      if (this.state === 0 && this.wending) {
        this.wending = false
        // 语音输入模式
        Communication.getDeviceInfo([0x20, 0x01, 0x19])
          .then(() => {
            setTimeout(() => {
              systemPasteboard.clearData();
            }, 2000);
          });
        return;
      }

      if (this.state === 1) {
        // 语音翻译模式
        this.handleTranslation(clipboardText, systemPasteboard);
      }
    })
      .catch((err: BusinessError) => {
        console.error('获取剪贴板数据失败: ' + err.message);
      });
  }

  private handleTranslation(text: string, systemPasteboard: pasteboard.SystemPasteboard): void {
    let params: translate_Params = {
      appkey: (AppStorage.get('getModelInfo') as getModelInfoModel).appkey,
      from: AppStorage.get('from_languages') ? AppStorage.get('from_languages') as string : 'ZH_CN',
      productCode: Communication.deviceInfo.productType.toString(),
      sno: Communication.deviceInfo.sn,
      text: text,
      to: AppStorage.get('to_languages') ? AppStorage.get('to_languages') as string : 'EN_US'
    };

    _translate(params).then((res) => {
      console.log('翻译请求成功————翻译结果：' + res.data?.transText);
      if (res.data) {
        let dataArray = AppStorage.get('voiceTranslationText') as translate_Response;
        dataArray = {
          transText: res.data?.transText as string,
          text: res.data?.text as string,
        };
        AppStorage.setOrCreate('voiceTranslationText', dataArray);
        systemPasteboard.clearData();
      } else {
        AppStorage.setOrCreate('flax_yuyinfanyi_chachaobudaoyuyan',
          !AppStorage.get('flax_yuyinfanyi_chachaobudaoyuyan'));
      }
    })
      .catch(() => {
      });
  }

  public disconnect(): void {
    this.cleanupSendInterval();
    this.isSending = false;

    if (this.ws) {
      try {
        this.ws.close({
          code: 1000,
          reason: "客户端主动关闭"
        }, (err: BusinessError, value: boolean) => {
          if (!err) {
            console.log("连接已成功关闭");
          } else {
            console.error("关闭连接失败。错误信息: " + JSON.stringify(err));
          }
          this.ws = null;
          this.isConnected = false;
        });
      } catch (error) {
        console.error('断开连接异常:', error);
        this.ws = null;
        this.isConnected = false;
      }
    }
  }

  private cleanupSendInterval(): void {
    if (this.sendIntervalId !== null) {
      clearInterval(this.sendIntervalId);
      this.sendIntervalId = null;
    }
  }

  public sendMessage(inputMessage: inputMessageModel): boolean {
    if (!this.isConnected || !this.ws) {
      console.error("未连接到服务器，无法发送消息");
      return false;
    }

    if (!inputMessage.content.trim()) {
      console.error("消息不能为空");
      return false;
    }

    try {
      this.ws.send(JSON.stringify(inputMessage), (err: BusinessError, value: boolean) => {
        if (err) {
          console.error("消息发送失败: " + err.message);
        } else {
          console.error("消息发送成功");
        }
      });
      return true;
    } catch (error) {
      console.error("发送消息未知错误：", error);
      return false;
    }
  }

  private arrayBufferToString(buffer: ArrayBuffer): string {
    try {
      const uint8Array: Uint8Array = new Uint8Array(buffer);
      let result: string = "";

      for (let i = 0; i < uint8Array.length; i++) {
        result += String.fromCharCode(uint8Array[i]);
      }

      return result;
    } catch (error) {
      console.error('ArrayBuffer转换字符串失败:', error);
      return '';
    }
  }

  // 优化的Base64编码实现
  private base64Encode(uint8Array: Uint8Array): string {
    if (!uint8Array || uint8Array.length === 0) {
      return '';
    }

    // 预分配足够的空间，避免频繁的字符串拼接
    const outputLength = Math.ceil(uint8Array.length / 3) * 4;
    const output = new Array<string>(outputLength);
    let outputIndex = 0;

    try {
      for (let i = 0; i < uint8Array.length; i += 3) {
        const byte1 = uint8Array[i];
        const byte2 = i + 1 < uint8Array.length ? uint8Array[i + 1] : 0;
        const byte3 = i + 2 < uint8Array.length ? uint8Array[i + 2] : 0;

        const enc1 = byte1 >> 2;
        const enc2 = ((byte1 & 0x3) << 4) | (byte2 >> 4);
        const enc3 = ((byte2 & 0xf) << 2) | (byte3 >> 6);
        const enc4 = byte3 & 0x3f;

        output[outputIndex++] = this.base64Chars.charAt(enc1);
        output[outputIndex++] = this.base64Chars.charAt(enc2);
        output[outputIndex++] = i + 1 < uint8Array.length ? this.base64Chars.charAt(enc3) : '=';
        output[outputIndex++] = i + 2 < uint8Array.length ? this.base64Chars.charAt(enc4) : '=';
      }

      return output.join('');
    } catch (error) {
      console.error('Base64编码错误:', error);
      return '';
    }
  }

  // 将Int16Array转换为Base64编码
  private int16ToBase64(int16Array: Int16Array): string {
    // 创建一个Uint8Array来存储转换后的字节
    const byteArray = new Uint8Array(int16Array.length * 2);

    // 将16位整数转换为两个8位字节
    for (let i = 0; i < int16Array.length; i++) {
      const value = int16Array[i];
      // 低8位
      byteArray[i * 2] = value & 0xFF;
      // 高8位
      byteArray[i * 2 + 1] = (value >> 8) & 0xFF;
    }

    // 使用自定义的Base64编码方法
    return this.base64Encode(byteArray);
  }

  // 分片处理音频数据
  private processAudioInChunks(audioData: Int16Array[]): Int16Array[][] {
    const chunks: Int16Array[][] = [];
    let currentChunk: Int16Array[] = [];
    let currentSize = 0;

    for (const frame of audioData) {
      const frameSize = frame.length * 2; // 每个Int16占2字节

      if (currentSize + frameSize > this.MAX_CHUNK_SIZE && currentChunk.length > 0) {
        chunks.push(currentChunk);
        currentChunk = [];
        currentSize = 0;
      }

      currentChunk.push(frame);
      currentSize += frameSize;
    }

    if (currentChunk.length > 0) {
      chunks.push(currentChunk);
    }

    return chunks;
  }

  // 限制单帧数据大小
  private limitFrameSize(frame: Int16Array): Int16Array {
    if (frame.length <= this.MAX_FRAME_SIZE) {
      return frame;
    }

    // 如果帧太大，进行截断
    return frame.subarray(0, this.MAX_FRAME_SIZE);
  }

  // 延迟函数
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  private startSafeAudioSending(): void {
    let lastDataLength = Communication.audioData.length;
    let stableCount = 0;
    const maxStableCount = 2;

    this.sendIntervalId = setInterval(async () => {
      try {
        // 如果正在发送，跳过本次处理
        if (this.isSending) {
          console.log('上一次发送仍在进行，跳过本次发送');
          return;
        }

        const currentLength = Communication.audioData.length;

        if (currentLength === lastDataLength) {
          stableCount++;
        } else {
          stableCount = 0;
          lastDataLength = currentLength;
        }

        // 检查内存使用
        this.checkMemoryUsage();

        if (currentLength > 0) {
          await this.sendAudioDataWithBackpressure(Communication.audioData);
        }

        if (stableCount >= maxStableCount) {
          setTimeout(() => {
            this.wending = true;
          }, 10);

          this.cleanupSendInterval();
          console.log('音频数据发送完成');
        }

      } catch (error) {
        console.error('音频发送错误:', error);
        this.cleanupSendInterval();
      }
    }, 500) as number;
  }

  private async sendAudioDataWithBackpressure(audioData: Int16Array[]): Promise<void> {
    this.isSending = true;

    try {
      // 分片处理数据
      const chunks = this.processAudioInChunks(audioData);

      for (let chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
        const chunk = chunks[chunkIndex];

        // 添加延迟，避免发送过快
        if (chunkIndex > 0) {
          await this.delay(this.SEND_DELAY_MS);
        }

        await this.sendAudioChunkSafe(chunk, chunkIndex, chunks.length);
      }
    } catch (error) {
      console.error('分片发送错误:', error);
    } finally {
      this.isSending = false;
    }
  }

  private async sendAudioChunkSafe(chunk: Int16Array[], chunkIndex: number, totalChunks: number): Promise<void> {
    for (let frameIndex = 0; frameIndex < chunk.length; frameIndex++) {
      try {
        const frame = chunk[frameIndex];

        if (!frame || frame.length === 0) {
          continue;
        }

        // 限制单帧数据大小
        const limitedFrame = this.limitFrameSize(frame);
        const base64Audio = this.int16ToBase64(limitedFrame);

        if (!base64Audio) {
          continue;
        }

        const isStart = (chunkIndex === 0 && frameIndex === 0);
        const isEnd = (chunkIndex === totalChunks - 1 && frameIndex === chunk.length - 1);

        const inputMessage: inputMessageModel = {
          "start": isStart,
          "clientId": this.inputMessage.clientId,
          "ptt": this.inputMessage.ptt,
          "serialNo": this.inputMessage.serialNo,
          "phrases": this.inputMessage.phrases,
          "format": this.inputMessage.format || "pcm",
          "apiKey": this.inputMessage.apiKey,
          "language": this.inputMessage.language,
          "end": isEnd,
          "rate": this.inputMessage.rate,
          "deviceNo": this.inputMessage.deviceNo,
          "content": base64Audio
        };

        const success = this.sendMessage(inputMessage);
        if (!success) {
          console.error('发送音频数据失败');
          break;
        }

        // 添加帧间延迟
        if (frameIndex % 5 === 0) {
          await this.delay(this.FRAME_DELAY_MS);
        }

      } catch (error) {
        console.error(`发送音频帧错误:`, error);
      }
    }
  }

  // 添加内存监控
  private checkMemoryUsage(): void {
    // 定期检查音频数据大小，避免内存泄漏
    const totalSize = this.audioData.reduce((total, frame) => total + (frame ? frame.length : 0), 0) * 2;
    console.log(`当前音频数据大小: ${(totalSize / 1024 / 1024).toFixed(2)} MB`);

    // 如果数据过大，清理旧数据
    if (totalSize > 50 * 1024 * 1024) { // 50MB限制
      console.warn('音频数据过大，清理部分数据');
      this.audioData = this.audioData.slice(-1000); // 保留最近1000帧
    }
  }

  private createAudioDataCopy(audioData: Int16Array[]): Int16Array[] {
    try {
      return audioData.map(arr => {
        if (arr && arr.length > 0) {
          return new Int16Array(arr);
        } else {
          console.warn('遇到空的Int16Array，创建空数组');
          return new Int16Array(0);
        }
      });
    } catch (error) {
      console.error('创建音频数据副本失败:', error);
      return [];
    }
  }

  // 清理资源
  public destroy(): void {
    this.disconnect();
    this.cleanupSendInterval();

    // 清理音频数据
    this.audioData = [];
    this.pendingChunks = [];
    this.isSending = false;
    this.ws = null;

    console.log('AudioWebSocketHandler资源已清理');
  }
}