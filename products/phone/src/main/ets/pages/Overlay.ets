import { CommonConfig } from "components_phone"

@Component
export struct Overlay {
   @StorageLink('voiceInputText') voiceInputText: string = ''
  @StorageLink('linshi') linshi: string = ''
  @StorageLink('voiceInputState') voiceInputState: boolean = true
  @StorageLink('isAI_assistant') isAI_assistant: boolean = false
  @StorageLink('assistant') assistant: boolean = false



  build() {
     if (this.voiceInputState){
       Flex({ direction: FlexDirection.Column }) {
         Flex() {
           Stack() {
             Image($r("app.media.float_window_deafult"))
               .width(100)
               .height(100)
             if (this.isAI_assistant) {
               Image($r(`${this.voiceInputState ? 'app.media.AI_assistant' : 'app.media.unAI_assistant'}`))
                 .width(32)
                 .height(32)
             } else {
               Image($r(`${this.voiceInputState ? 'app.media.voiceing_icon' : 'app.media.voice_icon'}`))
                 .width(32)
                 .height(32)
             }
           }
           .margin({ right: 24 })
           .width(100)

           Scroll() {
             Text(this.voiceInputText?this.voiceInputText:this.linshi)
               .textAlign(TextAlign.Start)
               .padding({ right: 8, left: 8 })
               .fontSize(14)
               .fontWeight(400)
               .fontColor(CommonConfig.commonBackgroundColor)
               .width('100%')
           }
           .align(Alignment.TopStart)
           .height('100%')
           .layoutWeight(1)
         }
         .width('100%')
         .padding(24)
         .borderRadius(16)
         .backgroundColor(Color.White)
       }

     }
  }
}