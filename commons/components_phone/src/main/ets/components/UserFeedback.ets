import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"
import { TopTitle } from "../common/TopTitle"
import { LengthMetrics } from "@kit.ArkUI"

@Builder
export function UserFeedbackBuilder() {
  UserFeedback()
}


@Component
struct UserFeedback {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @Consume('pageInfo') pageInfo: NavPathStack
  @StorageLink('languages') languages: string = 'ZH_CN'


  build() {
    NavDestination() {
      TopTitle({ title: Languages.membershipPackage[this.languages], isback: false })
        .margin({ left: 16, right: 16, bottom: 12 })
      Column() {
        Image($r('app.media.payment_terminal'))
          .width(163)
      }
      .width('100%')
      .layoutWeight(1)
      Text('完成')
        .width('100%')
        .textAlign(TextAlign.Center)
        .fontColor(Color.White)
        .fontWeight(CommonConfig.fontWeight_400)
        .fontSize(CommonConfig.fontSize_14)
        .backgroundColor(this.paletteTheme)
        .borderRadius(12)
        .padding(12)
        .onClick(()=>this.pageInfo.clear())

    }
    .padding(16)
    .backgroundColor(CommonConfig.commonBackgroundColor)
    .backgroundImage($r('app.media.background_1'))
    .backgroundImageSize({ width: '100%', height: '100%' })
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}