import {config} from 'config'
@Extend(Text) function textDefaultStyle(){
  .fontSize(config.login_dafault_text_font_size)
  .fontWeight(config.login_dafault_text_font_weight)
  .fontColor(config.login_dafault_text_font_color)
}
@Component
export struct Contentbottom {
  @Link isChecked:boolean
  @Link longin_operation:number
  @Consume('pageInfo') pageInfo:NavPathStack
  build() {
    Column(){
      Row(){
        Checkbox({ name: '', group: '' })
          .select(false)
          .width(14)
          .onChange((isChecked)=>{
            this.isChecked=isChecked
          })
          Text(){
            Span('我已阅读并同意')
            Span('服务协议')
              .fontColor('#00aecc')
            Span('和')
            Span('隐私保护')
              .fontColor('#00aecc')
          }
          .fontSize(config.login_dafault_text_font_size)
          .fontWeight(config.login_dafault_text_font_weight)
          .fontColor(config.login_dafault_text_font_color)
      }
      .width(config.login_dafault_input_width)
      .margin({bottom:10})
      Text(this.longin_operation===3?'确认修改':this.longin_operation===2?'注册并登录':'登录')
        .width(config.login_dafault_input_width)
        .textAlign(TextAlign.Center)
        .height(32)
        .borderRadius(4)
        .backgroundColor('#00aecc')
        .fontColor("#fff")
        .margin({bottom:20})
        .onClick(()=>{
          AppStorage.setOrCreate("login",true)
          this.pageInfo.pop()

        })
      Row(){
        Text(this.longin_operation===0?'切换至验证码登录':'切换至密码登录')
          .textDefaultStyle()
          .onClick(()=>{
            if (this.longin_operation===0) {
              this.longin_operation=1
            }else {
              this.longin_operation=0
            }
          })
        Blank()
        Text('注册账号')
          .textDefaultStyle()
          .margin({right:5})
          .onClick(()=>{
            this.longin_operation=2
          })
        Text('忘记密码?')
          .textDefaultStyle()
          .onClick(()=>{
            this.longin_operation=3
          })
      }
      .width(config.login_dafault_input_width)
      .visibility(this.longin_operation==0||this.longin_operation==1?Visibility.Visible:Visibility.None)
      Row(){
        Text('返回登录页')
          .textDefaultStyle()
          .onClick(()=>{
            this.longin_operation=0
          })
        Blank()
        Text('忘记密码?')
          .textDefaultStyle()
          .onClick(()=>{
            this.longin_operation=3
          })
      }
      .width(config.login_dafault_input_width)
      .visibility(this.longin_operation==2?Visibility.Visible:Visibility.None)
      Row(){
        Text('返回登录页')
          .textDefaultStyle()
          .onClick(()=>{
            this.longin_operation=0
          })
      }
      .justifyContent(FlexAlign.Center)
      .width(config.login_dafault_input_width)
      .visibility(this.longin_operation==3?Visibility.Visible:Visibility.None)
    }
  }
}