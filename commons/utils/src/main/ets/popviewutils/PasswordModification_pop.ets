import { Languages } from "config"
import { CursorController, promptAction } from "@kit.ArkUI"
import { getCode_Params, resetPwd_Params } from "../model/UserModel"
import { _getCode, _resetPwd } from "../viewmodel/UserViewModel"
import { AxiosError } from "@ohos/axios"
import { pointer } from "@kit.InputKit"

@Component
export struct PasswordModification_pop {
  @StorageLink('languages') languages: string = 'ZH_CN'
  @Link isShow_passwordModification_pop: boolean
  @State phone: string = '' //手机号
  @State old_password: string = '' //旧密码
  @State new_password: string = '' //新密码
  @State captcha: string = '' //验证码
  @State countdown: number = 60
  @State sendState: boolean = false
  private timerId: number = 0 // 用于存储定时器的ID
  @Consume('pageInfo') pageInfo: NavPathStack
  cursorCustom: CursorController = this.getUIContext().getCursorController();

  build() {
    Stack() {
      Column() {
        Row() {
          Text(Languages.changePassword[this.languages])
            .fontSize(18)
            .fontWeight(500)
            .fontColor('#31373d')
          Blank()
          Image($r('app.media.pop_down'))
            .height(44)
            .width(44)
            .onClick(() => {
              this.isShow_passwordModification_pop = false
            })
            .onHover((flag) => {
              if (flag) {
                this.cursorCustom.setCursor(pointer.PointerStyle.HAND_POINTING);
              } else {
                console.info("restoreDefault");
                this.cursorCustom.restoreDefault();
              }
            })

        }
        .width('100%')

        Column() {
          Column({ space: 20 }) {
            Row() {
              Text(Languages.login_Contact[this.languages] + ":")
                .margin({ right: 15 })
              TextInput({ placeholder: Languages.login_Contact[this.languages], text: $$this.phone })
                .placeholderColor('#bbbdbf')
                .fontSize(14)
                .fontWeight(400)
                .type(InputType.Email || InputType.PhoneNumber)
                .width(310)
                .height(36)
                .borderRadius(4)
                .backgroundColor('#fff')
                .border({ width: 1, color: '#EAEAEA' })
            }

            Row() {
              Text(Languages.verificationCode[this.languages] + ":")
                .fontSize(18)
                .margin({ right: 15 })
                .fontWeight(500)
                .fontColor('#31373d')
              Row() {
                TextInput({
                  placeholder: Languages.verificationInput[this.languages],
                  text: $$this.captcha
                })//填写验证码
                  .width(221)
                  .borderRadius({ topLeft: 8, bottomLeft: 8 })
                  .padding(8)
                  .type(InputType.Number)
                  .backgroundColor('#fff')
                  .border({ width: 1, color: '#EAEAEA' })
                  .placeholderColor('#bbbdbf')
                  .fontSize(14)
                  .height('100%')
                  .fontWeight(400)
                  .type(InputType.Number)
                Text(this.sendState ? `${this.countdown}s` :
                Languages.verificationRetrieval[AppStorage.get('languages') as string])//获取验证码
                  .fontColor('#fff')
                  .fontSize(12)
                  .fontWeight(400)
                  .borderRadius({ topRight: 4, bottomRight: 4 })
                  .backgroundColor(AppStorage.get('paletteTheme'))
                  .height('100%')
                  .width(89)
                  .textAlign(TextAlign.Center)
                  .onHover((flag) => {
                    if (flag) {
                      this.cursorCustom.setCursor(pointer.PointerStyle.HAND_POINTING);
                    } else {
                      console.info("restoreDefault");
                      this.cursorCustom.restoreDefault();
                    }
                  })
                  .onClick(() => {
                    if (this.sendState) {
                      return
                    }
                    // 2. 确定codeType（原逻辑保留）
                    let codeType: string = 'RESET'
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
                    // 若两者都不匹配，保持accountType为空（无需额外代码）
                    if (!accountType) {
                      promptAction.showToast({
                        message: Languages.login_invalidAccountFormat[AppStorage.get('languages') as string], //账号格式不正确,请输入正确的手机号/邮箱
                        duration: 2000,
                        alignment: 4 // 鸿蒙 Alignment.Center 的枚举值为 4，避免直接引用可能的类型问题
                      });
                      return
                    }
                    // 4. 构造请求参数（使用判断后的accountType）
                    const params: getCode_Params = {
                      account: this.phone.trim(), // 传参时去除空格，保证数据准确性
                      accountType: accountType,
                      codeType: codeType
                    }
                    // 5. 接口请求（原逻辑保留，仅参数替换为上面构造的params）
                    _getCode(params)
                      .then(res => {
                        // 5. 倒计时逻辑（原逻辑保留）
                        this.sendState = true
                        this.timerId = setInterval(() => {
                          if (this.countdown === 1) {
                            clearInterval(this.timerId)
                            this.sendState = false
                            this.timerId = 0
                            this.countdown = 60 // 重置倒计时，避免下次点击从1开始
                            return
                          }
                          this.countdown--
                          // console.warn(this.countdown.toString())
                        }, 1000)
                        // console.log('页面渲染', JSON.stringify(res))
                        // 提取验证码并存储到AppStorage
                        let verificationCode = ''
                        if (res.message && res.message.includes('临时显示:')) {
                          const parts = res.message.split('临时显示:')
                          if (parts.length > 1) {
                            verificationCode = parts[1].trim()
                            console.log('提取到的验证码:', verificationCode)
                          }
                        }
                        // AppStorage.setOrCreate('_getCode', verificationCode)
                      })
                      .catch((err: AxiosError) => {
                        // 请求失败：重置状态+清除定时器
                        this.sendState = false
                        if (this.timerId) {
                          clearInterval(this.timerId)
                          this.timerId = 0
                        }
                        this.countdown = 60 // 重置倒计时，方便用户重新尝试
                        console.log('err', JSON.stringify(err))
                      })
                  })
              }
              .height(36)
            }

            Row() {
              Text(Languages.originalPassword[this.languages] + ":")
                .margin({ right: 15 })
              TextInput({ placeholder: Languages.enterOriginalPassword[this.languages], text: $$this.old_password })
                .placeholderColor('#bbbdbf')
                .fontSize(14)
                .fontWeight(400)
                .type(InputType.Email || InputType.PhoneNumber)
                .width(310)
                .height(36)
                .borderRadius(4)
                .backgroundColor('#fff')
                .border({ width: 1, color: '#EAEAEA' })
                .type(InputType.Password)

            }

            Row() {
              Text(Languages.login_newPassword[this.languages] + ":")
                .margin({ right: 15 })
              TextInput({ placeholder: Languages.enterNewPassword[this.languages], text: $$this.new_password })
                .placeholderColor('#bbbdbf')
                .fontSize(14)
                .fontWeight(400)
                .type(InputType.Email || InputType.PhoneNumber)
                .width(310)
                .height(36)
                .borderRadius(4)
                .backgroundColor('#fff')
                .border({ width: 1, color: '#EAEAEA' })
                .type(InputType.Password)
            }

          }
          .alignItems(HorizontalAlign.End)
          .padding(30)
          .border({ width: { top: 1, bottom: 1 }, color: '#F8F8F8' })
        }


        Row() {
          Text(Languages.confirm[AppStorage.get('languages') as string])
            .fontSize(14)
            .backgroundColor(AppStorage.get('paletteTheme'))
            .fontColor('#fff')
            .borderRadius(4)
            .padding({
              top: 9,
              right: 24,
              bottom: 9,
              left: 24
            })
            .onHover((flag) => {
              if (flag) {
                this.cursorCustom.setCursor(pointer.PointerStyle.HAND_POINTING);
              } else {
                console.info("restoreDefault");
                this.cursorCustom.restoreDefault();
              }
            })
            .onClick(() => {
              /******修改密码页*********/
              if (!this.captcha) {
                promptAction.showToast({
                  message: Languages.login_captchaEmpty[this.languages], //请输入验证码
                  duration: 2000,
                  alignment: Alignment.Center
                });
                return
              }
              if (!this.old_password) {
                promptAction.showToast({
                  message: Languages.originalPasswordRequired[this.languages], //原有密码不能为空
                  duration: 2000,
                  alignment: Alignment.Center
                });
                return
              }

              if (!this.new_password) {
                promptAction.showToast({
                  message: Languages.login_newPwdEmpty[this.languages], //新密码不能为空
                  duration: 2000,
                  alignment: Alignment.Center
                });
                return
              }


              const params4: resetPwd_Params = {
                account: this.phone.trim(), // 传参时去除空格，保证数据准确性
                code: this.captcha,
                password: this.new_password,
              }

              _resetPwd(params4)
                .then(res => {
                  console.log('修改密码', JSON.stringify(res))
                  //显示必须要有登录密码
                  if (res.statusCode === 200) {
                    promptAction.showToast({ message: Languages.changeSuccess[this.languages] })
                    this.isShow_passwordModification_pop = false
                    AppStorage.setOrCreate('login', false)
                    AppStorage.setOrCreate('userLoginInfo', null)
                    this.pageInfo.pushPath({ "name": "login" })
                  }
                })
                .catch(() => {
                  console.log('修改失败')
                })
            })
        }
        .justifyContent(FlexAlign.End)
        .width('100%')
      }
      .shadow({ radius: 10, color: '#e9e9eb' })
      .width(622)
      .borderRadius(8)
      .backgroundColor('#fff')
      .zIndex(10)
      .padding(24)


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