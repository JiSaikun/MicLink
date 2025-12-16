import { DeviceArrayType_Ble } from "bluetooth"
import { getModelInfoModel, keyInfos_childs_childsModel, languagesModel } from "config"
import { ConnectDevice } from "mouse"
import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"

export interface Languages_params {
  ListData: SelectOption[]
  OperationType: string,
  currLanguages: number,
  device_isBle: boolean,
  title: string

}

@Component
export struct SmartSettings {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @Consume('pageInfo') pageInfo: NavPathStack
  @Link device_isBle: boolean
  @StorageLink('devices') devices: DeviceArrayType_Ble[] = []
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State getModelInfo: getModelInfoModel = AppStorage.get('getModelInfo') as getModelInfoModel
  @State isPunctuationRecognition: boolean = false //语音识别是否带标点
  @StorageLink('isEnableLongVoiceRecog') isEnableLongVoiceRecog: boolean = true //是否开启长语音识别
  @StorageLink('isWordScan_Translation') isWordScan_Translation: boolean = true //是否开启划词翻译功能
  @StorageLink('isOCR_Translate_Toggle') isOCR_Translate_Toggle: boolean = true //是否开启截图识别/翻译
  @StorageLink('isAutoCloseVoiceTransPop') isAutoCloseVoiceTransPop: boolean = true //是否开启语音翻译弹窗自动关闭
  @State speech_Recognition_languages: string = 'ZH_CN' //语音识别语种
  @State keystroke: SelectOption[] = [{ value: '动态打字模式' }, { value: '兼容打字模式' }] //打字输入模式选项
  @StorageLink('keystroke_curr') keystroke_curr: number = 0 //打字输入模式选项
  @StorageLink('EnhancedBrowserSearch') EnhancedBrowserSearch: number = 0 //搜索引擎
  @StorageLink('speech_Recognition_languages') speech_Recognition_languages_curr: number = 0 //语音识别语种索引
  @State searchEngine: SelectOption[] = [{ value: '百度' }, { value: 'Google' }] //搜索引擎
  @StorageLink('from_languages') from_languages: string = 'ZH_CN' //语音翻译源语言
  @StorageLink('to_languages') to_languages: string = 'EN_US' //语音翻译目标语言
  @StorageLink('wordScan_from_languages') wordScan_from_languages: string = 'ZH_CN' //划词翻译源语言
  @StorageLink('wordScan_to_languages') wordScan_to_languages: string = 'EN_US' //划词翻译目标语言
  @StorageLink('screenshotOCR_from_languages') screenshotOCR_from_languages: string = 'ZH_CN' //截图识别/翻译源语言
  @StorageLink('screenshotOCR_to_languages') screenshotOCR_to_languages: string = 'EN_US' //截图识别/翻译目标语言
  @State voice_recognition_shortcut: string = '' //语音识别快捷键
  @State voice_translation_shortcut: string = '' //语音翻译快捷键
  @State screenshot_recognition_shortcut: string = '' //截图识别快捷键

  aboutToAppear(): void {

    const deviceIndex = AppStorage.get('device_show_currIndex') as number || 0

    if (this.device_isBle) {
        this.isPunctuationRecognition = this.devices[deviceIndex].isPunctuationRecognition
        this.speech_Recognition_languages = this.devices[deviceIndex].speech_Recognition_languages //语音识别语种
        this.speech_Recognition_languages_curr = this.getDefaultSelectedIndex_from(this.speech_Recognition_languages)

    } else {
      if (ConnectDevice.Communication && deviceIndex >= 0 && deviceIndex < ConnectDevice.Communication.length &&
      ConnectDevice.Communication[deviceIndex]) {
        this.isPunctuationRecognition = ConnectDevice.Communication[deviceIndex].isPunctuationRecognition
        this.speech_Recognition_languages = ConnectDevice.Communication[deviceIndex].speech_Recognition_languages
        this.speech_Recognition_languages_curr = this.getDefaultSelectedIndex_from(this.speech_Recognition_languages)
      } else {
        console.error('ConfigPage1: 2.4G设备索引无效或设备不存在:', deviceIndex, ConnectDevice.Communication?.length)
        this.isPunctuationRecognition = true
        this.speech_Recognition_languages = 'ZH_CN'
      }
    }
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        //======================================================语音识别设置
        Text(Languages.voice_recognition_settings[this.languages])
          .fontSize(CommonConfig.fontSize_14)
          .fontWeight(CommonConfig.fontWeight_400)
          .fontColor(CommonConfig.hintTextColor)
        Column() {
          Row() {
            Text(Languages.punctuation_recognition[this.languages])
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
              .fontWeight(CommonConfig.fontWeight_400)
            Blank()
            Toggle({
              type: ToggleType.Switch,
              isOn: this.device_isBle ?
              this.devices[AppStorage.get('device_show_currIndex') as number].isPunctuationRecognition :
              ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].isPunctuationRecognition
            }).onChange((value: boolean) => {
              // 处理开关逻辑
              if (value) {
                console.log('*****************************打开识别带标点****************************************')
                if (this.device_isBle) {
                  this.devices[AppStorage.get('device_show_currIndex') as number].isPunctuationRecognition =
                    true
                } else {
                  ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].isPunctuationRecognition =
                    true
                }
              } else {
                console.log('****************************关闭识别带标点****************************************')
                if (this.device_isBle) {
                  this.devices[AppStorage.get('device_show_currIndex') as number].isPunctuationRecognition =
                    false
                } else {
                  ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].isPunctuationRecognition =
                    false
                }
              }
            })
              .selectedColor(this.paletteTheme)
              .height(22)
              .width(44)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding({ top: 12, bottom: 12 })
          .border({ width: { bottom: 1 }, color: CommonConfig.commonBackgroundColor })

          Row() {
            Text(Languages.long_voice_recognition[this.languages])
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
              .fontWeight(CommonConfig.fontWeight_400)
            Blank()
            Toggle({ type: ToggleType.Switch, isOn: this.isEnableLongVoiceRecog }).onChange((value: boolean) => {
              // 处理开关逻辑
              if (value) {
                console.log('*****************************打开长语音识别****************************************')
                this.isEnableLongVoiceRecog = true
              } else {
                console.log('*****************************关闭长语音识别****************************************')
                this.isEnableLongVoiceRecog = false
              }
            })
              .selectedColor(this.paletteTheme)
              .height(22)
              .width(44)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding({ top: 12, bottom: 12 })
          .border({ width: { bottom: 1 }, color: CommonConfig.commonBackgroundColor })

          Row() {
            Text(Languages.recognize_speech[this.languages])
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
              .fontWeight(CommonConfig.fontWeight_400)
            Blank()
            Row() {
              Text(this.getDefaultSelectedIndex_fromText(this.getModelInfo.languages[this.speech_Recognition_languages_curr]))
                .fontSize(CommonConfig.fontSize_12)
                .fontColor(CommonConfig.hintTextColor)
                .fontWeight(CommonConfig.fontWeight_400)
                .margin({ right: 8 })
              Image($r('app.media.Arrow_to_the_right'))
                .width(16)
                .height(16)
            }.onClick(() => {
              let params: Languages_params = {
                ListData: this.convert_LanguagesToOptions(),
                OperationType: 'speech_Recognition_languages',
                currLanguages: this.speech_Recognition_languages_curr,
                device_isBle: this.device_isBle,
                title: Languages.recognize_speech[this.languages]
              }
              this.pageInfo.pushPath({ "name": 'Changelanguage', param: params })
            })

          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding({ top: 12, bottom: 12 })
          .border({ width: { bottom: 1 }, color: CommonConfig.commonBackgroundColor })

          Row() {
            Text(Languages.typing_input_mode[this.languages])
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
              .fontWeight(CommonConfig.fontWeight_400)
            Blank()
            Row() {
              Text(this.keystroke[this.keystroke_curr].value)
                .fontSize(CommonConfig.fontSize_12)
                .fontColor(CommonConfig.hintTextColor)
                .fontWeight(CommonConfig.fontWeight_400)
                .margin({ right: 8 })
              Image($r('app.media.Arrow_to_the_right'))
                .width(16)
                .height(16)
            }.onClick(() => {
              let params: Languages_params = {
                ListData: this.keystroke,
                OperationType: 'typing_input_mode',
                currLanguages: this.keystroke_curr,
                device_isBle: this.device_isBle,
                title: Languages.typing_input_mode[this.languages]
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

        //======================================================语音翻译设置
        Text(Languages.voice_translation_settings[this.languages])
          .fontSize(CommonConfig.fontSize_14)
          .fontWeight(CommonConfig.fontWeight_400)
          .fontColor(CommonConfig.hintTextColor)
        Column() {
          Row() {
            Text(Languages.translation_language[this.languages])
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
              .fontWeight(CommonConfig.fontWeight_400)
            Blank()
            Row() {
              Text(this.getDefaultSelectedIndex_fromText(this.getModelInfo.transLanguages[this.getDefaultSelectedIndex_from(this.to_languages)]))
                .fontSize(CommonConfig.fontSize_12)
                .fontColor(CommonConfig.hintTextColor)
                .fontWeight(CommonConfig.fontWeight_400)
                .margin({ right: 8 })
              Image($r('app.media.Arrow_to_the_right'))
                .width(16)
                .height(16)
            }.onClick(() => {
              let params: Languages_params = {
                ListData: this.convert_ttsLanguagesToOptions(),
                OperationType: 'to_languages',
                currLanguages: this.getDefaultSelectedIndex_from(this.to_languages),
                device_isBle: this.device_isBle,
                title: Languages.translation_language[this.languages]
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

        //======================================================划词翻译
        Text(Languages.word_scan_translation[this.languages])
          .fontSize(CommonConfig.fontSize_14)
          .fontWeight(CommonConfig.fontWeight_400)
          .fontColor(CommonConfig.hintTextColor)
        Column() {
          Row() {
            Text(Languages.enable_function[this.languages])
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
              .fontWeight(CommonConfig.fontWeight_400)
            Blank()
            Toggle({ type: ToggleType.Switch, isOn: this.isWordScan_Translation }).onChange((value: boolean) => {
              // 处理开关逻辑
              if (value) {
                console.log('*****************************打开划词翻译****************************************')
                this.isWordScan_Translation = true
              } else {
                console.log('*****************************关闭划词翻译****************************************')
                this.isWordScan_Translation = false
              }
            })
              .selectedColor(this.paletteTheme)
              .height(22)
              .width(44)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding({ top: 12, bottom: 12 })
          .border({ width: { bottom: 1 }, color: CommonConfig.commonBackgroundColor })

          Row() {
            Text(Languages.translation_language[this.languages])
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
              .fontWeight(CommonConfig.fontWeight_400)
            Blank()
            Row() {
              Text(this.getDefaultSelectedIndex_fromText(this.getModelInfo.transLanguages[this.getDefaultSelectedIndex_from(this.wordScan_from_languages)]))
                .fontSize(CommonConfig.fontSize_12)
                .fontColor(CommonConfig.hintTextColor)
                .fontWeight(CommonConfig.fontWeight_400)
                .margin({ right: 8 })
              Image($r('app.media.Arrow_to_the_right'))
                .width(16)
                .height(16)
            }.onClick(() => {
              let params: Languages_params = {
                ListData: this.convert_ttsLanguagesToOptions(),
                OperationType: 'wordScan_from_languages',
                currLanguages: this.getDefaultSelectedIndex_from(this.wordScan_from_languages),
                device_isBle: this.device_isBle,
                title: Languages.translation_language[this.languages]
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

        //======================================================截图识别/翻译
        Text(Languages.screenshot_ocr_translation[this.languages])
          .fontSize(CommonConfig.fontSize_14)
          .fontWeight(CommonConfig.fontWeight_400)
          .fontColor(CommonConfig.hintTextColor)
        Column() {
          Row() {
            Text(Languages.enable_function[this.languages])
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
              .fontWeight(CommonConfig.fontWeight_400)
            Blank()
            Toggle({ type: ToggleType.Switch, isOn: this.isOCR_Translate_Toggle }).onChange((value: boolean) => {
              // 处理开关逻辑
              if (value) {
                console.log('*****************************打开截图识别/翻译****************************************')
                this.isOCR_Translate_Toggle = true
              } else {
                console.log('*****************************关闭截图识别/翻译****************************************')
                this.isOCR_Translate_Toggle = false
              }
            })
              .selectedColor(this.paletteTheme)
              .height(22)
              .width(44)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding({ top: 12, bottom: 12 })
          .border({ width: { bottom: 1 }, color: CommonConfig.commonBackgroundColor })

          Row() {
            Text(Languages.translation_language[this.languages])
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
              .fontWeight(CommonConfig.fontWeight_400)
            Blank()
            Row() {
              Text(this.getDefaultSelectedIndex_fromText(this.getModelInfo.transLanguages[this.getDefaultSelectedIndex_from(this.wordScan_from_languages)]))
                .fontSize(CommonConfig.fontSize_12)
                .fontColor(CommonConfig.hintTextColor)
                .fontWeight(CommonConfig.fontWeight_400)
                .margin({ right: 8 })
              Image($r('app.media.Arrow_to_the_right'))
                .width(16)
                .height(16)
            }.onClick(() => {
              let params: Languages_params = {
                ListData: this.convert_ttsLanguagesToOptions(),
                OperationType: 'screenshotOCR_from_languages',
                currLanguages: this.getDefaultSelectedIndex_from(this.screenshotOCR_from_languages),
                device_isBle: this.device_isBle,
                title: Languages.translation_language[this.languages]
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

        //======================================================语音搜索设置
        Text(Languages.voice_search_settings[this.languages])
          .fontSize(CommonConfig.fontSize_14)
          .fontWeight(CommonConfig.fontWeight_400)
          .fontColor(CommonConfig.hintTextColor)
        Column() {
          Row() {
            Text('搜索引擎')
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
              .fontWeight(CommonConfig.fontWeight_400)
            Blank()
            Row() {
              Text(this.searchEngine[this.EnhancedBrowserSearch].value)
                .fontSize(CommonConfig.fontSize_12)
                .fontColor(CommonConfig.hintTextColor)
                .fontWeight(CommonConfig.fontWeight_400)
                .margin({ right: 8 })
              Image($r('app.media.Arrow_to_the_right'))
                .width(16)
                .height(16)
            }.onClick(() => {
              let params: Languages_params = {
                ListData: this.searchEngine,
                OperationType: 'EnhancedBrowserSearch',
                currLanguages: this.EnhancedBrowserSearch,
                device_isBle: this.device_isBle,
                title: Languages.typing_input_mode[this.languages]
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

        //======================================================外部弹窗设置
        Text(Languages.external_popup_settings[this.languages])
          .fontSize(CommonConfig.fontSize_14)
          .fontWeight(CommonConfig.fontWeight_400)
          .fontColor(CommonConfig.hintTextColor)
        Column() {
          Row() {
            Text(Languages.auto_close_voice_translation_popup[this.languages])
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
              .fontWeight(CommonConfig.fontWeight_400)
            Blank()
            Toggle({ type: ToggleType.Switch, isOn: this.isAutoCloseVoiceTransPop }).onChange((value: boolean) => {
              // 处理开关逻辑
              if (value) {
                console.log('*****************************打开语音翻译弹窗自动关闭****************************************')
                this.isAutoCloseVoiceTransPop = true
              } else {
                console.log('*****************************关闭语音翻译弹窗自动关闭****************************************')
                this.isAutoCloseVoiceTransPop = false
              }
            })
              .selectedColor(this.paletteTheme)
              .height(22)
              .width(44)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding({ top: 12, bottom: 12 })
          .border({ width: { bottom: 1 }, color: CommonConfig.commonBackgroundColor })
        }
        .padding({ left: 12, right: 12 })
        .borderRadius(12)
        .backgroundColor(Color.White)

      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .height('100%')
    .scrollBarWidth(0)
  }

  private getDefaultSelectedIndex_from(from_languages: string): number {
    const index = this.getModelInfo.transLanguages.findIndex((item) => {
      return item.code === from_languages;
    });
    return index !== -1 ? index : 0; // 找到返回索引，否则返回0
  }

  private getDefaultSelectedIndex_fromText(item: languagesModel): string {
    switch (AppStorage.get('languages') as string) {
      case "FIL_PH":
        return item.nameFil_ph;
      case "ES_ES":
        return item.nameEs_es;
      case "JA_JP":
        return item.nameJp;
      case "ZH_TW":
        return item.nameTw;
      case "UYGUR":
        return item.nameUygur;
      case "MO_MO":
        return item.nameMo_mo;
      case "RU_RU":
        return item.nameRu_ru;
      case "IT_IT":
        return item.nameIt_it;
      case "ZH_TI":
        return item.nameZh_ti;
      case "EN_US":
        return item.nameEn;
      case "MAY_MAY":
        return item.nameMay_may;
      case "AR_SA":
        return item.nameAr_sa;
      case "DE_DE":
        return item.nameDe_de;
      case "KO_KR":
        return item.nameKo_kr;
      case "ID_ID":
        return item.nameId_id;
      case "TR_TR":
        return item.nameTr_tr;
      case "KA_KA":
        return item.nameKa_ka;
      case "FR_FR":
        return item.nameFr_fr;
      case "MN_MN":
        return item.nameMn_mn;
      case "TH_TH":
        return item.nameTh_th;
      case "VI_VN":
        return item.nameVi_vn;
      default:
        return item.name;
    }
  }

  convert_LanguagesToOptions(): SelectOption[] {
    return ((this.getModelInfo.languages).map((item, index) => {
      // 多语言适配：优先取当前语言文本，无则按顺序兜底
      let languageField: string = item.name; // 默认使用中文简体

      switch (AppStorage.get('languages') as string) {
        case "FIL_PH":
          languageField = item.nameFil_ph;
          break;
        case "ES_ES":
          languageField = item.nameEs_es;
          break;
        case "JA_JP":
          languageField = item.nameJp;
          break;
        case "ZH_TW":
          languageField = item.nameTw;
          break;
        case "UYGUR":
          languageField = item.nameUygur;
          break;
        case "MO_MO":
          languageField = item.nameMo_mo;
          break;
        case "RU_RU":
          languageField = item.nameRu_ru;
          break;
        case "IT_IT":
          languageField = item.nameIt_it;
          break;
        case "ZH_TI":
          languageField = item.nameZh_ti;
          break;
        case "EN_US":
          languageField = item.nameEn;
          break;
        case "MAY_MAY":
          languageField = item.nameMay_may;
          break;
        case "AR_SA":
          languageField = item.nameAr_sa;
          break;
        case "DE_DE":
          languageField = item.nameDe_de;
          break;
        case "KO_KR":
          languageField = item.nameKo_kr;
          break;
        case "ID_ID":
          languageField = item.nameId_id;
          break;
        case "TR_TR":
          languageField = item.nameTr_tr;
          break;
        case "KA_KA":
          languageField = item.nameKa_ka;
          break;
        case "FR_FR":
          languageField = item.nameFr_fr;
          break;
        case "MN_MN":
          languageField = item.nameMn_mn;
          break;
        case "TH_TH":
          languageField = item.nameTh_th;
          break;
        case "VI_VN":
          languageField = item.nameVi_vn;
          break;
        // 默认使用中文简体
        default:
          languageField = item.name;
          break;
      }

      // 使用方括号表示法动态访问属性
      return {
        value: languageField // 正确的属性访问方式
      } as SelectOption;
    }));
  }

  convert_ttsLanguagesToOptions(): SelectOption[] {
    return ((this.getModelInfo.transLanguages).map((item, index) => {
      // 多语言适配：优先取当前语言文本，无则按顺序兜底
      let languageField: string = item.name; // 默认使用中文简体

      switch (AppStorage.get('languages') as string) {
        case "FIL_PH":
          languageField = item.nameFil_ph;
          break;
        case "ES_ES":
          languageField = item.nameEs_es;
          break;
        case "JA_JP":
          languageField = item.nameJp;
          break;
        case "ZH_TW":
          languageField = item.nameTw;
          break;
        case "UYGUR":
          languageField = item.nameUygur;
          break;
        case "MO_MO":
          languageField = item.nameMo_mo;
          break;
        case "RU_RU":
          languageField = item.nameRu_ru;
          break;
        case "IT_IT":
          languageField = item.nameIt_it;
          break;
        case "ZH_TI":
          languageField = item.nameZh_ti;
          break;
        case "EN_US":
          languageField = item.nameEn;
          break;
        case "MAY_MAY":
          languageField = item.nameMay_may;
          break;
        case "AR_SA":
          languageField = item.nameAr_sa;
          break;
        case "DE_DE":
          languageField = item.nameDe_de;
          break;
        case "KO_KR":
          languageField = item.nameKo_kr;
          break;
        case "ID_ID":
          languageField = item.nameId_id;
          break;
        case "TR_TR":
          languageField = item.nameTr_tr;
          break;
        case "KA_KA":
          languageField = item.nameKa_ka;
          break;
        case "FR_FR":
          languageField = item.nameFr_fr;
          break;
        case "MN_MN":
          languageField = item.nameMn_mn;
          break;
        case "TH_TH":
          languageField = item.nameTh_th;
          break;
        case "VI_VN":
          languageField = item.nameVi_vn;
          break;
        // 默认使用中文简体
        default:
          languageField = item.name;
          break;
      }

      // 使用方括号表示法动态访问属性
      return {
        value: languageField // 正确的属性访问方式
      } as SelectOption;
    }));
  }
}