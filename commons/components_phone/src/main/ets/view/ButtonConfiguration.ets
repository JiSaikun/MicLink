import { DeviceArrayType_Ble } from "bluetooth"
import {
  getModelInfoModel,
  keyInfosModel,
  keyInfos_childsModel,
  keyInfos_childs_childsModel,
  LanguageNames,
  Languages
} from "config"
import { ConnectDevice, DeviceInfo, KeyPressType } from "mouse"
import { LengthMetrics, promptAction } from "@kit.ArkUI"
import { BusinessError } from "@kit.BasicServicesKit"
import { picker } from "@kit.CoreFileKit"
import { OpenFileWithSystemApp } from "api"
import { _addCustomerKey } from "../viewmodel/UserViewModel"
import { addCustomerKey_Params } from "../model/UserModel"
import { CommonConfig } from "../common/CommonConfig"
import { Languages_params } from "./SmartSettings"
import { common } from "@kit.AbilityKit"

@Component
export struct ButtonConfiguration {
  @Consume('pageInfo') pageInfo: NavPathStack
  @StorageLink('devices') devices: DeviceArrayType_Ble[] = []
  @Watch('onGetModelInfoChange') @StorageLink('getModelInfo') getModelInfo: getModelInfoModel =
    AppStorage.get('getModelInfo') as getModelInfoModel
  @State mouseconfig: DeviceInfo | null = null
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State KeymethodConfig: KeymethodConfig[] = []
  @Link device_isBle: boolean
  @State isLoading: boolean = false
  @State isDataReady: boolean = false
  @State hasDeviceDisconnected: boolean = false
  @Watch("changeOption") @StorageLink("currentSelectedIndex") currentSelectedIndex: number = -1
  @State index1: number = 0
  @State index2: number = 0
  @State childs: keyInfos_childs_childsModel[] = []
  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: Action_FT(),
    cancel: this.exitApp,
    autoCancel: true,
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: -20 },
    gridCount: 4,
    customStyle: false,
    cornerRadius: 16
  })
  dialogController_Action_OW: CustomDialogController | null = new CustomDialogController({
    builder: Action_OW({
      cancel: () => {
        this.onCancel();
      },
      confirm: () => {
        this.onAccept();
      }
    }),
    cancel: this.exitApp_,
    autoCancel: true,
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: -20 },
    gridCount: 4,
    customStyle: false,
    cornerRadius: 16
  })

  onCancel() {
    console.info('单击第一个按钮时回调');
  }

  onAccept() {
    console.info('点击第二个按钮时回调');
  }

  // 在自定义组件即将析构销毁时将dialogController置空
  aboutToDisappear() {
    this.dialogController = null; // 将dialogController置空
  }

  exitApp() {
    console.info('单击空白区域中的回拨');
    this.dialogController?.open()
  }

  exitApp_() {
    console.info('单击空白区域中的回拨');
    this.dialogController_Action_OW?.open()
  }

  /**
   * 处理特殊命令
   */
  private handleSpecialCommand(cmd: string): void {
    switch (cmd) {
      case 'Action_FT': //固定文本
        if (this.dialogController != null) {
          this.dialogController.open();
        }
        break
      case 'Action_OW': //打开网页
        if (this.dialogController_Action_OW != null) {
          this.dialogController_Action_OW.open();
        }
        break
      case 'Action_OF': //打开文件
        OpenFileWithSystemApp.openFileWithSystemApp()
        break
      case 'Action_OFJ': //打开文件夹
        this.selectFolder()
        break
    }
  }

  build() {

    Column({ space: 12 }) {
      if (this.hasDeviceDisconnected) {
        // 设备断开时显示空白
        Blank()
      } else if (this.getModelInfo?.keyInfos && this.isDataReady) {
        Scroll() {
          // 数据加载完成的情况
          Column({ space: 12 }) {
            ForEach(this.getModelInfo.keyInfos, (item: keyInfosModel, index1: number) => {
              Text((item.names as LanguageNames)[this.languages])
                .fontSize(CommonConfig.fontSize_14)
                .fontWeight(CommonConfig.fontWeight_400)
                .fontColor(CommonConfig.hintTextColor)

              ForEach(item.childs, (child: keyInfos_childsModel, index2: number) => {
                Column() {

                  Row() {
                    Text((child.names as LanguageNames)[this.languages])
                      .fontSize(CommonConfig.fontSize_14)
                      .fontColor(CommonConfig.hintTextColor_select)
                      .fontWeight(CommonConfig.fontWeight_400)
                    Blank()
                    Row() {
                      Text(((child.childs[this.getDefaultSelectedIndex(child.childs, index1,
                        index2)] as keyInfos_childs_childsModel).names as LanguageNames)[this.languages])
                        .fontSize(CommonConfig.fontSize_12)
                        .fontColor(CommonConfig.hintTextColor)
                        .fontWeight(CommonConfig.fontWeight_400)
                        .margin({ right: 8 })
                      Image($r('app.media.Arrow_to_the_right'))
                        .width(16)
                        .height(16)
                    }.onClick(() => {
                      this.index1 = index1
                      this.index2 = index2
                      this.childs = child.childs
                      this.currentSelectedIndex = -1
                      let params: Languages_params = {
                        ListData: this.convertChildsToOptions(child.childs || []),
                        OperationType: 'buttonConfiguration',
                        currLanguages: this.getDefaultSelectedIndex(child.childs || [], index1, index2),
                        device_isBle: this.device_isBle,
                        title: (child.names as LanguageNames)[this.languages],
                      }
                      this.pageInfo.pushPath({ "name": 'Changelanguage', param: params })
                    })

                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Center)
                  .padding({ top: 12, bottom: 12 })
                }
                .padding({ left: 12, right: 12 })
                .borderRadius(12)
                .backgroundColor(Color.White)

              }, (item: keyInfos_childsModel) => item.name)

            }, (item: keyInfosModel) => item.keyName)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .scrollBarWidth(0)
        .align(Alignment.TopStart)


        Blank()
        Column() {
          Text(Languages.firmwareVersion[this.languages] + this.mouseconfig?.firmwareVersion)
            .fontSize(CommonConfig.fontSize_12)
            .fontColor(CommonConfig.hintTextColor)
            .fontWeight(CommonConfig.fontWeight_400)
            .margin({ bottom: 8 })
          Text('SN：' + this.mouseconfig?.sn)
            .fontSize(CommonConfig.fontSize_12)
            .fontColor(CommonConfig.hintTextColor)
            .fontWeight(CommonConfig.fontWeight_400)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      } else {
        // 数据加载中的情况
        Column() {
          Text('加载中...')
            .fontSize(14)
            .fontColor('#a4aab2')
        }
        .width('100%')
        .height(100)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')

  }

  changeOption() {
    if (this.currentSelectedIndex >= 0) {
      this.handleSelect(this.index1, this.index2, this.currentSelectedIndex, this.childs || [])
    }
  }

  // 监听 getModelInfo 变化
  onGetModelInfoChange(): void {
    console.log('getModelInfo 已更新，重新初始化 KeymethodConfig')

    // 检查设备是否已断开连接
    if (this.checkDeviceDisconnected()) {
      console.log('检测到设备已断开连接，关闭配置页面')
      this.hasDeviceDisconnected = true
      return
    }

    this.initKeymethodConfig()
  }

  aboutToAppear(): void {
    const deviceIndex = AppStorage.get('device_show_currIndex') as number || 0

    if (this.device_isBle) {
      if (this.devices && deviceIndex >= 0 && deviceIndex < this.devices.length && this.devices[deviceIndex]) {
        this.mouseconfig = this.devices[deviceIndex].mouseconfig as DeviceInfo
      } else {
        console.error('ConfigPage2: 蓝牙设备索引无效或设备不存在:', deviceIndex, this.devices?.length)
        this.mouseconfig = null
      }
    } else {
      if (ConnectDevice.Communication && deviceIndex >= 0 && deviceIndex < ConnectDevice.Communication.length &&
      ConnectDevice.Communication[deviceIndex]) {
        this.mouseconfig = ConnectDevice.Communication[deviceIndex].mouseconfig as DeviceInfo
      } else {
        console.error('ConfigPage2: 2.4G设备索引无效或设备不存在:', deviceIndex, ConnectDevice.Communication?.length)
        this.mouseconfig = null
      }
    }

    // 初始检查设备状态
    if (this.checkDeviceDisconnected()) {
      console.log('初始检测到设备已断开连接，关闭配置页面')
      this.hasDeviceDisconnected = true
      return
    }

    this.initKeymethodConfig()
  }

  /**
   * 检查设备是否已断开连接
   */
  private checkDeviceDisconnected(): boolean {
    try {
      const currIndex = AppStorage.get('device_show_currIndex') as number
      const communication = this.device_isBle ? this.devices[currIndex] : ConnectDevice.Communication[currIndex]

      // 检查关键数据是否存在
      if (!communication ||
        !communication.getModelInfo ||
        !communication.mouseconfig) {
        return true
      }

      // 检查关键数据是否为空
      if (!this.getModelInfo ||
        !this.getModelInfo.keyInfos ||
        this.getModelInfo.keyInfos.length === 0) {
        return true
      }

      return false
    } catch (error) {
      console.error('检查设备状态时出错:', error)
      return true
    }
  }

  /**
   * 初始化 KeymethodConfig
   */
  private initKeymethodConfig(): void {
    if (this.hasDeviceDisconnected) {
      return
    }

    if (!this.getModelInfo?.keyInfos || this.getModelInfo.keyInfos.length === 0) {
      this.hasDeviceDisconnected = true
      return
    }

    // 创建默认配置
    const defaultConfig: KeymethodConfig[] = [
      { key: KeyPressType.VOICE_CLICK, currIndex: 0 },
      { key: KeyPressType.VOICE_LONG_PRESS_DOWN, currIndex: 0 },
      { key: KeyPressType.SEARCH_CLICK, currIndex: 0 },
      { key: KeyPressType.SEARCH_LONG_PRESS_DOWN, currIndex: 0 },
      { key: KeyPressType.TRANSLATE_CLICK, currIndex: 0 },
      { key: KeyPressType.TRANSLATE_LONG_PRESS_DOWN, currIndex: 0 },
      { key: KeyPressType.AI_CLICK, currIndex: 0 },
      { key: KeyPressType.AI_LONG_PRESS_DOWN, currIndex: 0 },
      { key: KeyPressType.CUSTOM_CLICK, currIndex: 0 },
      { key: KeyPressType.CUSTOM_LONG_PRESS_DOWN, currIndex: 0 }
    ]

    // 从 getModelInfo 中读取实际的配置
    this.getModelInfo.keyInfos.forEach((item: keyInfosModel, index1: number) => {
      item.childs.forEach((child: keyInfos_childsModel, index2: number) => {
        const childs = child.childs || []
        for (let i = 0; i < childs.length; i++) {
          if (childs[i].first === 1) {
            this.updateKeymethodConfigByOperation(item.key, child.operation, i, defaultConfig)
            break
          }
        }
      })
    })

    this.KeymethodConfig = [...defaultConfig]
    if (this.device_isBle) {
      this.devices[AppStorage.get('device_show_currIndex') as number].KeymethodConfig =
        [...defaultConfig]
    } else {
      ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].KeymethodConfig =
        [...defaultConfig]
    }
    this.isDataReady = true
    this.hasDeviceDisconnected = false
  }

  /**
   * 根据操作类型更新配置
   */
  private updateKeymethodConfigByOperation(key: string, operation: string, index: number,
    config: KeymethodConfig[]): void {
    switch (key) {
      case 'voice_key':
        if (operation === 'sk') {
          config[0].currIndex = index
        }
        if (operation === 'lk') {
          config[1].currIndex = index
        }
        break
      case 'search_key':
        if (operation === 'sk') {
          config[2].currIndex = index
        }
        if (operation === 'lk') {
          config[3].currIndex = index
        }
        break
      case 'translate_key':
        if (operation === 'sk') {
          config[4].currIndex = index
        }
        if (operation === 'lk') {
          config[5].currIndex = index
        }
        break
      case 'AI_key':
        if (operation === 'sk') {
          config[6].currIndex = index
        }
        if (operation === 'lk') {
          config[7].currIndex = index
        }
        break
      case 'M_key':
        if (operation === 'sk') {
          config[8].currIndex = index
        }
        if (operation === 'lk') {
          config[9].currIndex = index
        }
        break
    }
  }

  /**
   * 将子项转换为ArkUI官方SelectOption数组
   */
  private convertChildsToOptions(childs: keyInfos_childs_childsModel[]): SelectOption[] {
    if (!childs || childs.length === 0) {
      return []
    }

    return childs.map((child: keyInfos_childs_childsModel, index: number) => {
      const displayText = (child.names as LanguageNames)[this.languages] || `选项${index + 1}`
      return {
        value: displayText
      } as SelectOption
    })
  }

  /**
   * 获取默认选中索引
   */
  private getDefaultSelectedIndex(childs: keyInfos_childs_childsModel[], index1: number, index2: number): number {
    if (!childs || childs.length === 0) {
      return 0
    }

    // 从当前的 KeymethodConfig 中获取
    const configIndex = this.getKeymethodConfigIndex(
      this.getModelInfo.keyInfos[index1].key,
      this.getModelInfo.keyInfos[index1].childs[index2].operation
    )

    if (configIndex !== -1 && this.KeymethodConfig[configIndex]) {
      return this.KeymethodConfig[configIndex].currIndex
    }

    // 如果没有配置，则查找 first=1 的项
    for (let i = 0; i < childs.length; i++) {
      if (childs[i].first === 1) {
        return i
      }
    }

    return 0
  }

  /**
   * 根据 key 和 operation 获取 KeymethodConfig 索引
   */
  private getKeymethodConfigIndex(key: string, operation: string): number {
    switch (key) {
      case 'voice_key':
        return operation === 'sk' ? 0 : 1
      case 'search_key':
        return operation === 'sk' ? 2 : 3
      case 'translate_key':
        return operation === 'sk' ? 4 : 5
      case 'AI_key':
        return operation === 'sk' ? 6 : 7
      case 'M_key':
        return operation === 'sk' ? 8 : 9
      default:
        return -1
    }
  }

  /**
   * 处理选项选择
   */
  private handleSelect(index1: number, index2: number, index: number, childs: keyInfos_childs_childsModel[]): void {
    // 再次检查设备状态
    if (this.checkDeviceDisconnected()) {
      promptAction.showToast({ message: '设备已断开连接', duration: 2000 })
      return
    }

    let params: addCustomerKey_Params = {
      cmdId: this.getModelInfo.keyInfos[index1].childs[index2].childs[index].cmdId.toString(),
      keyId: this.getModelInfo.keyInfos[index1].childs[index2].childs[index].keyId.toString(),
      opId: this.getModelInfo.keyInfos[index1].childs[index2].childs[index].opId.toString(),
      sno: this.mouseconfig?.sn as string,
      userModelId: this.getModelInfo.id.toString()
    }

    _addCustomerKey(params)

    // 更新 first 标志
    const currentSelectedIndex = this.getDefaultSelectedIndex(childs, index1, index2)
    this.getModelInfo.keyInfos[index1].childs[index2].childs[currentSelectedIndex].first = 0
    this.getModelInfo.keyInfos[index1].childs[index2].childs[index].first = 1

    // 更新 KeymethodConfig
    const configIndex = this.getKeymethodConfigIndex(
      this.getModelInfo.keyInfos[index1].key,
      this.getModelInfo.keyInfos[index1].childs[index2].operation
    )

    if (configIndex !== -1) {
      this.KeymethodConfig[configIndex].currIndex = index
      if (this.device_isBle) {
        this.devices[AppStorage.get('device_show_currIndex') as number].KeymethodConfig =
          [...this.KeymethodConfig]
      } else {
        ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].KeymethodConfig =
          [...this.KeymethodConfig]
      }
    }

    // 处理特殊命令
    this.handleSpecialCommand(this.getModelInfo.keyInfos[index1].childs[index2].childs[index].cmd)
  }

  // 保留原有的 Watch_null 方法用于兼容性
  Watch_null(): void {
    if (!this.getModelInfo?.keyInfos || this.getModelInfo.keyInfos.length === 0) {
      this.hasDeviceDisconnected = true
    }
  }

  selectFolder(): void {
    this.isLoading = true
    try {
      let documentPicker = new picker.DocumentViewPicker()
      documentPicker.select({
        selectMode: picker.DocumentSelectMode.FOLDER
      })
        .then((result: string[]) => {
          if (!result || result.length === 0) {
            promptAction.showToast({ message: '未选择任何文件', duration: 2000 })
            return
          }
          const filePath = result[0]
          const lastSlashIndex = filePath.lastIndexOf('/')
          if (lastSlashIndex !== -1) {
            AppStorage.setOrCreate('folderPath', result[0])
            promptAction.showToast({ message: `已选择文件夹: ${result[0]}`, duration: 2500 })
          } else {
            promptAction.showToast({ message: '无法解析文件夹路径', duration: 2000 })
          }
        })
        .catch((err: BusinessError) => {
          const errorMsg = this.getFolderSelectErrorMsg(err.code)
          promptAction.showToast({ message: errorMsg, duration: 3000 })
        })
        .finally(() => {
          this.isLoading = false
        })
    } catch (err) {
      promptAction.showToast({ message: '文件夹选择功能异常', duration: 3000 })
      this.isLoading = false
    }
  }

  /**
   * 辅助函数：根据错误码返回文件夹选择的友好提示
   */
  getFolderSelectErrorMsg(errorCode: number): string {
    switch (errorCode) {
      case 1001:
        return '需要文件访问权限，请在设置中开启'
      case 1002:
        return '已取消文件夹选择'
      case 1003:
        return '无文件夹访问权限，请授权后重试'
      default:
        return `选择失败（错误码: ${errorCode}）`
    }
  }
}

export interface KeymethodConfig {
  key: KeyPressType
  currIndex: number
}

@CustomDialog
@Component
struct Action_FT {
  // 若尝试在CustomDialog中传入多个其他的Controller，以实现在CustomDialog中打开另一个或另一些CustomDialog，那么此处需要将指向自己的controller放在所有controller的后面
  controller?: CustomDialogController;
  @StorageLink('languages') languages: string = 'ZH_CN'
  @StorageLink('fixedText') fixedText: string = '' //输入固定文本
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme

  build() {
    Column() {
      Row() {
        // Text('输入固定文本')
        Text(Languages.input_fixed_text[this.languages])
          .fontSize(16)
          .fontWeight(400)
          .fontColor(Color.White)
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .borderRadius({ topLeft: 8, topRight: 8 })
      .padding(10)
      .backgroundColor(this.paletteTheme)

      // TextInput({ placeholder: '请输入固定文本', text: $$this.fixedText })
      TextInput({ placeholder: Languages.enter_fixed_text_placeholder[this.languages], text: $$this.fixedText })
        .backgroundColor('#fff')
        .placeholderColor('#bbbdbf')
        .margin({
          top: 50,
          bottom: 50,
          left: 20,
          right: 20
        })
        .placeholderFont({ size: 14, weight: 400 })
        .border({ width: 1, color: '#eaeaea' })
        .borderRadius(5)

      Flex({ justifyContent: FlexAlign.Center }) {
        // Text('确定')
        Text(Languages.confirm_btn[this.languages])
          .fontSize(16)
          .fontWeight(400)
          .fontColor(Color.White)
          .padding({
            top: 15,
            bottom: 15,
            left: 35,
            right: 35
          })
          .margin({ left: 20, right: 20 })
          .textAlign(TextAlign.Center)
          .backgroundColor(this.paletteTheme)
          .borderRadius(5)
          .onClick(() => {
            if (this.fixedText) {
              this.controller?.close()
            } else {
              this.getUIContext().getPromptAction().showDialog({
                title: ('固定输入文本为空，是否重新设置'),
                buttons: [{ text: '是', color: '#007DFF' }, { text: '否', color: '#FF3B30' },]
              }).then((res: promptAction.ShowDialogSuccessResponse) => {
                switch (res.index) {
                  case 1:
                    this.controller?.close()
                    break
                }
              })
            }
          })
          .width('100%')
      }
      .width('100%')
    }
    .shadow({ radius: 10, color: '#e9e9eb' })
    .width('100%')
    .borderRadius(8)
    .backgroundColor('#f5f5f5')
    .zIndex(10)
    .padding({ bottom: 20 })

  }
}

@CustomDialog
@Component
struct Action_OW {
  // 若尝试在CustomDialog中传入多个其他的Controller，以实现在CustomDialog中打开另一个或另一些CustomDialog，那么此处需要将指向自己的controller放在所有controller的后面
  cancel: () => void = () => {
  }
  confirm: () => void = () => {
  }
  controller?: CustomDialogController;
  @StorageLink('languages') languages: string = 'ZH_CN'
  @StorageLink('webUrlToOpen_pop') webUrlToOpen: string = '' //输入固定文本
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  aboutToAppear(): void {
    this.webUrlToOpen=AppStorage.get('webUrlToOpen') as string
  }

  build() {
    Column() {
      Row() {
        Text(Languages.input_web_url[this.languages])
          .fontSize(16)
          .fontWeight(400)
          .fontColor(Color.White)
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .borderRadius({ topLeft: 8, topRight: 8 })
      .padding(10)
      .backgroundColor(this.paletteTheme)

      TextInput({
        placeholder: Languages.enter_web_url_placeholder[this.languages] +
          '\n例如: www.example.com 或 https://example.com',
        text: $$this.webUrlToOpen
      })
        .backgroundColor('#fff')
        .placeholderColor('#bbbdbf')
        .margin({
          top: 50,
          bottom: 50,
          left: 20,
          right: 20
        })
        .placeholderFont({ size: 14, weight: 400 })
        .border({ width: 1, color: '#eaeaea' })
        .borderRadius(5)

      Flex({ justifyContent: FlexAlign.Center }) {
        Text(Languages.confirm_btn[this.languages])
          .fontSize(16)
          .fontWeight(400)
          .fontColor(Color.White)
          .padding({
            top: 15,
            bottom: 15,
            left: 35,
            right: 35
          })
          .textAlign(TextAlign.Center)
          .margin({
            left: 20,
            right: 20
          })
          .backgroundColor(this.paletteTheme)
          .borderRadius(5)
          .width('100%')
          .onClick(() => {
            const urlRegex = /^(https?:\/\/)?[\w.-]+\.[a-z]{2,}.*$/i;
            if (!this.webUrlToOpen) {
              this.getUIContext().getPromptAction().showDialog({
                title: ('网页地址为空值，是否重新设置'),
                buttons: [{ text: '是', color: '#007DFF' }, { text: '否', color: '#FF3B30' },]
              }).then((res: promptAction.ShowDialogSuccessResponse) => {
                switch (res.index) {
                  case 1:
                    AppStorage.setOrCreate('webUrlToOpen', 'https://www.baidu.com');
                    this.controller?.close()
                    break
                }
              })
              return
            }
            if (!urlRegex.test(this.webUrlToOpen)) {
              this.getUIContext().getPromptAction().showDialog({
                title: (Languages.please_enter_valid_website[this.languages] +
                  '\n例如: www.example.com 或 https://example.com' + "\n" + '是否选择清空重新输入？'),
                buttons: [{ text: '是', color: '#007DFF' }, { text: '否', color: '#FF3B30' },]
              }).then((res: promptAction.ShowDialogSuccessResponse) => {
                switch (res.index) {
                  case 0:
                    this.webUrlToOpen = ''
                    break
                }
              })
              return
            }
            // 如果URL已包含协议，直接使用
            if (this.webUrlToOpen.startsWith('http://') || this.webUrlToOpen.startsWith('https://')) {
              AppStorage.setOrCreate('webUrlToOpen', this.webUrlToOpen);
              this.controller?.close()
            } else {
              // 如果不包含协议，显示协议选择弹窗
              this.getUIContext().getPromptAction().showDialog({
                title: ('选择协议类型'),
                buttons: [{ text: '使用 HTTP', color: '#007DFF' }, { text: '使用 HTTPS (推荐)', color: '#007DFF' },]
              }).then((res: promptAction.ShowDialogSuccessResponse) => {
                switch (res.index) {
                  case 0:
                    this.webUrlToOpen = 'http://' + this.webUrlToOpen
                    AppStorage.setOrCreate('webUrlToOpen', this.webUrlToOpen);
                    this.controller?.close()
                    break
                  case 1:
                    this.webUrlToOpen = 'https://' + this.webUrlToOpen
                    AppStorage.setOrCreate('webUrlToOpen', this.webUrlToOpen);
                    this.controller?.close()
                    break
                }
              })
            }
          })
      }
      .width('100%')
    }
    .shadow({ radius: 10, color: '#e9e9eb' })
    .width('100%')
    .borderRadius(8)
    .backgroundColor('#f5f5f5')
    .zIndex(10)
    .padding({ bottom: 20 })

  }
}