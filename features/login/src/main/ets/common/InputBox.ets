import {config}from 'config'
@Component
export struct InputBox {
  @State placeholder:string=''
  @Link data:string
  build() {
    TextInput({placeholder:this.placeholder,text:$$this.data})
      .placeholderColor(config.login_dafault_text_font_color)
      .fontSize(config.login_dafault_text_font_size)
      .fontWeight(config.login_dafault_text_font_weight)
      .type(this.placeholder==='手机号'?InputType.Number:InputType.Normal)
      .width(config.login_dafault_input_width)
      .height(36)
      .borderRadius(8)
      .padding(8)
      .backgroundColor($r('app.color.backgroundColor'))
      .margin({bottom:10})
  }
}