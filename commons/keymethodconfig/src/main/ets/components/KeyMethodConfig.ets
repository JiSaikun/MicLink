import {
  Communication, DeviceInfo, AudioFileManager, AudioWebSocketHandler, inputMessageModel
} from 'mouse' //语音输入
import { WebSocket_serverUrl } from 'config'; //语音输入
import window from '@ohos.window'; //一键回到桌面————应用最小化
import { BusinessError } from '@ohos.base';
import common from '@ohos.app.ability.common'; //打开网页
import { Want } from '@kit.AbilityKit'; //打开网页


export class _KeyMethodConfig {
  /**
   * 语音输入
   */
  static voiceInput() {
    if (!Communication.audioDataState) {
      Communication.getDeviceInfo([0x62])
        .then(() => {
          Communication.audioData = []
          Communication.audioDataState = !Communication.audioDataState
        })
    } else {
      Communication.getDeviceInfo([0x63]).then(() => {
        Communication.audioDataState = !Communication.audioDataState
      })
      /**
       * 语音数据处理
       */
      //保存本地PCM文件
      // const context = AppStorage.get('context') as common.UIAbilityContext;
      // let a: AudioFileManager = new AudioFileManager(Communication.audioData, context)
      // console.log(Communication.audioData.length.toString(), '语音数据结束*****模拟')

      //WebSocket  语音数据处理
      let inputMessage: inputMessageModel = {
        start: false,
        "clientId": "clientId1751968608",
        "ptt": "1",
        "serialNo": Communication.deviceInfo.sn,
        "phrases": "",
        "format": "pcm",
        "apiKey": "ebb72c9db60147febd2ccd50a705de57",
        "language": "ZH_CN",
        "end": false,
        "rate": "16k",
        "deviceNo": "6c:b1:33:9f:b9:8b",
        content: ''
      }
      let audioToText: AudioWebSocketHandler =
        new AudioWebSocketHandler(WebSocket_serverUrl.audioToText, Communication.audioData,
          inputMessage) //语音转文字 websocket
      audioToText.connect()
    }
  }

  /**
   * 语音输入_长按按下
   */
  static voiceInput_long() {
    if (Communication.audioDataState) { //若开始长按时，有通过0x62命令开启的语音输入等，先进行关闭 ...否则改变audioDataState 采集状态，确保1b数据被放到语音数据里
      Communication.audioData = []
    } else {
      Communication.audioDataState = !Communication.audioDataState
    }
  }

  /**
   * 语音输入_长按抬起
   */
  static endvoiceInput_long() {
    Communication.audioDataState = !Communication.audioDataState
    /**
     * 语音数据处理
     */
    //保存本地PCM文件
    // const context = AppStorage.get('context') as common.UIAbilityContext;
    // let a: AudioFileManager = new AudioFileManager(Communication.audioData, context)
    // console.log(Communication.audioData.length.toString(), '语音数据结束*****模拟')

    //WebSocket  语音数据处理
    let inputMessage: inputMessageModel = {
      start: false,
      "clientId": "clientId1751968608",
      "ptt": "1",
      "serialNo": Communication.deviceInfo.sn,
      "phrases": "",
      "format": "pcm",
      "apiKey": "ebb72c9db60147febd2ccd50a705de57",
      "language": "ZH_CN",
      "end": false,
      "rate": "16k",
      "deviceNo": "6c:b1:33:9f:b9:8b",
      content: ''
    }
    let audioToText: AudioWebSocketHandler =
      new AudioWebSocketHandler(WebSocket_serverUrl.audioToText, Communication.audioData,
        inputMessage) //语音转文字 websocket
    audioToText.connect()
  }

  /**
   *回车/发送
   */
  static entry() {
    Communication.getDeviceInfo([0x20, 0, 0x28])
  }

  /**
   *删除
   */
  static delete() {
    Communication.getDeviceInfo([0x20, 0, 0x2A])
  }

  /**
   *打开网页 __百度
   */
  static openTheWebpage() {
    const context: common.UIAbilityContext = AppStorage.get('context') as common.UIAbilityContext;
    let want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: 'https://www.baidu.com/',
      parameters: {
        'ohos.ability.params.showDefaultPicker': true
      }
    };
    context.startAbility(want)
  }

  /**
   *ChatGPT
   */
  static openChatGPT() {
    let currpageIsAI: boolean = AppStorage.get('currpageIsAI') as boolean
    if (currpageIsAI) {
      let pageInfo: NavPathStack = AppStorage.get('pageInfo') as NavPathStack
      pageInfo.clear()
      pageInfo.pushPath({ name: 'aipage' })
      AppStorage.set('currpageIsAI', false)
    }
  }

  /**
   *回到桌面
   */
  static desktop() {
    Communication.getDeviceInfo([0x20, 0x08, 0x07])
  }

  /**
   *一键锁屏
   */
  static lockNow() {
    Communication.getDeviceInfo([0x20, 0x08, 0x0F])
  }

  /**
   *划词翻译
   */
  static word_SelectedTranslation() {
    Communication.getDeviceInfo([0x20, 0x01, 0x06]) //Ctrl+C
  }

  /**
   *DPI切换
   */
  static DPI_Switch() {
    let DPI_currInfo: DPI_currInfoModel = AppStorage.get('DPI_currInfo') as DPI_currInfoModel
    if (DPI_currInfo.curr === DPI_currInfo.length - 1) {
      DPI_currInfo.curr = 0
    } else {
      DPI_currInfo.curr += 1
    }
    AppStorage.setOrCreate('DPI_currInfo', DPI_currInfo)
    Communication.getDeviceInfo([0x68, DPI_currInfo.curr]).then(() => {
      let mouseconfig: DeviceInfo = AppStorage.get('mouseconfig') as DeviceInfo
      mouseconfig.dpiLevel = DPI_currInfo.curr
      AppStorage.setOrCreate("mouseconfig", mouseconfig);
    })
  }


  /**
   * 一键最小化
   */
  onMinimizeClick() {
    // 获取当前应用的最后窗口
    window.getLastWindow(getContext(this)).then((windowClass: window.Window) => {
      // 调用最小化方法
      windowClass.minimize((err: BusinessError) => {
        if (err) {
          console.error(`最小化窗口失败，错误码: ${err.code}, 信息: ${err.message}`);
          return;
        }
        console.info('窗口最小化成功');
      });
    }).catch((err: BusinessError) => {
      console.error(`获取窗口失败: ${err.message}`);
    });
  }
}

interface DPI_currInfoModel {
  length: number
  curr: number
}