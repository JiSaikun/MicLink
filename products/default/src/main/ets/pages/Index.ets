import { LeftBar, Topbar, Content, Reset, observeSystemLanguageChanges, AiModel_data, bottom_data } from 'common'
import Content_Ai from 'command_ai/src/main/ets/components/Command_Ai'
import { inputDevice, KeyCode } from '@kit.InputKit';
import { ConnectDevice, Communication, DeviceInfo, KeyPressType, DeviceArrayType, PRODUCT_TYPE, } from 'mouse'
import common from '@ohos.app.ability.common';
import { _change_keyboard_KeyPressType, _change_mouse_KeyPressType } from 'keymethodconfig';
import { Float_Window } from 'float_window';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { FixedText_pop, globalShortcutService, WebUrlToOpen_pop } from 'utils';
import { CreateNewInstruction_pop } from 'command_ai';
import { DeviceSettings } from '../components/DeviceSettings';


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

PersistentStorage.persistProp("voice_recognition_shortcut", { keyPreview: '', pressedKeys: [] }) //语音识别快捷键
PersistentStorage.persistProp("voice_translation_shortcut", { keyPreview: '', pressedKeys: [] }) //语音翻译快捷键
PersistentStorage.persistProp("screenshot_recognition_shortcut", { keyPreview: '', pressedKeys: [] }) //截图识别快捷键
PersistentStorage.persistProp("custom_shortcut", { keyPreview: '', pressedKeys: [] }) //自定义快捷键

@Entry
@Component
struct Index {
  @StorageLink("login") login: boolean = true
  @StorageLink("mouseconfig") mouseconfig: DeviceInfo | null = null
  @StorageLink("currpageIsAI") currpageIsAI: boolean = false
  @StorageLink('languages') languages: string = 'ZH_CN'
  @Provide('pageInfo') pageInfo: NavPathStack = new NavPathStack()
  @StorageLink("pageInfo") pageInfo_: NavPathStack = this.pageInfo
  @Watch('change_mouse_KeyPressType') @StorageLink("mouse_KeyPressType") mouse_KeyPressType: KeyPressType = KeyPressType.VOICE_CLICK

  @State web: string = 'https://asrai.miclink.net?sno=123&productCode=999999&config=configMiclink_B_1755079145452'
  @State currentIndex: number = 0
  @State bottomCurrIndex: number = 10000

  private tabsController: TabsController = new TabsController()

  // 修复：使用动态的 AiModel_data 长度
  private aiModelDataLength: number = AiModel_data.length;
  private bottomDataLength: number = bottom_data.length;

  @Watch('onTabsControllerIndexChange')
  @StorageLink('tabsControllerIndex') tabsControllerIndex: number = 0

  @State isShow_CreateNewInstruction_pop: boolean = false
  @State isShow_EditInstruction_pop: boolean = false
  @State EditInstruction_pop_currIndex: number = 0

  @Watch('onShortcutChange')
  @StorageLink("shortcut") shortcut: number = 0

  @StorageLink("isShowFixedText_pop") isShowFixedText_pop: boolean = false
  @StorageLink("isShow_webUrlToOpen_pop") isShow_webUrlToOpen_pop: boolean = false
  @State shortcut_pop: boolean = false

  // TabsControllerIndex 变化监听
  onTabsControllerIndexChange(): void {
    console.log('onTabsControllerIndexChange called:', this.tabsControllerIndex)
    if (this.tabsController) {
      this.tabsController.changeIndex(this.tabsControllerIndex)
    }
    // 同步更新 currentIndex 和 bottomCurrIndex
    this.syncCurrentIndexWithTabs()
  }

  // 修复：同步 currentIndex 和 bottomCurrIndex
  private syncCurrentIndexWithTabs(): void {
    console.log('syncCurrentIndexWithTabs - tabsControllerIndex:', this.tabsControllerIndex, 'aiModelDataLength:', this.aiModelDataLength)

    if (this.tabsControllerIndex < this.aiModelDataLength) {
      // 选中顶部选项
      this.currentIndex = this.tabsControllerIndex
      this.bottomCurrIndex = 10000
      console.log('Selected top item:', this.currentIndex)
    } else if (this.tabsControllerIndex < this.aiModelDataLength + this.bottomDataLength) {
      // 选中底部选项
      this.currentIndex = 10000
      this.bottomCurrIndex = this.tabsControllerIndex - this.aiModelDataLength
      console.log('Selected bottom item:', this.bottomCurrIndex)
    } else {
      // 无效索引，重置状态
      this.currentIndex = 10000
      this.bottomCurrIndex = 10000
      console.log('Invalid index, reset states')
    }
  }

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

  onShortcutChange() {
    this.shortcut_pop = !this.shortcut_pop
    if (this.shortcut_pop) {
      this.pageInfo.pushPath({ 'name': 'shortcut_pop' })
    }
  }

  onPageHide(): void {
    Float_Window.creat_hide()
  }

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    AppStorage.setOrCreate('context', context);
    AppStorage.setOrCreate('currpageIsAI', true);

    // 修复：初始化时获取正确的数据长度
    this.aiModelDataLength = AiModel_data.length;
    this.bottomDataLength = bottom_data.length;
    console.log('aiModelDataLength initialized:', this.aiModelDataLength)
    console.log('bottomDataLength initialized:', this.bottomDataLength)

    let isPhysicalKeyboardExist = true;
    try {
      inputDevice.on("change", (data: inputDevice.DeviceListener) => {
        Reset()
        console.log(`Device event info: ${JSON.stringify(data)}`);
        inputDevice.getKeyboardType(data.deviceId, (err: Error, type: inputDevice.KeyboardType) => {
          console.log("The keyboard type is: " + type);
          if (type == inputDevice.KeyboardType.ALPHABETIC_KEYBOARD && data.type == 'add') {
            isPhysicalKeyboardExist = true;
            ConnectDevice.connectDevice().then(() => {
              for (let item of ConnectDevice.Communication) {
                item.Communication.changPhysicalKeyboardExistState(isPhysicalKeyboardExist)
              }
            })
          } else if (type == inputDevice.KeyboardType.ALPHABETIC_KEYBOARD && data.type == 'remove') {
            isPhysicalKeyboardExist = false;
            for (let item of ConnectDevice.Communication) {
              item.Communication.changPhysicalKeyboardExistState(isPhysicalKeyboardExist)
            }
            ConnectDevice.connectDevice().then(() => {
              for (let item of ConnectDevice.Communication) {
                item.Communication.changPhysicalKeyboardExistState(true)
              }
            })
          }
        });
      });
    } catch (error) {
      console.error(`Get device info failed, error: ${JSON.stringify(error, ['code', 'message'])}`);
    }
  }

  onPageShow(): void {
    if (!AppStorage.get('firstOpen')) {
      try {
        ConnectDevice.connectDevice().then(() => {
          // 初始化后同步状态
          this.syncCurrentIndexWithTabs()
        })
      } catch (e) {
        console.log(e)
      }
      observeSystemLanguageChanges()
    } else {
      Float_Window.destroyWindow(Float_Window.window_hide)
    }
    this.pageInfo.disableAnimation(true)

    if (!this.login) {
      this.pageInfo.pushPath({ 'name': 'login' })
    }
    AppStorage.setOrCreate('firstOpen', 1)

    // 确保状态同步
    this.syncCurrentIndexWithTabs()
  }

  aboutToDisappear(): void {
    for (let item of ConnectDevice.Communication) {
      item.Communication.changPhysicalKeyboardExistState(false)
    }
  }

  build() {
    Column() {
      Navigation(this.pageInfo) {
        Stack() {
          Flex() {
            Column() {
              LeftBar({
                web: $web,
                currentIndex: this.currentIndex,
                bottomCurrIndex: this.bottomCurrIndex
              })
            }
            .flexGrow(1)
            .flexShrink(1)

            Tabs({ controller: this.tabsController, index: this.tabsControllerIndex }) {
              // 确保 TabContent 数量与 AiModel_data + bottom_data 匹配
              TabContent() { // AI-助手
                Stack() {
                  Content({ web: this.web })
                  Topbar()
                }
                .height('100%')
                .align(Alignment.TopStart)
              }

              TabContent() { // AI-办公
                Stack() {
                  Content({ web: this.web })
                  Topbar()
                }
                .height('100%')
                .align(Alignment.TopStart)
              }

              TabContent() { // AI-智能体
                Stack() {
                  Content({ web: this.web })
                  Topbar()
                }
                .height('100%')
                .align(Alignment.TopStart)
              }

              TabContent() { // AI-指令
                Stack() {
                  Content_Ai({
                    isShow_CreateNewInstruction_pop: this.isShow_CreateNewInstruction_pop,
                    isShow_EditInstruction_pop: this.isShow_EditInstruction_pop,
                    EditInstruction_pop_currIndex: this.EditInstruction_pop_currIndex
                  })
                  Topbar()
                }
                .height('100%')
                .align(Alignment.TopStart)
              }

              TabContent() { // 导航库
                Stack() {
                  Content({ web: this.web })
                  Topbar()
                }
                .height('100%')
                .align(Alignment.TopStart)
              }

              TabContent() { // 视频库
                Stack() {
                  Content({ web: this.web })
                  Topbar()
                }
                .height('100%')
                .align(Alignment.TopStart)
              }

              TabContent() { // 模板库
                Stack() {
                  Content({ web: this.web })
                  Topbar()
                }
                .height('100%')
                .align(Alignment.TopStart)
              }

              TabContent() { // 设备设置
                Stack() {
                  DeviceSettings()
                  Topbar()
                }
                .height('100%')
                .align(Alignment.TopStart)
              }

              TabContent() { // 企业中心
                Stack() {
                  Content({ web: this.web })
                  Topbar()
                }
                .height('100%')
                .align(Alignment.TopStart)
              }

              TabContent() { // 帮助中心
                Stack() {
                  Content({ web: this.web })
                  Topbar()
                }
                .height('100%')
                .align(Alignment.TopStart)
              }
            }
            .onChange((index: number) => {
              console.log('Tabs onChange:', index)
              this.tabsControllerIndex = index
            })
            .edgeEffect(EdgeEffect.Spring)
            .vertical(true)
            .barWidth(2)
            .flexGrow(1)
            .flexShrink(1)
            .scrollable(false)
            .layoutWeight(1)
            .barWidth(0)
            .animationDuration(0)
          }
          .width('100%')
          .height('100%')

          if (this.isShow_CreateNewInstruction_pop) {
            CreateNewInstruction_pop({
              isShow_CreateNewInstruction_pop: this.isShow_CreateNewInstruction_pop,
              isShow_EditInstruction_pop: this.isShow_EditInstruction_pop
            })
          }
          if (this.isShow_EditInstruction_pop) {
            CreateNewInstruction_pop({
              isShow_CreateNewInstruction_pop: this.isShow_CreateNewInstruction_pop,
              isShow_EditInstruction_pop: this.isShow_EditInstruction_pop,
              isParam: true,
              currIndexParam: this.EditInstruction_pop_currIndex
            })
          }
          if (this.isShowFixedText_pop) {
            FixedText_pop({ isShowFixedText_pop: this.isShowFixedText_pop })
          }
          if (this.isShow_webUrlToOpen_pop) {
            WebUrlToOpen_pop({ isShow_webUrlToOpen_pop: this.isShow_webUrlToOpen_pop })
          }

        }
        .width('100%')
        .height('100%')

      }
      .hideToolBar(true)
      .hideTitleBar(true)
      .mode(NavigationMode.Stack)

      Image($r('app.media.create_Command_Ai'))
    }.onKeyEvent((event: KeyEvent) => {
      globalShortcutService.handleGlobalKeyEvent(event)
    })
  }

  fixWindowToLandscape() {
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