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
import { common } from '@kit.AbilityKit'
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
  @Watch('Watch_null') @StorageLink('getModelInfo') getModelInfo: getModelInfoModel =ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].getModelInfo as getModelInfoModel
  @State mouseconfig: DeviceInfo  = ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].mouseconfig as DeviceInfo //鼠标信息
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State KeymethodConfig: KeymethodConfig[] = ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].KeymethodConfig
  @StorageLink("shortcut") shortcut: number = 0 //改变该值弹出对应快捷键悬浮窗口 1：语音识别 2：语音翻译 3:截图识别 4：自定义快捷键
  @Link isShowConfig: boolean
  @State isLoading: boolean = false;

  /**
   * 将子项转换为ArkUI官方SelectOption数组
   * （使用官方类型，避免自定义对象导致的“未声明类型”报错）
   */
  private convertChildsToOptions(childs: keyInfos_childs_childsModel[]): SelectOption[] {
    return childs.map((child, index) => {
      // 多语言适配：优先取当前语言文本，无则按顺序兜底
      const displayText = (child.names as LanguageNames)[this.languages]
      // console.error(displayText)
      // 返回ArkUI官方SelectOption类型的对象（非自定义类型，符合规范）
      return {
        value: displayText     // 选项显示文本
      } as SelectOption; // 显式断言为官方类型，消除“未声明类型”警告
    });
  }

  /**
   * 获取默认选中索引（childs中first=1的项为默认选中）
   */
  private getDefaultSelectedIndex(childs: keyInfos_childs_childsModel[], index1: number, index2: number): number {
    for (let i = 0; i < childs.length; i++) {
      if (childs[i].first === 1) {
        if (!this.KeymethodConfig.length) {
          // console.error('*****************************************************************',JSON.stringify(this.getModelInfo))
          this.KeymethodConfig=[
            { key: KeyPressType.VOICE_CLICK, currIndex: 0 }, { key: KeyPressType.VOICE_LONG_PRESS_DOWN, currIndex: 0 },
            { key: KeyPressType.SEARCH_CLICK, currIndex: 0 },
            { key: KeyPressType.SEARCH_LONG_PRESS_DOWN, currIndex: 0 },
            { key: KeyPressType.TRANSLATE_CLICK, currIndex: 0 },
            { key: KeyPressType.TRANSLATE_LONG_PRESS_DOWN, currIndex: 0 },
            { key: KeyPressType.AI_CLICK, currIndex: 0 }, { key: KeyPressType.TRANSLATE_LONG_PRESS_DOWN, currIndex: 0 },
          ]
        }
        switch (this.getModelInfo.keyInfos[index1].key) {
          case 'voice_key':
            if (this.getModelInfo.keyInfos[index1].childs[index2].operation==='sk') {
              this.KeymethodConfig[0].currIndex = i
            }
            if (this.getModelInfo.keyInfos[index1].childs[index2].operation==='lk') {
              this.KeymethodConfig[1].currIndex = i
            }
            break
          case 'search_key':
            if (this.getModelInfo.keyInfos[index1].childs[index2].operation==='sk') {
              this.KeymethodConfig[2].currIndex = i
            }
            if (this.getModelInfo.keyInfos[index1].childs[index2].operation==='lk') {
              this.KeymethodConfig[3].currIndex = i
            }
            break
          case 'translate_key':
            if (this.getModelInfo.keyInfos[index1].childs[index2].operation==='sk') {
              this.KeymethodConfig[4].currIndex = i
            }
            if (this.getModelInfo.keyInfos[index1].childs[index2].operation==='lk') {
              this.KeymethodConfig[5].currIndex = i
            }
            break
          case 'AI_key':
            if (this.getModelInfo.keyInfos[index1].childs[index2].operation==='sk') {
              this.KeymethodConfig[6].currIndex = i
            }
            if (this.getModelInfo.keyInfos[index1].childs[index2].operation==='lk') {
              this.KeymethodConfig[7].currIndex = i
            }
            break
        }
        ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].KeymethodConfig=this.KeymethodConfig
        // console.log('*/*/*/*/*', JSON.stringify(AppStorage.get('KeymethodConfig')))
        // AppStorage.setOrCreate('KeymethodConfig', this.KeymethodConfig)

        return i;
        // switch (this.getModelInfo.keyInfos[index1].key) {
        //   case 'voice_key':
        //     if (index2) {
        //       return this.KeymethodConfig[1].currIndex
        //     } else {
        //       return this.KeymethodConfig[0].currIndex
        //     }
        //   case 'search_key':
        //     if (index2) {
        //       return this.KeymethodConfig[3].currIndex
        //     } else {
        //       return this.KeymethodConfig[2].currIndex
        //     }
        //   case 'translate_key':
        //     if (index2) {
        //       return this.KeymethodConfig[5].currIndex
        //     } else {
        //       return this.KeymethodConfig[4].currIndex
        //     }
        //   case 'AI_key':
        //     if (index2) {
        //       return this.KeymethodConfig[7].currIndex
        //     } else {
        //       return this.KeymethodConfig[6].currIndex
        //     }
        // }
      }
    }
    return 0; // 无默认项时选中第一个
  }

  aboutToAppear(): void {
  }

  build() {
    if (this.getModelInfo.keyInfos) {
      Flex({ space: { main: LengthMetrics.px(15) }, direction: FlexDirection.Column }) {
        ForEach(this.getModelInfo.keyInfos, (item: keyInfosModel, index1) => {
          Text((item.names as LanguageNames)[this.languages])//多语言还未添加
            .fontSize(14)
            .lineHeight(14)
            .fontWeight(400)
            .fontColor('#a4aab2')
            .margin(index1 === 0 ? { bottom: 10 } : { bottom: 5, top: 10 })
          // Select()
          ForEach(item.childs, (item: keyInfos_childsModel, index2) => {
            Text((item.names as LanguageNames)[this.languages])
              .fontSize($r('app.float.default_text_font_size_14'))
              .fontWeight(400)
              .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
            Select(this.convertChildsToOptions(item.childs || []))
              .value(((item.childs[this.getDefaultSelectedIndex(item.childs, index1,
                index2)] as keyInfos_childs_childsModel).names as LanguageNames)[this.languages
              ])
              .onSelect((index: number, value) => {
                let params: addCustomerKey_Params = {
                  cmdId: this.getModelInfo.keyInfos[index1].childs[index2].childs[index].cmdId.toString(),
                  keyId: this.getModelInfo.keyInfos[index1].childs[index2].childs[index].keyId.toString(), //按键ID
                  opId: this.getModelInfo.keyInfos[index1].childs[index2].childs[index].opId.toString(), //操作ID
                  sno: this.mouseconfig?.sn as string, //设备号
                  userModelId: this.getModelInfo.id.toString()//按鍵模式ID
                }
                _addCustomerKey(params)
                this.getModelInfo.keyInfos[index1].childs[index2].childs[this.getDefaultSelectedIndex(item.childs || [],
                  index1, index2)].first = 0
                this.getModelInfo.keyInfos[index1].childs[index2].childs[index].first = 1
                // this.KeymethodConfig[index1 * 2+index2].currIndex = index
                // console.error('11', this.getModelInfo.keyInfos[index1].names['ZH_CN'], index2, index)
                switch (this.getModelInfo.keyInfos[index1].key) {
                  case 'voice_key':
                    if (this.getModelInfo.keyInfos[index1].childs[index2].operation==='sk') {
                      this.KeymethodConfig[0].currIndex = index
                    }
                    if (this.getModelInfo.keyInfos[index1].childs[index2].operation==='lk') {
                      this.KeymethodConfig[1].currIndex = index
                    }
                    break
                  case 'search_key':
                    if (this.getModelInfo.keyInfos[index1].childs[index2].operation==='sk') {
                      this.KeymethodConfig[2].currIndex = index
                    }
                    if (this.getModelInfo.keyInfos[index1].childs[index2].operation==='lk') {
                      this.KeymethodConfig[3].currIndex = index
                    }
                    break
                  case 'translate_key':
                    if (this.getModelInfo.keyInfos[index1].childs[index2].operation==='sk') {
                      this.KeymethodConfig[4].currIndex = index
                    }
                    if (this.getModelInfo.keyInfos[index1].childs[index2].operation==='lk') {
                      this.KeymethodConfig[5].currIndex = index
                    }
                    break
                  case 'AI_key':
                    if (this.getModelInfo.keyInfos[index1].childs[index2].operation==='sk') {
                      this.KeymethodConfig[6].currIndex = index
                    }
                    if (this.getModelInfo.keyInfos[index1].childs[index2].operation==='lk') {
                      this.KeymethodConfig[7].currIndex = index
                    }
                    break
                }
                // console.log('*/*/*/*/*', JSON.stringify(AppStorage.get('KeymethodConfig')))
                // AppStorage.setOrCreate('KeymethodConfig', this.KeymethodConfig)
                // console.log('*/*/*/*/*', JSON.stringify(AppStorage.get('KeymethodConfig')))
                ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].KeymethodConfig=this.KeymethodConfig
                console.error('11', this.getModelInfo.keyInfos[index1].childs[index2].childs[index].cmd)
                //快捷键
                if (this.getModelInfo.keyInfos[index1].childs[index2].childs[index].cmd === 'Action_SK') {
                  this.shortcut = 4;
                }
                //固定文案
                if (this.getModelInfo.keyInfos[index1].childs[index2].childs[index].cmd === 'Action_FT') {
                  AppStorage.setOrCreate('isShowFixedText_pop', true)
                }
                //打开网页
                if (this.getModelInfo.keyInfos[index1].childs[index2].childs[index].cmd === 'Action_OW') {
                  AppStorage.setOrCreate('isShow_webUrlToOpen_pop', true)
                }
                //打开文件
                if (this.getModelInfo.keyInfos[index1].childs[index2].childs[index].cmd === 'Action_OF') {
                  OpenFileWithSystemApp.openFileWithSystemApp()
                }
                // 文件夹————让用户选择一个目录文件夹中的文件，记录该文件目录
                if (this.getModelInfo.keyInfos[index1].childs[index2].childs[index].cmd === 'Action_OFJ') {
                  this.selectFolder()
                }
              })
              .selected(this.getDefaultSelectedIndex(item.childs || [], index1, index2))
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
    }
  }

  Watch_null() {
    if (JSON.stringify(this.getModelInfo.keyInfos) === '[]') {
      this.isShowConfig = false
      // AppStorage.setOrCreate('isShowConfig', false)
    }
  }

  selectFolder(): void {
    this.isLoading = true;
    try {
      promptAction.showToast({ message: '请选择目标文件夹中的任意一个文件', duration: 3000 });

      const documentSelectOptions = new picker.DocumentSelectOptions();
      documentSelectOptions.maxSelectNumber = 1;

      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const documentViewPicker = new picker.DocumentViewPicker(context);

      documentViewPicker.select(documentSelectOptions)
        .then((result: string[]) => {
          if (!result || result.length === 0) {
            promptAction.showToast({ message: '未选择任何文件', duration: 2000 });
            return;
          }

          const filePath = result[0];
          const lastSlashIndex = filePath.lastIndexOf('/');

          if (lastSlashIndex !== -1) {
            const folderPath = filePath.substring(0, lastSlashIndex);
            // 直接赋值而不是使用展开操作符
            AppStorage.setOrCreate('folderPath', folderPath)

            console.log('提取的文件夹路径:', folderPath);
            const folderName = folderPath.substring(folderPath.lastIndexOf('/') + 1);
            promptAction.showToast({ message: `已选择文件夹: ${folderName}`, duration: 2500 });
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