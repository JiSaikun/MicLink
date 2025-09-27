@Entry
@Component
export struct Overlay {
  build() {
    Flex({ direction: FlexDirection.Column }) {
      Flex() {
        Stack() {
          Image($r("app.media.float_window_deafult"))
            .width(100)
            .height(100)
          Image($r("app.media.voiceing_icon"))
            .width(32)
            .height(32)
        }
        Scroll() {
          Text(AppStorage.get(''))
            .textAlign(TextAlign.Start)
            .padding({ right: 32,left:32 })
            .fontSize(14)
            .fontWeight(400)
            .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        }
        .layoutWeight(1)
        .height('100%')
      }
      .width(1100)
      .height(300)
      .padding(24)
      .borderRadius(16)
      .backgroundColor(Color.White)
    }
  }
}