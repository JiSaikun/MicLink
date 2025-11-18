import { CommonConfig } from "../common/CommonConfig"
import { TopTitle } from "../common/TopTitle"

@Builder
export function ColorThemeBuilder() {
  ColorTheme()
}

@Component
struct ColorTheme {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column }) {
        TopTitle({ title: '主题' })
          .margin({ bottom: 12 })
        Column() {
          Row(){
            Text('色彩主题')
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
              .fontWeight(CommonConfig.fontWeight_400)
            Blank()
            Image($r('app.media.Arrow_to_the_right'))
              .width(16)
              .height(16)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding({ top: 12, bottom: 12 })
          Row(){
            Text('界面语言')
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
              .fontWeight(CommonConfig.fontWeight_400)
            Blank()
            Image($r('app.media.Arrow_to_the_right'))
              .width(16)
              .height(16)
          }
          .border({width:{top:1,bottom:1},color:CommonConfig.commonBackgroundColor})
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding({ top: 12, bottom: 12 })
          Row(){
            Text('后台保持运行')
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
              .fontWeight(CommonConfig.fontWeight_400)
            Blank()
            Toggle({ type: ToggleType.Switch, isOn: true }).onChange((value: boolean) => {
              // 处理开关逻辑
            })
              .selectedColor(this.paletteTheme)
              .height(22)
              .width(44)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding({ top: 12, bottom: 12 })
        }
        .padding({ left: 12, right: 12 })
        .borderRadius(12)
        .backgroundColor(Color.White)
      }
      .width('100%')
    }
    .padding(16)
    .backgroundColor(CommonConfig.commonBackgroundColor)
    // .hideTitleBar(true)
    // .hideToolBar(true)
    .title('ashdjkh')
  }
}