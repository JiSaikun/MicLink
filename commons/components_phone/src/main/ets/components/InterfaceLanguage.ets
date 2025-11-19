import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"
import { TopTitle } from "../common/TopTitle"

@Builder
export function InterfaceLanguageBuilder() {
  InterfaceLanguage()
}

@Preview
@Component
struct InterfaceLanguage {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @StorageLink('languages') languages: string = 'ZH_CN'

  // 固定的语言代码列表（不变）
  private languageCodes: string[] = [
    'ZH_CN', 'EN_US', 'ZH_TW', 'JA_JP', 'VI_VN', 'KO_KR',
    'ID_ID', 'TH_TH', 'FIL_PH', 'MAY_MAY', 'RU_RU', 'TR_TR',
    'FR_FR', 'DE_DE', 'IT_IT', 'ES_ES', 'MN_MN', 'AR_SA',
    'KA_KA', 'UYGUR'
  ]

  // 根据语言代码获取显示名称（响应式）
  getLanguageName(langCode: string): string {
    let langData: Record<string, string> | undefined;
    
    // 根据语言代码获取对应的翻译对象
    switch (langCode) {
      case 'ZH_CN':
        langData = Languages.ZH_CN;
        break;
      case 'EN_US':
        langData = Languages.EN_US;
        break;
      case 'ZH_TW':
        langData = Languages.ZH_TW;
        break;
      case 'JA_JP':
        langData = Languages.JA_JP;
        break;
      case 'VI_VN':
        langData = Languages.VI_VN;
        break;
      case 'KO_KR':
        langData = Languages.KO_KR;
        break;
      case 'ID_ID':
        langData = Languages.ID_ID;
        break;
      case 'TH_TH':
        langData = Languages.TH_TH;
        break;
      case 'FIL_PH':
        langData = Languages.FIL_PH;
        break;
      case 'MAY_MAY':
        langData = Languages.MAY_MAY;
        break;
      case 'RU_RU':
        langData = Languages.RU_RU;
        break;
      case 'TR_TR':
        langData = Languages.TR_TR;
        break;
      case 'FR_FR':
        langData = Languages.FR_FR;
        break;
      case 'DE_DE':
        langData = Languages.DE_DE;
        break;
      case 'IT_IT':
        langData = Languages.IT_IT;
        break;
      case 'ES_ES':
        langData = Languages.ES_ES;
        break;
      case 'MN_MN':
        langData = Languages.MN_MN;
        break;
      case 'AR_SA':
        langData = Languages.AR_SA;
        break;
      case 'KA_KA':
        langData = Languages.KA_KA;
        break;
      case 'UYGUR':
        langData = Languages.UYGUR;
        break;
      default:
        return langCode;
    }
    
    // 从翻译对象中获取当前界面语言对应的文本
    if (langData) {
      // 使用switch根据当前界面语言获取对应文本
      switch (this.languages) {
        case 'ZH_CN': return langData.ZH_CN || langCode;
        case 'EN_US': return langData.EN_US || langCode;
        case 'ZH_TW': return langData.ZH_TW || langCode;
        case 'JA_JP': return langData.JA_JP || langCode;
        case 'VI_VN': return langData.VI_VN || langCode;
        case 'KO_KR': return langData.KO_KR || langCode;
        case 'ID_ID': return langData.ID_ID || langCode;
        case 'TH_TH': return langData.TH_TH || langCode;
        case 'FIL_PH': return langData.FIL_PH || langCode;
        case 'MAY_MAY': return langData.MAY_MAY || langCode;
        case 'RU_RU': return langData.RU_RU || langCode;
        case 'TR_TR': return langData.TR_TR || langCode;
        case 'FR_FR': return langData.FR_FR || langCode;
        case 'DE_DE': return langData.DE_DE || langCode;
        case 'IT_IT': return langData.IT_IT || langCode;
        case 'ES_ES': return langData.ES_ES || langCode;
        case 'MN_MN': return langData.MN_MN || langCode;
        case 'AR_SA': return langData.AR_SA || langCode;
        case 'KA_KA': return langData.KA_KA || langCode;
        case 'UYGUR': return langData.UYGUR || langCode;
        default: return langCode;
      }
    }
    return langCode;
  }

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column }) {
        TopTitle({ title: Languages.member[this.languages] })
          .margin({ bottom: 12 })
        List() {
          ForEach(this.languageCodes, (langCode: string, index: number) => {
            ListItem() {
              Row() {
                Text(this.getLanguageName(langCode))
                  .fontSize(CommonConfig.fontSize_14)
                  .fontColor(CommonConfig.hintTextColor_select)
                  .fontWeight(CommonConfig.fontWeight_400)
                  .margin({ right: 8 })
                  .border({
                    width: { bottom: langCode === 'UYGUR' ? 0 : 1 },
                    color: CommonConfig.commonBackgroundColor
                  })
                Blank()
                if (this.languages === langCode) {
                  Image($r('app.media.Frame_2538'))
                    .width(16)
                    .height(16)
                }
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              .padding({ top: 12, bottom: 12 })
              .onClick(() => {
                this.languages = langCode
              })
            }
          }, (langCode: string) => langCode)
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