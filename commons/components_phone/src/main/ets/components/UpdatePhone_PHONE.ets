import { UserLoginInfo } from "common";
import { CommonConfig } from "../common/CommonConfig";
import { Languages } from "../common/Languages";
import { CountryCode, GetCountryCode } from "../model/GetCountryCode";

@Component
export struct UpdatePhone_PHONE {
  @State userLoginInfo: UserLoginInfo = AppStorage.get('userLoginInfo') as UserLoginInfo
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State country: CountryCode[] = GetCountryCode.getCountryCode
  @State currCountry: number = this.country.length - 1
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @Link isEMAIL: boolean
  @State updataCountry: boolean = false

  build() {
    Stack() {
      Column() {
        Text('更换手机号')
          .fontSize(CommonConfig.fontSize_18)
          .fontColor(CommonConfig.hintTextColor_select)
          .fontWeight(CommonConfig.fontWeight_700)
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ bottom: 36 })
        Text('国家/地区')
          .fontSize(CommonConfig.fontSize_14)
          .fontWeight(CommonConfig.fontWeight_400)
          .fontColor(CommonConfig.hintTextColor)
          .width('100%')
        Row() {
          Text('国家/地区')
            .fontSize(CommonConfig.fontSize_14)
            .fontWeight(CommonConfig.fontWeight_400)
            .fontColor(CommonConfig.hintTextColor_select)
            .margin({ right: 12 })
          Text(this.country[this.currCountry].countryCn)
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

        Text(Languages.phoneNumber[this.languages])
          .fontSize(CommonConfig.fontSize_14)
          .fontWeight(CommonConfig.fontWeight_400)
          .fontColor(CommonConfig.hintTextColor)
          .width('100%')
        Row() {
          Text(Languages.phoneNumber[this.languages])
            .fontSize(CommonConfig.fontSize_14)
            .fontWeight(CommonConfig.fontWeight_400)
            .fontColor(CommonConfig.hintTextColor)
            .margin({ right: 36 })
          Text('+' + this.country[this.currCountry].countryCode)
            .fontSize(CommonConfig.fontSize_14)
            .fontWeight(CommonConfig.fontWeight_400)
            .fontColor(CommonConfig.hintTextColor)
            .margin({ right: 12 })
          Text(this.userLoginInfo ? this.userLoginInfo.account : '123 4567 8989')
            .fontSize(CommonConfig.fontSize_14)
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
          .onClick(() => this.isEMAIL = true)


      }
      .width('100%')
      .padding({ top: 76 })
      .height('100%')

      if (this.updataCountry) {
        List() {
          ForEach(this.country, (item: CountryCode, index) => {
            ListItem() {
              Row() {
                Text(item.countryCn)
                  .fontSize(CommonConfig.fontSize_14)
                  .fontColor(CommonConfig.hintTextColor_select)
                  .fontWeight(CommonConfig.fontWeight_400)
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              .padding({ top: 12, bottom: 12 })
              .border({
                width: { bottom: index === this.country.length ? 0 : 1 },
                color: CommonConfig.commonBackgroundColor
              })
              .onClick(() => {
                this.currCountry = index
                this.updataCountry=false
              })
            }
          }, (item: CountryCode) => item.countryCode)
        }
        .backgroundColor(CommonConfig.commonBackgroundColor).width('100%')
        .height('100%')
      }
    }

  }
}