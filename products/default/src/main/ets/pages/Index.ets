import {
  LeftBar,
  Topbar,
  Content,
  Reset,
  observeSystemLanguageChanges,
  AiModel_data,
  bottom_data,
  ThemeConfig,
  AppUtil
} from 'common'
import Content_Ai from 'command_ai/src/main/ets/components/Command_Ai'
import { inputDevice } from '@kit.InputKit';
import { ConnectDevice, DeviceInfo, KeyPressType, DeviceArrayType, PRODUCT_TYPE, } from 'mouse'
import common from '@ohos.app.ability.common';
import { _change_keyboard_KeyPressType, _change_mouse_KeyPressType } from 'keymethodconfig';
import { Float_Window } from 'float_window';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import {
  BluetoothConnect_pop,
  FixedText_pop,
  globalShortcutService,
  PasswordModification_pop,
  WebUrlToOpen_pop
} from 'utils';
import { CreateNewInstruction_pop } from 'command_ai';
import { DeviceSettings } from '../components/DeviceSettings';
import { connectDevice, DeviceArrayType_Ble } from 'bluetooth';
import { DraggableResizableRect } from 'api'; //截图翻译
import { sideFunctionList } from 'config';
import { url } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Want } from '@kit.AbilityKit';

PersistentStorage.persistProp("login", false)
PersistentStorage.persistProp("userLoginInfo", null)
PersistentStorage.persistProp("table_data", []) //AI指令本地存储
// PersistentStorage.persistProp("KeymethodConfig", null) //按键设置方法执行记录
PersistentStorage.persistProp("keystroke_curr", 0) //打字模式
PersistentStorage.persistProp("getModelInfo", null) //获取用户按键模式详情
PersistentStorage.persistProp("languages", 'ZH_CN') //用户语言
PersistentStorage.persistProp("speech_Recognition_languages", 'ZH_CN') //语音识别语言
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
PersistentStorage.persistProp("folderPath", '') //打开文件夹记录文件夹路径
PersistentStorage.persistProp("foldPath", '') //打开文件记录文件路径
PersistentStorage.persistProp("webUrlToOpen", '') //输入打开网页的具体网址
PersistentStorage.persistProp("EnhancedBrowserSearch", 0) //搜索引擎
PersistentStorage.persistProp("device_currIndex", 0) //设备信息接收与发送
PersistentStorage.persistProp("device_isBle", false) //是否是蓝牙连接设备
PersistentStorage.persistProp("device_show_currIndex", 0) //设备信息展示

PersistentStorage.persistProp("voice_recognition_shortcut", { keyPreview: '', pressedKeys: [] }) //语音识别快捷键
PersistentStorage.persistProp("voice_translation_shortcut", { keyPreview: '', pressedKeys: [] }) //语音翻译快捷键
PersistentStorage.persistProp("screenshot_recognition_shortcut", { keyPreview: '', pressedKeys: [] }) //截图识别快捷键
PersistentStorage.persistProp("custom_shortcut", { keyPreview: '', pressedKeys: [] }) //自定义快捷键
PersistentStorage.persistProp("paletteTheme", ThemeConfig.PaletteTheme) //主题颜色
PersistentStorage.persistProp("resolutionScale", 'followSystem') //分辨率缩放

@Entry
@Component
struct Index {
  @StorageLink("login") login: boolean = true
  @Watch('restart')@StorageLink("netAvailable") netAvailable: boolean = true
  @StorageLink("keyConfigExclusion") keyConfigExclusion: string[] = ["Action_ST"] //按键配置剔除  截图翻译
  @StorageLink("mouseconfig") mouseconfig: DeviceInfo | null = null
  @StorageLink("currpageIsAI") currpageIsAI: boolean = false
  @Watch('refreshPage') @StorageLink('languages') languages: string = 'ZH_CN'
  @Provide('pageInfo') pageInfo: NavPathStack = new NavPathStack()
  @StorageLink("pageInfo") pageInfo_: NavPathStack = this.pageInfo
  @Watch('change_mouse_KeyPressType') @StorageLink("mouse_KeyPressType") mouse_KeyPressType: KeyPressType =
    KeyPressType.DEFAULT
  @StorageLink("sideFunctionList") flax: sideFunctionList | null = null
  @StorageLink("device_isBle") device_isBle: boolean = false
  @State web: string = ''
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
  @StorageLink("isShow_passwordModification_pop") isShow_passwordModification_pop: boolean = false
  @Watch('change_isShow_bluetoothConnect_pop') @StorageLink("isShow_bluetoothConnect_pop") isShow_bluetoothConnect_pop: boolean =
    false
  @StorageLink("isBluetoothConnect_state") isBluetoothConnect_state: boolean = false //蓝牙检索状态
  @State shortcut_pop: boolean = false
  @State isNavigationLibActive: boolean = true //导航库重置
  @State isDeviceSettingsActive: boolean = true //设备设置状态
  @Watch('onDevicesChange') @StorageLink('devices') devices: DeviceArrayType_Ble[] = []
  @StorageLink("paletteTheme") paletteTheme: string = ThemeConfig.PaletteTheme
  @Watch('onResolutionChange') @StorageLink("resolutionScale") resolutionScale: string = 'followSystem'
  @State scaleValue: number = 1.0
  @State refresh: boolean = true
  @StorageLink("refreshDevicesList") refreshDevicesList: boolean = true
  @StorageLink("Unconnected") Unconnected: boolean = false //是否有设备连接
  restart(){
    if (this.netAvailable) {
      /**
       * 应用重启
       */
      // console.log('应用重启')
      // let applicationContext = (this.getUIContext().getHostContext() as common.UIAbilityContext).getApplicationContext();
      // let want: Want = {
      //   bundleName: 'com.miclink.myapplication',
      //   abilityName: 'EntryAbility'
      // };
      // try {
      //   applicationContext.restartApp(want);
      //   hilog.info(0x0000, 'testTag', '%{public}s', 'applicationContext.restartApp');
      // } catch (error) {
      //   console.error(`restartApp fail, error: ${JSON.stringify(error)}`);
      // }
    }
  }
  refreshPage() {
    this.refresh = false
    setTimeout(() => {
      this.refresh = true
    }, 20)
  }

  change_isShow_bluetoothConnect_pop() {
    if (!this.isShow_bluetoothConnect_pop) {
      if (this.isBluetoothConnect_state) {
        setTimeout(() => {
          this.isDeviceSettingsActive = false
          setTimeout(() => this.isDeviceSettingsActive = true, 20)
        }, 100)
      }
    }
  }

  return_url(condition: string): string {
    return (this.flax?.Function[this.flax.Function.findIndex(item => item.name ===
      condition)].url as string).replaceAll('SN', this.mouseconfig?.sn ? this.mouseconfig?.sn : "123")
      .replaceAll('PRDUCTCODE',
        this.mouseconfig?.productType ? this.mouseconfig?.productType.toString() : "999999")
      .replaceAll("LANGUAGE", this.languages)

  }

  web_prefix(web: number): string {
    let url: string = ''
    if (this.flax) {
      switch (web) {
        case 1:
          return this.return_url("ai-助手")
        case 2:
          return this.return_url("ai-办公")
        case 3:
          return this.return_url("ai-智能体")
        case 5:
          return this.return_url("导航库")
        case 6:
          return this.return_url("视频库")
        case 7:
          return this.return_url("模板库")
        case 9:
          return this.return_url("帮助中心")
      }
    }
    return url
    // return `https://asrai.miclink.net?sno=${this.mouseconfig?.sn ? this.mouseconfig?.sn :
    //   123}&productCode=${}&language=${this.languages}` + this.web
  }

  // TabsControllerIndex 变化监听
  onTabsControllerIndexChange(): void {
    console.log('onTabsControllerIndexChange called:', this.tabsControllerIndex)
    if (this.tabsController) {
      // 导航库逻辑
      if (this.tabsControllerIndex === 5) {
        this.isNavigationLibActive = true
      } else {
        this.isNavigationLibActive = false
      }

      // 设备设置逻辑 - 每次进入都刷新状态，触发重新渲染
      if (this.tabsControllerIndex === 0) {
        // 使用setTimeout确保状态变化生效后再设置为true，触发重新渲染
        this.isDeviceSettingsActive = true
      } else {
        this.isDeviceSettingsActive = false
      }
      this.tabsController.changeIndex(this.tabsControllerIndex)
    }
    // 同步更新 currentIndex 和 bottomCurrIndex
    this.syncCurrentIndexWithTabs()
  }

  // 修复：同步 currentIndex 和 bottomCurrIndex
  private syncCurrentIndexWithTabs(): void {
    console.log('syncCurrentIndexWithTabs - tabsControllerIndex:', this.tabsControllerIndex, 'aiModelDataLength:',
      this.aiModelDataLength)

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

  // 监听分辨率变化
  onResolutionChange(): void {
    this.updateScaleValue()
  }

  // 更新缩放值
  updateScaleValue(): void {
    if (this.resolutionScale === 'followSystem') {
      this.scaleValue = 1.0
    } else {
      this.scaleValue = parseFloat(this.resolutionScale) / 100
    }
    // console.info(`全局应用缩放比例: ${this.scaleValue}`)
  }

  // 监听设备列表变化
  onDevicesChange(): void {
    console.log('设备列表发生变化，当前设备数量:', this.devices.length)

    // 当设备列表被清空时，重置相关索引
    if (this.devices.length === 0) {
      AppStorage.setOrCreate('device_currIndex', 0)
      AppStorage.setOrCreate('device_show_currIndex', 0)
      AppStorage.setOrCreate('device_isBle', false)
      console.log('设备列表已清空，重置设备索引')
    } else {
      // 当有设备时，确保当前索引有效
      const currentIndex = AppStorage.get('device_currIndex') as number || 0
      if (currentIndex >= this.devices.length) {
        // 如果当前索引超出范围，设置为最后一个设备
        AppStorage.setOrCreate('device_currIndex', Math.max(0, this.devices.length - 1))
        console.log('设备索引超出范围，已调整为最后一个设备')
      }
    }
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

  onShortcutChange() {
    this.shortcut_pop = !this.shortcut_pop
    if (this.shortcut_pop) {
      this.pageInfo.pushPath({ 'name': 'shortcut_pop' })
    }
  }

  onPageHide(): void {
    console.log('应用最小化')
    Float_Window.creat_hide()
  }

  @State canReset: boolean = true

  aboutToAppear(): void {
    ThemeConfig.PaletteTheme = this.paletteTheme
    // const context =  this.getUIContext().getHostContext() as common.UIAbilityContext;//正规；暂不做更改
    const context = getContext(this) as common.UIAbilityContext;
    AppStorage.setOrCreate('context', context);
    AppUtil.init(context)
    AppStorage.setOrCreate('currpageIsAI', true);
    // 修复：初始化时获取正确的数据长度
    this.aiModelDataLength = AiModel_data.length;
    this.bottomDataLength = bottom_data.length;
    console.log('aiModelDataLength initialized:', this.aiModelDataLength)
    console.log('bottomDataLength initialized:', this.bottomDataLength)

    // 初始化缩放值
    this.updateScaleValue()

    let isPhysicalKeyboardExist = true;
    try {
      inputDevice.on("change", (data: inputDevice.DeviceListener) => {
        Reset()
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
        });
        ConnectDevice.connectDevice().then(() => {
          for (let item of ConnectDevice.Communication) {
            item.Communication.changPhysicalKeyboardExistState(true)
          }
          if (this.canReset) {
            hilog.warn(0x00,'热插拔','检索蓝牙设备');
            const context: common.UIAbilityContext =
              this.getUIContext().getHostContext() as common.UIAbilityContext;
            connectDevice(context)
          }
          this.canReset = false
          setTimeout(() => {
            this.canReset = true
          }, 500)

        })
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
        const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
        connectDevice(context)
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
            .scale({ x: this.scaleValue, y: this.scaleValue })
            .zIndex(100)

            if (this.refresh)
            Tabs({ controller: this.tabsController, index: this.tabsControllerIndex }) {
              // 确保 TabContent 数量与 AiModel_data + bottom_data 匹配

              TabContent() { // 设备设置
                Stack() {
                  if (this.isDeviceSettingsActive) {
                    if (this.refreshDevicesList) {
                      DeviceSettings()
                    }
                  }
                  Topbar()
                }
                .height('100%')
                .align(Alignment.TopStart)
              }

              if (this.flax)
              TabContent() { // AI-助手
                Stack() {
                  Content({ web: this.web_prefix(1) })
                  Topbar()
                }
                .height('100%')
                .align(Alignment.TopStart)
              }
              if (this.flax)
              TabContent() { // AI-办公
                Stack() {
                  Content({
                    web: this.web_prefix(2)
                    // web: 'https://asrai.miclink.net/?sno=123&productCode=999999&config=configMiclink_B_1755079145452#/aiOffice'
                  })
                  Topbar()
                }
                .height('100%')
                .align(Alignment.TopStart)
              }
              if (this.flax)
              TabContent() { // AI-智能体
                Stack() {
                  Content({ web: this.web_prefix(3) })
                  Topbar()
                }
                .height('100%')
                .align(Alignment.TopStart)
              }

              if (this.flax)
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

              if (this.flax)
              TabContent() { // 导航库
                Stack() {
                  if (this.isNavigationLibActive) {
                    Content({ web: this.web_prefix(5) })
                  }
                  Topbar()
                }
                .height('100%')
                .align(Alignment.TopStart)
              }

              if (this.flax)
              TabContent() { // 视频库
                Stack() {
                  Content({ web: this.web_prefix(6) })
                  Topbar()
                }
                .height('100%')
                .align(Alignment.TopStart)
              }

              if (this.flax)
              TabContent() { // 模板库
                Stack() {
                  Content({ web: this.web_prefix(7) })
                  Topbar()
                }
                .height('100%')
                .align(Alignment.TopStart)
              }

              if (this.flax)
              TabContent() { // 企业中心
                Stack() {
                  Content({ web: 'https://www.miclink.info/' })
                  Topbar()
                }
                .height('100%')
                .align(Alignment.TopStart)
              }

              if (this.flax)
              TabContent() { // 帮助中心
                Stack() {
                  Content({ web: this.web_prefix(9) })
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
            .scale({ x: this.scaleValue, y: this.scaleValue })
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
          if (this.isShow_passwordModification_pop) { //修改密码弹窗
            PasswordModification_pop({ isShow_passwordModification_pop: this.isShow_passwordModification_pop })
          }
          if (this.isShow_bluetoothConnect_pop) { //检索并建立蓝牙连接弹窗弹窗
            BluetoothConnect_pop({
              isShow_bluetoothConnect_pop: this.isShow_bluetoothConnect_pop,
              isBluetoothConnect_state: this.isBluetoothConnect_state
            })
          }
          // DraggableResizableRect()
        }
        .width('100%')
        .height('100%')

      }
      .hideToolBar(true)
      .hideTitleBar(true)
      .mode(NavigationMode.Stack)

      Image($r('app.media.create_Command_Ai'))
    }
    .onKeyEvent((event: KeyEvent) => {
      // 异步处理按键事件，避免阻塞UI渲染，添加超时保护
      const timeoutId = setTimeout(() => {
        try {
          globalShortcutService.handleGlobalKeyEvent(event)
        } catch (error) {
          console.error('按键事件处理失败:', error)
        }
      }, 0)

      // 如果处理时间过长，取消执行
      setTimeout(() => {
        clearTimeout(timeoutId)
      }, 100) // 100ms超时保护
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