import { UserLoginInfo } from "common";
import { CommonConfig } from "../common/CommonConfig";

@Component
export struct UpdatePhone_EMAIL {
  @State userLoginInfo: UserLoginInfo = AppStorage.get('userLoginInfo') as UserLoginInfo
  @StorageLink('languages') languages: string = 'ZH_CN'
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @State updataCountry: boolean = false

  build() {
    Stack() {
      Column() {
        Text('更换邮箱')
          .fontSize(CommonConfig.fontSize_18)
          .fontColor(CommonConfig.hintTextColor_select)
          .fontWeight(CommonConfig.fontWeight_700)
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ bottom: 36 })
        Text('原邮箱账号')
          .fontSize(CommonConfig.fontSize_14)
          .fontWeight(CommonConfig.fontWeight_400)
          .fontColor(CommonConfig.hintTextColor)
          .width('100%')
        Row() {
          Text('原邮箱账号')
            .fontSize(CommonConfig.fontSize_14)
            .fontWeight(CommonConfig.fontWeight_400)
            .fontColor(CommonConfig.hintTextColor_select)
            .margin({ right: 12 })
          Text(this.userLoginInfo ? this.userLoginInfo.account : '123 4567 8989')
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
          this.updataCountry = true
          // this.pageInfo.pushPath({ "name": 'UpdatePhone' })
        })

        // Text(Languages.phoneNumber[this.languages])
        Text('验证码')
          .fontSize(CommonConfig.fontSize_14)
          .fontWeight(CommonConfig.fontWeight_400)
          .fontColor(CommonConfig.hintTextColor)
          .width('100%')
        Row() {
          TextInput({ placeholder: '请输入验证码' })
            .fontColor(CommonConfig.hintTextColor)
            .fontSize(CommonConfig.fontSize_14)
            .fontWeight(CommonConfig.fontWeight_400)
            .padding(0)
            .backgroundColor(Color.White)
            .borderRadius(0)
            .layoutWeight(1)
          Text('获取验证码')
            .backgroundColor(CommonConfig.commonBorderColor)
            .borderRadius(4)
            .padding({
              top: 4,
              right: 8,
              bottom: 4,
              left: 8
            })
            .fontSize(CommonConfig.fontSize_12)
            .fontColor(CommonConfig.hintTextColor_select)
            .fontWeight(CommonConfig.fontWeight_400)
        }
        .backgroundColor(Color.White)
        .alignItems(VerticalAlign.Center)
        .width('100%')
        .borderRadius(12)
        .margin({ top: 12 })
        .padding(12)

        Blank()
        Text('下一步')
          .width('100%')
          .padding(12)
          .borderRadius(12)
          .textAlign(TextAlign.Center)
          .fontSize(CommonConfig.fontSize_16)
          .fontWeight(CommonConfig.fontWeight_400)
          .fontColor(Color.White)
          .backgroundColor(this.paletteTheme)
          .onClick(() => {})


      }
      .width('100%')
      .padding({ top: 76 })
      .height('100%')

    }

  }
}