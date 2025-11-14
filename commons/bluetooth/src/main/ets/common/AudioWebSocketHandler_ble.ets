import { webSocket } from '@kit.NetworkKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { BusinessError } from '@kit.BasicServicesKit';
// import { inputMethodEngine } from '@kit.IMEKit';
import { getModelInfoModel } from 'config'
import { _translate, translate_Params, translate_Response, inputMessageModel } from 'mouse'
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
const CHECK_INTERVAL_MS: number = 50; // 从20ms增加到50ms，减少检测频率
const COMPLETION_CHECK_MS: number = 100;
const DISCONNECT_TIMEOUT_MS: number = 5000;
const END_MARKER_DELAY_MS: number = 100;
const PASTEBOARD_CLEAR_DELAY_MS: number = 2000;
const TRANSLATION_EXECUTE_DELAY_MS: number = 50;
const MIN_DATA_PACKETS: number = 3;
const MAX_STABLE_COUNT: number = 30; // 从75减少到30次（1500ms无新数据），减少检测次数
const MIN_SAMPLES_FOR_COMPLETION: number = 1024; // 最小采样点数才开始检测完成（约0.064秒@16kHz）
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
  private lastSentSampleIndex: number = 0; // 记录已发送的采样点位置（全局）
  private completionCheckId: number | null = null;
  private isClosing: boolean = false; // 新增：标记是否正在关闭
  private lastSendTime: number = 0; // 添加：记录上次发送时间
  private lastCheckTime: number = 0; // 添加：记录上次检查时间
  private readonly MIN_SEND_INTERVAL: number = 10; // 最小发送间隔10ms
  private readonly MIN_CHECK_INTERVAL: number = 25; // 最小检查间隔25ms
  private cachedTotalSamples: number = 0; // 缓存总采样点数
  private lastCacheUpdateTime: number = 0; // 缓存更新时间
  private sessionStartTime: number = 0; // 会话开始时间
  private readonly MAX_SESSION_DURATION: number = 30000; // 最大会话持续时间30秒

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
      AppStorage.setOrCreate('changeText', false)
    } else {
      AppStorage.setOrCreate('voiceInputText', '')
      AppStorage.setOrCreate('linshi', '')
    }
    this.wending = false
    this.isSending = false;
    this.lastSentSampleIndex = 0;
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

          this.sessionStartTime = Date.now();
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

        if (devices && devices.length > 0 && deviceIndex >= 0 && deviceIndex < devices.length &&
          devices[deviceIndex]?.BlueTooth_devices) {
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
        let dataArray : translate_Response = {
          transText: res.data?.transText as string,
          text: res.data?.text as string,
        };
        AppStorage.setOrCreate('voiceTranslationText', dataArray);
        if (this.wending) {
          setTimeout(() => {
            AppStorage.setOrCreate('changeText', true)
          }, 2000)
        }
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
                          currentDevice.BlueTooth_devices.audioDataState =
                            !currentDevice.BlueTooth_devices.audioDataState;
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

  // 将音频数据分片为1024字节的块（连续分片，避免数据断开）
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

  // 获取连续的音频分片，从全局采样点位置开始
  private getContinuousAudioChunks(): Int16Array[] {
    const chunks: Int16Array[] = [];

    // 计算总采样点数
    let totalSamples = 0;
    for (let i = 0; i < this.audioData.length; i++) {
      totalSamples += this.audioData[i].length;
    }

    // 如果没有新数据，返回空数组
    if (totalSamples <= this.lastSentSampleIndex) {
      return chunks;
    }

    // 创建合并的数据缓冲区
    const combinedData = new Int16Array(totalSamples);
    let offset = 0;
    for (const frame of this.audioData) {
      combinedData.set(frame, offset);
      offset += frame.length;
    }

    // 从上次发送的位置开始连续分片
    for (let i = this.lastSentSampleIndex; i < combinedData.length; i += SAMPLES_PER_CHUNK) {
      const endIndex = Math.min(i + SAMPLES_PER_CHUNK, combinedData.length);
      const chunk = combinedData.slice(i, endIndex);
      chunks.push(chunk);
      console.log(`蓝牙连续分片 ${chunks.length}: 从采样点${i}到${endIndex - 1}, 大小: ${chunk.length}采样点`);
    }

    console.log(`蓝牙连续分片总共生成 ${chunks.length} 个分片，从全局采样点${this.lastSentSampleIndex}开始`);
    return chunks;
  }

  // 延迟函数
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  // 获取总采样点数（带缓存优化）
  private getTotalSamples(): number {
    const currentTime = Date.now();
    // 缓存5ms内的计算结果，避免频繁计算
    if (currentTime - this.lastCacheUpdateTime < 5) {
      return this.cachedTotalSamples;
    }

    let totalSamples = 0;
    for (let i = 0; i < this.audioData.length; i++) {
      totalSamples += this.audioData[i].length;
    }

    this.cachedTotalSamples = totalSamples;
    this.lastCacheUpdateTime = currentTime;
    return totalSamples;
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

      // 使用连续分片处理现有数据
      const chunks = this.getContinuousAudioChunks();
      console.log(`生成 ${chunks.length} 个连续1024字节分片`);

      for (let chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
        if (this.isClosing) {
          break;
        }

        const chunk = chunks[chunkIndex];
        console.log(`蓝牙发送分片 ${chunkIndex + 1}/${chunks.length}, 大小: ${chunk.length} 采样点`);
        await this.sendAudioChunk(chunk, chunkIndex, chunks.length);

        // 更新全局采样点位置
        this.lastSentSampleIndex += chunk.length;

        // 控制发送速率
        if (chunkIndex < chunks.length - 1) {
          await this.delay(SEND_INTERVAL_MS);
        }
      }

      console.log(`现有数据发送完成，最后发送采样点位置: ${this.lastSentSampleIndex}`);


    } catch (error) {
      console.error('发送现有数据错误:', error);
    } finally {
      this.isSending = false;
    }
  }

  private setupRealTimeListener(): void {
    console.log('设置实时监听器');

    this.sendIntervalId = setInterval(async () => {
      try {
        // 检查对象是否仍然有效（防止GC后的访问）
        if (!this || this.isClosing) {
          return;
        }

        if (this.isSending) {
          return;
        }

        // 添加节流控制：确保最小发送间隔
        const currentTime = Date.now();
        if (currentTime - this.lastSendTime < this.MIN_SEND_INTERVAL) {
          return;
        }

        // 检查会话是否超时，强制清理资源
        if (currentTime - this.sessionStartTime > this.MAX_SESSION_DURATION) {
          console.warn('音频处理会话超时，强制清理资源');
          if (this && this.cleanupIntervals) {
            this.cleanupIntervals();
          }
          return;
        }

        // 检查是否有新数据（基于采样点总数）
        const totalSamples = this.getTotalSamples();

        if (totalSamples > this.lastSentSampleIndex) {
          this.lastSendTime = currentTime;
          await this.sendNewDataImmediately();
        }
      } catch (error) {
        console.error('蓝牙实时监听器回调异常:', error);
        // 如果出现异常，清理定时器
        if (this && this.cleanupIntervals) {
          this.cleanupIntervals();
        }
      }
    }, CHECK_INTERVAL_MS) as number;
  }

  private async sendNewDataImmediately(): Promise<void> {
    // 计算总采样点数来检查是否有新数据
    const totalSamples = this.getTotalSamples();

    if (totalSamples <= this.lastSentSampleIndex || this.isSending || this.isClosing) {
      return;
    }

    try {
      this.isSending = true;

      // 使用连续分片获取新数据
      const chunks = this.getContinuousAudioChunks();

      if (chunks.length > 0) {
        console.log(`发送 ${chunks.length} 个新数据连续分片`);

        for (let chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
          if (this.isClosing) {
            break;
          }

          const chunk = chunks[chunkIndex];
          await this.sendAudioChunk(chunk, chunkIndex, chunks.length);

          // 更新全局采样点位置
          this.lastSentSampleIndex += chunk.length;

          // 最小延迟
          if (chunkIndex < chunks.length - 1) {
            await this.delay(SEND_INTERVAL_MS);
          }
        }
      }

      console.log(`新数据发送完成，当前采样点位置: ${this.lastSentSampleIndex}`);


    } catch (error) {
      console.error('发送新数据错误:', error);
    } finally {
      this.isSending = false;
    }
  }

  private setupCompletionDetection(): void {
    console.log('设置完成检测');

    let lastTotalSamples = this.getTotalSamples();
    let stableCount = 0;

    this.completionCheckId = setInterval(() => {
      try {
        // 检查对象是否仍然有效（防止GC后的访问）
        if (!this || this.isClosing) {
          if (this && this.cleanupIntervals) {
            this.cleanupIntervals();
          }
          return;
        }

        // 添加节流控制：确保最小检查间隔
        const currentTime = Date.now();
        if (currentTime - this.lastCheckTime < this.MIN_CHECK_INTERVAL) {
          return;
        }

        // 检查会话是否超时，强制清理资源
        if (currentTime - this.sessionStartTime > this.MAX_SESSION_DURATION) {
          console.warn('完成检测会话超时，强制清理资源');
          if (this && this.cleanupIntervals) {
            this.cleanupIntervals();
          }
          return;
        }

        this.lastCheckTime = currentTime;

        // 计算当前总采样点数
        const currentTotalSamples = this.getTotalSamples();

        // 只有在至少有最小数据量后才开始检测完成，避免误判
        if (currentTotalSamples < MIN_SAMPLES_FOR_COMPLETION) {
          // 减少日志输出频率
          if (stableCount % 10 === 0) {
            console.log(`蓝牙采样点不足(${currentTotalSamples}/${MIN_SAMPLES_FOR_COMPLETION})，继续等待...`);
          }
          return;
        }

        if (currentTotalSamples === lastTotalSamples) {
          stableCount++;

          // 每200ms输出一次日志，减少日志量
          if (stableCount % 10 === 0 || stableCount >= MAX_STABLE_COUNT) {
            console.log(`蓝牙数据稳定计数: ${stableCount}/${MAX_STABLE_COUNT} (${stableCount * CHECK_INTERVAL_MS}ms)`);
          }

          if (stableCount >= MAX_STABLE_COUNT) {
            console.log(`蓝牙数据稳定超过${MAX_STABLE_COUNT * CHECK_INTERVAL_MS}ms，发送结束标记`);
            this.sendEndMarker();
            this.cleanupIntervals();
          }
        } else {
          if (stableCount > 0 && stableCount % 5 === 0) { // 减少日志输出
            console.log(`蓝牙接收到新数据，重置稳定计数 (之前: ${stableCount})，当前采样点数: ${currentTotalSamples}`);
          }
          stableCount = 0;
          lastTotalSamples = currentTotalSamples;
        }
      } catch (error) {
        console.error('蓝牙完成检测回调异常:', error);
        // 如果出现异常，清理定时器
        if (this && this.cleanupIntervals) {
          this.cleanupIntervals();
        }
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

      // 添加超时控制，防止长时间阻塞
      const timeoutPromise = new Promise<never>((_, reject) => {
        setTimeout(() => reject(new Error('发送音频分片超时')), 2000);
      });

      const sendPromise = new Promise<void>((resolve) => {
        try {
          const base64Audio = this.int16ToBase64(chunk);

          if (!base64Audio) {
            resolve();
            return;
          }

          // 减少日志输出频率，避免阻塞
          if (chunkIndex % 10 === 0 || chunkIndex < 3) {
            console.log(`蓝牙分片 ${chunkIndex}/${totalChunks} Base64长度: ${base64Audio.length}`);
          }

          const isStart = (chunkIndex === 0 && this.lastSentSampleIndex === 0);
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
          resolve();
        } catch (error) {
          console.error(`音频分片处理错误:`, error);
          resolve(); // 继续执行，不中断整个流程
        }
      });

      await Promise.race([sendPromise, timeoutPromise]);

    } catch (error) {
      console.error(`发送音频分片错误:`, error);
      // 如果是超时错误，标记为需要重试或跳过
      if (error.message && error.message.includes('超时')) {
        console.warn('音频分片发送超时，跳过此分片');
      }
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
    console.error('发送结束标记', JSON.stringify(endMessage.rate));

    this.sendMessage(endMessage);
    this.wending = true;
  }


  // 清理资源
  public destroy(): void {
    console.log('开始销毁AudioWebSocketHandler_ble');

    // 立即标记对象为无效状态，防止定时器回调继续执行
    this.isClosing = true;

    // 立即清理所有定时器，防止SIGSEGV
    this.cleanupIntervals();

    this.disconnect();
    // 清理音频数据
    this.audioData = [];
    this.pendingChunks = [];
    this.isSending = false;
    this.ws = null;
    this.lastSentSampleIndex = 0;
    console.log('AudioWebSocketHandler_ble资源已完全清理');
  }
}