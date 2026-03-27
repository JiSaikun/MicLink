import { connectDevice, DeviceArrayType_Ble } from 'bluetooth'
import { _change_keyboard_KeyPressType, _change_mouse_KeyPressType } from 'keymethodconfig'
import { ConnectDevice, DeviceArrayType, KeyPressType, PRODUCT_TYPE } from 'mouse'
import { Tab_command } from '../components/Tab_command'
import { Tab_device } from '../components/Tab_device'
import { Tab_library } from '../components/Tab_library'
import { Tab_profile } from '../components/Tab_profile'
import { inputDevice } from '@kit.InputKit'
import { common } from '@kit.AbilityKit'
import { CommonConfig, Languages } from 'components_phone'
import { Tab_ai } from '../components/Tab_ai'
import { Login_phone } from 'login'

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
PersistentStorage.persistProp("userLoginInfo", null) //用户信息
PersistentStorage.persistProp("paletteTheme", '#00aecc') //主题色
PersistentStorage.persistProp("isEnableLongVoiceRecog", true) //是否开启长语音识别
PersistentStorage.persistProp("isWordScan_Translation", true) //是否开启划词翻译功能
PersistentStorage.persistProp("isOCR_Translate_Toggle", false) //是否开启截图识别/翻译
PersistentStorage.persistProp("isAutoCloseVoiceTransPop", false) //是否开启语音翻译弹窗自动关闭
PersistentStorage.persistProp("keystroke_curr", 0) //打字输入模式选项
PersistentStorage.persistProp("EnhancedBrowserSearch", 0) //搜索引擎
PersistentStorage.persistProp("from_languages", 'ZH_CN') //语音翻译源语言
PersistentStorage.persistProp("downloadDirectoryUri", '')
PersistentStorage.persistProp("to_languages", 'EN_US') //语音翻译目标语言
PersistentStorage.persistProp("wordScan_from_languages", 'ZH_CN') //划词翻译源语言
PersistentStorage.persistProp("wordScan_to_languages", 'EN_US') //划词翻译目标语言
PersistentStorage.persistProp("screenshotOCR_from_languages", 'ZH_CN') //截图识别/翻译源语言
PersistentStorage.persistProp("screenshotOCR_to_languages", 'EN_US') //截图识别/翻译目标语言
PersistentStorage.persistProp("flax", true) //手机专属标记
PersistentStorage.persistProp("Backgrounding", true) //后台保持运行的开关状态
PersistentStorage.persistProp("keyConfigExclusion ", ["Action_ST", "Action_LockScreen"]) //按键配置剔除  截图翻译、一键锁屏

@Entry
@Component
struct Index {
  // interface ModelsItem    {
  //   image: string,
  //   name:string,
  //   title: string,
  //   recommended: boolean
  // }
  // @State models: ModelsItem[] = [
  //   {
  //     image: 'deepseek',
  //     name: 'DeepSeck-V3 ',
  //     title: '长文本强，逻辑推理。',
  //     recommended: true
  //   }, {
  //   image: 'deepseek',
  //   name: 'DeepSeek-Rl',
  //   title: '数学专精，代码优化。',
  //   recommended: false
  // }, {
  //   image: 'Frame_2511',
  //   name: '豆包',
  //   title: '响应迅速，轻量高效。',
  //   recommended: false
  // }, {
  //   image: 'tyqw',
  //   name: '通义千问',
  //   title: '多轮对话，知识丰富。',
  //   recommended: false
  // }, {
  //   image: 'wxyy',
  //   name: '文心一言',
  //   title: '中文理解，创作力强。',
  //   recommended: false
  // }, {
  //   image: 'Kimi',
  //   name: 'KIMI',
  //   title: '简洁交互，信息精准。',
  //   recommended: false
  // }, {
  //   image: 'xfxh',
  //   name: '讯飞星火',
  //   title: '多轮对话，响应迅捷。',
  //   recommended: false
  // }, {
  //   image: 'xfxh',
  //   name: '讯飞星火-X1',
  //   title: '多模态强，视觉理解。',
  //   recommended: false
  // }]
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @StorageLink("keyConfigExclusion") keyConfigExclusion: string[] =  ["Action_ST", "Action_LockScreen",'Action_SK']//按键配置剔除
  //  截图翻译、一键锁屏、快捷按键
  @StorageLink("login") login: boolean = true
  @Provide('pageInfo') pageInfo: NavPathStack = new NavPathStack()
  @StorageLink("pageInfo") pageInfo_: NavPathStack = this.pageInfo
  @Watch('onLanguagesChange') @StorageLink('languages') languages: string = 'ZH_CN'
  @Watch('change_mouse_KeyPressType') @StorageLink("mouse_KeyPressType") mouse_KeyPressType: KeyPressType =
    KeyPressType.DEFAULT
  @StorageLink("device_isBle") device_isBle: boolean = false
  @StorageLink('devices') devices: DeviceArrayType_Ble[] = []
  @Watch('changeflax') @State currPageIndex: number = 1
  @State barList: BarType[] = [
    { img: 'un_tab_device', selectImg: 'tab_device', title: Languages.tab_device[this.languages] },
    // { img: 'un_tab_command', selectImg: 'tab_command', title: Languages.tab_command[this.languages] },
    { img: 'un_tab_ai', selectImg: 'tab_ai', title: "AI" },
    { img: 'un_tab_library', selectImg: 'tab_library', title: Languages.tab_library[this.languages] },
    { img: 'un_tab_profile', selectImg: 'tab_profile', title: Languages.tab_profile[this.languages] },
  ]
  private controller: TabsController = new TabsController()
  @StorageLink("flax") flax: boolean = true
  @State firstShow: boolean = true

  changeflax() {
    if (this.currPageIndex === 0) {
      this.flax = false
      setTimeout(() => {
        this.flax = true
      }, 10)
    }

  }

  // 当语言改变时，更新底部导航栏标题
  onLanguagesChange() {
    this.barList = [
      { img: 'un_tab_device', selectImg: 'tab_device', title: Languages.tab_device[this.languages] },
      // { img: 'un_tab_command', selectImg: 'tab_command', title: Languages.tab_command[this.languages] },
      { img: 'un_tab_ai', selectImg: 'tab_ai', title: "AI" },
      { img: 'un_tab_library', selectImg: 'tab_library', title: Languages.tab_library[this.languages] },
      { img: 'un_tab_profile', selectImg: 'tab_profile', title: Languages.tab_profile[this.languages] }
    ];
  }

  aboutToAppear(): void {
    console.warn(JSON.stringify(JSON.parse("{     \"Function\":[{\"name\":\"ai-助手\",\"url\":\"https://asrai.miclink.net?sno=SN&productCode=PRDUCTCODE&language=LANGUAGE\"},{\"name\":\"ai-办公\",\"url\":\"https://asrai.miclink.net?sno=SN&productCode=PRDUCTCODE&language=LANGUAGE&config=config_pad#/aiOffice\"},{\"name\":\"ai-智能体\",\"url\":\"https://asrai.miclink.net?sno=SN&productCode=PRDUCTCODE&language=LANGUAGE#/aiAgent\"},{\"name\":\"导航库\",\"url\":\"https://asrai.miclink.net?sno=SN&productCode=PRDUCTCODE&language=LANGUAGE#/navLibrary\"},{\"name\":\"模板库\",\"url\":\"https://asrai.miclink.net?sno=SN&productCode=PRDUCTCODE&language=LANGUAGE#/temLibrary\"},{\"name\":\"帮助中心\",\"url\":\"https://asrai.miclink.net?sno=SN&productCode=PRDUCTCODE&language=LANGUAGE#/helpCenter\"},{\"name\":\"视频库\",\"url\":\"https://asrai.miclink.net/?sno=SN&productCode=PRDUCTCODE&language=LANGUAGE#/videoGallery\"}],     \"Level\":\"1\" }")))
    setTimeout(() => {
      this.controller.changeIndex(1)
    }, 10)
    const context = getContext(this) as common.UIAbilityContext;
    AppStorage.setOrCreate('context', context);
    AppStorage.setOrCreate('currpageIsAI', true);

    let isPhysicalKeyboardExist = true;
    let hotplugTimer: number = 0;
    try {
      inputDevice.on("change", (data: inputDevice.DeviceListener) => {
        if (hotplugTimer !== 0) {
          clearTimeout(hotplugTimer)
        }
        hotplugTimer = setTimeout((): void => {
          hotplugTimer = 0
          console.log(`Device event info: ${JSON.stringify(data)}`);
          inputDevice.getKeyboardType(data.deviceId, (err: Error, type: inputDevice.KeyboardType) => {
            console.log("The keyboard type is: " + type);
            if (type == inputDevice.KeyboardType.ALPHABETIC_KEYBOARD && data.type == 'add') {
              isPhysicalKeyboardExist = true;
            } else if (type == inputDevice.KeyboardType.ALPHABETIC_KEYBOARD && data.type == 'remove') {
              isPhysicalKeyboardExist = false;
            }
            for (let item of ConnectDevice.Communication) {
              item.Communication.changPhysicalKeyboardExistState(isPhysicalKeyboardExist)
            }
            ConnectDevice.rescanUsbIfMiclinkEnumerationChanged().then(() => {
              for (let item of ConnectDevice.Communication) {
                item.Communication.changPhysicalKeyboardExistState(true)
              }
              if (type == inputDevice.KeyboardType.ALPHABETIC_KEYBOARD && data.type == 'add') {
                const context: common.UIAbilityContext =
                  this.getUIContext().getHostContext() as common.UIAbilityContext;
                connectDevice(context)
              }
            })
          });
        }, 450)
      });
    } catch (error) {
      console.error(`Get device info failed, error: ${JSON.stringify(error, ['code', 'message'])}`);
    }
  }

  onPageShow(): void {
    try {
      ConnectDevice.connectDevice()
      const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      connectDevice(context)
    } catch (e) {
      console.log(e)
    }
    this.pageInfo.disableAnimation(true)
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
    Navigation(this.pageInfo) {
      Stack() {
        if (!this.login) {
          Login_phone()
            .zIndex(10000000)
        }
        // Overlay()
        //   .zIndex(100)
        Column() {
          Tabs({ controller: this.controller }) {
            TabContent() {
              if (this.flax) {
                Tab_device()
              }
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
          .barHeight(0)
          .scrollable(false)

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
        }
        .padding({ left: 16, right: 16 })
        .backgroundColor(CommonConfig.commonBackgroundColor)
        .width('100%')
        .height('100%')
        .backgroundImage(this.currPageIndex !== 1 ? $r('app.media.background_1') : '')
        .backgroundImageSize({ width: '100%', height: '100%' })
        // if (this.firstShow) {
        //   Stack() {
        //     Column()
        //       .height('100%')
        //       .width('100%')
        //       .backgroundColor("#000")
        //       .opacity(0.3)
        //     Column() {
        //       Row() {
        //         Row() {
        //           Image($r('app.media.Frame_2511'))
        //             .width(16)
        //             .margin({ right: 4 })
        //           Text('豆包')
        //             .fontSize(CommonConfig.fontSize_12)
        //             .fontWeight(CommonConfig.fontWeight_400)
        //             .fontColor(CommonConfig.secondaryTextColorMain)
        //         }
        //         .alignItems(VerticalAlign.Center)
        //         .borderRadius(4)
        //         .backgroundColor(Color.White)
        //         .padding({
        //           left: 4,
        //           top: 2,
        //           right: 4,
        //           bottom: 2
        //         })
        //       }
        //       .height(40)
        //       .alignItems(VerticalAlign.Center)
        //
        //       Column() {
        //         Row() {
        //           Image($r('app.media.delete_ai'))
        //             .width(24)
        //             .onClick(() => {
        //               this.firstShow = false
        //             })
        //         }
        //         .width('100%')
        //         .justifyContent(FlexAlign.End)
        //
        //         Scroll() {
        //           Column() {
        //             ForEach(this.models, (item: ModelsItem) => {
        //               Column() {
        //                 Flex({ alignItems: ItemAlign.Center }) {
        //                   Text(item.name)
        //                     .fontWeight(CommonConfig.fontWeight_400)
        //                     .fontColor(CommonConfig.hintTextColor_select)
        //                     .fontSize(CommonConfig.fontSize_12)
        //                   Text('推荐')
        //                     .backgroundColor('#e6f7fa')
        //                     .visibility(item.recommended?Visibility.Visible:Visibility.None)
        //                     .padding({
        //                       left: 4,
        //                       top: 2,
        //                       right: 4,
        //                       bottom: 2
        //                     })
        //                     .fontWeight(CommonConfig.fontWeight_400)
        //                     .fontColor(this.paletteTheme)
        //                     .fontSize(CommonConfig.fontSize_12)
        //                 }
        //                 .width('100%')
        //                 .margin({ bottom: 4 })
        //
        //                 Flex({ alignItems: ItemAlign.Center }) {
        //                   Text(item.title)
        //                     .fontWeight(CommonConfig.fontWeight_400)
        //                     .fontColor(CommonConfig.hintTextColor)
        //                     .fontSize(CommonConfig.fontSize_12)
        //                 }
        //                 .width('100%')
        //               }
        //               .border({width:{bottom:1},color:'#EAEAEA'})
        //               .padding(8)
        //             }, (item: ModelsItem) => item.name)
        //           }
        //         }
        //         .width('100%')
        //         .height(178)
        //         .align(Alignment.TopStart)
        //         .padding(8)
        //         .scrollBarWidth(1)
        //         .borderRadius(8)
        //         .backgroundColor(Color.White)
        //         .margin({ right: 24, bottom: 24 })
        //
        //         Text('切换模型')
        //           .fontWeight(CommonConfig.fontWeight_400)
        //           .fontColor(CommonConfig.hintTextColor_select)
        //           .fontSize(CommonConfig.fontSize_14)
        //           .width('100%')
        //           .margin({ bottom: 8 })
        //         Text('在这里您可以选择支持的AI大模型，效果将有所不同。')
        //           .fontWeight(CommonConfig.fontWeight_400)
        //           .fontColor(CommonConfig.secondaryTextColorMain)
        //           .fontSize(CommonConfig.fontSize_11)
        //           .width('100%')
        //
        //       }
        //       .padding({
        //         left: 32,
        //         bottom: 32,
        //         top: 8,
        //         right: 8
        //       })
        //       .borderRadius(12)
        //       .backgroundColor('#f2f2f2')
        //     }
        //     .width(224)
        //     .margin({ left: 84 })
        //     .alignItems(HorizontalAlign.Start)
        //
        //   }
        //   .align(Alignment.TopStart)
        // }
      }

    }
    .hideToolBar(true)
    .hideTitleBar(true)

  }
}