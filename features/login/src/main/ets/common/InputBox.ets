import { config } from 'config'

@Component
export struct InputBox {
  @State placeholder: string = ''
  @Link data: string
  @Prop type: InputType=InputType.Number

  build() {
    TextInput({ placeholder: this.data ? this.data : this.placeholder, text: $$this.data })
      .placeholderColor(config.login_dafault_text_font_color)
      .fontSize(config.login_dafault_text_font_size)
      .fontWeight(config.login_dafault_text_font_weight)
      .type(this.type)
      .width(config.login_dafault_input_width)
      .height(36)
      .borderRadius(8)
      .padding(8)
      .backgroundColor($r('app.color.backgroundColor'))
      .margin({ bottom: 10 })
  }
}
@Component
export struct InputBox_Phone {
  @State placeholder: string = ''
  @Link data: string
  @Prop type: InputType=InputType.Number

  build() {
    TextInput({ placeholder: this.data ? this.data : this.placeholder, text: $$this.data })
      .placeholderColor("#999")
      .fontSize(14)
      .fontWeight(config.login_dafault_text_font_weight)
      .type(this.type)
      .width("100%")
      .borderRadius(12)
      .padding(12)
      .backgroundColor(Color.White)
  }
}