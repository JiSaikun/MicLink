import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"
import { TopTitle } from "../common/TopTitle"

@Builder
export function InterfaceLanguageBuilder() {
  InterfaceLanguage()
}

interface languagesListType {
  languages: string
  languagesCode: string
}

@Preview
@Component
struct InterfaceLanguage {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State languagesList: languagesListType[] = []

  aboutToAppear(): void {
    this.updateOptions()
  }

  onLanguagesChange() {
    this.updateOptions()
  }

  // 更新所有选项
  updateOptions(): void {
    this.languagesList = this.getLanguageOptions()
  }

  // 动态生成语言选项
  getLanguageOptions(): languagesListType[] {
    return [
      { languagesCode: 'ZH_CN', languages: Languages.ZH_CN[this.languages] },
      { languagesCode: 'EN_US', languages: Languages.EN_US[this.languages] },
      { languagesCode: 'ZH_TW', languages: Languages.ZH_TW[this.languages] },
      { languagesCode: 'JA_JP', languages: Languages.JA_JP[this.languages] },
      { languagesCode: 'VI_VN', languages: Languages.VI_VN[this.languages] },
      { languagesCode: 'KO_KR', languages: Languages.KO_KR[this.languages] },
      { languagesCode: 'ID_ID', languages: Languages.ID_ID[this.languages] },
      { languagesCode: 'TH_TH', languages: Languages.TH_TH[this.languages] },
      { languagesCode: 'FIL_PH', languages: Languages.FIL_PH[this.languages] },
      { languagesCode: 'MAY_MAY', languages: Languages.MAY_MAY[this.languages] },
      { languagesCode: 'RU_RU', languages: Languages.RU_RU[this.languages] },
      { languagesCode: 'TR_TR', languages: Languages.TR_TR[this.languages] },
      { languagesCode: 'FR_FR', languages: Languages.FR_FR[this.languages] },
      { languagesCode: 'DE_DE', languages: Languages.DE_DE[this.languages] },
      { languagesCode: 'IT_IT', languages: Languages.IT_IT[this.languages] },
      { languagesCode: 'ES_ES', languages: Languages.ES_ES[this.languages] },
      { languagesCode: 'MN_MN', languages: Languages.MN_MN[this.languages] },
      { languagesCode: 'AR_SA', languages: Languages.AR_SA[this.languages] },
      { languagesCode: 'KA_KA', languages: Languages.KA_KA[this.languages] },
      { languagesCode: 'UYGUR', languages: Languages.UYGUR[this.languages] }
    ]
  }

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column }) {
        TopTitle({ title: Languages.member[this.languages] })
          .margin({ bottom: 12 })
        List() {
          ForEach(this.languagesList, (item: languagesListType) => {
            ListItem() {
              Row() {
                Text(item.languages)
                  .fontSize(CommonConfig.fontSize_14)
                  .fontColor(CommonConfig.hintTextColor_select)
                  .fontWeight(CommonConfig.fontWeight_400)
                  .margin({ right: 8 })
                  .border({
                    width: { bottom: item.languagesCode === 'UYGUR' ? 0 : 1 },
                    color: CommonConfig.commonBackgroundColor
                  })
                Blank()
                if (this.languages === item.languagesCode) {
                  Image($r('app.media.Frame_2538'))
                    .width(16)
                    .height(16)
                }
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              .padding({ top: 12, bottom: 12 })
              .onClick(() => {
                this.languages = item.languagesCode
              })
            }
          }, (item: languagesListType) => item.languagesCode)


        }
        .padding({ left: 12, right: 12 })
        .borderRadius(12)
        .backgroundColor(Color.White)
      }
      .width('100%')
    }
    .padding(16)
    .backgroundColor(CommonConfig.commonBackgroundColor)
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}