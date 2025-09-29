import { Communication } from 'mouse'

@Entry
@Component
export struct Overlay {
  @StorageLink('voiceInputText') voiceInputText: string = ''
  @StorageLink('voiceInputState') voiceInputState: boolean = true

  build() {
    Flex({ direction: FlexDirection.Column }) {
      Flex() {
        Stack() {
          Image($r("app.media.float_window_deafult"))
            .width(100)
            .height(100)
          Image($r(`${this.voiceInputState ? 'app.media.voiceing_icon' : 'app.media.voice_icon'}`))
            .width(32)
            .height(32)
        }
        .margin({ right: 24 })
        .width(100)

        Scroll() {
          Text(this.voiceInputText)
            .textAlign(TextAlign.Start)
            .padding({ right: 8, left: 8 })
            .fontSize(14)
            .fontWeight(400)
            .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
            .width('100%')
        }
        .align(Alignment.TopStart)
        .height('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .padding(24)
      .borderRadius(16)
      .backgroundColor(Color.White)
    }
  }
}