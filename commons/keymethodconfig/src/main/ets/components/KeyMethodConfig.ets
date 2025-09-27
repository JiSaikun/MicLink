import {
  Communication, DeviceInfo, AudioFileManager, AudioWebSocketHandler, inputMessageModel
} from 'mouse' //语音输入
import { WebSocket_serverUrl, getModelInfoModel } from 'config'; //语音输入
import window from '@ohos.window'; //一键回到桌面————应用最小化
import { BusinessError } from '@ohos.base';
import common from '@ohos.app.ability.common'; //打开网页
import { Want } from '@kit.AbilityKit'; //打开网页

import { OpenLinkOptions } from '@kit.AbilityKit'; // 导入AbilityKit中的常用功能和打开链接选项
import { hilog } from '@kit.PerformanceAnalysisKit'; // 导入性能分析工具包中的日志功能
import { pasteboard } from '@kit.BasicServicesKit'; //划词翻译————剪切板
import { _translate, translate_Params } from 'mouse'
import abilityAccessCtrl from '@ohos.abilityAccessCtrl'; //读取剪切板————主动获取权限
import { Float_Window } from 'float_window'; //按键执行方法回调

export class _KeyMethodConfig {
  /**
   * 语音输入--语音翻译
   * 0：语音输入
   * 1：语音翻译
   */
  static voiceInput(state: number = 0) {
    if (!Communication.audioDataState) {
      Communication.getDeviceInfo([0x62])
        .then(() => {
          Communication.audioData = []
          Communication.audioDataState = !Communication.audioDataState
        })
      Float_Window.creat()
      setTimeout(() => {
        Float_Window.destroyWindow()
      }, 60000)
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
        new AudioWebSocketHandler(WebSocket_serverUrl.audioToText, Communication.audioData, state,
          inputMessage) //语音转文字 websocket  //0：语音输入
      audioToText.connect()
    }
  }

  /**
   * 语音输入_长按按下
   */
  static voiceInput_long() {
    Communication.audioData = []
    if (Communication.audioDataState) { //若开始长按时，有通过0x62命令开启的语音输入等，先进行关闭 ...否则改变audioDataState 采集状态，确保1b数据被放到语音数据里 ——————手动发起0x62收集录音数据
      Communication.getDeviceInfo([0x62])
    } else {
      Communication.audioDataState = !Communication.audioDataState
    }
  }

  /**
   * 语音输入_长按抬起
   */
  static endvoiceInput_long(state: number = 0) {
    Communication.audioDataState = !Communication.audioDataState
    Communication.getDeviceInfo([0x63])
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
      new AudioWebSocketHandler(WebSocket_serverUrl.audioToText, Communication.audioData, state,
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
   *前进
   */
  static forward() {
    Communication.getDeviceInfo([0x20, 0x04, 0x4F])
  }

  /**
   *后退
   */
  static back() {
    Communication.getDeviceInfo([0x20, 0x04, 0x50])
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
    let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard(); //获取系统剪贴板对象。
    Communication.getDeviceInfo([0x20, 0x01, 0x06]) //Ctrl+C
    let atManager = abilityAccessCtrl.createAtManager();
    try {
      // 向用户申请读取剪贴板的权限
      atManager.requestPermissionsFromUser(AppStorage.get('context'), ['ohos.permission.READ_PASTEBOARD'])
        .then((data) => {
          console.info("权限申请结果: " + JSON.stringify(data));
        })
        .catch((err: BusinessError) => {
          console.error("权限申请失败: " + err.message);
        });
    } catch (err) {
      console.error(`权限申请捕获异常: ${err.code}, ${err.message}`);
    }
    setTimeout(() => {
      // Communication.getDeviceInfo([0x20, 0x01, 0x19]) //Ctrl+C
      // Communication.getDeviceInfo([0x20, 0x01, 0x19]) //Ctrl+C
      systemPasteboard.getData().then((pasteData: pasteboard.PasteData) => {
        console.error(JSON.stringify(pasteData.getRecordCount()))
        let text: string = pasteData.getPrimaryText();
        console.log('111111111111111', text)
        let params: translate_Params = {
          appkey: (AppStorage.get('getModelInfo') as getModelInfoModel).appkey, //获取用户按键模式详情中得到
          from: 'ZH_CN', //源语言___后面配置
          productCode: Communication.deviceInfo.productType.toString(), //产品编码
          sno: Communication.deviceInfo.sn, //设备号
          text: text, //翻译内容
          to: 'EN_US' //翻译语言___后面配置
        }
        _translate(params).then((res) => {
          console.log('翻译请求成功————翻译结果：' + res.data?.transText)
          const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, res.data?.transText);
          // Communication.getDeviceInfo([0x20, 0x01, 0x19])
          systemPasteboard.clearData() //清空剪贴板
        })

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
    }, 200)
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
   *打开文件夹
   */
  static explorer() {
    const TAG: string = '[UIAbilityComponentsOpenLink]'; // 定义日志标签
    const DOMAIN_NUMBER: number = 0xFF00; // 定义日志域编号
    let context: common.UIAbilityContext = AppStorage.get('context') as common.UIAbilityContext; // 获取当前UIAbility上下文
    let link: string = 'filemanager://openDirectory'; // 定义要打开的链接，这里是文件管理的URI
    let openLinkOptions: OpenLinkOptions = {
      // 配置打开链接的选项
      parameters: {
        // 参数设置
        'fileUri': '' // 文件URI参数，这里为空
        // 'fileUri': 'file://docs/storage/Users/currentUser/Desktop/%E6%96%B0%E5%BB%BA%20DWG%20%E6%96%87%E4%BB%B6.dwg' // 文件URI参数，这里为空
        // 'fileUri': 'file://docs/storage/Users/currentUser/Documents/test.txt' // 文件URI参数，这里为空
      }
    };
    try { // 异常处理
      context.openLink(link, openLinkOptions) // 调用打开链接方法
        .then(() => { // 成功回调
          hilog.info(DOMAIN_NUMBER, TAG, 'open link success.'); // 记录成功日志
        }).catch((err: BusinessError) => { // 失败回调
        hilog.error(DOMAIN_NUMBER, TAG,
          `open link failed. Code is ${err.code}, message is ${err.message}`); // 记录错误日志
      });
    } catch (paramError) { // 捕获参数错误
      hilog.error(DOMAIN_NUMBER, TAG,
        `Failed to start link. Code is ${paramError.code}, message is ${paramError.message}`); // 记录参数错误日志
    }
  }


  /**
   * 一键最小化
   */
  static onMinimizeClick() {
    // 获取当前应用的最后窗口
    window.getLastWindow(AppStorage.get('context') as common.UIAbilityContext).then((windowClass: window.Window) => {
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

interface DPI_currInfoModel { //切换DPI 记录当前DPI挡位
  length: number
  curr: number
}