import { LeftBar, Topbar, Content } from 'common'
// import {Hid}from "usb_hid"
// import { BlueTooth_api } from "bluetooth"
import { inputDevice, KeyCode } from '@kit.InputKit';
import { Communication, DeviceInfo, MouseICType, KeyPressType, AudioFileManager } from 'mouse'
import common from '@ohos.app.ability.common';
import { AudioWebSocketHandler, inputMessageModel } from 'api';
import { WebSocket_serverUrl } from 'config';


PersistentStorage.persistProp("login", false)

// PersistentStorage.persistProp("mouseconfig", null)

@Entry
@Component
struct Index {
  @StorageLink("login") login: boolean = true //登录状态
  @StorageLink("mouseconfig") mouseconfig: DeviceInfo | null = null //鼠标信息
  @Watch('change_mouse_KeyPressType') @StorageLink("mouse_KeyPressType") mouse_KeyPressType: KeyPressType =
    KeyPressType.VOICE_CLICK //鼠标按键事件监听
  @Provide('pageInfo') pageInfo: NavPathStack = new NavPathStack() //页面跳转路由栈
  @State web: string =
    'https://asrai.miclink.net?sno=123&productCode=999999&config=configMiclink_B_1755079145452' //web组件链接

  change_mouse_KeyPressType() {
    console.log('77777777777777777777777777777', this.mouse_KeyPressType)
    if (this.mouse_KeyPressType === 11) {
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
          setTimeout(()=>{
            Communication.getDeviceInfo([0x20, 0x01, 0x19])
          },1000)
      }
    }
    if (this.mouse_KeyPressType === 12) {
    }
    if (this.mouse_KeyPressType === 13) {
    }
    if (this.mouse_KeyPressType === 14) {

    }
    if (this.mouse_KeyPressType === 21) {
    }
    if (this.mouse_KeyPressType === 22) {
    }
    if (this.mouse_KeyPressType === 23) {
    }
    if (this.mouse_KeyPressType === 24) {

    }
    if (this.mouse_KeyPressType === 31) {
      Communication.getDeviceInfo([0x20, 0x01, 0x06])
    }
    if (this.mouse_KeyPressType === 32) {
    }
    if (this.mouse_KeyPressType === 33) {
    }
    if (this.mouse_KeyPressType === 34) {

    }
    if (this.mouse_KeyPressType === 41) {
    }
    if (this.mouse_KeyPressType === 42) {
    }
    if (this.mouse_KeyPressType === 43) {
    }
    if (this.mouse_KeyPressType === 44) {

    }
    if (this.mouse_KeyPressType === 51) {
      this.pageInfo.clear()
      // this.pageInfo.pushPath({ name: 'aipage' })
    }
    if (this.mouse_KeyPressType === 52) {
    }
    if (this.mouse_KeyPressType === 53) {
    }
    if (this.mouse_KeyPressType === 54) {

    }

    this.mouse_KeyPressType = 0
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
            LeftBar({ web: this.web })
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