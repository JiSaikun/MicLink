import { ConnectDevice, DeviceInfo, KeyPressType } from 'mouse'
import { LengthMetrics, promptAction } from "@kit.ArkUI"
import { addCustomerKey_Params } from '../model/UserModel'
import { _addCustomerKey } from '../viewmodel/UserViewModel'
import {
  getModelInfoModel,
  keyInfosModel,
  LanguageNames,
  keyInfos_childsModel,
  keyInfos_childs_childsModel
} from 'config' //获取设备按键信息
import { picker } from '@kit.CoreFileKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { OpenFileWithSystemApp } from 'api'

export interface KeymethodConfig {
  key: KeyPressType
  currIndex: number
}

/**
 * 按键设置
 */
@Component
export struct ConfigPage2 {
  @Watch('onGetModelInfoChange') @StorageLink('getModelInfo') getModelInfo: getModelInfoModel =
    ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].getModelInfo as getModelInfoModel
  @State mouseconfig: DeviceInfo =
    ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].mouseconfig as DeviceInfo //鼠标信息
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State KeymethodConfig: KeymethodConfig[] = []
  @StorageLink("shortcut") shortcut: number = 0 //改变该值弹出对应快捷键悬浮窗口 1：语音识别 2：语音翻译 3:截图识别 4：自定义快捷键
  @Link isShowConfig: boolean
  @State isLoading: boolean = false;
  @State isDataReady: boolean = false

  // 监听 getModelInfo 变化
  onGetModelInfoChange() {
    console.log('getModelInfo 已更新，重新初始化 KeymethodConfig')
    this.initKeymethodConfig()
  }

  aboutToAppear(): void {
    this.initKeymethodConfig()
  }

  /**
   * 初始化 KeymethodConfig
   */
  private initKeymethodConfig() {
    if (!this.getModelInfo?.keyInfos || this.getModelInfo.keyInfos.length === 0) {
      console.log('keyInfos 为空，跳过初始化')
      this.KeymethodConfig = []
      this.isDataReady = false
      return
    }

    console.log('开始初始化 KeymethodConfig')

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
    this.getModelInfo.keyInfos.forEach((item, index1) => {
      item.childs.forEach((child, index2) => {
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
    ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].KeymethodConfig = [...defaultConfig]
    this.isDataReady = true

    console.log('KeymethodConfig 初始化完成:', JSON.stringify(defaultConfig))
  }

  /**
   * 根据操作类型更新配置
   */
  private updateKeymethodConfigByOperation(key: string, operation: string, index: number, config: KeymethodConfig[]) {
    switch (key) {
      case 'voice_key':
        if (operation === 'sk') config[0].currIndex = index
        if (operation === 'lk') config[1].currIndex = index
        break
      case 'search_key':
        if (operation === 'sk') config[2].currIndex = index
        if (operation === 'lk') config[3].currIndex = index
        break
      case 'translate_key':
        if (operation === 'sk') config[4].currIndex = index
        if (operation === 'lk') config[5].currIndex = index
        break
      case 'AI_key':
        if (operation === 'sk') config[6].currIndex = index
        if (operation === 'lk') config[7].currIndex = index
        break
      case 'M_key':
        if (operation === 'sk') config[8].currIndex = index
        if (operation === 'lk') config[9].currIndex = index
        break
    }
  }

  /**
   * 将子项转换为ArkUI官方SelectOption数组
   */
  private convertChildsToOptions(childs: keyInfos_childs_childsModel[]): SelectOption[] {
    return childs.map((child, index) => {
      const displayText = (child.names as LanguageNames)[this.languages]
      return {
        value: displayText
      } as SelectOption;
    });
  }

  /**
   * 获取默认选中索引
   */
  private getDefaultSelectedIndex(childs: keyInfos_childs_childsModel[], index1: number, index2: number): number {
    if (!childs || childs.length === 0) return 0

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
  private handleSelect(index1: number, index2: number, index: number, childs: keyInfos_childs_childsModel[]) {
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
      ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].KeymethodConfig = [...this.KeymethodConfig]
    }

    // 处理特殊命令
    this.handleSpecialCommand(this.getModelInfo.keyInfos[index1].childs[index2].childs[index].cmd)
  }

  /**
   * 处理特殊命令
   */
  private handleSpecialCommand(cmd: string) {
    switch (cmd) {
      case 'Action_SK':
        this.shortcut = 4
        break
      case 'Action_FT':
        AppStorage.setOrCreate('isShowFixedText_pop', true)
        break
      case 'Action_OW':
        AppStorage.setOrCreate('isShow_webUrlToOpen_pop', true)
        break
      case 'Action_OF':
        OpenFileWithSystemApp.openFileWithSystemApp()
        break
      case 'Action_OFJ':
        this.selectFolder()
        break
    }
  }

  build() {
    if (this.getModelInfo?.keyInfos && this.isDataReady) {
      Flex({ space: { main: LengthMetrics.px(15) }, direction: FlexDirection.Column }) {
        ForEach(this.getModelInfo.keyInfos, (item: keyInfosModel, index1) => {
          Text((item.names as LanguageNames)[this.languages])
            .fontSize(14)
            .lineHeight(14)
            .fontWeight(400)
            .fontColor('#a4aab2')
            .margin(index1 === 0 ? { bottom: 10 } : { bottom: 5, top: 10 })

          ForEach(item.childs, (child: keyInfos_childsModel, index2) => {
            Text((child.names as LanguageNames)[this.languages])
              .fontSize($r('app.float.default_text_font_size_14'))
              .fontWeight(400)
              .fontColor($r('app.string.DEFAULT_FONT_COLOR'))

            Select(this.convertChildsToOptions(child.childs || []))
              .value(((child.childs[this.getDefaultSelectedIndex(child.childs, index1, index2)] as keyInfos_childs_childsModel).names as LanguageNames)[this.languages])
              .onSelect((index: number, value) => {
                this.handleSelect(index1, index2, index, child.childs || [])
              })
              .selected(this.getDefaultSelectedIndex(child.childs || [], index1, index2))
              .width('100%')
              .font({ size: $r('app.float.default_text_font_size_14'), weight: 400 })
              .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
              .borderRadius(4)
              .border({ width: 1, color: $r('app.string.DEFAULT_BORDER_COLOR') })
              .backgroundColor(Color.White)
          }, (item: keyInfos_childsModel) => item.name)

        }, (item: keyInfosModel) => item.keyName)
      }
      .width('100%')
    } else {
      // 数据加载中的状态
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

  Watch_null() {
    if (!this.getModelInfo?.keyInfos || this.getModelInfo.keyInfos.length === 0) {
      this.isShowConfig = false
    }
  }

  selectFolder(): void {
    this.isLoading = true;
    try {
      let documentPicker = new picker.DocumentViewPicker();
      documentPicker.select({
        selectMode: picker.DocumentSelectMode.FOLDER
      })
        .then((result: string[]) => {
          if (!result || result.length === 0) {
            promptAction.showToast({ message: '未选择任何文件', duration: 2000 });
            return;
          }
          const filePath = result[0];
          const lastSlashIndex = filePath.lastIndexOf('/');
          if (lastSlashIndex !== -1) {
            AppStorage.setOrCreate('folderPath', result[0])
            console.log('提取的文件夹路径:', result[0]);
            promptAction.showToast({ message: `已选择文件夹: ${result[0]}`, duration: 2500 });
          } else {
            promptAction.showToast({ message: '无法解析文件夹路径', duration: 2000 });
          }
        })
        .catch((err: BusinessError) => {
          const errorMsg = this.getFolderSelectErrorMsg(err.code);
          console.error('文件夹选择失败:', errorMsg, '错误码:', err.code);
          promptAction.showToast({ message: errorMsg, duration: 3000 });
        })
        .finally(() => {
          this.isLoading = false;
        });
    } catch (err) {
      console.error('文件夹选择代码异常:', (err as Error).message);
      promptAction.showToast({ message: '文件夹选择功能异常', duration: 3000 });
      this.isLoading = false;
    }
  }

  /**
   * 辅助函数：根据错误码返回文件夹选择的友好提示
   */
  getFolderSelectErrorMsg(errorCode: number): string {
    switch (errorCode) {
      case 1001:
        return '需要文件访问权限，请在设置中开启';
      case 1002:
        return '已取消文件夹选择';
      case 1003:
        return '无文件夹访问权限，请授权后重试';
      default:
        return `选择失败（错误码: ${errorCode}）`;
    }
  }
}