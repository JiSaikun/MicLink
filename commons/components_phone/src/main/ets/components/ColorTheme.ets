import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"
import { TopTitle } from "../common/TopTitle"

@Builder
export function ColorThemeBuilder() {
  ColorTheme()
}

@Component
struct ColorTheme {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @StorageLink('languages') languages: string = 'ZH_CN'

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column }) {
        TopTitle({ title:  Languages.theme[this.languages] })
          .margin({ bottom: 12 })
        Column() {
          Row() {
            Text(Languages.primaryColor[this.languages])
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
              .fontWeight(CommonConfig.fontWeight_400)
              .margin({ right: 8 })
            Row()
              .width(12)
              .height(12)
              .borderRadius('50%')
              .backgroundColor('#00AECC')
            Blank()
            if (this.paletteTheme === '#00AECC') {
              Image($r('app.media.Frame_2538'))
                .width(16)
                .height(16)
            }
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding({ top: 12, bottom: 12 })
          .onClick(() => {
            this.paletteTheme = '#00AECC'
          })

          Row() {
            Text(Languages.black[this.languages])
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
              .fontWeight(CommonConfig.fontWeight_400)
              .margin({ right: 8 })
            Row()
              .width(12)
              .height(12)
              .borderRadius('50%')
              .backgroundColor('#000')
            Blank()
            if (this.paletteTheme === '#000') {
              Image($r('app.media.Frame_2538'))
                .width(16)
                .height(16)
            }
          }
          .border({ width: { top: 1, bottom: 1 }, color: CommonConfig.commonBackgroundColor })
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding({ top: 12, bottom: 12 })
          .onClick(() => {
            this.paletteTheme = '#000'
          })

          Row() {
            Text( Languages.white[this.languages])
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
              .fontWeight(CommonConfig.fontWeight_400)
              .margin({ right: 8 })
            Row()
              .width(12)
              .height(12)
              .border({ width: 1, color: '#EAEAEA' })
            // .borderColor('#00AECC')
              .borderRadius('50%')
            Blank()
            if (this.paletteTheme === '#fff') {
              Image($r('app.media.Frame_2538'))
                .width(16)
                .height(16)
            }
          }
          .width('100%').onClick(() => {
            this.paletteTheme = '#fff'
          })
          .alignItems(VerticalAlign.Center)
          .padding({ top: 12, bottom: 12 })
        }
        .padding({ left: 12, right: 12 })
        .borderRadius(12)
        .backgroundColor(Color.White)
      }
      .width('100%')
    }
    .padding({left:16,right:16})
    .backgroundColor(CommonConfig.commonBackgroundColor)
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}