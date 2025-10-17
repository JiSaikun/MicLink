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
  // Base64编码表，用于自定义Base64编码实现
  private base64Chars: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  // constructor(serverUrl: string, audioData: Int16Array[], inputMessage: inputMessageModel) {
  //   this.serverUrl = serverUrl;
  //   this.audioData = audioData;
  //   this.inputMessage = inputMessage;
  // }

  constructor(serverUrl: string, audioData: Int16Array[], state: number, inputMessage: inputMessageModel) {
    this.serverUrl = serverUrl;
    this.audioData = audioData;
    this.state = state;
    this.inputMessage = inputMessage;
  }


  public connect(): void {
    try {

      let voiceInputText = AppStorage.get('voiceInputText') as string
      console.log('*************************进入webSocket连接************************', typeof this.ws)
      if (this.ws) {
        this.disconnect();
      }

      this.ws = webSocket.createWebSocket();

      this.ws.on('open', (err: BusinessError, value: Object) => {
        if (!err) {
          this.isConnected = true;
          console.log("连接已打开，状态:" + JSON.stringify(value));
          console.log('*******************************语音数据长度：', this.audioData.length)
          this.sendAudioData(this.audioData)
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
            // console.error(JSON.stringify(AppStorage.get('voiceInputText')) + '33333333333333333333333333333333333')
          }
          if (res.status === 200 && (res.data.type === 'LAST' || res.data.type === "FIN")) {
            // AppStorage.setOrCreate('audioToText_res', res.data.text)
            let audioToText_res: string = res.data.text
            if (!audioToText_res) {
              return;
            }
            try {
              const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, audioToText_res);
              let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard(); //获取系统剪贴板对象。
              // systemPasteboard.setAppShareOptions(pasteboard.ShareOption.INAPP);
              systemPasteboard.setData(pasteData)
                .then(() => {
                  console.info('文本已复制到剪贴板: ' + audioToText_res);
                  let atManager = abilityAccessCtrl.createAtManager();
                  try {
                    atManager.requestPermissionsFromUser(AppStorage.get('context'), ['ohos.permission.READ_PASTEBOARD'])
                  } catch (err) {
                    console.error(`权限申请失败: ${err.code}, ${err.message}`);
                  }
                  systemPasteboard.getData().then((pasteData: pasteboard.PasteData) => {
                    console.error(JSON.stringify(pasteData.getRecordCount()))
                    let text: string = pasteData.getPrimaryText();
                    // console.log('111111111111111', text, this.state)
                    if (this.state === 0) { //:语音输入
                      Communication.getDeviceInfo([0x20, 0x01, 0x19])
                        .then(() => {
                          setTimeout(() => {
                            systemPasteboard.clearData() //清空剪贴板
                          }, 2000)
                        })
                    }
                    if (this.state === 1) { //语音翻译
                      let params: translate_Params = {
                        appkey: (AppStorage.get('getModelInfo') as getModelInfoModel).appkey, //获取用户按键模式详情中得到
                        from: AppStorage.get('from_languages') ? AppStorage.get('from_languages') as string :
                          'ZH_CN', //源语言___后面配置
                        productCode: Communication.deviceInfo.productType.toString(), //产品编码
                        sno: Communication.deviceInfo.sn, //设备号
                        text: text, //翻译内容
                        to: AppStorage.get('to_languages') ? AppStorage.get('to_languages') as string :
                          'EN_US' //翻译语言___后面配置
                      }
                      _translate(params).then((res) => {
                        console.log('翻译请求成功————翻译结果：' + res.data?.transText)
                        if (res.data) {
                          let dataArray = AppStorage.get('voiceTranslationText') as translate_Response
                          dataArray= {
                            transText: res.data?.transText as string,
                            text: res.data?.text as string,
                          }
                          AppStorage.setOrCreate('voiceTranslationText', dataArray)
                          // const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, res.data?.transText);
                          // systemPasteboard.setData(pasteData).then(() => {
                          //   Communication.getDeviceInfo([0x20, 0x01, 0x19])
                          //     .then(() => {
                          systemPasteboard.clearData() //清空剪贴板
                          //     })
                          // })
                        } else {
                          AppStorage.setOrCreate('flax_yuyinfanyi_chachaobudaoyuyan',
                            !AppStorage.get('flax_yuyinfanyi_chachaobudaoyuyan'))
                        }

                      })
                    }
                    // setTimeout(() => { //移除一条条目
                    //   pasteData.removeRecord(0)
                    //   // let isRemove: boolean = pasteData.removeRecordAt(0);
                    //   // console.error(JSON.stringify(isRemove))
                    // }, 10)
                  }
                  )
                    .catch((err: BusinessError) => {
                      console.error('Failed to get PasteData. Cause: ' + err.message);
                    });
                })
                .catch((err: BusinessError) => {
                  console.error('复制失败: ' + err.message);
                });
            } catch (error) {
              console.error('复制操作异常: ' + error.message);
            }

          } else {
            console.error('响应异常')
          }
        } else {
          console.error("消息错误:" + JSON.stringify(err));
        }
      }
      )
      ;

      this.ws.on('close', (err: BusinessError, value: webSocket.CloseResult) => {
        this.isConnected = false;
        console.log(`连接已关闭，状态码: ${value.code}, 原因: ${value.reason}`);
      });

      this.ws.on('error', (err: BusinessError) => {
        console.error("发生错误: " + err.message);
      });

      console.warn('正在连接到服务器...')
      this.ws.connect(this.serverUrl, (err: BusinessError, value: boolean) => {
        if (!err) {
          console.warn("连接成功");
        } else {
          console.error("连接失败。错误信息:" + err.message);
        }
      });
    } catch (e) {

    }
  }

  public disconnect(): void {
    if (this.ws) {
      this.ws.close({
        code: 1000,
        reason: "客户端主动关闭"
      }, (err: BusinessError, value: boolean) => {
        if (!err) {
          console.log("连接已成功关闭");
        } else {
          console.error("关闭连接失败。错误信息: " + JSON.stringify(err));
        }
      }
      )
      ;
      this.ws = null;
      this.isConnected = false;
    }
  }

  public sendMessage(inputMessage: inputMessageModel): boolean {
    if (!this.isConnected || !this.ws) {
      console.error("未连接到服务器，无法发送消息")
      return false;
    }

    if (!inputMessage.content.trim()) {
      console.error("消息不能为空")
      return false;
    }
    try {
      this.ws.send(JSON.stringify(inputMessage), (err: BusinessError, value: boolean) => {
        if (err) {
          console.error("消息发送失败: " + err.message);
        } else {
          // console.error("消息发送成功~~~")
        }
      });

      return true;
    } catch (e) {
      console.error("未知错误：", e)
      return false;
    }

  }

  private arrayBufferToString(buffer: ArrayBuffer): string {
    const uint8Array: Uint8Array = new Uint8Array(buffer);
    let result: string = "";

    for (let i = 0; i < uint8Array.length; i++) {
      result += String.fromCharCode(uint8Array[i]);
    }

    return result;
  }

  // 自定义Base64编码实现，不依赖平台特定模块
  private base64Encode(uint8Array: Uint8Array):
    string {
    let result = '';
    let i = 0;
    const length = uint8Array.length;

    while (i < length) {
      // 取三个字节
      const byte1 = uint8Array[i++] || 0;
      const byte2 = i < length ? uint8Array[i++] : 0;
      const byte3 = i < length ? uint8Array[i++] : 0;

      // 拆分为4个6位值
      const enc1 = byte1 >> 2;
      const enc2 = ((byte1 & 0x03) << 4) | (byte2 >> 4);
      const enc3 = ((byte2 & 0x0F) << 2) | (byte3 >> 6);
      const enc4 = byte3 & 0x3F;

      // 转换为Base64字符
      result += this.base64Chars.charAt(enc1);
      result += this.base64Chars.charAt(enc2);
      result += i > length + 1 ? '=' : this.base64Chars.charAt(enc3);
      result += i > length ? '=' : this.base64Chars.charAt(enc4);
    }

    return result;
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

  private sendAudioData(audioData: Int16Array[]) {
    for (let a = 0; a < audioData.length; a++) {
      const isStart: boolean = a === 0;
      const isEnd: boolean = a === audioData.length - 1;

      // 将Int16Array转换为Base64编码的音频数据
      const base64Audio = this.int16ToBase64(audioData[a]);
      // console.log(`第${a+1}帧音频数据Base64长度:`, base64Audio.length);

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

      this.sendMessage(inputMessage);

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
    }
  }
}

/**
 * 响应数据记录
 */
// [
//   {
//     "data": {
//       "btype": false,
//       "clientId": "clientId1751968608",
//       "sn": "iat000d0ef1@dx19956d2f7747024802",
//       "text": "语",
//       "type": "MID"
//     },
//     "message": "操作成功",
//     "status": 200
//   },
//   {
//     "data": {
//       "btype": false,
//       "clientId": "clientId1751968608",
//       "sn": "iat000d0ef1@dx19956d2f7747024802",
//       "text": "语音",
//       "type": "MID"
//     },
//     "message": "操作成功",
//     "status": 200
//   },
//   {
//     "data": {
//       "btype": false,
//       "clientId": "clientId1751968608",
//       "sn": "iat000d0ef1@dx19956d2f7747024802",
//       "text": "语音测试，语音测试",
//       "type": "MID"
//     },
//     "message": "操作成功",
//     "status": 200
//   },
//   {
//     "data": {
//       "btype": false,
//       "clientId": "clientId1751968608",
//       "sn": "iat000d0ef1@dx19956d2f7747024802",
//       "text": "语音测试，语音测试。",
//       "type": "LAST"
//     },
//     "message": "操作成功",
//     "status": 200
//   }
// ]

