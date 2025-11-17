import { DeviceArrayType_Ble } from 'bluetooth'
import { _change_keyboard_KeyPressType, _change_mouse_KeyPressType } from 'keymethodconfig'
import { ConnectDevice, DeviceArrayType, KeyPressType, PRODUCT_TYPE } from 'mouse'
import { CommonConfig } from '../common/config/CommonConfig'
import { Languages } from '../common/config/Languages'
import { Tab_ai } from '../components/Tab_ai'
import { Tab_command } from '../components/Tab_command'
import { Tab_device } from '../components/Tab_device'
import { Tab_library } from '../components/Tab_library'
import { Tab_profile } from '../components/Tab_profile'

interface BarType {
  img: string
  selectImg: string
  title: string
}

PersistentStorage.persistProp("languages", 'ZH_CN') //用户语言
PersistentStorage.persistProp("login", false)
PersistentStorage.persistProp("device_currIndex", 0) //设备信息接收与发送
PersistentStorage.persistProp("device_isBle", false) //是否是蓝牙连接设备
PersistentStorage.persistProp("device_show_currIndex", 0) //设备信息展示

@Entry
@Component
struct Index {
  @StorageLink("login") login: boolean = true
  @Provide('pageInfo') pageInfo: NavPathStack = new NavPathStack()
  @StorageLink("pageInfo") pageInfo_: NavPathStack = this.pageInfo
  @StorageLink('languages') languages: string = 'ZH_CN'
  @Watch('change_mouse_KeyPressType') @StorageLink("mouse_KeyPressType") mouse_KeyPressType: KeyPressType =
    KeyPressType.DEFAULT
  @StorageLink("device_isBle") device_isBle: boolean = false
  @StorageLink('devices') devices: DeviceArrayType_Ble[] = []
  @State currPageIndex: number = 2
  @State barList: BarType[] = [
    { img: 'un_tab_device', selectImg: 'tab_device', title: Languages.tab_device[this.languages] },
    { img: 'un_tab_command', selectImg: 'tab_command', title: Languages.tab_command[this.languages] },
    { img: 'un_tab_ai', selectImg: 'tab_ai', title: Languages.tab_ai[this.languages] },
    { img: 'un_tab_library', selectImg: 'tab_library', title: Languages.tab_library[this.languages] },
    { img: 'un_tab_profile', selectImg: 'tab_profile', title: Languages.tab_profile[this.languages] },
  ]
  private controller: TabsController = new TabsController()

  onPageShow(): void {

  }

  change_mouse_KeyPressType() {
    if (this.login) {
      let PRODUCT_TYPE_: PRODUCT_TYPE = PRODUCT_TYPE.DEFAULT
      if (this.device_isBle) {
        /**
         * BLE
         */
        PRODUCT_TYPE_ = (this.devices[AppStorage.get('device_currIndex')as number]).PRODUCT_TYPE
      } else {
        /**
         * 2.4G
         */
        PRODUCT_TYPE_ =
          (ConnectDevice.Communication[AppStorage.get('device_currIndex')as number] as DeviceArrayType).PRODUCT_TYPE
      }
      switch (PRODUCT_TYPE_) {
        case PRODUCT_TYPE.DEFAULT: //鼠标
          _change_mouse_KeyPressType()
          break
        case PRODUCT_TYPE.keyboard: //键盘
          _change_keyboard_KeyPressType()
          break
      }
    }
  }

  build() {
    Navigation() {
      Column() {
        Tabs({ controller: this.controller }) {
          TabContent() {
            Tab_device()
          }

          TabContent() {
            Tab_command()
          }

          TabContent() {
            Tab_ai()
          }

          TabContent() {
            Tab_library()
          }

          TabContent() {
            Tab_profile()
          }
        }
        .animationDuration(0)
        .layoutWeight(1)

        Flex({ justifyContent: FlexAlign.SpaceBetween }) {
          ForEach(this.barList, (item: BarType, index) => {
            Column() {
              Image($r(`app.media.${this.currPageIndex === index ? item.selectImg : item.img}`))
                .width(24)
                .margin({ bottom: 10 })
              Text(item.title)
                .fontSize(CommonConfig.fontSize_11)
                .fontColor(this.currPageIndex === index ? CommonConfig.hintTextColor_select :
                CommonConfig.hintTextColor)
            }
            .flexGrow(1)
            .flexShrink(1)
            .onClick(() => {
              this.currPageIndex = index
              this.controller.changeIndex(index)
            })
          }, (item: BarType) => item.title)
        }.width('100%')
        .padding(10)
        .backgroundColor(Color.White)
        .borderRadius(8)
      }.padding({ left: 16, right: 16 })
      .backgroundColor(CommonConfig.commonBackgroundColor)
      .width('100%')
      .height('100%')
    }
    .hideToolBar(true)
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
  }
}