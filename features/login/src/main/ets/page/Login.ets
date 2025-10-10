import { Contentbottom } from '../components/Contentbottom'
import { InputBox } from '../common/InputBox'
import { Captcha } from '../common/Captcha'
import { Languages } from 'config'


@Builder
export function LoginBuilder() {
  Login()
}

@Component
struct Login {
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State longin_operation: number = 0 //0:登录页 1：验证登录页 2：注册页 3：修改密码
  @State phone: string = '2847714478@qq.com' //手机号
  @State captcha: string = '' //验证码
  @State loginPassword: string = '' //登陆密码
  @State confirmPasswordTwice: string = '' //二次确认密码
  @State oldPassword: string = '' //旧密码
  @State newPassword: string = '' //新密码

  aboutToAppear(): void {
    // console.log('进入了登录页面')
  }

  build() {
    NavDestination() {
      Stack() {
        Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center }) {
          Image($r('app.media.Close'))
            .width(44)
            .margin({ left: 348, top: 8 })
          Image($r("app.media.trademark_login"))
            .width(150)
            .height(55)
          Column() {
            InputBox({
              placeholder: Languages.login_Contact[this.languages],
              data: this.phone,
              type: InputType.Email || InputType.PhoneNumber
            }) //手机号/邮箱
            Captcha({ captcha: this.captcha, phone: this.phone, longin_operation: this.longin_operation })
              .visibility(this.longin_operation !== 0 ? Visibility.Visible : Visibility.None)
            InputBox({
              placeholder: Languages.login_Password[this.languages],
              data: this.loginPassword,
              type: InputType.Password
            })//登录密码
              .visibility(this.longin_operation === 0 || this.longin_operation === 2 ? Visibility.Visible :
              Visibility.None)
            InputBox({
              placeholder: Languages.login_confirmPassword[this.languages],
              data: this.confirmPasswordTwice,
              type: InputType.Password
            })//二次确认密码
              .visibility(this.longin_operation === 2 ? Visibility.Visible : Visibility.None)
            InputBox({
              placeholder: Languages.login_oldPassword[this.languages],
              data: this.oldPassword,
              type: InputType.Password
            })//旧密码
              .visibility(this.longin_operation === 3 ? Visibility.Visible : Visibility.None)
            InputBox({
              placeholder: Languages.login_newPassword[this.languages],
              data: this.newPassword,
              type: InputType.Password
            })//新密码
              .visibility(this.longin_operation === 3 ? Visibility.Visible : Visibility.None)
          }
          .margin({ top: this.longin_operation === 0 || this.longin_operation === 1 ? 60 : 20 })

          Contentbottom({
            longin_operation: this.longin_operation,
            phone: this.phone,
            captcha: this.captcha,
            loginPassword: this.loginPassword,
            confirmPasswordTwice: this.confirmPasswordTwice,
            oldPassword: this.oldPassword,
            newPassword: this.newPassword
          })

        }
        .width(400)
        .height(500)
        .backgroundColor(Color.White)
        .borderRadius(8)

      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.backgroundColor'))
    }
    .title("登录")
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}