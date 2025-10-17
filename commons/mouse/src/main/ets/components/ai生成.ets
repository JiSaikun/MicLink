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
  private wending: boolean = false //0:语音数据不再变化
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

  // 新增：稳定性改进的成员变量
  private timerId: number | null = null;
  private isSending: boolean = false;
  private reconnectAttempts: number = 0;
  private maxReconnectAttempts: number = 3;
  private shouldReconnect: boolean = true;
  private systemPasteboard: pasteboard.SystemPasteboard |null = null;

  // Base64编码表，用于自定义Base64编码实现
  private base64Chars: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  constructor(serverUrl: string, audioData: Int16Array[], state: number, inputMessage: inputMessageModel) {
    this.serverUrl = serverUrl;
    this.audioData = audioData;
    this.state = state;
    this.inputMessage = inputMessage;
    AppStorage.setOrCreate('voiceInputText','')
    AppStorage.setOrCreate('voiceTranslationText',{
      transText: '',
      text: ''
    })
  }

  public connect(): void {
    try {
      console.log('*************************进入webSocket连接************************')

      // 清理之前的连接和资源
      this.cleanup();

      let voiceInputText = AppStorage.get('voiceInputText') as string

      if (this.ws) {
        this.disconnect();
      }

      this.ws = webSocket.createWebSocket();

      // 设置事件监听器
      this.setupEventListeners();

      console.warn('正在连接到服务器...')
      this.ws.connect(this.serverUrl, (err: BusinessError, value: boolean) => {
        if (!err) {
          console.warn("连接成功");
        } else {
          console.error("连接失败。错误信息:" + err.message);
          this.handleReconnection();
        }
      });
    } catch (e) {
      console.error("连接异常: " + e.message);
      this.handleReconnection();
    }
  }

  private setupEventListeners(): void {
    if (!this.ws) return;

    this.ws.on('open', (err: BusinessError, value: Object) => {
      if (!err) {
        this.isConnected = true;
        this.reconnectAttempts = 0; // 重置重连计数
        console.error("连接已打开，状态:" + JSON.stringify(value));
        console.error('*******************************语音数据长度：', this.audioData.length)

        this.startAudioDataSending();
      } else {
        console.error("连接错误:" + JSON.stringify(err));
        this.handleReconnection();
      }
    });

    this.ws.on('message', (err: BusinessError, value: string | ArrayBuffer) => {
      if (!err) {
        this.handleMessage(value);
      } else {
        console.error("消息错误:" + JSON.stringify(err));
      }
    });

    this.ws.on('close', (err: BusinessError, value: webSocket.CloseResult) => {
      this.isConnected = false;
      this.cleanupTimer();
      console.log(`连接已关闭，状态码: ${value.code}, 原因: ${value.reason}`);

      // 如果不是正常关闭，尝试重连
      if (value.code !== 1000 && this.shouldReconnect && this.reconnectAttempts < this.maxReconnectAttempts) {
        this.handleReconnection();
      }
    });

    this.ws.on('error', (err: BusinessError) => {
      console.error("WebSocket发生错误: " + err.message);
      this.isConnected = false;
      this.cleanupTimer();
    });
  }

  private handleMessage(value: string | ArrayBuffer): void {
    let message: string;
    if (typeof value === 'string') {
      message = value;
    } else {
      message = this.arrayBufferToString(value);
    }
    console.error("收到消息，内容:" + message);

    try {
      let res: res_moudel = JSON.parse(message)
      if (res.status === 200 && this.state === 0) {
        if (AppStorage.get('isAI_assistant')) {
          if (res.data.type === 'LAST' || res.data.type === "FIN") {
            AppStorage.setOrCreate('voiceInputText', res.data.text)
            return
          }
        } else {
          AppStorage.setOrCreate('voiceInputText', res.data.text)
        }
      }

      if (res.status === 200 && (res.data.type === 'LAST' || res.data.type === "FIN")) {
        this.handleFinalResult(res.data.text);
      } else {
        console.error('响应异常')
      }
    } catch (parseError) {
      console.error("解析消息失败: " + parseError.message);
    }
  }

  private handleFinalResult(audioToText_res: string): void {
    if (!audioToText_res) {
      AppStorage.setOrCreate('voiceInputText', '未识别到语音')
      return;
    }

    try {
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, audioToText_res);
      let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      this.systemPasteboard=systemPasteboard
      systemPasteboard.setData(pasteData)
        .then(() => {
          console.info('文本已复制到剪贴板: ' + audioToText_res);
          this.processClipboardData(systemPasteboard, audioToText_res);
        })
        .catch((err: BusinessError) => {
          console.error('复制失败: ' + err.message);
        });
    } catch (error) {
      console.error('复制操作异常: ' + error.message);
    }
  }

  private processClipboardData(systemPasteboard: pasteboard.SystemPasteboard, originalText: string): void {
    let atManager = abilityAccessCtrl.createAtManager();
    try {
      atManager.requestPermissionsFromUser(AppStorage.get('context'), ['ohos.permission.READ_PASTEBOARD'])
    } catch (err) {
      console.error(`权限申请失败: ${err.code}, ${err.message}`);
    }

    systemPasteboard.getData().then((pasteData: pasteboard.PasteData) => {
      console.error(JSON.stringify(pasteData.getRecordCount()))
      let text: string = pasteData.getPrimaryText();

      if (this.state === 0 && this.wending) {
        // 语音输入模式
        Communication.getDeviceInfo([0x20, 0x01, 0x19])
          .then(() => {
            setTimeout(() => {
              systemPasteboard.clearData()
            }, 2000)
          })
        return
      }

      if (this.state === 1) {
        // 语音翻译模式
        this.handleTranslation(text);
      }
    })
      .catch((err: BusinessError) => {
        console.error('Failed to get PasteData. Cause: ' + err.message);
      });
  }

  private handleTranslation(text: string): void {
    let params: translate_Params = {
      appkey: (AppStorage.get('getModelInfo') as getModelInfoModel).appkey,
      from: AppStorage.get('from_languages') ? AppStorage.get('from_languages') as string : 'ZH_CN',
      productCode: Communication.deviceInfo.productType.toString(),
      sno: Communication.deviceInfo.sn,
      text: text,
      to: AppStorage.get('to_languages') ? AppStorage.get('to_languages') as string : 'EN_US'
    }

    _translate(params).then((res) => {
      console.log('翻译请求成功————翻译结果：' + res.data?.transText)
      if (res.data) {
        let dataArray: translate_Response = {
          transText: res.data?.transText as string,
          text: res.data?.text as string,
        }
        AppStorage.setOrCreate('voiceTranslationText', dataArray);
        (this.systemPasteboard as pasteboard.SystemPasteboard).clearData()
      } else {
        AppStorage.setOrCreate('flax_yuyinfanyi_chachaobudaoyuyan',
          !AppStorage.get('flax_yuyinfanyi_chachaobudaoyuyan'))
      }
    })
  }

  private startAudioDataSending(): void {
    if (!this.isConnected) {
      return;
    }

    let lastDataLength = Communication.audioData.length;
    let checkCount = 0;
    const maxCheckCount = 5; // 最多检查5次无变化就停止

    this.timerId = setInterval(() => {
      // 检查连接状态
      if (!this.isConnected || !this.ws) {
        this.cleanupTimer();
        return;
      }

      // 检查数据是否变化
      const currentLength = Communication.audioData.length;
      if (currentLength === lastDataLength) {
        checkCount++;
        if (checkCount >= maxCheckCount) {
          console.error('信息停止发送，数据稳定')
          this.cleanupTimer();
          this.wending = true;
          return;
        }
      } else {
        checkCount = 0; // 重置计数
      }

      lastDataLength = currentLength;

      // 安全发送数据
      this.sendAudioDataSafely(Communication.audioData);
    }, 2000);
  }

  private sendAudioDataSafely(audioData: Int16Array[]): void {
    if (!this.isConnected || !this.ws || this.isSending) {
      return;
    }

    try {
      this.isSending = true;
      this.sendAudioData(audioData);
    } catch (error) {
      console.error('发送音频数据出错: ' + error.message);
      this.isConnected = false;
      this.cleanupTimer();
    } finally {
      this.isSending = false;
    }
  }

  private handleReconnection(): void {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.error('达到最大重连次数，停止重连');
      promptAction.showToast({
        message: '网络连接失败，请检查网络后重试',
        duration: 3000
      });
      return;
    }

    this.reconnectAttempts++;
    console.log(`尝试第 ${this.reconnectAttempts} 次重连...`);

    setTimeout(() => {
      if (!this.isConnected && this.shouldReconnect) {
        this.connect();
      }
    }, 2000 * this.reconnectAttempts);
  }

  private cleanupTimer(): void {
    if (this.timerId) {
      clearInterval(this.timerId);
      this.timerId = null;
    }
  }

  private cleanup(): void {
    this.cleanupTimer();
    this.isSending = false;
    this.wending = false;
  }

  public disconnect(): void {
    this.shouldReconnect = false;
    this.cleanup();

    if (this.ws) {
      try {
        // 移除所有事件监听器
        this.ws.off('open');
        this.ws.off('message');
        this.ws.off('close');
        this.ws.off('error');

        this.ws.close({
          code: 1000,
          reason: "客户端主动关闭"
        }, (err: BusinessError, value: boolean) => {
          if (!err) {
            console.log("连接已成功关闭");
          } else {
            console.error("关闭连接失败。错误信息: " + JSON.stringify(err));
          }
        });
      } catch (error) {
        console.error("关闭连接时发生错误: " + error.message);
      } finally {
        this.ws = null;
        this.isConnected = false;
      }
    }
  }

  public sendMessage(inputMessage: inputMessageModel): boolean {
    if (!this.isConnected || !this.ws) {
      console.error("未连接到服务器，无法发送消息")
      return false;
    }

    if (!inputMessage.content || !inputMessage.content.trim()) {
      console.error("消息内容为空")
      return false;
    }

    try {
      this.ws.send(JSON.stringify(inputMessage), (err: BusinessError, value: boolean) => {
        if (err) {
          console.error("消息发送失败: " + err.message);
          this.isConnected = false;
          this.handleReconnection();
        }
      });
      return true;
    } catch (e) {
      console.error("发送消息未知错误：", e)
      this.isConnected = false;
      this.handleReconnection();
      return false;
    }
  }

  public destroy(): void {
    this.disconnect();
    this.audioData = [];
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
      console.error("ArrayBuffer转换字符串失败: " + error.message);
      return "";
    }
  }

  // 优化的Base64编码实现，添加错误处理
  private base64Encode(uint8Array: Uint8Array): string {
    if (!uint8Array || uint8Array.length === 0) {
      return '';
    }

    let result = '';
    let i = 0;
    const length = uint8Array.length;

    try {
      while (i < length) {
        const byte1 = uint8Array[i++] || 0;
        const byte2 = i < length ? uint8Array[i++] : 0;
        const byte3 = i < length ? uint8Array[i++] : 0;

        const enc1 = byte1 >> 2;
        const enc2 = ((byte1 & 0x03) << 4) | (byte2 >> 4);
        const enc3 = ((byte2 & 0x0F) << 2) | (byte3 >> 6);
        const enc4 = byte3 & 0x3F;

        result += this.base64Chars.charAt(enc1);
        result += this.base64Chars.charAt(enc2);
        result += i > length + 1 ? '=' : this.base64Chars.charAt(enc3);
        result += i > length ? '=' : this.base64Chars.charAt(enc4);
      }
    } catch (error) {
      console.error('Base64编码错误: ' + error.message);
      return '';
    }

    return result;
  }

  // 将Int16Array转换为Base64编码
  private int16ToBase64(int16Array: Int16Array): string {
    if (!int16Array || int16Array.length === 0) {
      return '';
    }

    try {
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
    } catch (error) {
      console.error("Int16Array转Base64失败: " + error.message);
      return '';
    }
  }

  private sendAudioData(audioData: Int16Array[]) {
    if (!audioData || audioData.length === 0) {
      console.error('音频数据为空');
      return;
    }

    console.error('开始发送音频数据，帧数:', audioData.length);

    for (let a = 0; a < audioData.length; a++) {
      // 检查连接状态，如果断开则停止发送
      if (!this.isConnected || !this.ws) {
        console.error('连接已断开，停止发送音频数据');
        return;
      }

      const isStart: boolean = a === 0;
      const isEnd: boolean = a === audioData.length - 1;

      try {
        // 将Int16Array转换为Base64编码的音频数据
        const base64Audio = this.int16ToBase64(audioData[a]);
        if (!base64Audio) {
          console.error(`第${a+1}帧音频数据Base64编码失败`);
          continue;
        }

        // 显式创建对象
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
          console.error(`第${a+1}帧音频数据发送失败`);
          break;
        }

        if (isEnd) {
          // 使用显式接口定义的对象
          const logMessage: logMessageModel = {
            "start": inputMessage.start,
            "clientId": inputMessage.clientId,
            "ptt": inputMessage.ptt,
            "serialNo": inputMessage.serialNo,
            "phrases": inputMessage.phrases,
            "format": inputMessage.format,
            "apiKey": inputMessage.apiKey,
            "language": inputMessage.language,
            "end": inputMessage.end,
            "rate": inputMessage.rate,
            "deviceNo": inputMessage.deviceNo,
            "content": inputMessage.content.substring(0, 50) + "...[省略部分内容]"
          };
          console.log('最后一帧数据信息：', a.toString(), JSON.stringify(logMessage));
        }
      } catch (error) {
        console.error(`处理第${a+1}帧音频数据时发生错误: ` + error.message);
      }
    }
  }
}