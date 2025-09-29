import { Float_Window } from 'float_window'
import { translate_Response } from "mouse"

/**
 * 语音翻译悬浮窗
 */
@Entry
@Component
struct VoiceTranslation {
  @StorageLink('voiceTranslationText') voiceTranslationText: translate_Response[] = []
  @StorageLink('voiceTranslationState') voiceTranslationState: boolean = true
  @StorageLink('voiceOrText') voiceOrText: boolean = true //语音翻译为true,文本翻译为false

  build() {
    Flex({ direction: FlexDirection.Column }) {
      Flex({ justifyContent: FlexAlign.SpaceBetween }) {
        Image($r('app.media.MicLink'))
          .width(48)
        Stack() {
          Image($r("app.media.float_window_deafult"))
            .width(100)
            .height(100)
          if (this.voiceOrText) {
            Image($r(`${this.voiceTranslationState ? 'app.media.voiceing_icon' : 'app.media.voice_icon'}`))
              .width(32)
              .height(32)
          } else {
            Image($r("app.media.textTranslation"))
              .objectFit(ImageFit.Contain)
              .width(32)
              .height(32)
          }

        }
        .width(100)

        Image($r('app.media.Frame_12'))
          .width(50)
          .height(50)
          .onClick(() => {
            Float_Window.destroyWindow(Float_Window.window_VoiceTranslation)
            Float_Window.showVoiceTranslation = false
          })
      }
      .width('100%')

      Column() {
        Scroll() {
          Column() {
            ForEach(this.voiceTranslationText, (item: translate_Response) => {
              TextArea({text:item.text})
                .width('100%')
                .textAlign(TextAlign.Start)
                .padding({ bottom: 10 })
                .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
                .fontWeight(400)
                .fontSize(14)
                .backgroundColor('#f8f8f8')
            }, (item: translate_Response) => item.index.toString())
          }
          .padding(12)
        }
        .width('100%')
        .height('50%')
        .align(Alignment.TopStart)

        Scroll() {
          Column() {
            ForEach(this.voiceTranslationText, (item: translate_Response) => {
              TextArea({ text: item.transText })
                .width('100%')
                .textAlign(TextAlign.Start)
                .padding({ bottom: 10 })
                .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
                .fontWeight(400)
                .fontSize(14)
                .backgroundColor(Color.White)
            }, (item: translate_Response) => item.index.toString())
          }
          .padding(12)
        }
        .borderRadius(8)
        .backgroundColor(Color.White)
        .width('100%')
        .height('50%')
        .align(Alignment.TopStart)
      }
      .layoutWeight(1)
      .width('100%')

      Flex() {

      }
    }.width('100%')
    .padding(24)
    .height('100%')
    .backgroundColor('#f8f8f8')
  }
}