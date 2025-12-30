import { updateAvatar, UserLoginInfo } from "common"
import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"
import { TopTitle } from "../common/TopTitle"

@Builder
export function PersonalProfileBuilder() {
  PersonalProfile()
}

@Component
struct PersonalProfile {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @Consume('pageInfo') pageInfo: NavPathStack
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State userLoginInfo: UserLoginInfo = AppStorage.get('userLoginInfo') as UserLoginInfo

  build() {
    NavDestination() {
      TopTitle({ title: Languages.editProfile[this.languages] })
        .margin({ bottom: 12 })
      Column() {
        Stack() {
          Image(this.userLoginInfo?.avatar ? this.userLoginInfo.avatar : $r('app.media.avatar'))
            .width(80)
            .height(80)
            .borderRadius(100)
            .objectFit(ImageFit.Fill)

          Stack() {
            Row()
              .width(24)
              .height(24)
              .borderRadius('50%')
              .backgroundColor(Color.White)
            Image($r('app.media.Ellipse_47'))
              .width(16)
              .height(16)
          }
          .alignContent(Alignment.Center)
        }.align(Alignment.BottomEnd)
        .margin({ bottom: 8 })

        Text(Languages.editAvatar[this.languages])
          .fontSize(CommonConfig.fontSize_14)
          .fontWeight(CommonConfig.fontWeight_400)
          .fontColor(CommonConfig.hintTextColor_select)
      }
      .margin({ bottom: 18 })
      .onClick(() => {
        this.pageInfo.pushPath({ "name": 'AvatarView' })

      })

      Text(Languages.name_1[this.languages])
        .fontSize(CommonConfig.fontSize_14)
        .fontWeight(CommonConfig.fontWeight_400)
        .fontColor(CommonConfig.hintTextColor)
        .width('100%')
      Text(this.userLoginInfo ? this.userLoginInfo.name : '用户123456')
        .width('100%')
        .fontSize(CommonConfig.fontSize_14)
        .fontColor(CommonConfig.hintTextColor_select)
        .fontWeight(CommonConfig.fontWeight_400)
        .borderRadius(12)
        .margin({ bottom: 12, top: 12 })
        .padding(12)
        .backgroundColor(Color.White)
      Text(this.userLoginInfo?.type !== 'EMAIL' ? Languages.phoneNumber[this.languages] :
      Languages.account_1[this.languages])
        .fontSize(CommonConfig.fontSize_14)
        .fontWeight(CommonConfig.fontWeight_400)
        .fontColor(CommonConfig.hintTextColor)
        .width('100%')
      Row() {
        if (this.userLoginInfo?.type !== 'EMAIL') {
          Text('+86')
            .fontSize(CommonConfig.fontSize_14)
            .fontWeight(CommonConfig.fontWeight_400)
            .fontColor(CommonConfig.hintTextColor)
            .margin({ right: 12 })
        }
        Text(this.userLoginInfo ? this.userLoginInfo.account : '123 **** **89')
          .fontSize(CommonConfig.fontSize_14)
          .fontColor(CommonConfig.hintTextColor_select)
          .fontWeight(CommonConfig.fontWeight_400)
        Blank()
        Image($r('app.media.Arrow_to_the_right'))
          .width(16)
          .height(16)
      }
      .backgroundColor(Color.White)
      .alignItems(VerticalAlign.Center)
      .width('100%')
      .borderRadius(12)
      .margin({ bottom: 12, top: 12 })
      .padding(12)
      .onClick(() => {
        this.pageInfo.pushPath({"name":'UpdatePhone'})
      })

    }
    .padding({ left: 16, right: 16 })
    .backgroundColor(CommonConfig.commonBackgroundColor)
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}