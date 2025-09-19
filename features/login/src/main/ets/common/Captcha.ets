import { config } from 'config'
import { getCode_Params } from '../model/UserModel' //数据响应模型
import { _getCode } from '../viewmodel/UserViewModel'
import { AxiosError } from '@ohos/axios';
import { promptAction } from '@kit.ArkUI';

@Component
export struct Captcha {
  @Link captcha: string //验证码
  @Link longin_operation: number //0:登录页 1：验证登录页 2：注册页 3：修改密码
  @Link phone: string //邮箱或者手机号
  @State countdown: number = 60
  @State sendState: boolean = false
  private timerId: number = 0 // 用于存储定时器的ID

  build() {
    Row() {
      TextInput({ placeholder: '填写验证码', text: $$this.captcha })
        .width(175)
        .borderRadius({ topLeft: 8, bottomLeft: 8 })
        .padding(8)
        .type(InputType.Number)
        .backgroundColor($r('app.color.backgroundColor'))
        .placeholderColor(config.login_dafault_text_font_color)
        .fontSize(config.login_dafault_text_font_size)
        .fontWeight(config.login_dafault_text_font_weight)
      Text(this.sendState ? `${this.countdown}s` : '获取验证码')
        .fontColor('#fff')
        .layoutWeight(1)
        .fontSize(12)
        .fontWeight(400)
        .borderRadius({ topRight: 8, bottomRight: 8 })
        .backgroundColor('#00aecc')
        .height('100%')
        .textAlign(TextAlign.Center)
        .onClick(() => {
          if (this.sendState) {
            return
          }

          // 2. 确定codeType（原逻辑保留）
          let codeType: string = ''
          switch (this.longin_operation) {
            case 1:
              codeType = 'LOGIN'
              break
            case 2:
              codeType = 'REGISTER'
              break
            case 3:
              codeType = 'RESET'
              break
            default:
              codeType = '' // 避免未匹配时的undefined
              break
          }

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
              message: '账号格式不正确,请输入正确的手机号/邮箱',
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
                console.warn(this.countdown.toString())
              }, 1000)
              console.log('页面渲染', JSON.stringify(res))
              // 提取验证码并存储到AppStorage
              let verificationCode = ''
              if (res.message && res.message.includes('临时显示:')) {
                const parts = res.message.split('临时显示:')
                if (parts.length > 1) {
                  verificationCode = parts[1].trim()
                  console.log('提取到的验证码:', verificationCode)
                }
              }
              AppStorage.setOrCreate('_getCode', verificationCode)
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
    .width(251)
    .height(36)
    .margin({ bottom: 10 })
  }
}