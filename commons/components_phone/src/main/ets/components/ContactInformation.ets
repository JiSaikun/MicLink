import { Call_PHONE } from "api"
import { updateAvatar, UserLoginInfo } from "common"
import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"
import { TopTitle } from "../common/TopTitle"

@Builder
export function ContactInformationBuilder() {
  ContactInformation()
}

@Component
struct ContactInformation {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @Consume('pageInfo') pageInfo: NavPathStack
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State device_isBle: boolean = false //该设备是否是蓝牙连接

  aboutToAppear(): void {
    console.log(JSON.stringify(this.pageInfo.getParamByName('DevicesConfig')))
  }

  build() {
    NavDestination() {
      // TopTitle({ title: Languages.editProfile[this.languages] })
      TopTitle({ title: "联系方式" })
        .margin({ bottom: 12 })
      Row() {
        Column() {
          Text('联系电话 1')
            .fontSize(CommonConfig.fontSize_14)
            .fontColor(CommonConfig.hintTextColor_select)
            .fontWeight(CommonConfig.fontWeight_400)
            .margin({ bottom: 4 })
          Row() {
            Text('+86')
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor)
              .fontWeight(CommonConfig.fontWeight_400)
              .margin({ right: 8 })
            Text('123 4567 8910')
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor)
              .fontWeight(CommonConfig.fontWeight_400)
          }

        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Row() {
          Image($r('app.media.phone'))
            .width(32)
            .height(32)
            .onClick(() => {
              Call_PHONE('123 4567 8910')
            })
        }
        .width(80)
        .justifyContent(FlexAlign.Center)
        .border({ width: { left: 1 }, color: CommonConfig.commonBackgroundColor })
      }
      .alignItems(VerticalAlign.Center)
      .borderRadius(12)
      .backgroundColor(Color.White)
      .margin({ bottom: 12 })
      .padding({
        bottom: 12, top: 12, left: 12
      })
      .width('100%')

      Row() {
        Column() {
          Text('联系电话 2')
            .fontSize(CommonConfig.fontSize_14)
            .fontColor(CommonConfig.hintTextColor_select)
            .fontWeight(CommonConfig.fontWeight_400)
            .margin({ bottom: 4 })
          Row() {
            Text('+86')
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor)
              .fontWeight(CommonConfig.fontWeight_400)
              .margin({ right: 8 })
            Text('123 4567 8910')
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor)
              .fontWeight(CommonConfig.fontWeight_400)
          }

        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Row() {
          Image($r('app.media.phone'))
            .width(32)
            .height(32)
            .onClick(() => {
              Call_PHONE('123 4567 8910')
            })
        }
        .width(80)
        .justifyContent(FlexAlign.Center)
        .border({ width: { left: 1 }, color: CommonConfig.commonBackgroundColor })
      }
      .alignItems(VerticalAlign.Center)
      .borderRadius(12)
      .backgroundColor(Color.White)
      .padding({
        bottom: 12, top: 12, left: 12
      })
      .width('100%')

    }
    .padding({ left: 16, right: 16 })
    .backgroundColor(CommonConfig.commonBackgroundColor)
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}