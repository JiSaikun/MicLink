import { webSocket } from '@kit.NetworkKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { BusinessError } from '@kit.BasicServicesKit';
// import { inputMethodEngine } from '@kit.IMEKit';
import { getModelInfoModel } from 'config'
import {_translate, translate_Params, translate_Response, inputMessageModel } from 'mouse'
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import { Float_Window } from 'float_window';
import { DeviceArrayType_Ble } from './BlueTooth_devices';

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

// 配置常量
const SERVER_URL: string = "ws://asr.miclink.net/ws";
const CHUNK_SIZE_BYTES: number = 1024;
const SAMPLES_PER_CHUNK: number = 512;
const SEND_INTERVAL_MS: number = 0;
const CHECK_INTERVAL_MS: number = 3;
const COMPLETION_CHECK_MS: number = 100;
const DISCONNECT_TIMEOUT_MS: number = 5000;
const END_MARKER_DELAY_MS: number = 100;
const PASTEBOARD_CLEAR_DELAY_MS: number = 2000;
const TRANSLATION_EXECUTE_DELAY_MS: number = 50;
const MIN_DATA_PACKETS: number = 3;
const MAX_STABLE_COUNT: number = 25;
const BASE64_CHARS: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
const LOG_LEVEL: string = 'info';

export class AudioWebSocketHandler_ble {
  public isConnected: boolean = false;
  private ws: webSocket.WebSocket | null = null;
  private serverUrl: string;
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
  private isClosing: boolean = false; // 新增：标记是否正在关闭

  constructor(serverUrl: string, audioData: Int16Array[], state: number, inputMessage: inputMessageModel) {
    this.serverUrl = serverUrl || SERVER_URL;
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

      console.log('开始WebSocket连接');

      // 清理之前的连接
      this.disconnect();

      this.ws = webSocket.createWebSocket();

      this.ws.on('open', (err: BusinessError, value: Object) => {
        if (!err) {
          this.isConnected = true;
          this.isClosing = false;
          console.log("连接已打开");
          console.log('语音数据长度：', this.audioData.length);

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
        } else {
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
        this.wending = false;
        // 语音输入模式 - 安全检查设备访问
        const devices = AppStorage.get('devices') as DeviceArrayType_Ble[];
        const deviceIndex = AppStorage.get('device_currIndex') as number || 0;

        if (devices && devices.length > 0 && deviceIndex >= 0 && deviceIndex < devices.length && devices[deviceIndex]?.BlueTooth_devices) {
          devices[deviceIndex].BlueTooth_devices.send([0x20, 0x01, 0x19])
            .then(() => {
              setTimeout(() => {
                systemPasteboard.clearData();
              }, PASTEBOARD_CLEAR_DELAY_MS);
            });
        } else {
          console.warn('设备列表或设备索引无效，跳过音频状态重置');
        }
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
    // 安全检查设备访问
    const devices = AppStorage.get('devices') as DeviceArrayType_Ble[];
    const deviceIndex = AppStorage.get('device_currIndex') as number || 0;

    if (!devices || devices.length === 0 || deviceIndex < 0 || deviceIndex >= devices.length || !devices[deviceIndex]) {
      console.error('设备列表或设备索引无效，无法进行翻译');
      return;
    }

    const currentDevice = devices[deviceIndex];

    let params: translate_Params = {
      appkey: (currentDevice.getModelInfo as getModelInfoModel)?.appkey || '',
      from: AppStorage.get('from_languages') ? AppStorage.get('from_languages') as string : 'ZH_CN',
      productCode: currentDevice.BlueTooth_devices?.deviceInfo?.productType?.toString() || '0',
      sno: currentDevice.BlueTooth_devices?.deviceInfo?.sn || '',
      text: text,
      to: AppStorage.get('to_languages') ? AppStorage.get('to_languages') as string : 'EN_US'
    };

    _translate(params).then((res) => {
      console.log('翻译请求成功————翻译结果：' + res.data?.transText, type);
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
                  // 语音输入模式 - 安全检查设备访问
                  if (currentDevice?.BlueTooth_devices) {
                    currentDevice.BlueTooth_devices.send([0x20, 0x01, 0x19])
                      .then(() => {
                        console.error('执行粘贴操作: ' + dataArray.transText);
                        Float_Window.showVoiceTranslation = false;
                        if (currentDevice.BlueTooth_devices.audioDataState) {
                          currentDevice.BlueTooth_devices.send([0x63]);
                          currentDevice.BlueTooth_devices.audioDataState = !currentDevice.BlueTooth_devices.audioDataState;
                        }
                        setTimeout(() => {
                          systemPasteboard.clearData();
                        }, PASTEBOARD_CLEAR_DELAY_MS);
                      });
                  } else {
                    console.warn('设备对象无效，跳过粘贴操作');
                  }
                }, TRANSLATION_EXECUTE_DELAY_MS);
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

    // 立即清理定时器和状态
    this.cleanupIntervals();
    this.isSending = false;
    this.isClosing = true;

    if (this.ws && this.isConnected) {
      try {
        console.log('正在关闭WebSocket连接...');

        // 先发送结束标记
        this.sendEndMarker();

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
        }, END_MARKER_DELAY_MS);

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

  private cleanupIntervals(): void {
    if (this.sendIntervalId !== null) {
      clearInterval(this.sendIntervalId);
      this.sendIntervalId = null;
    }
    if (this.completionCheckId !== null) {
      clearInterval(this.completionCheckId);
      this.completionCheckId = null;
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

  // 优化的Base64编码实现，使用查找表提高性能
  private base64Encode(uint8Array: Uint8Array): string {
    if (!uint8Array || uint8Array.length === 0) {
      return '';
    }

    try {
      // 使用更高效的编码方式
      const length = uint8Array.length;
      const outputLength = Math.ceil(length / 3) * 4;
      let output = '';

      for (let i = 0; i < length; i += 3) {
        const byte1 = uint8Array[i];
        const byte2 = i + 1 < length ? uint8Array[i + 1] : 0;
        const byte3 = i + 2 < length ? uint8Array[i + 2] : 0;

        // 使用位运算进行编码
        output += BASE64_CHARS.charAt(byte1 >> 2);
        output += BASE64_CHARS.charAt(((byte1 & 0x3) << 4) | (byte2 >> 4));

        if (i + 1 < length) {
          output += BASE64_CHARS.charAt(((byte2 & 0xf) << 2) | (byte3 >> 6));
        } else {
          output += '=';
        }

        if (i + 2 < length) {
          output += BASE64_CHARS.charAt(byte3 & 0x3f);
        } else {
          output += '=';
        }
      }

      return output;
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

  // 将音频数据分片为1024字节的块
  private chunkAudioData(audioData: Int16Array[]): Int16Array[] {
    const chunks: Int16Array[] = [];

    // 将所有音频数据合并为一个大的Int16Array
    let totalLength = 0;
    for (const frame of audioData) {
      totalLength += frame.length;
    }

    console.log(`蓝牙分片前总采样点数: ${totalLength}, 总字节数: ${totalLength * 2}`);

    const combinedData = new Int16Array(totalLength);
    let offset = 0;
    for (const frame of audioData) {
      combinedData.set(frame, offset);
      offset += frame.length;
    }

    // 按512个采样点（1024字节）分块
    for (let i = 0; i < combinedData.length; i += SAMPLES_PER_CHUNK) {
      const endIndex = Math.min(i + SAMPLES_PER_CHUNK, combinedData.length);
      const chunk = combinedData.slice(i, endIndex);
      chunks.push(chunk);
      console.log(`蓝牙生成分片 ${chunks.length}: ${chunk.length}采样点 (${chunk.length * 2}字节)`);
    }

    console.log(`蓝牙总共生成 ${chunks.length} 个分片`);
    return chunks;
  }

  // 延迟函数
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  // ========== 优化的1024字节分片发送方法 ==========

  private startRealTimeAudioSending(): void {
    console.log('开始实时音频发送 - 1024字节分片');

    // 立即发送现有数据
    this.sendExistingDataImmediately();

    // 设置实时监听新数据
    this.setupRealTimeListener();

    // 设置完成检测
    this.setupCompletionDetection();
  }

  private async sendExistingDataImmediately(): Promise<void> {
    if (this.audioData.length === 0) {
      return;
    }

    console.log(`立即发送现有数据: ${this.audioData.length} 帧`);

    try {
      this.isSending = true;

      // 分片处理现有数据为1024字节块
      const chunks = this.chunkAudioData(this.audioData);
      console.log(`生成 ${chunks.length} 个1024字节分片`);

      for (let chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
        if (this.isClosing) {
          break;
        }

        const chunk = chunks[chunkIndex];
        console.log(`蓝牙发送分片 ${chunkIndex + 1}/${chunks.length}, 大小: ${chunk.length} 采样点`);
        await this.sendAudioChunk(chunk, chunkIndex, chunks.length);

        // 控制发送速率
        if (chunkIndex < chunks.length - 1) {
          await this.delay(SEND_INTERVAL_MS);
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
      if (this.isSending || this.isClosing) {
        return;
      }

      // 检查是否有新数据
      if (this.audioData.length > this.lastSentIndex) {
        await this.sendNewDataImmediately();
      }
    }, CHECK_INTERVAL_MS) as number;
  }

  private async sendNewDataImmediately(): Promise<void> {
    const newDataCount = this.audioData.length - this.lastSentIndex;
    if (newDataCount <= 0 || this.isSending || this.isClosing) {
      return;
    }

    try {
      this.isSending = true;

      const newData = this.audioData.slice(this.lastSentIndex);
      const chunks = this.chunkAudioData(newData);

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
            await this.delay(SEND_INTERVAL_MS);
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

    this.completionCheckId = setInterval(() => {
      if (this.isClosing) {
        this.cleanupIntervals();
        return;
      }

      const currentLength = this.audioData.length;

      // 只有在至少有指定数量的数据包后才开始检测完成
      if (currentLength < MIN_DATA_PACKETS) {
        console.log(`蓝牙数据包不足(${currentLength})，继续等待...`);
        return;
      }

      if (currentLength === lastDataLength) {
        stableCount++;
        console.log(`蓝牙数据稳定计数: ${stableCount}/${MAX_STABLE_COUNT}`);

        if (stableCount >= MAX_STABLE_COUNT) {
          console.log('蓝牙数据稳定，发送结束标记');
          this.sendEndMarker();
          this.cleanupIntervals();
        }
      } else {
        stableCount = 0;
        lastDataLength = currentLength;
        console.log(`蓝牙接收到新数据，当前长度: ${currentLength}`);
      }
    }, CHECK_INTERVAL_MS) as number;
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

      console.log(`蓝牙分片 ${chunkIndex} Base64长度: ${base64Audio.length}, 前50字符: ${base64Audio.substring(0, 50)}`);

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
    console.error('发送结束标记',JSON.stringify(endMessage.rate));

    this.sendMessage(endMessage);
    this.wending = true;
  }


  // 清理资源
  public destroy(): void {
    console.log('开始销毁AudioWebSocketHandler');
    this.disconnect();
    // 清理音频数据
    this.audioData = [];
    this.pendingChunks = [];
    this.isSending = false;
    this.ws = null;
    this.lastSentIndex = 0;
    this.isClosing = false;
    console.log('AudioWebSocketHandler资源已完全清理');
  }
}