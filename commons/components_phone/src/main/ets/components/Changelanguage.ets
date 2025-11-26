import { DeviceArrayType_Ble } from "bluetooth"
import { getModelInfoModel } from "config"
import { ConnectDevice } from "mouse"
import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"
import { TopTitle } from "../common/TopTitle"
import { Languages_params } from "../view/SmartSettings"

@Builder
export function ChangelanguageBuilder() {
  Changelanguage()
}

@Component
struct Changelanguage {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @Consume('pageInfo') pageInfo: NavPathStack
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State params: Languages_params | null = null
  @State currOption: number = 0
  @StorageLink('devices') devices: DeviceArrayType_Ble[] = []
  @State getModelInfo: getModelInfoModel = AppStorage.get('getModelInfo') as getModelInfoModel
  @StorageLink('from_languages') from_languages: string = 'ZH_CN' //语音翻译源语言
  @StorageLink('wordScan_from_languages') wordScan_from_languages: string = 'ZH_CN' //划词翻译源语言
  @StorageLink('screenshotOCR_from_languages') screenshotOCR_from_languages: string = 'ZH_CN' //截图识别/翻译源语言

  aboutToAppear(): void {
    this.params = this.pageInfo.getParamByName("Changelanguage")[0] as Languages_params
    this.currOption = this.params.currLanguages
  }

  build() {
    NavDestination() {
      // TopTitle({ title: Languages.editProfile[this.languages] })
      TopTitle({ title: this.params?.title })
        .margin({ bottom: 12 })
      Scroll() {
        Column() {
          ForEach(this.params?.ListData, (item: SelectOption, index) => {
            Row() {
              Text(item.value)
                .fontSize(CommonConfig.fontSize_14)
                .fontColor(CommonConfig.hintTextColor_select)
                .fontWeight(CommonConfig.fontWeight_400)
                .margin({ right: 8 })
              Blank()
              if (this.currOption === index) {
                Image($r('app.media.Frame_2538'))
                  .width(16)
                  .height(16)
              }
            }
            .border({
              width: { bottom: index === (this.params as Languages_params).ListData.length - 1 ? 0 : 1 },
              color: CommonConfig.commonBackgroundColor
            })
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .padding({ top: 12, bottom: 12 })
            .onClick(() => {
              this.currOption = index
              switch (this.params?.OperationType) {
                case 'speech_Recognition_languages': //识别语言
                  if (this.params.device_isBle) {
                    this.devices[AppStorage.get('device_show_currIndex') as number].speech_Recognition_languages =
                      this.getModelInfo.languages[index].code
                  } else {
                    ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].speech_Recognition_languages =
                      this.getModelInfo.languages[index].code
                  }
                  break
                case 'from_languages': //翻译语言_源语言
                  this.from_languages = this.getModelInfo.transLanguages[index].code
                  break
                case 'wordScan_from_languages': //划词翻译语言_源语言
                  this.wordScan_from_languages = this.getModelInfo.transLanguages[index].code
                  break
                case 'screenshotOCR_from_languages': //截图翻译语言_源语言
                  this.screenshotOCR_from_languages = this.getModelInfo.transLanguages[index].code
                  break
                case 'EnhancedBrowserSearch': //语音搜索设置
                  AppStorage.setOrCreate('EnhancedBrowserSearch', index)
                  break
                case 'typing_input_mode': //打字输入模式
                  AppStorage.setOrCreate('keystroke_curr', index)
                  break
                case 'buttonConfiguration': //按键设置
                  AppStorage.setOrCreate('currentSelectedIndex', index)
                  break
                case 'DPI_currIndex': //修改DPI
                  AppStorage.setOrCreate('DPI_currIndex', index)
                  break
                case 'reportRate_currIndex': //修改回报率
                  AppStorage.setOrCreate('reportRate_currIndex', index)
                  break
              }
            })
          }, (item: SelectOption) => item.value.toString())
        }
      }
      .borderRadius(12)
      .padding({ left: 12, right: 12 })
      .backgroundColor(Color.White)
      .layoutWeight(1)

    }
    .padding({ left: 16, right: 16, bottom: 16 })
    .backgroundColor(CommonConfig.commonBackgroundColor)
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}