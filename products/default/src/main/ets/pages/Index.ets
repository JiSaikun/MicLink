import { LeftBar, Topbar, Content } from 'common'
// import {Hid}from "usb_hid"
// import { BlueTooth_api } from "bluetooth"
import { inputDevice, KeyCode } from '@kit.InputKit';
import {
  Communication,
  DeviceInfo,
  MouseICType,
  KeyPressType,
  AudioFileManager,
  AudioWebSocketHandler,
  inputMessageModel
} from 'mouse'
import common from '@ohos.app.ability.common';
import { WebSocket_serverUrl } from 'config';
import { Want } from '@kit.AbilityKit';


PersistentStorage.persistProp("login", false)
PersistentStorage.persistProp("KeymethodConfig", null)


// PersistentStorage.persistProp("mouseconfig", null)
export interface KeymethodConfig {
  key: KeyPressType
  currIndex: number
}


@Entry
@Component
struct Index {
  @StorageLink("login") login: boolean = true //登录状态
  @StorageLink("mouseconfig") mouseconfig: DeviceInfo | null = null //鼠标信息
  @StorageLink("currpageIsAI") currpageIsAI: boolean = true //鼠标信息
  @Watch('change_mouse_KeyPressType') @StorageLink("mouse_KeyPressType") mouse_KeyPressType: KeyPressType =
    KeyPressType.VOICE_CLICK //鼠标按键事件监听
  @Provide('pageInfo') pageInfo: NavPathStack = new NavPathStack() //页面跳转路由栈
  @State web: string =
    'https://asrai.miclink.net?sno=123&productCode=999999&config=configMiclink_B_1755079145452' //web组件链接
  @State currentIndex: number = 0

  change_mouse_KeyPressType() {
    // console.log('77777777777777777777777777777', this.mouse_KeyPressType)
    let KeymethodConfig = AppStorage.get('KeymethodConfig') as KeymethodConfig []
    if (this.mouse_KeyPressType === 11) {
      switch (KeymethodConfig[0].currIndex) {
        case 0:
          //语音输入
          console.warn('语音输入+')
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
            // const context = getContext(this) as common.UIAbilityContext;
            // let a: AudioFileManager = new AudioFileManager(Communication.audioData, context)
            // console.log(Communication.audioData.length.toString(), '语音数据结束*****模拟')

            //WebSocket  语音数据处理
            let inputMessage: inputMessageModel = {
              start: false,
              "clientId": "clientId1751968608",
              "ptt": "1",
              "serialNo": this.mouseconfig?.sn as string,
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
          break
        case 1:
          //语音翻译
          console.warn('语音翻译+')
          break
        case 2:
          //回车/发送
          console.warn('回车/发送+')
          break
        case 3:
          //固定文案
          console.warn('固定文案+')
          break
        case 4:
          //文件
          console.warn('文件+')
          break
        case 5:
          //打开网页
          console.warn('打开网页+')
          break
        case 6:
          //快捷按键
          console.warn('快捷按键+')
          break
        case 7:
          //截图翻译
          console.warn('截图翻译+')
          break
        case 8:
          //删除
          console.warn('删除+')
          break
        case 9:
          //回到桌面
          console.warn('回到桌面+')
          break
        case 10:
          //一键锁屏
          console.warn('一键锁屏+')
          break
        case 11:
          //前进
          console.warn('前进+')
          break
        case 12:
          //后退
          console.warn('后退+')
          break
        case 13:
          //划词翻译
          console.warn('划词翻译+')
          break
        case 14:
          //DPI切换
          console.warn('DPI切换+')
          break

      }
    }
    if (this.mouse_KeyPressType === 13) {
      switch (KeymethodConfig[1].currIndex) {
        case 0:
          //语音输入
          console.warn('语音输入+')
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
            // const context = getContext(this) as common.UIAbilityContext;
            // let a: AudioFileManager = new AudioFileManager(Communication.audioData, context)
            // console.log(Communication.audioData.length.toString(), '语音数据结束*****模拟')

            //WebSocket  语音数据处理
            let inputMessage: inputMessageModel = {
              start: false,
              "clientId": "clientId1751968608",
              "ptt": "1",
              "serialNo": this.mouseconfig?.sn as string,
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
          break
        case 1:
          //语音翻译
          console.warn('语音翻译+')
          break
        case 2:
          //语音助手
          console.warn('语音助手+')
          break
        case 3:
          //删除
          console.warn('删除+')
          break
      }
    }
    if (this.mouse_KeyPressType === 21) {
      switch (KeymethodConfig[2].currIndex) {
        case 0:
          //回车/发送
          console.warn('回车/发送+')
          break
        case 1:
          //文件
          console.warn('文件+')
          break
        case 2:
          //文件夹
          console.warn('文件夹+')
          break
        case 3:
          //打开网页
          console.warn('打开网页+')

          const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
          let want: Want = {
            action: 'ohos.want.action.viewData',
            entities: ['entity.system.browsable'],
            uri: 'https://www.baidu.com/',
            parameters: {
              'ohos.ability.params.showDefaultPicker': true
            }
          };
          context.startAbility(want)

          break
        case 4:
          //快捷按键
          console.warn('快捷按键+')
          break

        case 5:
          //截图翻译
          console.warn('截图翻译+')
          break
        case 6:
          //语音输入
          console.warn('语音输入+')
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
            // const context = getContext(this) as common.UIAbilityContext;
            // let a: AudioFileManager = new AudioFileManager(Communication.audioData, context)
            // console.log(Communication.audioData.length.toString(), '语音数据结束*****模拟')

            //WebSocket  语音数据处理
            let inputMessage: inputMessageModel = {
              start: false,
              "clientId": "clientId1751968608",
              "ptt": "1",
              "serialNo": this.mouseconfig?.sn as string,
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
          break
        case 7:
          //回到桌面
          console.warn('回到桌面+')
          break
        case 8:
          //删除
          console.warn('删除+')
          break
        case 9:
          //DPI切换
          console.warn('DPI切换+')
          break
        case 10:
          //前进
          console.warn('前进+')
          break
          break
        case 11:
          //后退
          console.warn('后退+')
          break
        case 12:
          //划词翻译
          console.warn('划词翻译+')
          break
      }
    }
    if (this.mouse_KeyPressType === 23) {
      switch (KeymethodConfig[3].currIndex) {
        case 0:
          //语音输入
          console.warn('语音输入+')
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
            // const context = getContext(this) as common.UIAbilityContext;
            // let a: AudioFileManager = new AudioFileManager(Communication.audioData, context)
            // console.log(Communication.audioData.length.toString(), '语音数据结束*****模拟')

            //WebSocket  语音数据处理
            let inputMessage: inputMessageModel = {
              start: false,
              "clientId": "clientId1751968608",
              "ptt": "1",
              "serialNo": this.mouseconfig?.sn as string,
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
          break
        case 1:
          //语音翻译
          console.warn('语音翻译+')
          break
        case 2:
          //语音助手
          console.warn('语音助手+')
          break
        case 3:
          //删除
          console.warn('删除+')
          break
      }
    }
    if (this.mouse_KeyPressType === 31) {
      switch (KeymethodConfig[4].currIndex) {
        case 0:
          //截图翻译
          console.warn('截图翻译+')
          break
        case 1:
          //回车/发送
          console.warn('回车/发送+')
          break
        case 2:
          //语音输入
          console.warn('语音输入+')
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
            // const context = getContext(this) as common.UIAbilityContext;
            // let a: AudioFileManager = new AudioFileManager(Communication.audioData, context)
            // console.log(Communication.audioData.length.toString(), '语音数据结束*****模拟')

            //WebSocket  语音数据处理
            let inputMessage: inputMessageModel = {
              start: false,
              "clientId": "clientId1751968608",
              "ptt": "1",
              "serialNo": this.mouseconfig?.sn as string,
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
          break
        case 3:
          //语音翻译
          console.warn('语音翻译+')
          break
        case 4:
          //语音助手
          console.warn('语音助手+')
          break
        case 5:
          //DPI切换
          console.warn('DPI切换+')
          break
        case 6:
          //回到桌面
          console.warn('回到桌面+')
          break
        case 7:
          //打开网页
          console.warn('打开网页+')
          break
        case 8:
          //文件夹
          console.warn('文件夹+')
          break
        case 9:
          //文件
          console.warn('文件+')
          break
        case 10:
          //固定文案
          console.warn('固定文案+')
          break
        case 11:
          //划词翻译
          console.warn('划词翻译+')
          Communication.getDeviceInfo([0x20, 0x01, 0x06])
          break
      }

    }
    if (this.mouse_KeyPressType === 33) {
      switch (KeymethodConfig[5].currIndex) {
        case 0:
          //删除
          console.warn('删除+')
          break
        case 1:
          //语音翻译
          console.warn('语音翻译+')
          break
        case 2:
          //语音助手
          console.warn('语音助手+')
          break
      }
    }
    if (this.mouse_KeyPressType === 41) {
    }
    if (this.mouse_KeyPressType === 43) {
    }
    if (this.mouse_KeyPressType === 51) {
      switch (KeymethodConfig[6].currIndex) {
        case 0:
          //无功能
          console.warn('无功能+')
          break
        case 1:
          //ChatGPT
          console.warn('ChatGPT+')
          if (this.currpageIsAI) {
            this.pageInfo.clear()
            this.pageInfo.pushPath({ name: 'aipage' })
            this.currpageIsAI = false
          }
          break
        case 2:
          //划词翻译
          console.warn('划词翻译+')
          break
      }
    }
    if (this.mouse_KeyPressType === 53) {
      if (this.currpageIsAI) {
        this.pageInfo.clear()
        this.pageInfo.pushPath({ name: 'aipage' })
        this.currpageIsAI = false
      }
    }
    this.mouse_KeyPressType = KeyPressType.DEFAULT
  }

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    AppStorage.setOrCreate('context', context);

    /*
    热插拔:检测鼠标的插入与拔出
    */
    let isPhysicalKeyboardExist = true;
    try {
      inputDevice.on("change", (data: inputDevice.DeviceListener) => {
        console.log(`Device event info: ${JSON.stringify(data)}`);
        inputDevice.getKeyboardType(data.deviceId, (err: Error, type: inputDevice.KeyboardType) => {
          console.log("The keyboard type is: " + type);
          if (type == inputDevice.KeyboardType.ALPHABETIC_KEYBOARD && data.type == 'add') {
            // 监听物理键盘已连接。
            isPhysicalKeyboardExist = true;
            Communication.connectDevice()
            Communication.changPhysicalKeyboardExistState(isPhysicalKeyboardExist)
            /**
             * 检查鼠标设备，并建立连接
             */
            Communication.connectDevice().then(() => {
              Communication.getDeviceInfo()
            })
          } else if (type == inputDevice.KeyboardType.ALPHABETIC_KEYBOARD && data.type == 'remove') {
            // 监听物理键盘已断开。
            isPhysicalKeyboardExist = false;
            Communication.changPhysicalKeyboardExistState(isPhysicalKeyboardExist)
          }
        });
      });
      // 根据isPhysicalKeyboardExist的值决定软键盘是否弹出。
    } catch (error) {
      console.error(`Get device info failed, error: ${JSON.stringify(error, [`code`, `message`])}`);
    }
  }

  onPageShow(): void {
    // BlueTooth_api.init_bluetoothState()
    // Hid.Hid_add()
    try {
      /**
       * 检查鼠标设备，并建立连接
       */
      console.log('*/*/*/*/*', JSON.stringify(AppStorage.get('KeymethodConfig')))
      Communication.connectDevice().then(() => {
        Communication.getDeviceInfo([0x63])
        setTimeout(() => {
          Communication.getDeviceInfo() //获取鼠标初始信息
        }, 2000)
      })
    } catch (e) {
      console.log(e)
    }
    this.pageInfo.disableAnimation(true)
    // console.log(JSON.stringify(this.login))
    if (!this.login) {
      this.pageInfo.pushPath({ 'name': 'login' })
    } else {
    }


  }

  aboutToDisappear(): void {
    // console.log('应用关闭======================================')
    console.log(JSON.stringify(Communication.devicePipe))
    Communication.changPhysicalKeyboardExistState(false)
  }

  build() {
    Column() {
      Navigation(this.pageInfo) {
        Flex() {
          Column() {
            LeftBar({ web: this.web, currentIndex: this.currentIndex })
          }
          .flexGrow(1)
          .flexShrink(1)

          Stack() {
            Topbar()
              .zIndex(100)
            Content({ web: this.web })
          }
          .flexGrow(1)
          .flexShrink(1)
          // .border({width:1})
          .align(Alignment.TopStart)
          .height('100%')
          .layoutWeight(1)
        }
        // .backgroundColor(Color.Blue)
        .width('100%')
        .height('100%')
        .onClick(() => {
          // type Action = 'home'
        })
      }
      .hideToolBar(true)
      .hideTitleBar(true)
      .mode(NavigationMode.Stack)

      Image($r('app.media.create_Command_Ai'))
    }

  }
}