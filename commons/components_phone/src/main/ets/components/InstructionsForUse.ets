import { DeviceArrayType_Ble } from "bluetooth"
import { getModelInfoModel } from "config"
import { ConnectDevice } from "mouse"
import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"
import { TopTitle } from "../common/TopTitle"
import { Languages_params } from "../view/SmartSettings"

@Builder
export function InstructionsForUseBuilder() {
  InstructionsForUse()
}

@Component
struct InstructionsForUse {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @Consume('pageInfo') pageInfo: NavPathStack
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State search: string = ''
  @State currTitleIndex: number = 0

  build() {
    NavDestination() {
      // TopTitle({ title: Languages.editProfile[this.languages] })
      TopTitle({ title: "使用说明" })
        .margin({ bottom: 24 })
      Text('Hi，用户123456')
        .fontWeight(CommonConfig.fontWeight_400)
        .fontColor(CommonConfig.hintTextColor_select)
        .fontSize(CommonConfig.fontSize_24)

      Row() {
        Image($r('app.media.search'))
          .width(24)
          .margin({ right: 8 })
        TextInput({ placeholder: '搜索问题', text: $$this.search })
          .placeholderColor(CommonConfig.hintTextColor)
          .fontSize(CommonConfig.fontSize_14)
          .fontWeight(400)
      }.width('100%')
      .padding({
        left: 12,
        top: 8,
        bottom: 8,
        right: 12
      })
      .margin({ top: 24, bottom: 12 })

      Scroll() {
        Column() {
          Row() {
            Text('常见问题')
              .fontWeight(CommonConfig.fontWeight_400)
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(this.currTitleIndex === 0 ? this.paletteTheme : CommonConfig.hintTextColor_select)
              .onClick(() => {
                this.currTitleIndex = 0
              })
              .margin({ right: 16 })
            Text('常见问题')
              .fontWeight(CommonConfig.fontWeight_400)
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(this.currTitleIndex === 1 ? this.paletteTheme : CommonConfig.hintTextColor_select)
              .onClick(() => {
                this.currTitleIndex = 1
              })
          }
          .padding({ top: 12, bottom: 12 })

          if (this.currTitleIndex = 0) {
            ForEach(['问题的标题', '问题的标题', '问题的标题', '问题的标题'], (item: string) => {
              Row() {
                Text(item)
                  .fontColor(CommonConfig.hintTextColor_select)
                  .fontSize(CommonConfig.fontSize_14)
                  .fontWeight(CommonConfig.fontWeight_400)
                Blank()
                Image($r('app.media.Arrow_to_the_right'))
                  .width(16)
                  .height(16)
              }
              .width('100%')
              .padding({ top: 12, bottom: 12 })
              .border({ width: { bottom: 1 }, color: CommonConfig.commonBackgroundColor })
              .onClick(() => {

              })
            })
          } else {
            ForEach(['使用手册', '使用手册', '使用手册', '使用手册', '使用手册', '使用手册', '使用手册', '使用手册',
              '使用手册', '使用手册'], (item: string) => {
              Row() {
                Text(item)
                  .fontColor(CommonConfig.hintTextColor_select)
                  .fontSize(CommonConfig.fontSize_14)
                  .fontWeight(CommonConfig.fontWeight_400)
                Blank()
                Image($r('app.media.Arrow_to_the_right'))
                  .width(16)
                  .height(16)
              }
              .width('100%')
              .padding({ top: 12, bottom: 12 })
              .border({ width: { bottom: 1 }, color: CommonConfig.commonBackgroundColor })
              .onClick(() => {

              })
            })
          }
        }
        .padding({ left: 12, right: 12 })
        .borderRadius(12)
      }
      .layoutWeight(1)

    }
    .padding({ left: 16, right: 16, bottom: 16 })
    .backgroundColor(CommonConfig.commonBackgroundColor)
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}