import { PopViewUtils, LaunchLogin_pop, PopParams_1 } from 'utils'
import { Languages } from 'config'
import { UserLoginInfo } from '../model/UserLoginInfo'

@Component
export struct Topbar {
  @State isDown: boolean = false
  @StorageLink('languages') languages: string = 'ZH_CN' //语言适配
  @StorageLink('userLoginInfo') userLoginInfo: UserLoginInfo = AppStorage.get('userLoginInfo') as UserLoginInfo //语言适配
  @Consume('pageInfo') pageInfo: NavPathStack

  @Styles
  textStyle(){
    .height(40)
  }

  aboutToAppear(): void {
    // this.pageInfo.pushPath({"name":'login'})
  }

  down() {
    PopViewUtils.closePopView()
  }

  // 修改后（使用箭头函数自动绑定 this）
  confirm = () => {
    PopViewUtils.closePopView();
    AppStorage.setOrCreate("login", false);
    this.pageInfo.pushPath({ "name": 'login' });
    AppStorage.setOrCreate('userLoginInfo', null)
  }

  build() {
    Row() {
      RelativeContainer() {
        Row() {
          Image(this.userLoginInfo?.avatar?this.userLoginInfo.avatar: $r('app.media.avatar'))
            .width(32)
            .height(32)
            .borderRadius(100)
            .objectFit(ImageFit.Fill)
            .margin({ right: 10 })
          Text(this.userLoginInfo ? this.userLoginInfo.name : '迷人的Justin')
            .fontSize(14)
            .fontWeight(400)
            .lineHeight(14)
            .fontColor('#31373d')
          Image($r('app.media.downward_arrow'))
            .width(16)
            .rotate({
              angle: this.isDown ? 180 : 0,
              centerZ: 180
            })
        }
        .alignRules({
          middle: { anchor: '__container__', align: HorizontalAlign.Center },
          center: { anchor: '__container__', align: VerticalAlign.Center },
        })
        .onClick(() => {
          this.isDown = !this.isDown
          if (this.isDown) {
            setTimeout(() => {
              this.isDown = false
            }, 5000)
          }
        })

        Column() {
          Text(Languages.profile[this.languages])
            .textStyle()
            .onClick(() => {
              this.pageInfo.pushPath({ name: 'personalCenter' })
            })
          Text(Languages.passwordReset[this.languages])
            .textStyle()
            .onClick(() => {
              AppStorage.setOrCreate('isShow_passwordModification_pop', true)
            })
          Divider()
            .width('100%')
            .height(1)
          Text(Languages.logout[this.languages])
            .textStyle()
            .onClick(() => {
              // console.log('===============================退出登录')
              const params_1: PopParams_1 = {
                content: Languages.logout_pop_title[this.languages],
                down: this.down,
                confirm: this.confirm
              }
              PopViewUtils.showPopView<PopParams_1>(wrapBuilder(LaunchLogin_pop), params_1,
                { alignment: DialogAlignment.Center });
            })
        }
        .visibility(this.isDown ? Visibility.Visible : Visibility.None)
        .width('100%')
        .height(130)
        .backgroundColor('#fff')
        .shadow({ radius: 10, color: '#e9e9eb' })
        // .backgroundColor(Color.Red)
        .borderRadius(4)
        .alignRules({
          middle: { anchor: '__container__', align: HorizontalAlign.Center },
          top: { anchor: '__container__', align: VerticalAlign.Bottom },
        })
      }
      .width(142)
      .margin({ right: 20 })

      // Image($r('app.media.Frame_11'))
      //   .width(44)
      // Image($r('app.media.Frame_10'))
      //   .width(44)
      // Image($r('app.media.Frame_12'))
      //   .width(44)
      //   .margin({right:10})
    }
    .justifyContent(FlexAlign.End)
    .alignItems(VerticalAlign.Center)
    // .backgroundColor(Color.Blue)
    .height(64)
    .width('100%')
    .border({ width: { bottom: 2 }, color: '#f8f8f8' })
  }
}