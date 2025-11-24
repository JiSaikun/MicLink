import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"
import { TopTitle } from "../common/TopTitle"
import { LengthMetrics } from "@kit.ArkUI"

@Builder
export function AboutSoftwareBuilder() {
  AboutSoftware()
}


@Component
struct AboutSoftware {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @Consume('pageInfo') pageInfo: NavPathStack
  @StorageLink('languages') languages: string = 'ZH_CN'

  build() {
    NavDestination() {
      Column() {
        // TopTitle({ title: Languages.membershipPackage[this.languages], isback: false })
        TopTitle({ title: '关于软件', isback: false })
          .margin({ bottom: 80 })
        Image($r('app.media.MicLink'))
          .width(44)
          .height(41)
          .margin({ bottom: 32 })
        Column() {
          Row() {
            Text('当前版本')
              .fontWeight(CommonConfig.fontWeight_400)
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
            Blank()
            Text('V2.7.17（14）')
              .fontWeight(CommonConfig.fontWeight_400)
              .fontSize(CommonConfig.fontSize_12)
              .fontColor(CommonConfig.hintTextColor)
          }
          .padding({ top: 12, bottom: 12 })
          .alignItems(VerticalAlign.Center)
          .width("100%")
          Row() {

            Text('检查版本更新')
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
              .fontWeight(CommonConfig.fontWeight_400)
            Blank()
            Image($r('app.media.Arrow_to_the_right'))
              .width(16)
              .height(16)
          }
          .backgroundColor(Color.White)
          .alignItems(VerticalAlign.Center)
          .width('100%')
          .padding({ bottom: 12, top: 12 })
          .onClick(() => {
          })
        }
        .width('100%')
        .borderRadius(12)
        .padding({ left: 12, right: 12 })
        .backgroundColor(Color.White)
      }

    }
    .padding({ left: 16, right: 16 })
    .backgroundColor(CommonConfig.commonBackgroundColor)
    .backgroundImage($r('app.media.background_1'))
    .backgroundImageSize({ width: '100%', height: '100%' })
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}