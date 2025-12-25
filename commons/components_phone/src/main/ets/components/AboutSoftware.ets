import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"
import { TopTitle } from "../common/TopTitle"
import { LengthMetrics } from "@kit.ArkUI"
import { AppUtil } from "common"

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
        TopTitle({ title: Languages.aboutSoftware[this.languages], isback: false })
          .margin({ bottom: 80 })
        Image($r('app.media.MicLink'))
          .width(44)
          .height(41)
          .margin({ bottom: 32 })
        Column() {
          Row() {
            Text(Languages.currentVersion[this.languages]) // 当前版本
              .fontWeight(CommonConfig.fontWeight_400)
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
            Blank()
            Text(`V${AppUtil.getVersionName()}`)
              .fontWeight(CommonConfig.fontWeight_400)
              .fontSize(CommonConfig.fontSize_12)
              .fontColor(CommonConfig.hintTextColor)
          }
          .padding({ top: 12, bottom: 12 })
          .alignItems(VerticalAlign.Center)
          .border({ width: { bottom: 1 }, color: CommonConfig.commonBackgroundColor })
          .width("100%")

          Row() {
            Text(Languages.checkVersionUpdate[this.languages])  // 检查版本更新
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
              .fontWeight(CommonConfig.fontWeight_400)
              .onClick(()=>{
                AppUtil.checkAppUpdate()
              })
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

        Blank()
        Text(Languages.softwareVersion[this.languages] + `: V${AppUtil.getVersionName()}`)
          .fontWeight(CommonConfig.fontWeight_400)
          .fontSize(CommonConfig.fontSize_12)
          .fontColor(CommonConfig.hintTextColor)
      }
      .height('100%')

    }
    .padding({ left: 16, right: 16 })
    .backgroundColor(CommonConfig.commonBackgroundColor)
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}