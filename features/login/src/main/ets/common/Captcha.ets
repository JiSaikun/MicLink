import {config}from 'config'
@Component
export  struct Captcha {
  @Link data:string
  build() {
    Row(){
      TextInput({placeholder:'填写验证码',text:$$this.data})
        .width(175)
        .borderRadius({ topLeft:8,bottomLeft:8 })
        .padding(8)
        .type(InputType.Number)
        .backgroundColor($r('app.color.backgroundColor'))
        .placeholderColor(config.login_dafault_text_font_color)
        .fontSize(config.login_dafault_text_font_size)
        .fontWeight(config.login_dafault_text_font_weight)
      Text('获取验证码')
        .fontColor('#fff')
        .layoutWeight(1)
        .fontSize(12)
        .fontWeight(400)
        .borderRadius({topRight:8,bottomRight:8})
        .backgroundColor('#00aecc')
        .height('100%')
        .textAlign(TextAlign.Center)
    }
      .width(251)
      .height(36)
      .margin({bottom:10})

  }
}