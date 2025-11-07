import { LengthMetrics } from "@kit.ArkUI";
import { ThemeConfig } from "common";
import { Languages } from "config";

@Component
export struct Settings {
  // 监听语言变化，更新选项
  @Watch('updateOptions')@StorageLink('languages') languages: string = 'ZH_CN'
  @StorageLink("paletteTheme") paletteTheme: string = ThemeConfig.PaletteTheme
  @StorageLink("resolutionScale") resolutionScale: string = 'followSystem'

  aboutToAppear(): void {
    this.paletteTheme = ThemeConfig.PaletteTheme
    this.updateOptions()
  }

  @State resolution: SelectOption[] = []
  @State languagesList: SelectOption[] = []
  @State languagesCode: string[] = [
    'ZH_CN', 'EN_US', 'ZH_TW', 'JA_JP', 'VI_VN', 'KO_KR', 'ID_ID', 'TH_TH', 'FIL_PH', 'MAY_MAY',
    'RU_RU', 'TR_TR', 'FR_FR', 'DE_DE', 'IT_IT', 'ES_ES', 'MN_MN', 'AR_SA', 'KA_KA', 'UYGUR'
  ]
  @State resolutionValues: string[] = ['followSystem', '100%', '125%', '150%', '175%', '200%']


  onLanguagesChange() {
    this.updateOptions()
  }

  // 更新所有选项
  updateOptions(): void {
    this.resolution = this.getResolutionOptions()
    this.languagesList = this.getLanguageOptions()
  }

  // 动态生成分辨率选项
  getResolutionOptions(): SelectOption[] {
    return [
      { value: Languages.followSystem[this.languages] },
      { value: '100%' },
      { value: '125%' },
      { value: '150%' },
      { value: '175%' },
      { value: '200%' }
    ]
  }

  // 动态生成语言选项
  getLanguageOptions(): SelectOption[] {
    return [
      { value: Languages.ZH_CN[this.languages] },
      { value: Languages.EN_US[this.languages] },
      { value: Languages.ZH_TW[this.languages] },
      { value: Languages.JA_JP[this.languages] },
      { value: Languages.VI_VN[this.languages] },
      { value: Languages.KO_KR[this.languages] },
      { value: Languages.ID_ID[this.languages] },
      { value: Languages.TH_TH[this.languages] },
      { value: Languages.FIL_PH[this.languages] },
      { value: Languages.MAY_MAY[this.languages] },
      { value: Languages.RU_RU[this.languages] },
      { value: Languages.TR_TR[this.languages] },
      { value: Languages.FR_FR[this.languages] },
      { value: Languages.DE_DE[this.languages] },
      { value: Languages.IT_IT[this.languages] },
      { value: Languages.ES_ES[this.languages] },
      { value: Languages.MN_MN[this.languages] },
      { value: Languages.AR_SA[this.languages] },
      { value: Languages.KA_KA[this.languages] },
      { value: Languages.UYGUR[this.languages] }
    ]
  }

  init_languagesCode(): number {
    for (let index = 0; index < this.languagesCode.length; index++) {
      if (this.languagesCode[index] === this.languages) {
        return index
      }
    }
    return 0
  }

  init_resolution(): number {
    for (let index = 0; index < this.resolutionValues.length; index++) {
      if (this.resolutionValues[index] === this.resolutionScale) {
        return index
      }
    }
    return 0
  }

  // 应用分辨率设置
  applyResolution(scale: string): void {
    console.info(`应用分辨率: ${scale}`)
    // 这里可以添加实际应用分辨率的逻辑
    // 例如调整窗口大小、字体大小等
    if (scale === 'followSystem') {
      // 跟随系统设置
      console.info('使用系统默认分辨率')
    } else {
      // 应用指定的缩放比例
      const scaleValue = parseFloat(scale) / 100
      console.info(`应用缩放比例: ${scaleValue}`)
      // 可以在这里设置全局缩放因子
    }
  }

  build() {
    Flex({ space: { main: LengthMetrics.px(24) }, direction: FlexDirection.Column }) {
      Text(Languages.displaySettings[this.languages])
        .fontSize(ThemeConfig.TextSize_14)
        .fontWeight(ThemeConfig.TextWeight_400)
        .fontColor(ThemeConfig.SecondaryTextColor)

      Flex() {
        Column() {
          Text(Languages.resolution[this.languages])
            .fontSize(ThemeConfig.TextSize_14)
            .fontWeight(ThemeConfig.TextWeight_400)
            .margin({ bottom: 12 })
            .fontColor(ThemeConfig.TextBodyColor)

          Select(this.resolution)
            .value(this.resolution[this.init_resolution()].value)
            .onSelect((index: number) => {
              const selectedScale = this.resolutionValues[index]
              AppStorage.setOrCreate('resolutionScale', selectedScale)
              this.applyResolution(selectedScale)
            })
            .selected(this.init_resolution())
            .width('100%')
            .font({ size: ThemeConfig.TextSize_12, weight: 400 })
            .fontColor(ThemeConfig.TextBodyColor)
            .borderRadius(4)
            .border({ width: 1, color: 'f2f2f2' })
            .backgroundColor(Color.White)
        }
        .padding({ right: 150 })
        .flexShrink(1)
        .flexGrow(1)
        .width(1)
        .alignItems(HorizontalAlign.Start)

        Column() {
          Text(Languages.languages[this.languages])
            .fontSize(ThemeConfig.TextSize_14)
            .fontWeight(ThemeConfig.TextWeight_400)
            .fontColor(ThemeConfig.TextBodyColor)
            .margin({ bottom: 12 })

          Select(this.languagesList)
            .value(this.languagesList[this.init_languagesCode()].value)
            .onSelect((index: number) => {
              AppStorage.setOrCreate('languages', this.languagesCode[index])
            })
            .selected(this.init_languagesCode())
            .width('100%')
            .font({ size: ThemeConfig.TextSize_12, weight: 400 })
            .fontColor(ThemeConfig.TextBodyColor)
            .borderRadius(4)
            .border({ width: 1, color: 'f2f2f2' })
            .optionHeight(300)
            .backgroundColor(Color.White)
        }
        .alignItems(HorizontalAlign.Start)
        .width(1)
        .padding({ right: 150 })
        .flexShrink(1)
        .flexGrow(1)
      }
      .width('100%')

      Text('开机启动')
        .fontSize(ThemeConfig.TextSize_14)
        .fontWeight(ThemeConfig.TextWeight_400)
        .fontColor(ThemeConfig.TextBodyColor)
      Toggle({ type: ToggleType.Switch, isOn: true }).onChange((value: boolean) => {
        // 处理开关逻辑
      })
        .selectedColor(this.paletteTheme)
        .height(22)
        .width(44)

      Text('色彩主题')
        .fontSize(ThemeConfig.TextSize_14)
        .fontWeight(ThemeConfig.TextWeight_400)
        .fontColor(ThemeConfig.SecondaryTextColor)

      Flex({ space: { main: LengthMetrics.px(15) } }) {
        Column() {
          Row()
            .width(24)
            .height(24)
            .borderRadius('50%')
            .backgroundColor('#EB5E12')
          Radio({
            value: 'Radio1', group: 'radioGroup',
            indicatorType: RadioIndicatorType.DOT
          })
            .checked(this.paletteTheme === '#EB5E12')
            .height(14)
            .width(14)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                ThemeConfig.PaletteTheme = '#EB5E12'
                AppStorage.setOrCreate('paletteTheme', ThemeConfig.PaletteTheme)
              }
            })
            .radioStyle({ checkedBackgroundColor: this.paletteTheme })
        }
        .onClick(() => {
          ThemeConfig.PaletteTheme = '#EB5E12'
          AppStorage.setOrCreate('paletteTheme', ThemeConfig.PaletteTheme)
        })

        Column() {
          Row()
            .width(24)
            .height(24)
            .borderRadius('50%')
            .backgroundColor('#00aecc')
          Radio({
            value: 'Radio2', group: 'radioGroup',
            indicatorType: RadioIndicatorType.DOT
          })
            .checked(this.paletteTheme === '#00aecc')
            .height(14)
            .width(14)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                ThemeConfig.PaletteTheme = '#00aecc'
                AppStorage.setOrCreate('paletteTheme', ThemeConfig.PaletteTheme)
              }
            })
            .radioStyle({ checkedBackgroundColor: this.paletteTheme })
        }
        .onClick(() => {
          ThemeConfig.PaletteTheme = '#00aecc'
          AppStorage.setOrCreate('paletteTheme', ThemeConfig.PaletteTheme)
        })

        Column() {
          Row()
            .width(24)
            .height(24)
            .borderRadius('50%')
            .backgroundColor('#74B101')
          Radio({
            value: 'Radio3', group: 'radioGroup',
            indicatorType: RadioIndicatorType.DOT
          })
            .checked(this.paletteTheme === '#74B101')
            .height(14)
            .width(14)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                ThemeConfig.PaletteTheme = '#74B101'
                AppStorage.setOrCreate('paletteTheme', ThemeConfig.PaletteTheme)
              }
            })
            .radioStyle({ checkedBackgroundColor: this.paletteTheme })
        }
        .onClick(() => {
          ThemeConfig.PaletteTheme = '#74B101'
          AppStorage.setOrCreate('paletteTheme', ThemeConfig.PaletteTheme)
        })
      }
    }
    .padding(20)
  }
}