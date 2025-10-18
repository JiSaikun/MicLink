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
  }

  public connect(): void {
    try {
      // 添加内存使用检查
      if (this.audioData && this.audioData.length > 1000) {
        console.warn('音频数据量较大，可能存在内存风险:', this.audioData.length);
      }
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

          // 使用更安全的数据发送方式
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
            // setTimeout(() => {
            //   Float_Window.minimize_float_window()
            // }, 2000)
          }
        } else {
          AppStorage.setOrCreate('voiceInputText', res.data.text);
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
        // setTimeout(() => {
        //   Float_Window.minimize_float_window()
        // }, 2000)
        // 语音输入模式
        Communication.getDeviceInfo([0x20, 0x01, 0x19])
          .then(() => {
            this.wending=false
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

  // 修复后的Base64编码实现
  private base64Encode(uint8Array: Uint8Array): string {
    if (!uint8Array || uint8Array.length === 0) {
      return '';
    }

    let result = '';
    let i = 0;
    const length = uint8Array.length;

    try {
      while (i < length) {
        // 安全地获取字节，确保不越界
        const byte1 = uint8Array[i] || 0;
        const byte2 = (i + 1) < length ? uint8Array[i + 1] : 0;
        const byte3 = (i + 2) < length ? uint8Array[i + 2] : 0;

        // 转换为Base64字符
        const enc1 = byte1 >> 2;
        const enc2 = ((byte1 & 0x03) << 4) | (byte2 >> 4);
        const enc3 = ((byte2 & 0x0F) << 2) | (byte3 >> 6);
        const enc4 = byte3 & 0x3F;

        result += this.base64Chars.charAt(enc1);
        result += this.base64Chars.charAt(enc2);
        result += (i + 2) < length ? this.base64Chars.charAt(enc3) : '=';
        result += (i + 3) < length ? this.base64Chars.charAt(enc4) : '=';

        i += 3;
      }
    } catch (error) {
      console.error('Base64编码错误:', error);
      return '';
    }

    return result;
  }

  // 将Int16Array转换为Base64编码
  private int16ToBase64(int16Array: Int16Array): string {
    // 添加更严格的输入验证
    if (!int16Array || int16Array.length === 0) {
      console.warn('提供了空的或无效的Int16Array');
      return '';
    }

    try {
      // 添加长度限制，防止内存溢出
      const maxLength = 48000; // 根据实际需求调整最大长度
      const safeLength = Math.min(int16Array.length, maxLength);

      // 使用更安全的方式创建 ArrayBuffer
      let buffer: ArrayBuffer;
      try {
        buffer = new ArrayBuffer(safeLength * 2);
      } catch (memoryError) {
        console.error('内存分配失败:', memoryError);
        return '';
      }

      const byteArray = new Uint8Array(buffer);

      // 使用更安全的循环，添加边界检查
      for (let i = 0; i < safeLength; i++) {
        try {
          // 确保值在Int16范围内并进行安全转换
          const value = Math.max(-32768, Math.min(32767, int16Array[i]));

          // 安全地计算字节位置
          const byteIndex = i * 2;
          if (byteIndex + 1 < byteArray.length) {
            byteArray[byteIndex] = value & 0xFF;
            byteArray[byteIndex + 1] = (value >> 8) & 0xFF;
          } else {
            console.warn(`字节索引越界: i=${i}, byteIndex=${byteIndex}`);
            break;
          }
        } catch (valueError) {
          console.warn(`处理第 ${i} 个值时出错:`, valueError);
          continue;
        }
      }

      return this.base64Encode(byteArray);
    } catch (error) {
      console.error('Int16到Base64转换错误:', error);
      return '';
    }
  }

  private startSafeAudioSending(): void {
    let lastDataLength = Communication.audioData.length;
    let stableCount = 0;
    const maxStableCount = 2; // 连续2次数据不变认为稳定

    this.sendIntervalId = setInterval(() => {
      try {
        const currentLength = Communication.audioData.length;

        if (currentLength === lastDataLength) {
          stableCount++;
        } else {
          stableCount = 0;
          lastDataLength = currentLength;
        }

        // 发送当前数据
        if (currentLength > 0) {
          this.sendAudioDataSafe(Communication.audioData);
        }

        // 检查是否稳定且需要结束
        if (stableCount >= maxStableCount) {
          setTimeout(() => {
            this.wending = true;
          }, 500)
          if (this.sendIntervalId) {
            clearInterval(this.sendIntervalId);
            this.sendIntervalId = null;
          }
          console.log('音频数据发送完成');
        }

      } catch (error) {
        console.error('音频发送错误:', error);
        this.cleanupSendInterval();
      }
    }, 500) as number;
  }

  private sendAudioDataSafe(audioData: Int16Array[]): void {
    if (!audioData || audioData.length === 0) {
      console.warn('音频数据为空，跳过发送');
      return;
    }

    // 创建数据副本，避免竞争条件
    const dataCopy = this.createAudioDataCopy(audioData);

    for (let a = 0; a < dataCopy.length; a++) {
      try {
        // 添加数据验证
        if (!dataCopy[a] || !(dataCopy[a] instanceof Int16Array)) {
          console.warn(`无效的音频数据在索引: ${a}`);
          continue;
        }

        const isStart = a === 0;
        const isEnd = a === dataCopy.length - 1;

        // 添加空数组检查
        if (dataCopy[a].length === 0) {
          console.warn('空音频数据在索引:', a);
          continue;
        }

        // 限制单次发送的数据大小
        const maxChunkSize = 16000; // 根据服务器限制调整
        let audioChunk = dataCopy[a];

        if (audioChunk.length > maxChunkSize) {
          console.warn(`音频块过大: ${audioChunk.length}, 将被截断`);
          audioChunk = audioChunk.slice(0, maxChunkSize);
        }

        const base64Audio = this.int16ToBase64(audioChunk);

        if (!base64Audio) {
          console.warn('Base64编码失败，跳过帧:', a);
          continue;
        }

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
          console.error('发送音频数据失败，帧:', a);
          // 不立即退出，继续尝试发送其他帧
        }

        if (isEnd) {
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

        // 添加小的延迟，避免快速连续发送导致内存压力
        if (a % 10 === 0) {
          this.delay(1);
        }
      } catch (error) {
        console.error(`处理音频帧 ${a} 错误:`, error);
        // 继续处理下一帧而不是停止整个发送过程
        continue;
      }
    }
  }
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  private createAudioDataCopy(audioData: Int16Array[]): Int16Array[] {
    if (!audioData || !Array.isArray(audioData)) {
      console.warn('无效的音频数据输入');
      return [];
    }

    const result: Int16Array[] = [];

    try {
      for (let i = 0; i < audioData.length; i++) {
        const arr = audioData[i];
        if (arr && arr instanceof Int16Array && arr.length > 0) {
          // 限制单个数组的最大长度
          const maxSubArrayLength = 48000;
          const safeLength = Math.min(arr.length, maxSubArrayLength);
          result.push(new Int16Array(arr.buffer, 0, safeLength));
        } else {
          console.warn(`跳过无效的音频数据索引 ${i}`);
        }
      }
    } catch (error) {
      console.error('创建音频数据副本失败:', error);
    }

    return result;
  }

  // 清理资源
  public destroy(): void {
    this.disconnect();
    this.cleanupSendInterval();
    this.audioData = [];
    this.ws = null;
  }
}