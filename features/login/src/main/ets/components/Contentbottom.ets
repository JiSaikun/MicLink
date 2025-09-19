import { config } from 'config'
import { promptAction } from '@kit.ArkUI'
import { register_Params, register_Response, login_Params, resetPwd_Params } from '../model/UserModel' //数据响应模型
import { _register, _login, _resetPwd } from '../viewmodel/UserViewModel'
import { AxiosError } from '@ohos/axios';

@Extend(Text)
function textDefaultStyle() {
  .fontSize(config.login_dafault_text_font_size)
  .fontWeight(config.login_dafault_text_font_weight)
  .fontColor(config.login_dafault_text_font_color)
}

@Component
export struct Contentbottom {
  @State isChecked: boolean = false
  @Watch('change_longin_operation') @Link longin_operation: number
  @Consume('pageInfo') pageInfo: NavPathStack
  @Link phone: string
  @Link captcha: string
  @Link loginPassword: string
  @Link confirmPasswordTwice: string
  @Link oldPassword: string
  @Link newPassword: string

  change_longin_operation() {
    console.error('索引号改变')
    // AppStorage.setOrCreate('_getCode', '')
    // this.phone=''
    this.captcha = ''
    this.loginPassword = ''
    this.confirmPasswordTwice = ''
    this.oldPassword = ''
    this.newPassword = ''
  }

  build() {
    Column() {
      Row() {
        Checkbox({ name: '', group: '' })
          .select(false)
          .width(14)
          .onChange((isChecked) => {
            this.isChecked = isChecked
          })
        Text() {
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
      .margin({ bottom: 10 })

      Text(this.longin_operation === 3 ? '确认修改' : this.longin_operation === 2 ? '注册并登录' : '登录')
        .width(config.login_dafault_input_width)
        .textAlign(TextAlign.Center)
        .height(32)
        .borderRadius(4)
        .backgroundColor('#00aecc')
        .fontColor("#fff")
        .margin({ bottom: 20 })
        .onClick(() => {
          console.log('********************************点击登录')
          if (!this.phone) {
            promptAction.showToast({
              message: '账号不能为空',
              duration: 2000,
              alignment: Alignment.Center
            });
            return
          }
          if (this.longin_operation === 0) {
            /******登录页*********/
            if (!this.loginPassword) {
              promptAction.showToast({
                message: '登录密码不能为空1',
                duration: 2000,
                alignment: Alignment.Center
              });
              return
            }
          }
          if (this.longin_operation === 1) {
            /******验证登录页*********/
            if (!this.captcha) {
              promptAction.showToast({
                message: '请输入验证码',
                duration: 2000,
                alignment: Alignment.Center
              });
              return
            }
          }
          if (this.longin_operation == 2) {
            /******注册页*********/
            if (!this.captcha) {
              promptAction.showToast({
                message: '请输入验证码',
                duration: 2000,
                alignment: Alignment.Center
              });
              return
            }
            if (!this.loginPassword) {
              promptAction.showToast({
                message: '登录密码不能为空2',
                duration: 2000,
                alignment: Alignment.Center
              });
              return
            }
            if (!this.confirmPasswordTwice) {
              promptAction.showToast({
                message: '二次确认密码不能为空',
                duration: 2000,
                alignment: Alignment.Center
              });
              return
            }
            if (this.loginPassword !== this.confirmPasswordTwice) {
              promptAction.showToast({
                message: '两次密码输入不一致',
                duration: 2000,
                alignment: Alignment.Center
              });
              return
            }

          }
          if (this.longin_operation == 3) {
            /******修改密码页*********/
            if (!this.captcha) {
              promptAction.showToast({
                message: '请输入验证码',
                duration: 2000,
                alignment: Alignment.Center
              });
              return
            }
            if (!this.oldPassword) {
              promptAction.showToast({
                message: '旧密码不能为空',
                duration: 2000,
                alignment: Alignment.Center
              });
              return
            }
            if (!this.newPassword) {
              promptAction.showToast({
                message: '新密码不能为空',
                duration: 2000,
                alignment: Alignment.Center
              });
              return
            }

          }
          if (!this.isChecked) {
            promptAction.showToast({
              message: '请先阅读并同意服务协议和隐私保护',
              duration: 2000,
              alignment: Alignment.Center
            });
            return
          }
          let getcode = AppStorage.get('_getCode') as string
          if (this.captcha !== getcode && this.longin_operation !== 0) {
            promptAction.showToast({
              message: '验证码不正确',
              duration: 2000,
              alignment: Alignment.Center
            });
            return
          }

          /**
           * 判断账号类型
           */

          // 3. 核心修改：根据phone判断accountType
          let accountType = '' // 初始为空（默认“两者都不是”）
          // 3.1 手机号正则：匹配11位数字（国内手机号通用格式）
          const phoneReg = /^1\d{10}$/
          // 3.2 邮箱正则：匹配“xxx@xxx.xxx”格式（基础通用邮箱规则）
          const emailReg = /^[a-zA-Z0-9_-]+@[a-zA-Z0-9_-]+(\.[a-zA-Z0-9_-]+)+$/

          // 3.3 优先级：先判断手机号，再判断邮箱（可根据业务调整）
          if (phoneReg.test(this.phone.trim())) { // 去除空格后匹配（避免用户误输入空格）
            accountType = 'PHONE'
          } else if (emailReg.test(this.phone.trim())) {
            accountType = 'EMAIL'
          }
          switch (this.longin_operation) {
            case 0:
              const params1: login_Params = {
                account: this.phone.trim(), // 传参时去除空格，保证数据准确性
                password: this.loginPassword
              }
              _login(params1)
                .then(res => {
                  console.log('注册登录', JSON.stringify(res))
                  if (res.statusCode === 200) {
                    let userLoginInfo: register_Response = res.data as register_Response
                    AppStorage.setOrCreate('userLoginInfo', userLoginInfo)
                    AppStorage.setOrCreate("login", true)
                    this.pageInfo.pop()
                  }
                  // let userLoginInfo: register_Response = res.data as register_Response
                  // AppStorage.setOrCreate('userLoginInfo', userLoginInfo)
                })
                .catch(() => {
                  console.log('注册登录失败')
                })
              break
            case 1:
              const params2: login_Params = {
                account: this.phone.trim(), // 传参时去除空格，保证数据准确性
                code: this.captcha
              }
              _login(params2)
                .then(res => {
                  console.log('验证码登录', JSON.stringify(res))
                  //显示必须要有登录密码

                  //   if (res.statusCode === 200) {
                  //     // let userLoginInfo: register_Response = res.data as register_Response
                  //     // AppStorage.setOrCreate('userLoginInfo', userLoginInfo)
                  //     // AppStorage.setOrCreate("login", true)
                  //     // this.pageInfo.pop()
                  //   }
                  //   // let userLoginInfo: register_Response = res.data as register_Response
                  //   // AppStorage.setOrCreate('userLoginInfo', userLoginInfo)
                  // })
                  // .catch(() => {
                  //   console.log('注册登录失败')
                })
              break
            case 2:
              const params3: register_Params = {
                account: this.phone.trim(), // 传参时去除空格，保证数据准确性
                code: this.captcha,
                password: this.loginPassword,
                type: accountType
              }
              _register(params3)
                .then(res => {
                  console.log('注册登录', JSON.stringify(res))
                  if (res.statusCode === 200) {
                    let userLoginInfo: register_Response = res.data as register_Response
                    AppStorage.setOrCreate('userLoginInfo', userLoginInfo)
                    AppStorage.setOrCreate("login", true)
                    this.pageInfo.pop()
                  } else {
                    return
                  }

                }).catch(() => {
                /**
                 * 请求错误
                 */
              })
              break
            case 3:
              const params4: resetPwd_Params = {
                account: this.phone.trim(), // 传参时去除空格，保证数据准确性
                code: this.captcha,
                password: this.loginPassword,
              }
              _resetPwd(params4)
                .then(res => {
                  console.log('验证码登录', JSON.stringify(res))
                  //显示必须要有登录密码

                  //   if (res.statusCode === 200) {
                  //     // let userLoginInfo: register_Response = res.data as register_Response
                  //     // AppStorage.setOrCreate('userLoginInfo', userLoginInfo)
                  //     // AppStorage.setOrCreate("login", true)
                  //     // this.pageInfo.pop()
                  //   }
                  //   // let userLoginInfo: register_Response = res.data as register_Response
                  //   // AppStorage.setOrCreate('userLoginInfo', userLoginInfo)
                  // })
                  // .catch(() => {
                  //   console.log('注册登录失败')
                })
              break
          }

        })
      Row() {
        Text(this.longin_operation === 0 ? '切换至验证码登录' : '切换至密码登录')
          .textDefaultStyle()
          .onClick(() => {
            if (this.longin_operation === 0) {
              this.longin_operation = 1
            } else {
              this.longin_operation = 0
            }
          })
        Blank()
        Text('注册账号')
          .textDefaultStyle()
          .margin({ right: 5 })
          .onClick(() => {
            this.longin_operation = 2
          })
        Text('忘记密码?')
          .textDefaultStyle()
          .onClick(() => {
            this.longin_operation = 3
          })
      }
      .width(config.login_dafault_input_width)
      .visibility(this.longin_operation == 0 || this.longin_operation == 1 ? Visibility.Visible : Visibility.None)

      Row() {
        Text('返回登录页')
          .textDefaultStyle()
          .onClick(() => {
            this.longin_operation = 0
          })
        Blank()
        Text('忘记密码?')
          .textDefaultStyle()
          .onClick(() => {
            this.longin_operation = 3
          })
      }
      .width(config.login_dafault_input_width)
      .visibility(this.longin_operation == 2 ? Visibility.Visible : Visibility.None)

      Row() {
        Text('返回登录页')
          .textDefaultStyle()
          .onClick(() => {
            this.longin_operation = 0
          })
      }
      .justifyContent(FlexAlign.Center)
      .width(config.login_dafault_input_width)
      .visibility(this.longin_operation == 3 ? Visibility.Visible : Visibility.None)
    }
  }
}