import { LeftBar, Topbar, Content } from 'common'
// import {Hid}from "usb_hid"
// import { BlueTooth_api } from "bluetooth"
import { inputDevice } from '@kit.InputKit';
import { Communication, DeviceInfo, MouseICType } from 'mouse'


PersistentStorage.persistProp("login", false)
PersistentStorage.persistProp("mouseconfig", null)

@Entry
@Component
struct Index {
  @StorageLink("login") login: boolean = true //登录状态
  @StorageLink("mouseconfig") mouseconfig: DeviceInfo | null = null //鼠标信息
  @Provide('pageInfo') pageInfo: NavPathStack = new NavPathStack() //页面跳转路由栈
  @State web: string =
    'https://asrai.miclink.net?sno=123&productCode=999999&config=configMiclink_B_1755079145452' //web组件链接

  aboutToAppear(): void {
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

    this.pageInfo.disableAnimation(true)
    // console.log(JSON.stringify(this.login))
    if (!this.login) {
      this.pageInfo.pushPath({ 'name': 'login' })
    } else {
    }
    /**
     * 检查鼠标设备，并建立连接
     */
    Communication.connectDevice().then(() => {
      Communication.getDeviceInfo()//获取鼠标初始信息
    })


  }

  build() {
    Column() {
      Navigation(this.pageInfo) {
        Row() {
          LeftBar({ web: this.web })
          Stack() {
            Topbar()
              .zIndex(100)
            Content({ web: this.web })
          }
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
    }

  }
}