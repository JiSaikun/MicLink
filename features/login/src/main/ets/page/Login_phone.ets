import { Contentbottom, Contentbottom_Phone } from '../components/Contentbottom'
import { InputBox_Phone } from '../common/InputBox'
import { Captcha_Phone } from '../common/Captcha'
import { Languages } from 'config'


@Component
export struct Login_phone {
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State longin_operation: number = 0 //0:登录页 1：验证登录页 2：注册页 3：修改密码 4:忘记密码
  @State phone: string = '' //手机号
  @State captcha: string = '' //验证码
  @State loginPassword: string = '' //登陆密码
  // @State confirmPasswordTwice: string = '' //二次确认密码
  @State oldPassword: string = '' //旧密码
  @State newPassword: string = '' //新密码
  @State newPassword_confirmPasswordTwice: string = '' //新密码_确认密码

  aboutToAppear(): void {
    // console.log('进入了登录页面')
  }

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center }) {
        Image('')
          .height(44)

        Image($r("app.media.trademark_login"))
          .width(160)
          .height(59)
          .objectFit(ImageFit.Fill)
          .margin({top:50,bottom:32})

        Column() {
          InputBox_Phone({
            placeholder: Languages.login_Contact[this.languages],
            data: this.phone,
            type: InputType.Email || InputType.PhoneNumber
          }) //手机号/邮箱
          Captcha_Phone({ captcha: this.captcha, phone: this.phone, longin_operation: this.longin_operation })
            .visibility(this.longin_operation !== 0 ? Visibility.Visible : Visibility.None)
            .margin({top:24})
          InputBox_Phone({
            placeholder: Languages.login_Password[this.languages],
            data: this.loginPassword,
            type: InputType.Password
          })//登录密码
            .visibility(this.longin_operation === 0 || this.longin_operation === 2 ? Visibility.Visible :
            Visibility.None)
            .margin({top:24})
          //
          // InputBox_Phone({
          //   placeholder: Languages.login_confirmPassword[this.languages],
          //   data: this.confirmPasswordTwice,
          //   type: InputType.Password
          // })//二次确认密码
          //   .visibility(this.longin_operation === 2 ? Visibility.Visible : Visibility.None)
          //   .margin({top:24})
          InputBox_Phone({
            placeholder: Languages.login_oldPassword[this.languages],
            data: this.oldPassword,
            type: InputType.Password
          })//旧密码
            .visibility(this.longin_operation === 3 ? Visibility.Visible : Visibility.None)
            .margin({top:24})
          InputBox_Phone({
            placeholder: Languages.login_newPassword[this.languages],
            data: this.newPassword,
            type: InputType.Password
          })//新密码
            .visibility(this.longin_operation === 3 || this.longin_operation === 4 ? Visibility.Visible :
            Visibility.None)
            .margin({top:24})
          InputBox_Phone({
            placeholder: Languages.login_confirmPassword[this.languages],
            data: this.newPassword_confirmPasswordTwice,
            type: InputType.Password
          })
            .margin({top:24})
            .visibility(this.longin_operation === 4 ? Visibility.Visible : Visibility.None)
        }
        .margin({bottom:32})
        Contentbottom_Phone({
          longin_operation: this.longin_operation,
          phone: this.phone,
          captcha: this.captcha,
          loginPassword: this.loginPassword,
          oldPassword: this.oldPassword,
          newPassword: this.newPassword,
          newPassword_confirmPasswordTwice: this.newPassword_confirmPasswordTwice
        })

      }
      .width('100%')
      .padding({left:40,right:40})
    }
    // .title("登录")
    .hideTitleBar(true)
    .backgroundImage($r('app.media.background_1'))
    .backgroundImageSize({ width: '100%', height: '100%' })
    .hideToolBar(true)
  }
}