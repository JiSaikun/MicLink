import { Languages } from "config"

@Component
export struct FixedText_pop {
  @StorageLink('languages') languages: string = 'ZH_CN'
  @StorageLink("paletteTheme") paletteTheme: string = ''
  @StorageLink('fixedText') fixedText: string = '' //输入固定文本
  @Link isShowFixedText_pop: boolean

  build() {
    Stack() {
      Column() {
        Row() {
          // Text('输入固定文本')
          Text(Languages.input_fixed_text[this.languages])
            .fontSize(16)
            .fontWeight(400)
            .fontColor(Color.White)
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .borderRadius({ topLeft: 8, topRight: 8 })
        .padding(10)
        .backgroundColor(this.paletteTheme)

        // TextInput({ placeholder: '请输入固定文本', text: $$this.fixedText })
        TextInput({ placeholder: Languages.enter_fixed_text_placeholder[this.languages], text: $$this.fixedText })
          .backgroundColor('#fff')
          .placeholderColor('#bbbdbf')
          .margin({ top: 50, bottom: 50 ,left:20,right:20})
          .placeholderFont({ size: 14, weight: 400 })
          .border({ width: 1, color: '#eaeaea' })
          .borderRadius(5)

        Flex({ justifyContent: FlexAlign.Center }) {
          // Text('确定')
          Text(Languages.confirm_btn[this.languages])
            .fontSize(16)
            .fontWeight(400)
            .fontColor(Color.White)
            .padding({
              top: 15,
              bottom: 15,
              left: 35,
              right: 35
            })
            .backgroundColor(this.paletteTheme)
            .borderRadius(5)
            .onClick(() => {
              this.isShowFixedText_pop = false
            })
        }
        .width('100%')
      }
      .shadow({ radius: 10, color: '#e9e9eb' })
      .width(340)
      .borderRadius(8)
      .backgroundColor('#f5f5f5')
      .zIndex(10)
      .padding({ bottom: 20 })


      Column() {

      }
      .width('100%')
      .height('100%')
      .backgroundColor('#000')
      .opacity(0.2)
    }
    .width('100%')
    .height('100%')

  }
}