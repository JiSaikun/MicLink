import { LeftBar, Topbar, Content, Reset, observeSystemLanguageChanges } from 'common'
// import {Hid}from "usb_hid"
// import { BlueTooth_api } from "bluetooth"
import { inputDevice, KeyCode } from '@kit.InputKit';
import { ConnectDevice, Communication, DeviceInfo, KeyPressType, DeviceArrayType, PRODUCT_TYPE, } from 'mouse'
import common from '@ohos.app.ability.common';
import { _change_keyboard_KeyPressType, _change_mouse_KeyPressType } from 'keymethodconfig'; //按键执行方法回调
import { Float_Window } from 'float_window'; //按键执行方法回调
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { globalShortcutService } from 'utils';


PersistentStorage.persistProp("login", false)
PersistentStorage.persistProp("table_data", []) //AI指令本地存储
// PersistentStorage.persistProp("KeymethodConfig", null) //按键设置方法执行记录
// PersistentStorage.persistProp("mouseconfig", null) //鼠标实时数据
// PersistentStorage.persistProp("getModelInfo", null) //获取用户按键模式详情
PersistentStorage.persistProp("languages", 'ZH_CN') //用户语言
// PersistentStorage.persistProp("speech_Recognition_languages", 'ZH_CN') //语音识别语言
PersistentStorage.persistProp("from_languages", 'ZH_CN') //语音翻译源语言
PersistentStorage.persistProp("to_languages", 'EN_US') //语音翻译目标语言
PersistentStorage.persistProp("wordScan_from_languages", 'ZH_CN') //划词翻译源语言
PersistentStorage.persistProp("wordScan_to_languages", 'EN_US') //划词翻译目标语言
PersistentStorage.persistProp("screenshotOCR_from_languages", 'ZH_CN') //截图识别/翻译源语言
PersistentStorage.persistProp("screenshotOCR_to_languages", 'EN_US') //截图识别/翻译目标语言
PersistentStorage.persistProp("isPunctuationRecognition", true) //语音识别是否带标点
PersistentStorage.persistProp("isEnableLongVoiceRecog", true) //是否开启长语音识别
PersistentStorage.persistProp("isWordScan_Translation", true) //是否开启划词翻译功能
PersistentStorage.persistProp("isOCR_Translate_Toggle", false) //是否开启截图识别/翻译
PersistentStorage.persistProp("isAutoCloseVoiceTransPop", false) //是否开启语音翻译弹窗自动关闭
PersistentStorage.persistProp("fixedText", '') //输入固定文本
PersistentStorage.persistProp("folderPath", '') //打开文件夹记录文件夹路径  暂不做更改
PersistentStorage.persistProp("foldPath", '') //打开文件记录文件路径  暂不做更改
PersistentStorage.persistProp("webUrlToOpen", '') //输入打开网页的具体网址
PersistentStorage.persistProp("EnhancedBrowserSearch", 0) //搜索引擎
PersistentStorage.persistProp("device_currIndex", 0) //设备信息接收与发送
PersistentStorage.persistProp("device_show_currIndex", 0) //设备信息展示

@Entry
@Component
struct Index {
  @StorageLink("login") login: boolean = true //登录状态
  @StorageLink("mouseconfig") mouseconfig: DeviceInfo | null = null //鼠标信息
  @StorageLink("currpageIsAI") currpageIsAI: boolean = false //鼠标信息
  @StorageLink('languages') languages: string = 'ZH_CN'
  // @Watch('change_mouse_KeyPressType') @StorageLink("float_window") float_window: boolean = true //悬浮窗显示与隐藏
  @Provide('pageInfo') pageInfo: NavPathStack = new NavPathStack() //页面跳转路由栈
  @StorageLink("pageInfo") pageInfo_: NavPathStack = this.pageInfo
  @Watch('change_mouse_KeyPressType') @StorageLink("mouse_KeyPressType") mouse_KeyPressType: KeyPressType =
    KeyPressType.VOICE_CLICK //鼠标按键事件监听
  @State web: string =
    'https://asrai.miclink.net?sno=123&productCode=999999&config=configMiclink_B_1755079145452' //web组件链接
  @State currentIndex: number = 0

  change_mouse_KeyPressType() {
    if (this.login) {
      switch ((ConnectDevice.Communication[AppStorage.get('device_currIndex')as number] as DeviceArrayType).PRODUCT_TYPE) {
        case PRODUCT_TYPE.DEFAULT:
          _change_mouse_KeyPressType()
          break
        case PRODUCT_TYPE.keyboard:
          _change_keyboard_KeyPressType()
          break
      }


    }

  }

  // watch_float_window() {
  //   // if (this.float_window) {
  //   //   Float_Window.creat()
  //   // } else {
  //   //   Float_Window.destroyWindow()
  //   // }
  // }
  onPageHide(): void {
    // console.log('应用最小化')
    Float_Window.creat_hide()
  }

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    AppStorage.setOrCreate('context', context);
    AppStorage.setOrCreate('currpageIsAI', true);
    // AppStorage.setOrCreate('float_window', false);
    /*
    热插拔:检测鼠标的插入与拔出
    */
    let isPhysicalKeyboardExist = true;
    try {
      inputDevice.on("change", (data: inputDevice.DeviceListener) => {
        Reset()
        console.log(`Device event info: ${JSON.stringify(data)}`);
        inputDevice.getKeyboardType(data.deviceId, (err: Error, type: inputDevice.KeyboardType) => {
          console.log("The keyboard type is: " + type);
          if (type == inputDevice.KeyboardType.ALPHABETIC_KEYBOARD && data.type == 'add') {
            // 监听物理键盘已连接。
            isPhysicalKeyboardExist = true;
            ConnectDevice.connectDevice().then(() => {
              for (let item of ConnectDevice.Communication) {
                item.Communication.changPhysicalKeyboardExistState(isPhysicalKeyboardExist)
              }
            })

            // /**
            //  * 检查鼠标设备，并建立连接
            //  */
            // Communication.connectDevice().then(() => {
            //   Communication.getDeviceInfo()
            // })
          } else if (type == inputDevice.KeyboardType.ALPHABETIC_KEYBOARD && data.type == 'remove') {
            // 监听物理键盘已断开。
            isPhysicalKeyboardExist = false;
            for (let item of ConnectDevice.Communication) {
              item.Communication.changPhysicalKeyboardExistState(isPhysicalKeyboardExist)
            }
            ConnectDevice.connectDevice().then(() => {
              for (let item of ConnectDevice.Communication) {
                item.Communication.changPhysicalKeyboardExistState(true)
              }
            })

            // Communication.changPhysicalKeyboardExistState(isPhysicalKeyboardExist)
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
    if (!AppStorage.get('firstOpen')) { //确保最小化后重新进入页面时的再次执行——————只在最开始打开应用的时候调用一次即可
      try {
        /**
         * 检查鼠标设备，并建立连接
         */
        ConnectDevice.connectDevice().then(() => {
        })
      } catch (e) {
        console.log(e)
      }
      observeSystemLanguageChanges()
    } else {
      Float_Window.destroyWindow(Float_Window.window_hide)
    }
    this.pageInfo.disableAnimation(true)
    // console.log(JSON.stringify(this.login))
    if (!this.login) {
      this.pageInfo.pushPath({ 'name': 'login' })
    }
    AppStorage.setOrCreate('firstOpen', 1)
  }

  aboutToDisappear(): void {
    // console.log('应用关闭======================================')
    // console.log(JSON.stringify(Communication.devicePipe))
    for (let item of ConnectDevice.Communication) {
      item.Communication.changPhysicalKeyboardExistState(false)
    }

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
            Content({ web: this.web })
            Topbar()
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
    }.onKeyEvent((event: KeyEvent) => {
      // console.error('err：',JSON.stringify(event))
      // 将按键事件传递给全局监听服务
      globalShortcutService.handleGlobalKeyEvent(event)
    })

  }

  //锁定设备横屏，使得窗口不随屏幕旋转————平板适配：暂时不做处理
  fixWindowToLandscape() {
    //1.Get the window instance object, use the createWindow method to create a new window, and use the findWindow method to obtain an existing window
    let windowClass: window.Window | undefined = undefined;
    let config: window.Configuration = {
      name: "alertWindow",
      windowType: window.WindowType.TYPE_SYSTEM_ALERT,
      ctx: AppStorage.get('context')
    };
    try {
      let promise = window.createWindow(config);
      promise.then((data) => {
        windowClass = data;
        console.info('Succeeded in creating the window. Data:' + JSON.stringify(data));
      }).catch((err: BusinessError) => {
        console.error('Failed to create the Window. Cause:' + JSON.stringify(err));
      });
    } catch (exception) {
      console.error('Failed to create the window. Cause: ' + JSON.stringify(exception));
    }
    //2.The window instance uses the setPreferred Orientation method to set the display orientation of the window. PORTRAIT is a fixed vertical screen, and other orientations can refer to the reference link
    let orientation = window.Orientation.LANDSCAPE;
    try {
      let windowClass: window.Window = window.findWindow("test");
      windowClass.setPreferredOrientation(orientation, (err: BusinessError) => {
        const errCode: number = err.code;
        if (errCode) {
          console.error('Failed to set window orientation. Cause: ' + JSON.stringify(err));
          return;
        }
        console.info('Succeeded in setting window orientation.');
      });
    } catch (exception) {
      console.error('Failed to set window orientation. Cause: ' + JSON.stringify(exception));
    }
  }
}

interface shortcutType {
  keyPreview: string
  pressedKeys: number[]
}
