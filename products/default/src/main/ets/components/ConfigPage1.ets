import { LengthMetrics } from "@kit.ArkUI"
import { DeviceArrayType_Ble } from "bluetooth"
import { ThemeConfig } from "common"
import { Languages, getModelInfoModel, languagesModel } from 'config'
import { ConnectDevice } from "mouse"

interface shortcutType {
  keyPreview: string
  pressedKeys: number[]
}

/**
 * 智能设置
 */
@Component
export struct ConfigPage1 {
  @StorageLink('devices') devices: DeviceArrayType_Ble[] = []
  @Consume device_isBle: boolean //该设备是否是蓝牙连接
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State getModelInfo: getModelInfoModel = AppStorage.get('getModelInfo') as getModelInfoModel
  @State isPunctuationRecognition: boolean = false //语音识别是否带标点
  @StorageLink('isEnableLongVoiceRecog') isEnableLongVoiceRecog: boolean = true //是否开启长语音识别
  @StorageLink('isWordScan_Translation') isWordScan_Translation: boolean = true //是否开启划词翻译功能
  @StorageLink('isOCR_Translate_Toggle') isOCR_Translate_Toggle: boolean = true //是否开启截图识别/翻译
  @StorageLink('isAutoCloseVoiceTransPop') isAutoCloseVoiceTransPop: boolean = true //是否开启语音翻译弹窗自动关闭
  @State speech_Recognition_languages: string = 'ZH_CN' //语音识别语种
  @State keystroke: SelectOption[] = [{ value: '动态打字模式' }, { value: '兼容打字模式' }] //打字输入模式选项
  @State searchEngine: SelectOption[] = [{ value: '百度' }, { value: 'Google' }] //搜索引擎
  @StorageLink('from_languages') from_languages: string = 'ZH_CN' //语音翻译源语言
  @StorageLink('to_languages') to_languages: string = 'EN_US' //语音翻译目标语言
  @StorageLink('wordScan_from_languages') wordScan_from_languages: string = 'ZH_CN' //划词翻译源语言
  @StorageLink('wordScan_to_languages') wordScan_to_languages: string = 'EN_US' //划词翻译目标语言
  @StorageLink('screenshotOCR_from_languages') screenshotOCR_from_languages: string = 'ZH_CN' //截图识别/翻译源语言
  @StorageLink('screenshotOCR_to_languages') screenshotOCR_to_languages: string = 'EN_US' //截图识别/翻译目标语言
  @Watch('shortcut_change') @StorageLink("shortcut") shortcut: number =
    0 //改变该值弹出对应快捷键悬浮窗口 1：语音识别 2：语音翻译 3:截图识别 4：自定义快捷键
  @State voice_recognition_shortcut: string = '' //语音识别快捷键
  @State voice_translation_shortcut: string = '' //语音翻译快捷键
  @State screenshot_recognition_shortcut: string = '' //截图识别快捷键

  aboutToAppear(): void {
    this.shortcut_change()
    if (this.device_isBle) {
      this.isPunctuationRecognition =
        this.devices[AppStorage.get('device_show_currIndex') as number].isPunctuationRecognition
      this.speech_Recognition_languages =
        this.devices[AppStorage.get('device_show_currIndex') as number].speech_Recognition_languages //语音识别语种
    } else {
      this.isPunctuationRecognition =
        ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].isPunctuationRecognition
      this.speech_Recognition_languages =
        ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].speech_Recognition_languages
    }
  }

  build() {
    Flex({ space: { main: LengthMetrics.px(15) }, direction: FlexDirection.Column }) {
      // Text('语音识别设置')
      Text(Languages.voice_recognition_settings[this.languages])
        .fontSize(14)
        .lineHeight(14)
        .fontWeight(400)
        .fontColor('#a4aab2')
        .margin({ bottom: 5 })
      Row() {
        // Text('识别带标点')
        Text(Languages.punctuation_recognition[this.languages])
          .fontSize($r('app.float.default_text_font_size_14'))
          .fontWeight(400)
          .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        Blank()
        Row() {
          Radio({
            value: 'Radio1', group: 'radioGroup1',
            indicatorType: RadioIndicatorType.DOT
          })
            .checked(this.isPunctuationRecognition)
            .height(14)
            .radioStyle({ checkedBackgroundColor: ThemeConfig.PaletteTheme })
            .width(14)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                console.log('*****************************打开识别带标点****************************************')
                if (this.device_isBle) {
                  this.devices[AppStorage.get('device_show_currIndex') as number].isPunctuationRecognition =
                    true
                } else {
                  ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].isPunctuationRecognition =
                    true
                }
              }
            })
          Text(Languages.on_common[this.languages])
            .fontSize($r('app.float.default_text_font_size_14'))
            .fontWeight(400)
            .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        }
        .onClick(() => {
          if (this.device_isBle) {
            this.devices[AppStorage.get('device_show_currIndex') as number].isPunctuationRecognition =
              true
          } else {
            ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].isPunctuationRecognition =
              true
          }
        })

        Row() {
          Radio({
            value: 'Radio1', group: 'radioGroup1',
            indicatorType: RadioIndicatorType.DOT
          })
            .checked(!this.isPunctuationRecognition)
            .height(14)
            .radioStyle({ checkedBackgroundColor: ThemeConfig.PaletteTheme })
            .width(14)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                console.log('*****************************关闭识别带标点****************************************')
                if (this.device_isBle) {
                  this.devices[AppStorage.get('device_show_currIndex') as number].isPunctuationRecognition =
                    false
                } else {
                  ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].isPunctuationRecognition =
                    false
                }

              }
            })
          Text(Languages.off_common[this.languages])
            .fontSize($r('app.float.default_text_font_size_14'))
            .fontWeight(400)
            .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        }

        .onClick(() => {
          if (this.device_isBle) {
            this.devices[AppStorage.get('device_show_currIndex') as number].isPunctuationRecognition =
              false
          } else {
            ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].isPunctuationRecognition =
              false
          }
        })
      }
      .width('100%')

      Row() {
        // Text('长语音识别')
        Text(Languages.long_voice_recognition[this.languages])
          .fontSize($r('app.float.default_text_font_size_14'))
          .fontWeight(400)
          .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        Blank()
        Row() {
          Radio({
            value: 'Radio2', group: 'radioGroup2',
            indicatorType: RadioIndicatorType.DOT
          })
            .checked(this.isEnableLongVoiceRecog)
            .height(14)
            .radioStyle({ checkedBackgroundColor: ThemeConfig.PaletteTheme })
            .width(14)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                console.log('*****************************打开长语音识别****************************************')
                this.isEnableLongVoiceRecog = true
              }
            })
          Text(Languages.on_common[this.languages])
            .fontSize($r('app.float.default_text_font_size_14'))
            .fontWeight(400)
            .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        }
        .onClick(() => {
          this.isEnableLongVoiceRecog = true
        })

        Row() {
          Radio({
            value: 'Radio2', group: 'radioGroup2',
            indicatorType: RadioIndicatorType.DOT
          })
            .checked(!this.isEnableLongVoiceRecog)
            .height(14)
            .radioStyle({ checkedBackgroundColor: ThemeConfig.PaletteTheme })
            .width(14)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                console.log('*****************************关闭长语音识别****************************************')
                this.isEnableLongVoiceRecog = false

              }
            })
          Text(Languages.off_common[this.languages])
            .fontSize($r('app.float.default_text_font_size_14'))
            .fontWeight(400)
            .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        }
        .onClick(() => {
          this.isEnableLongVoiceRecog = false
        })
      }
      .width('100%')

      // Text("识别语音")
      Text(Languages.recognize_speech[this.languages])
        .margin({ top: 5 })
        .fontSize($r('app.float.default_text_font_size_14'))
        .fontWeight(400)
        .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
      Select(this.convert_LanguagesToOptions())
        .value(this.getDefaultSelectedIndex_fromText(this.getModelInfo.languages[this.getDefaultSelectedIndex_from(this.speech_Recognition_languages)]))
        .onSelect((index: number) => {
          if (this.device_isBle) {
            this.devices[AppStorage.get('device_show_currIndex') as number].speech_Recognition_languages =
              this.getModelInfo.languages[index].code
          } else {
            ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].speech_Recognition_languages =
              this.getModelInfo.languages[index].code
          }
        })
        .selected(this.getDefaultSelectedIndex_from(this.speech_Recognition_languages))
        .width('100%')
        .font({ size: 14, weight: 400 })
        .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        .borderRadius(4)
        .border({ width: 1, color: $r('app.string.DEFAULT_BORDER_COLOR') })
        .backgroundColor(Color.White)
        .width('100%')
        .optionHeight(200)
      // Text("打字输入模式")
      Text(Languages.typing_input_mode[this.languages])
        .margin({ top: 5 })
        .fontSize($r('app.float.default_text_font_size_14'))
        .fontWeight(400)
        .fontColor($r('app.string.DEFAULT_FONT_COLOR'))

      Select(this.keystroke)
        .value(this.keystroke[0].value)
        .onSelect((index: number) => {
          // this.DPI_currIndex = index
        })
        // .selected(this.DPI_currInfo ? this.DPI_currInfo?.curr : this.DPI_currIndex)
        .selected(0)
        .width('100%')
        .font({ size: $r('app.float.default_text_font_size_14'), weight: 400 })
        .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        .borderRadius(4)
        .border({ width: 1, color: $r('app.string.DEFAULT_BORDER_COLOR') })
        .backgroundColor(Color.White)
      // Text("快捷键")
      Text(Languages.shortcut_key[this.languages])
        .margin({ top: 5 })
        .fontSize($r('app.float.default_text_font_size_14'))
        .fontWeight(400)
        .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
      TextInput({ placeholder: Languages.click_to_input_keys[this.languages], text: this.voice_recognition_shortcut })
        .backgroundColor('#fff')
        .placeholderColor('#bbbdbf')
        .placeholderFont({ size: 14, weight: 400 })
        .focusable(false)
        .border({ width: 1, color: $r('app.string.DEFAULT_BORDER_COLOR') })
        .borderRadius(5)
        .onClick(() => this.shortcut = 1)
      //======================================================语音翻译设置
      // Text('语音翻译设置')
      Text(Languages.voice_translation_settings[this.languages])
        .fontSize(14)
        .lineHeight(14)
        .fontWeight(400)
        .fontColor('#a4aab2')
        .margin({ bottom: 5, top: 10 })
      // Text("翻译语言")
      Text(Languages.translation_language[this.languages])
        .margin({ top: 5 })
        .fontSize($r('app.float.default_text_font_size_14'))
        .fontWeight(400)
        .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
      Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
        Select(this.convert_ttsLanguagesToOptions())
          .value(this.getDefaultSelectedIndex_fromText(this.getModelInfo.transLanguages[this.getDefaultSelectedIndex_from(this.from_languages)]))
          .onSelect((index: number) => {
            this.from_languages = this.getModelInfo.transLanguages[index].code
          })
          .selected(this.getDefaultSelectedIndex_from(this.from_languages))
          .width(200)
          .font({ size: 14, weight: 400 })
          .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
          .borderRadius(4)
          .border({ width: 1, color: $r('app.string.DEFAULT_BORDER_COLOR') })
          .backgroundColor(Color.White)
          .optionHeight(180)
          .flexGrow(1)
          .flexShrink(1)
        // Text('至')
        Text(Languages.to[this.languages])
          .fontSize(12)
          .fontWeight(400)
          .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
          .margin({ left: 20, right: 20 })
          .flexShrink(1)
        Select(this.convert_ttsLanguagesToOptions())
          .value(this.getDefaultSelectedIndex_fromText(this.getModelInfo.transLanguages[this.getDefaultSelectedIndex_from(this.to_languages)]))
          .onSelect((index: number) => {
            this.to_languages = this.getModelInfo.transLanguages[index].code
          })
          .selected(this.getDefaultSelectedIndex_from(this.to_languages))
          .width(200)
          .font({ size: 14, weight: 400 })
          .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
          .borderRadius(4)
          .border({ width: 1, color: $r('app.string.DEFAULT_BORDER_COLOR') })
          .backgroundColor(Color.White)
          .optionHeight(180)
          .flexGrow(1)
          .flexShrink(1)
      }

      // Text("快捷键")
      Text(Languages.shortcut_key[this.languages])
        .margin({ top: 5 })
        .fontSize($r('app.float.default_text_font_size_14'))
        .fontWeight(400)
        .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
      TextInput({
        placeholder: Languages.click_to_input_keys[this.languages],
        text: this.voice_translation_shortcut
      })//点击后输入目标按键即可
        .backgroundColor('#fff')
        .placeholderColor('#bbbdbf')
        .placeholderFont({ size: 14, weight: 400 })
        .focusable(false)
        .border({ width: 1, color: $r('app.string.DEFAULT_BORDER_COLOR') })
        .borderRadius(5)
        .onClick(() => this.shortcut = 2)
      //======================================================划词翻译
      // Text('划词翻译')
      Text(Languages.word_scan_translation[this.languages])
        .fontSize(14)
        .lineHeight(14)
        .fontWeight(400)
        .fontColor('#a4aab2')
        .margin({ bottom: 5, top: 10 })
      Row() {
        // Text('启动功能')
        Text(Languages.enable_function[this.languages])
          .fontSize($r('app.float.default_text_font_size_14'))
          .fontWeight(400)
          .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        Blank()
        Row() {
          Radio({
            value: 'Radio3', group: 'radioGroup3',
            indicatorType: RadioIndicatorType.DOT
          })
            .checked(this.isWordScan_Translation)
            .radioStyle({ checkedBackgroundColor: ThemeConfig.PaletteTheme })
            .height(14)
            .width(14)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                console.log('*****************************打开划词翻译****************************************')
                this.isWordScan_Translation = true
              }
            })
          Text(Languages.on_common[this.languages])
            .fontSize($r('app.float.default_text_font_size_14'))
            .fontWeight(400)
            .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        }
        .onClick(() => {
          this.isWordScan_Translation = true
        })

        Row() {
          Radio({
            value: 'Radio3', group: 'radioGroup3',
            indicatorType: RadioIndicatorType.DOT
          })
            .checked(!this.isWordScan_Translation)
            .radioStyle({ checkedBackgroundColor: ThemeConfig.PaletteTheme })
            .height(14)
            .width(14)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                console.log('*****************************关闭划词翻译****************************************')
                this.isWordScan_Translation = false

              }
            })
          Text(Languages.off_common[this.languages])
            .fontSize($r('app.float.default_text_font_size_14'))
            .fontWeight(400)
            .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        }
        .onClick(() => {
          this.isWordScan_Translation = false
        })
      }
      .width('100%')

      // Text("翻译语言")
      Text(Languages.translation_language[this.languages])
        .margin({ top: 5 })
        .fontSize($r('app.float.default_text_font_size_14'))
        .fontWeight(400)
        .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
      Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
        Select(this.convert_ttsLanguagesToOptions())
          .value(this.getDefaultSelectedIndex_fromText(this.getModelInfo.transLanguages[this.getDefaultSelectedIndex_from(this.wordScan_from_languages)]))
          .onSelect((index: number) => {
            this.wordScan_from_languages = this.getModelInfo.transLanguages[index].code
          })
          .selected(this.getDefaultSelectedIndex_from(this.wordScan_from_languages))
          .width(200)
          .font({ size: 14, weight: 400 })
          .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
          .borderRadius(4)
          .border({ width: 1, color: $r('app.string.DEFAULT_BORDER_COLOR') })
          .backgroundColor(Color.White)
          .optionHeight(180)
          .flexGrow(1)
          .flexShrink(1)
        Text(Languages.to[this.languages])
          .fontSize(12)
          .fontWeight(400)
          .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
          .margin({ left: 20, right: 20 })
          .flexShrink(1)
        Select(this.convert_ttsLanguagesToOptions())
          .value(this.getDefaultSelectedIndex_fromText(this.getModelInfo.transLanguages[this.getDefaultSelectedIndex_from(this.wordScan_to_languages)]))
          .onSelect((index: number) => {
            this.wordScan_to_languages = this.getModelInfo.transLanguages[index].code
          })
          .selected(this.getDefaultSelectedIndex_from(this.wordScan_to_languages))
          .width(200)
          .font({ size: 14, weight: 400 })
          .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
          .borderRadius(4)
          .border({ width: 1, color: $r('app.string.DEFAULT_BORDER_COLOR') })
          .backgroundColor(Color.White)
          .optionHeight(180)
          .flexGrow(1)
          .flexShrink(1)
      }

      //======================================================截图识别/翻译
      // Text('截图识别/翻译')
      Text(Languages.screenshot_ocr_translation[this.languages])
        .fontSize(14)
        .lineHeight(14)
        .fontWeight(400)
        .fontColor('#a4aab2')
        .margin({ bottom: 5, top: 10 })
      Row() {
        // Text('启动功能')
        Text(Languages.enable_function[this.languages])
          .fontSize($r('app.float.default_text_font_size_14'))
          .fontWeight(400)
          .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        Blank()
        Row() {
          Radio({
            value: 'Radio4', group: 'radioGroup4',
            indicatorType: RadioIndicatorType.DOT
          })
            .checked(this.isOCR_Translate_Toggle)
            .height(14)
            .radioStyle({ checkedBackgroundColor: ThemeConfig.PaletteTheme })
            .width(14)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                console.log('*****************************打开截图识别/翻译****************************************')
                this.isOCR_Translate_Toggle = true
              }
            })
          Text(Languages.on_common[this.languages])
            .fontSize($r('app.float.default_text_font_size_14'))
            .fontWeight(400)
            .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        }
        .onClick(() => {
          this.isOCR_Translate_Toggle = true
        })

        Row() {
          Radio({
            value: 'Radio4', group: 'radioGroup4',
            indicatorType: RadioIndicatorType.DOT
          })
            .checked(!this.isOCR_Translate_Toggle)
            .height(14)
            .radioStyle({ checkedBackgroundColor: ThemeConfig.PaletteTheme })
            .width(14)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                console.log('*****************************关闭截图识别/翻译****************************************')
                this.isOCR_Translate_Toggle = false
              }
            })
          Text(Languages.off_common[this.languages])
            .fontSize($r('app.float.default_text_font_size_14'))
            .fontWeight(400)
            .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        }
        .onClick(() => {
          this.isOCR_Translate_Toggle = false
        })
      }
      .width('100%')

      // Text("翻译语言")
      Text(Languages.translation_language[this.languages])
        .margin({ top: 5 })
        .fontSize($r('app.float.default_text_font_size_14'))
        .fontWeight(400)
        .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
      Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
        Select(this.convert_ttsLanguagesToOptions())
          .value(this.getDefaultSelectedIndex_fromText(this.getModelInfo.transLanguages[this.getDefaultSelectedIndex_from(this.screenshotOCR_from_languages)]))
          .onSelect((index: number) => {
            this.screenshotOCR_from_languages = this.getModelInfo.transLanguages[index].code
          })
          .selected(this.getDefaultSelectedIndex_from(this.screenshotOCR_from_languages))
          .width(200)
          .font({ size: 14, weight: 400 })
          .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
          .borderRadius(4)
          .border({ width: 1, color: $r('app.string.DEFAULT_BORDER_COLOR') })
          .backgroundColor(Color.White)
          .optionHeight(180)
          .flexGrow(1)
          .flexShrink(1)
        // Text('至')
        Text(Languages.to[this.languages])
          .fontSize(12)
          .fontWeight(400)
          .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
          .margin({ left: 20, right: 20 })
          .flexShrink(1)
        Select(this.convert_ttsLanguagesToOptions())
          .value(this.getDefaultSelectedIndex_fromText(this.getModelInfo.transLanguages[this.getDefaultSelectedIndex_from(this.screenshotOCR_to_languages)]))
          .onSelect((index: number) => {
            this.screenshotOCR_to_languages = this.getModelInfo.transLanguages[index].code
          })
          .selected(this.getDefaultSelectedIndex_from(this.screenshotOCR_to_languages))
          .width(200)
          .font({ size: 14, weight: 400 })
          .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
          .borderRadius(4)
          .border({ width: 1, color: $r('app.string.DEFAULT_BORDER_COLOR') })
          .backgroundColor(Color.White)
          .optionHeight(180)
          .flexGrow(1)
          .flexShrink(1)
      }

      // Text("快捷键")
      Text(Languages.shortcut_key[this.languages])
        .margin({ top: 5 })
        .fontSize($r('app.float.default_text_font_size_14'))
        .fontWeight(400)
        .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
      TextInput({
        placeholder: Languages.click_to_input_keys[this.languages],
        text: this.screenshot_recognition_shortcut
      })
        .backgroundColor('#fff')
        .placeholderColor('#bbbdbf')
        .placeholderFont({ size: 14, weight: 400 })
        .focusable(false)
        .border({ width: 1, color: $r('app.string.DEFAULT_BORDER_COLOR') })
        .borderRadius(5)
        .onClick(() => this.shortcut = 3)

      //======================================================语音搜索设置
      // Text('语音搜索设置')
      Text(Languages.voice_search_settings[this.languages])
        .fontSize(14)
        .lineHeight(14)
        .fontWeight(400)
        .fontColor('#a4aab2')
        .margin({ bottom: 5, top: 10 })
      // Text("语音搜索")
      Text(Languages.voice_search[this.languages])
        .margin({ top: 5 })
        .fontSize($r('app.float.default_text_font_size_14'))
        .fontWeight(400)
        .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
      Select(this.searchEngine)
        .value(this.searchEngine[AppStorage.get('EnhancedBrowserSearch') as number].value)
        .onSelect((index: number, value) => {
          AppStorage.setOrCreate('EnhancedBrowserSearch', index)
        })
        .selected(AppStorage.get('EnhancedBrowserSearch') as number)
        .width('100%')
        .font({ size: $r('app.float.default_text_font_size_14'), weight: 400 })
        .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        .borderRadius(4)
        .border({ width: 1, color: $r('app.string.DEFAULT_BORDER_COLOR') })
        .backgroundColor(Color.White)

      //======================================================外部弹窗设置
      // Text('外部弹窗设置')
      Text(Languages.external_popup_settings[this.languages])
        .fontSize(14)
        .lineHeight(14)
        .fontWeight(400)
        .fontColor('#a4aab2')
        .margin({ bottom: 5, top: 10 })
      Row() {
        // Text('语音翻译弹窗自动关闭')
        Text(Languages.auto_close_voice_translation_popup[this.languages])
          .fontSize($r('app.float.default_text_font_size_14'))
          .fontWeight(400)
          .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        Blank()
        Row() {
          Radio({
            value: 'Radio5', group: 'radioGroup5',
            indicatorType: RadioIndicatorType.DOT
          })
            .checked(this.isAutoCloseVoiceTransPop)
            .height(14)
            .radioStyle({ checkedBackgroundColor: ThemeConfig.PaletteTheme })
            .width(14)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                console.log('*****************************打开语音翻译弹窗自动关闭****************************************')
                this.isAutoCloseVoiceTransPop = true
              }
            })
          Text(Languages.on_common[this.languages])
            .fontSize($r('app.float.default_text_font_size_14'))
            .fontWeight(400)
            .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        }
        .onClick(() => {
          this.isAutoCloseVoiceTransPop = true
        })

        Row() {
          Radio({
            value: 'Radio5', group: 'radioGroup5',
            indicatorType: RadioIndicatorType.DOT
          })
            .checked(!this.isAutoCloseVoiceTransPop)
            .height(14)
            .radioStyle({ checkedBackgroundColor: ThemeConfig.PaletteTheme })
            .width(14)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                console.log('*****************************关闭语音翻译弹窗自动关闭****************************************')
                this.isAutoCloseVoiceTransPop = false

              }
            })
          Text(Languages.off_common[this.languages])
            .fontSize($r('app.float.default_text_font_size_14'))
            .fontWeight(400)
            .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        }
        .onClick(() => {
          this.isAutoCloseVoiceTransPop = false
        })
      }
      .width('100%')

    }
    .width('100%')
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

  shortcut_change() {
    // console.error('asdjkai:1',AppStorage.get('voice_recognition_shortcut'))
    // console.error('asdjkai:2',AppStorage.get('screenshot_recognition_shortcut'))
    // console.error('asdjkai:3',JSON.stringify(AppStorage.get('screenshot_recognition_shortcut')))
    // console.error('asdjkai:4',JSON.stringify(AppStorage.get('custom_shortcut')))
    this.voice_recognition_shortcut = (AppStorage.get('voice_recognition_shortcut') as shortcutType).keyPreview
    this.voice_translation_shortcut = (AppStorage.get('voice_translation_shortcut') as shortcutType).keyPreview
    this.screenshot_recognition_shortcut =
      (AppStorage.get('screenshot_recognition_shortcut') as shortcutType).keyPreview
  }
}
