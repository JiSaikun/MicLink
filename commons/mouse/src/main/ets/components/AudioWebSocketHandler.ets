import { webSocket } from '@kit.NetworkKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { BusinessError } from '@kit.BasicServicesKit';
// import { inputMethodEngine } from '@kit.IMEKit';
import { getModelInfoModel } from 'config'
import { Communication, ConnectDevice } from './Communication'
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
  private lastSentIndex: number = 0; // 记录已发送的位置
  private completionCheckId: number | null = null;
  private pendingInitTimerId: number | null = null; // 初始化延迟定时器
  private isClosing: boolean = false; // 新增：标记是否正在关闭

  // 优化配置 - 1024字节分片
  private readonly CHUNK_SIZE_BYTES = 1024; // 目标分片大小
  private readonly SAMPLES_PER_CHUNK = 512; // 1024字节 / 2字节每采样点 = 512个采样点
  private readonly SEND_INTERVAL_MS = 0; // 发送间隔（立即发送）
  private readonly CHECK_INTERVAL_MS = 20; // 检查间隔（从3ms增加到20ms，减少检测频率）
  private readonly COMPLETION_CHECK_MS = 100; // 完成检查间隔
  private readonly MAX_BUFFER_SIZE = 50; // 最大缓冲分片数
  private readonly MIN_SAMPLES_FOR_COMPLETION = 1024; // 最小采样点数才开始检测完成（约0.064秒@16kHz）

  // Base64编码表
  private base64Chars: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  constructor(serverUrl: string, audioData: Int16Array[], state: number, inputMessage: inputMessageModel) {
    this.serverUrl = serverUrl;
    this.audioData = audioData;
    this.state = state;
    this.inputMessage = inputMessage;
    if (state) {
      AppStorage.setOrCreate('voiceTranslationText', {
        transText: '',
        text: ''
      })
    } else {
      AppStorage.setOrCreate('voiceInputText', '')
      AppStorage.setOrCreate('linshi', '')
    }
    this.wending = false
    this.isSending = false;
    this.lastSentIndex = 0;
    this.isClosing = false;
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
          this.isClosing = false;
          console.log("连接已打开，状态:" + JSON.stringify(value));
          console.log('*******************************语音数据长度：', this.audioData.length);

          // 使用优化的实时发送方式
          this.startRealTimeAudioSending();
        } else {
          console.error("连接错误:" + JSON.stringify(err));
          this.isConnected = false;
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
          console.error("收到消息，内容:" + message);
          this.handleWebSocketMessage(message);
        } else {
          console.error("消息错误:" + JSON.stringify(err));
        }
      });

      this.ws.on('close', (err: BusinessError, value: webSocket.CloseResult) => {
        this.isConnected = false;
        this.isClosing = false;
        this.cleanupIntervals();
        console.log(`连接已关闭，状态码: ${value.code}, 原因: ${value.reason}`);
      });

      this.ws.on('error', (err: BusinessError) => {
        console.error("发生错误: " + err.message);
        this.cleanupIntervals();
        this.isConnected = false;
      });

      console.warn('正在连接到服务器...')
      this.ws.connect(this.serverUrl, (err: BusinessError, value: boolean) => {
        if (!err) {
          console.warn("连接成功");
        } else {
          console.error("连接失败。错误信息:" + err.message);
          this.cleanupIntervals();
          this.isConnected = false;
        }
      });
    } catch (error) {
      console.error('连接异常:', error);
      this.cleanupIntervals();
      this.isConnected = false;
    }
  }

  private handleWebSocketMessage(message: string): void {
    try {
      let res: res_moudel = JSON.parse(message);
      if (res.data.text === '') {
        return
      }
      if (res.status === 200 && this.state === 0) {
        if (AppStorage.get('isAI_assistant')) {
          if (this.wending && (res.data.type === 'LAST' || res.data.type === "FIN")) {
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

      if (res.status === 200) {
        let audioToText_res: string = res.data.text;
        if (!audioToText_res) {
          return;
        }
        if (this.state) {
          if (this.wending) {
            if (res.data.type === 'LAST' || res.data.type === "FIN") {
              this.handleTextResult(audioToText_res, res.data.type);
            }
           return
          }
          this.handleTextResult(audioToText_res, res.data.type);
        }
        else {
          this.handleTextResult(audioToText_res, res.data.type);
        }

      } else {
        console.error('响应异常:', res.message);
      }
    } catch (error) {
      console.error('处理WebSocket消息异常:', error);
    }
  }

  private handleTextResult(text: string, type: string): void {
    try {
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();

      systemPasteboard.setData(pasteData)
        .then(() => {
          console.error('文本已复制到剪贴板: ' + text);
          this.processClipboardText(text, systemPasteboard, type);
        })
        .catch((err: BusinessError) => {
          console.error('复制失败: ' + err.message);
        });
    } catch (error) {
      console.error('复制操作异常: ' + error);
    }
  }

  private processClipboardText(text: string, systemPasteboard: pasteboard.SystemPasteboard, type: string): void {
    let atManager = abilityAccessCtrl.createAtManager();
    try {
      atManager.requestPermissionsFromUser(AppStorage.get('context'), ['ohos.permission.READ_PASTEBOARD']);
    } catch (err) {
      console.error(`权限申请失败: ${err.code}, ${err.message}`);
    }

    systemPasteboard.getData().then((pasteData: pasteboard.PasteData) => {
      console.log('剪贴板记录数量:', pasteData.getRecordCount());
      let clipboardText: string = pasteData.getPrimaryText();

      if (this.state === 0 && this.wending && !AppStorage.get('isAI_assistant')) {
        this.wending = false
        // 语音输入模式
        ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.getDeviceInfo([0x20,
          0x01, 0x19])
          .then(() => {
            setTimeout(() => {
              systemPasteboard.clearData();
            }, 2000);
          });
        return;
      }

      if (this.state === 1) {
        // 语音翻译模式
        this.handleTranslation(clipboardText, systemPasteboard, type);
      }
    })
      .catch((err: BusinessError) => {
        console.error('获取剪贴板数据失败: ' + err.message);
      });
  }

  private handleTranslation(text: string, systemPasteboard: pasteboard.SystemPasteboard, type: string): void {
    let params: translate_Params = {
      appkey: (ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].getModelInfo as getModelInfoModel).appkey,
      from: AppStorage.get('from_languages') ? AppStorage.get('from_languages') as string : 'ZH_CN',
      productCode: ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||
        0].Communication.deviceInfo.productType.toString(),
      sno: ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.deviceInfo.sn,
      text: text,
      to: AppStorage.get('to_languages') ? AppStorage.get('to_languages') as string : 'EN_US'
    };

    _translate(params).then((res) => {
      console.log('翻译请求成功————翻译结果：' + res.data?.transText,type);
      if (res.data) {
        let dataArray = AppStorage.get('voiceTranslationText') as translate_Response;
        dataArray = {
          transText: res.data?.transText as string,
          text: res.data?.text as string,
        };
        AppStorage.setOrCreate('voiceTranslationText', dataArray);
        systemPasteboard.clearData();
        // console.error('翻译文本已复制到剪贴板: ' + dataArray);
        // console.error('翻译文本已复制到剪贴板: ' + AppStorage.get('isAutoCloseVoiceTransPop')+(type === 'LAST' || type === "FIN"));
        if (AppStorage.get('isAutoCloseVoiceTransPop') && (type === 'LAST' || type === "FIN")) {
          // console.error('翻译文本已复制到剪贴板1: ' + dataArray.transText);
          try {
            const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, dataArray.transText);
            systemPasteboard.setData(pasteData)
              .then(() => {
                console.error('翻译文本已复制到剪贴板: ' + dataArray.transText);
                this.wending = false
                Float_Window.destroyWindow(Float_Window.window_VoiceTranslation)
                setTimeout(() => {
                  // 语音输入模式
                  ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||
                    0].Communication.getDeviceInfo([0x20,
                    0x01, 0x19])
                    .then(() => {
                      console.error('执行粘贴操作: ' + dataArray.transText);
                      Float_Window.showVoiceTranslation = false
                      if (ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.audioDataState) {
                        ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.getDeviceInfo([0x63])
                        ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.audioDataState = !ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.audioDataState
                      }
                      setTimeout(() => {
                        systemPasteboard.clearData();
                      }, 2000);
                    });
                }, 50);
              })
              .catch((err: BusinessError) => {
                console.error('翻译文本复制失败: ' + err.message);
              });
          } catch (error) {
            console.error('复制操作异常: ' + error);
          }
        }

      } else {
        AppStorage.setOrCreate('flax_yuyinfanyi_chachaobudaoyuyan',
          !AppStorage.get('flax_yuyinfanyi_chachaobudaoyuyan'));
      }
    })
      .catch(() => {
      });
  }

  public disconnect(): void {
    console.log('开始断开WebSocket连接');

    if (this.ws && this.isConnected) {
      try {
        console.log('正在关闭WebSocket连接...');

        // 先发送结束标记（在设置isClosing之前）
        this.sendEndMarker();
        
        // 然后清理定时器和状态
        this.cleanupIntervals();
        this.isSending = false;
        this.isClosing = true;

        // 延迟一段时间确保结束标记发送完成
        setTimeout(() => {
          this.ws!.close({
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
            this.isClosing = false;
          });
        }, 100);

      } catch (error) {
        console.error('断开连接异常:', error);
        this.ws = null;
        this.isConnected = false;
        this.isClosing = false;
      }
    } else {
      console.log('WebSocket实例不存在或未连接，直接清理');
      this.ws = null;
      this.isConnected = false;
      this.isClosing = false;
    }
  }

  // 强制断开连接（用于超时等情况）
  private forceDisconnect(): void {
    console.log('强制断开WebSocket连接');
    this.cleanupIntervals();
    this.isSending = false;
    this.isConnected = false;
    this.isClosing = false;

    if (this.ws) {
      try {
        this.ws.close({
          code: 1000,
          reason: "强制关闭"
        });
      } catch (error) {
        console.error('强制关闭异常:', error);
      } finally {
        this.ws = null;
      }
    }
  }

  // 异步断开连接方法
  public async disconnectAsync(): Promise<void> {
    return new Promise((resolve) => {
      console.log('开始异步断开WebSocket连接');

      this.cleanupIntervals();
      this.isSending = false;
      this.isClosing = true;

      if (!this.ws || !this.isConnected) {
        console.log('WebSocket未连接，直接完成');
        this.isConnected = false;
        this.isClosing = false;
        resolve();
        return;
      }

      // 设置超时保护
      const timeoutId = setTimeout(() => {
        console.warn('WebSocket关闭超时，强制断开');
        this.forceDisconnect();
        resolve();
      }, 5000);

      try {
        // 发送结束标记
        this.sendEndMarker();

        setTimeout(() => {
          this.ws!.close({
            code: 1000,
            reason: "客户端主动关闭"
          }, (err: BusinessError, value: boolean) => {
            clearTimeout(timeoutId);
            if (!err) {
              console.log("连接已成功关闭");
            } else {
              console.error("关闭连接失败。错误信息: " + JSON.stringify(err));
            }
            this.ws = null;
            this.isConnected = false;
            this.isClosing = false;
            resolve();
          });
        }, 100);

      } catch (error) {
        console.error('断开连接异常:', error);
        clearTimeout(timeoutId);
        this.forceDisconnect();
        resolve();
      }
    });
  }

  private cleanupIntervals(): void {
    if (this.sendIntervalId !== null) {
      clearInterval(this.sendIntervalId);
      this.sendIntervalId = null;
    }
    if (this.completionCheckId !== null) {
      clearInterval(this.completionCheckId);
      this.completionCheckId = null;
    }
    if (this.pendingInitTimerId !== null) {
      clearTimeout(this.pendingInitTimerId);
      this.pendingInitTimerId = null;
    }
  }

  public sendMessage(inputMessage: inputMessageModel): boolean {
    if (!this.isConnected || !this.ws || this.isClosing) {
      console.error("未连接到服务器或正在关闭，无法发送消息");
      return false;
    }

    if (!inputMessage.content.trim() && !inputMessage.end) {
      console.error("消息不能为空");
      return false;
    }

    try {
      this.ws.send(JSON.stringify(inputMessage), (err: BusinessError, value: boolean) => {
        if (err) {
          console.error("消息发送失败: " + err.message);
        } else {
          console.log("消息发送成功");
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

  // Base64编码实现
  private base64Encode(uint8Array: Uint8Array): string {
    if (!uint8Array || uint8Array.length === 0) {
      return '';
    }

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
    const byteArray = new Uint8Array(int16Array.length * 2);

    for (let i = 0; i < int16Array.length; i++) {
      const value = int16Array[i];
      byteArray[i * 2] = value & 0xFF;
      byteArray[i * 2 + 1] = (value >> 8) & 0xFF;
    }

    return this.base64Encode(byteArray);
  }

  // 将音频数据分片为1024字节的块（异步处理避免阻塞主线程）
  private async chunkAudioDataAsync(audioData: Int16Array[]): Promise<Int16Array[]> {
    const chunks: Int16Array[] = [];

    // 将所有音频数据合并为一个大的Int16Array
    let totalLength = 0;
    for (const frame of audioData) {
      totalLength += frame.length;
    }

    // 减少详细日志输出以提高性能
    // console.log(`2.4G分片前总采样点数: ${totalLength}, 总字节数: ${totalLength * 2}`);

    const combinedData = new Int16Array(totalLength);
    let offset = 0;
    for (const frame of audioData) {
      combinedData.set(frame, offset);
      offset += frame.length;

      // 每处理100帧数据，让出主线程控制权
      if (offset % 100 === 0) {
        await this.delay(1);
      }
    }

    // 按512个采样点（1024字节）分块，异步处理
    for (let i = 0; i < combinedData.length; i += this.SAMPLES_PER_CHUNK) {
      const endIndex = Math.min(i + this.SAMPLES_PER_CHUNK, combinedData.length);
      const chunk = combinedData.slice(i, endIndex);
      chunks.push(chunk);

      // 每处理10个分片，让出主线程控制权
      if (chunks.length % 10 === 0) {
        await this.delay(1);
      }
    }

      // console.log(`2.4G总共生成 ${chunks.length} 个分片`);

    return chunks;
  }

  // 保留同步版本用于兼容性，但添加警告
  private chunkAudioData(audioData: Int16Array[]): Int16Array[] {
    console.warn('使用同步chunkAudioData方法，可能阻塞主线程。建议使用chunkAudioDataAsync');
    return this.chunkAudioDataSync(audioData);
  }

  private chunkAudioDataSync(audioData: Int16Array[]): Int16Array[] {
    const chunks: Int16Array[] = [];

    let totalLength = 0;
    for (const frame of audioData) {
      totalLength += frame.length;
    }

    const combinedData = new Int16Array(totalLength);
    let offset = 0;
    for (const frame of audioData) {
      combinedData.set(frame, offset);
      offset += frame.length;
    }

    for (let i = 0; i < combinedData.length; i += this.SAMPLES_PER_CHUNK) {
      const endIndex = Math.min(i + this.SAMPLES_PER_CHUNK, combinedData.length);
      const chunk = combinedData.slice(i, endIndex);
      chunks.push(chunk);
    }

    return chunks;
  }

  // 延迟函数
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  // ========== 优化的1024字节分片发送方法 ==========

  private startRealTimeAudioSending(): void {
    console.log('开始实时音频发送 - 1024字节分片');

    // 延迟一小段时间，让音频数据有时间积累
    const initTimerId = setTimeout(async () => {
      // 检查对象是否仍然有效
      if (this.isClosing || !this.ws || this.lastSentIndex < 0) return;

      // 发送现有数据（如果有的话）
      await this.sendExistingDataIfAvailable();

      // 设置实时监听新数据
      this.setupRealTimeListener();

      // 设置完成检测
      this.setupCompletionDetection();
    }, 500); // 500ms延迟，让数据有时间积累

    // 存储初始化定时器ID以便清理
    this.pendingInitTimerId = initTimerId;
  }

  private async sendExistingDataIfAvailable(): Promise<void> {
    if (this.audioData.length === 0 || this.isClosing || this.lastSentIndex < 0 || !this.ws) {
      return;
    }

    console.log(`立即发送现有数据: ${this.audioData.length} 帧`);

    try {
      this.isSending = true;

      // 分片处理现有数据为1024字节块
      const chunks = await this.chunkAudioDataAsync(this.audioData);
      console.log(`生成 ${chunks.length} 个1024字节分片`);

      for (let chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
        if (this.isClosing) {
          break;
        }

        const chunk = chunks[chunkIndex];
        console.log(`2.4G发送分片 ${chunkIndex + 1}/${chunks.length}, 大小: ${chunk.length} 采样点`);
        await this.sendAudioChunk(chunk, chunkIndex, chunks.length);

        // 控制发送速率
        if (chunkIndex < chunks.length - 1) {
          await this.delay(this.SEND_INTERVAL_MS);
        }
      }

      this.lastSentIndex = this.audioData.length;
      console.log(`现有数据发送完成，最后发送位置: ${this.lastSentIndex}`);

    } catch (error) {
      console.error('发送现有数据错误:', error);
    } finally {
      this.isSending = false;
    }
  }

  private setupRealTimeListener(): void {
    console.log('设置实时监听器');

    this.sendIntervalId = setInterval(async () => {
      if (this.isSending || this.isClosing || this.lastSentIndex < 0 || !this.ws) {
        return;
      }

      // 检查是否有新数据
      if (this.audioData.length > this.lastSentIndex) {
        await this.sendNewDataImmediately();
      }
    }, this.CHECK_INTERVAL_MS) as number;
  }

  private async sendNewDataImmediately(): Promise<void> {
    const newDataCount = this.audioData.length - this.lastSentIndex;
    if (newDataCount <= 0 || this.isSending || this.isClosing) {
      return;
    }

    try {
      this.isSending = true;

      const newData = this.audioData.slice(this.lastSentIndex);
      const chunks = await this.chunkAudioDataAsync(newData);

      if (chunks.length > 0) {
        console.log(`发送 ${chunks.length} 个新数据分片`);

        for (let chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
          if (this.isClosing) {
            break;
          }

          const chunk = chunks[chunkIndex];
          await this.sendAudioChunk(chunk, chunkIndex, chunks.length);

          // 最小延迟
          if (chunkIndex < chunks.length - 1) {
            await this.delay(this.SEND_INTERVAL_MS);
          }
        }
      }

      this.lastSentIndex = this.audioData.length;

    } catch (error) {
      console.error('发送新数据错误:', error);
    } finally {
      this.isSending = false;
    }
  }

  private setupCompletionDetection(): void {
    console.log('设置完成检测');

    let lastDataLength = this.audioData.length;
    let stableCount = 0;
    const maxStableCount = 50; // 1000ms无新数据 (20ms * 50) - 增加到1秒，防止长语音截断
    let initialDelayCount = 0;
    const initialDelayMax = 25; // 500ms初始延迟 (20ms * 25)

    this.completionCheckId = setInterval(() => {
      if (this.isClosing || this.lastSentIndex < 0 || !this.ws) {
        this.cleanupIntervals();
        return;
      }

      // 初始延迟，让数据有时间积累
      initialDelayCount++;
      if (initialDelayCount < initialDelayMax) {
        return; // 跳过初始延迟期间的检查
      }

      const currentLength = this.audioData.length;

      // 计算总采样点数
      let totalSamples = 0;
      for (const frame of this.audioData) {
        totalSamples += frame.length;
      }

      // 只有在至少有最小数据量后才开始检测完成，避免误判
      if (totalSamples < this.MIN_SAMPLES_FOR_COMPLETION) {
        console.log(`2.4G采样点不足(${totalSamples}/${this.MIN_SAMPLES_FOR_COMPLETION})，继续等待...`);
        return;
      }

      if (currentLength === lastDataLength) {
        stableCount++;
        console.log(`2.4G数据稳定计数: ${stableCount}/${maxStableCount} (${stableCount * this.CHECK_INTERVAL_MS}ms)`);

        if (stableCount >= maxStableCount) {
          console.log(`2.4G数据稳定超过${maxStableCount * this.CHECK_INTERVAL_MS}ms，发送结束标记`);
          this.sendEndMarker();
          this.cleanupIntervals();
        }
      } else {
        if (stableCount > 0) {
          console.log(`2.4G接收到新数据，重置稳定计数 (之前: ${stableCount})`);
        }
        stableCount = 0;
        lastDataLength = currentLength;
      }
    }, this.CHECK_INTERVAL_MS) as number;
  }

  private async sendAudioChunk(chunk: Int16Array, chunkIndex: number, totalChunks: number): Promise<void> {
    try {
      if (this.isClosing) {
        return;
      }

      if (!chunk || chunk.length === 0) {
        return;
      }

      const base64Audio = this.int16ToBase64(chunk);

      if (!base64Audio) {
        return;
      }

      console.log(`2.4G分片 ${chunkIndex} Base64长度: ${base64Audio.length}, 前50字符: ${base64Audio.substring(0, 50)}`);

      const isStart = (chunkIndex === 0 && this.lastSentIndex === 0);
      const isEnd = false;

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
      }

    } catch (error) {
      console.error(`发送音频分片错误:`, error);
    }
  }

  private sendEndMarker(): void {
    console.log('发送结束标记');

    const endMessage: inputMessageModel = {
      "start": false,
      "clientId": this.inputMessage.clientId,
      "ptt": this.inputMessage.ptt,
      "serialNo": this.inputMessage.serialNo,
      "phrases": this.inputMessage.phrases,
      "format": this.inputMessage.format || "pcm",
      "apiKey": this.inputMessage.apiKey,
      "language": this.inputMessage.language,
      "end": true,
      "rate": this.inputMessage.rate,
      "deviceNo": this.inputMessage.deviceNo,
      "content": ""
    };

    this.sendMessage(endMessage);
    this.wending = true;
  }

  // 清理资源
  public destroy(): void {
    console.log('开始销毁AudioWebSocketHandler');

    // 立即标记对象为无效状态，防止定时器回调继续执行
    this.lastSentIndex = -1; // 无效标记
    this.isClosing = true;

    this.disconnectAsync().then(() => {
      // 清理音频数据
      this.audioData = [];
      this.pendingChunks = [];
      this.isSending = false;
      this.ws = null;
      console.log('AudioWebSocketHandler资源已完全清理');
    });
  }
}