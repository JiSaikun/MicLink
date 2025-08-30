import { LoginPage } from '../components/LoginPage'
import { Contentbottom } from '../components/Contentbottom'
import {InputBox}from '../common/InputBox'
import {Captcha}from '../common/Captcha'

@Builder
export function LoginBuilder() {
  Login()
}


@Component
struct Login {
  @State longin_operation: number = 0 //0:登录页 1：验证登录页 2：注册页 3：修改密码
  @State phone:string=''    //手机号
  @State captcha:string=''  //验证码
  @State loginPassword:string=''  //登陆密码
  @State confirmPasswordTwice:string=''  //二次确认密码
  @State oldPassword:string=''  //旧密码
  @State newPassword:string=''  //新密码
  @State isReaded:boolean=false

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
          Column(){
            InputBox({placeholder:'手机号',data:this.phone})
            Captcha({data:this.captcha})
              .visibility(this.longin_operation!==0?Visibility.Visible:Visibility.None)
            InputBox({placeholder:'登录密码',data:this.loginPassword})
              .visibility(this.longin_operation===0||this.longin_operation===2?Visibility.Visible:Visibility.None)
            InputBox({placeholder:'二次确认密码',data:this.confirmPasswordTwice})
              .visibility(this.longin_operation===2?Visibility.Visible:Visibility.None)
            InputBox({placeholder:'旧密码',data:this.oldPassword})
              .visibility(this.longin_operation===3?Visibility.Visible:Visibility.None)
            InputBox({placeholder:'新密码',data:this.newPassword})
              .visibility(this.longin_operation===3?Visibility.Visible:Visibility.None)
          }
          .margin({top:this.longin_operation===0||this.longin_operation===1?60:20})
          Contentbottom({isChecked:this.isReaded,longin_operation:this.longin_operation})

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