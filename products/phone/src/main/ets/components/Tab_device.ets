import { CommonConfig } from "components_phone"
import { LengthMetrics } from "@kit.ArkUI"

@Component
export struct Tab_device {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme

  build() {
    Column() {
      Row() {
        Image($r('app.media.MicLink_title'))
          .width(100)
        Blank()
        Image($r('app.media.Group_137'))
          .width(40)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 51 })

      Text('设备')
        .fontWeight(CommonConfig.fontWeight_700)
        .fontColor(CommonConfig.hintTextColor_select)
        .fontSize(CommonConfig.fontSize_16)
        .margin({ bottom: 29 })
      Column() {
        /**
         * 没有设备连接
         */
        Image($r('app.media.VacancyPage'))
          .width(171)
          .margin({ top: 18, bottom: 23 })
        Row() {
          Text('未连接设备，前往连接')
            .fontColor(Color.White)
            .fontSize(CommonConfig.fontSize_14)
            .fontWeight(CommonConfig.fontWeight_400)

        }
        .width('100%')
        .borderRadius(12)
        .backgroundColor(this.paletteTheme)
        .justifyContent(FlexAlign.Center)
        .padding(12)
      }
      .width('100%')
      .borderRadius(16)
      .padding(12)
      .backgroundColor(CommonConfig.commonBackgroundColor)
      .border({ width: 1, color: Color.White })

      Column({space:8}) {
        Row() {
          Image($r('app.media.Frame_2133'))
            .width(24)
            .margin({ right: 12 })
          Text('AI 服务器连接')
            .fontWeight(CommonConfig.fontWeight_400)
            .fontSize(CommonConfig.fontSize_14)
            .fontColor(CommonConfig.hintTextColor_select)
          Blank()
          Image($r('app.media.fork'))
            .width(16)
          // Image($r('app.media.Frame_2531'))
          //   .width(16)
        }
        .width('100%')
        .borderRadius(8)
        .padding({
          left: 12,
          top: 10,
          right: 12,
          bottom: 10
        })
        .backgroundColor(Color.White)
        .alignItems(VerticalAlign.Center)

        Row() {
          Image($r('app.media.Frame_1'))
            .width(24)
            .margin({ right: 12 })
          Text('设备连接')
            .fontWeight(CommonConfig.fontWeight_400)
            .fontSize(CommonConfig.fontSize_14)
            .fontColor(CommonConfig.hintTextColor_select)
          Blank()
          Image($r('app.media.fork'))
            .width(16)
          // Image($r('app.media.Frame_2531'))
          //   .width(16)
        }
        .width('100%')
        .borderRadius(8)
        .padding({
          left: 12,
          top: 10,
          right: 12,
          bottom: 10
        })
        .backgroundColor(Color.White)
        .alignItems(VerticalAlign.Center)

        Row() {
          Image($r('app.media.smartphone'))
            .width(24)
            .margin({ right: 12 })
          Text('设备设置')
            .fontWeight(CommonConfig.fontWeight_400)
            .fontSize(CommonConfig.fontSize_14)
            .fontColor(CommonConfig.hintTextColor_select)
          Blank()
          Text('去设置')
            .fontWeight(CommonConfig.fontWeight_400)
            .fontSize(CommonConfig.fontSize_11)
            .fontColor(CommonConfig.hintTextColor)
            .backgroundColor('#EAEAEA')
            .padding(8)
            .borderRadius(16)
          // Image($r('app.media.Frame_2531'))
          //   .width(16)
        }
        .width('100%')
        .borderRadius(8)
        .padding({
          left: 12,
          top: 10,
          right: 12,
          bottom: 10
        })
        .backgroundColor(Color.White)
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .borderRadius(16)
      .padding(8)
      .backgroundColor(CommonConfig.commonBackgroundColor)
      .border({ width: 1, color: Color.White })
      .margin({ bottom: 16 })

      Flex({ space: { main: LengthMetrics.px(17) } }) {
        Row() {
          Column() {
            Text('使用说明')
              .fontColor('#EE4278')
              .fontSize(CommonConfig.fontSize_14)
              .fontWeight(CommonConfig.fontWeight_700)
              .margin({ bottom: 4 })
            Text('功能使用说明')
              .fontColor(CommonConfig.hintTextColor)
              .fontSize(CommonConfig.fontSize_11)
              .fontWeight(CommonConfig.fontWeight_400)
          }
          .alignItems(HorizontalAlign.Start)

          Blank()
          Image($r("app.media.pink_book_floating"))
            .height(54)
        }
        .width(100)
        .flexGrow(1)
        .flexShrink(1)
        .borderRadius(16)
        .alignItems(VerticalAlign.Center)
        .padding({
          left: 16,
          right: 16,
          top: 13,
          bottom: 13
        })
        .backgroundImage($r('app.media.Rectangle_529'))
        .backgroundImageSize({ width: '100%', height: '100%' })

        Row() {
          Column() {
            Text('联系方式')
              .fontColor('#E74C3A')
              .fontSize(CommonConfig.fontSize_14)
              .fontWeight(CommonConfig.fontWeight_700)
              .margin({ bottom: 4 })
            Text('咨询更多详情')
              .fontColor(CommonConfig.hintTextColor)
              .fontSize(CommonConfig.fontSize_11)
              .fontWeight(CommonConfig.fontWeight_400)
          }
          .alignItems(HorizontalAlign.Start)

          Blank()
          Image($r("app.media.contacts"))
            .height(54)
        }
        .width(100)
        .flexGrow(1)
        .flexShrink(1)
        .borderRadius(16)
        .alignItems(VerticalAlign.Center)
        .padding({
          left: 16,
          right: 16,
          top: 13,
          bottom: 13
        })
        .backgroundImage($r('app.media.Rectangle_530'))
        .backgroundImageSize({ width: '100%', height: '100%' })
      }

    }
    .alignItems(HorizontalAlign.Start)
    .height('100%')
    .width('100%')
    .padding({ top: 8 })

  }
}