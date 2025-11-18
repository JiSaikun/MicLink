import { UserLoginInfo } from "common"
import { CommonConfig } from "../common/config/CommonConfig"
import { Languages } from "../common/config/Languages"
import { LengthMetrics } from "@kit.ArkUI"

interface bottListType {
  icon: string
  title: string
  name: string
}

@Component
export struct Tab_profile {
  @State userLoginInfo: UserLoginInfo = AppStorage.get('userLoginInfo') as UserLoginInfo
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State bottList: bottListType[] = [
    {
      icon: 'soundSetting',
      title: '音色设置',
      name: 'soundSetting'
    }, {
    icon: 'fileManagement',
    title: '文件管理',
    name: 'fileManagement'
  }, {
    icon: 'userFeedback',
    title: '用户反馈',
    name: 'userFeedback'
  }, {
    icon: 'aboutSoftware',
    title: '关于软件',
    name: 'aboutSoftware'
  }
  ]

  @Builder
  TextGradient(text: string) {
    Row() {
      Text(text)
        .fontWeight(400)
        .fontSize(CommonConfig.fontSize_12)
        .blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
    }
    .linearGradient({
      direction: GradientDirection.Right,
      colors: [[0xEFC15D, 0.0], [0xFFEABB, 1.0]] // 渐变颜色，可自定义
    })
    .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)
  }

  @Builder
  Product(price: number, name: string) {
    Row() {
      Column() {
        Text(price + '￥')
          .fontSize(CommonConfig.fontSize_12)
          .fontColor('#8C6000')
          .fontWeight(CommonConfig.fontWeight_700)
          .padding({ bottom: 4 })
        Text(name)
          .fontSize(CommonConfig.fontSize_12)
          .fontColor('#CBA24A')
          .fontWeight(CommonConfig.fontWeight_400)
          .padding({ bottom: 4 })
      }
      .alignItems(HorizontalAlign.Start)

      Blank()
      Row() {
        Text('查看')
          .fontSize(CommonConfig.fontSize_12)
          .fontColor('#8C6000')
          .fontWeight(CommonConfig.fontWeight_400)
          .padding({
            left: 8,
            right: 8,
            top: 6,
            bottom: 6
          })
      }
      .borderRadius('50%')
      .linearGradient({
        direction: GradientDirection.Right,
        colors: [[0xEFC15D, 0.0], [0xFFEABB, 1.0]] // 渐变颜色，可自定义
      })
    }
    .padding({
      left: 12,
      right: 12,
      top: 6,
      bottom: 6
    })
    .flexShrink(1)
    .flexGrow(1)
    .width('35%')
    .backgroundImage($r('app.media.Frame_2600'))
    .backgroundImageSize({ width: '100%', height: '100%' })
  }

  build() {
    Flex({ direction: FlexDirection.Column }) {
      Flex({ alignItems: ItemAlign.Center }) {
        Text(Languages.my[this.languages])
          .fontSize(CommonConfig.fontSize_18)
          .fontColor(CommonConfig.hintTextColor_select)
          .fontWeight(700)
        Blank()
        Image($r('app.media.Frame_2570'))
          .width(40)
          .height(40)
      }
      .width('100%')
      .padding({ bottom: 24 })
      .flexGrow(1)
      .flexShrink(1)

      Flex({ alignItems: ItemAlign.Center }) {
        Image($r('app.media.avatar'))
          .width(60)
          .height(60)
          .margin({ right: 16 })
        Column() {
          Row() {
            Text(this.userLoginInfo ? this.userLoginInfo.name : '用户名称')
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
              .margin({ right: 8 })
            Row() {
              Image($r('app.media.MembershipTier_1'))
                .width(16)
                .padding({ right: 6 })
              this.TextGradient('V1' + Languages.member[this.languages])


            }
            .borderRadius('50%')
            .backgroundColor(Color.White)
            .padding({
              left: 4,
              top: 2,
              right: 4,
              bottom: 2
            })
          }
          .margin({ bottom: 8 })

          Row() {
            Text(Languages.account[this.languages])
              .fontSize(CommonConfig.fontSize_12)
              .fontWeight(CommonConfig.fontWeight_400)
              .fontColor(CommonConfig.hintTextColor)
            Text('123 **** **89')
              .fontSize(CommonConfig.fontSize_12)
              .fontWeight(CommonConfig.fontWeight_400)
              .fontColor(CommonConfig.hintTextColor)
          }
        }
        .alignItems(HorizontalAlign.Start)

        Blank()
        Image($r('app.media.back'))
          .width(24)
          .height(24)
      }
      .width('100%')
      .padding({ bottom: 24 })
      .flexGrow(1)
      .flexShrink(1)

      Flex({ direction: FlexDirection.Column }) {
        Row() {
          Flex({ alignItems: ItemAlign.End }) {
            Row() {
              Text('VIP 1')
                .fontWeight(CommonConfig.fontWeight_400)
                .fontSize(CommonConfig.fontSize_24)
                .padding({ right: 12 })
                .blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
            }
            .linearGradient({
              direction: GradientDirection.Right,
              colors: [[0xEFC15D, 0.0], [0xFFEABB, 1.0]] // 渐变颜色，可自定义
            })
            .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)

            Column() {
              Row({ space: 4 }) {
                this.TextGradient('成长值')
                this.TextGradient('6713')
                this.TextGradient('/')
                Text('10000')
                  .fontWeight(CommonConfig.fontWeight_400)
                  .fontSize(CommonConfig.fontSize_12)
                  .fontColor('#EAEAEA')
              }

              Progress({ value: 6713, total: 10000 })
                .color(
                  '#f6d388'
                )
                .width('100%')
                .style({ strokeWidth: 4 })
                .backgroundColor('#EAEAEA')
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Image($r('app.media.MembershipTier_1'))
              .width(24)
              .height(24)
              .margin({ left: 18 })
          }
          .width('100%')
          .backgroundColor(CommonConfig.hintTextColor_select)
          .borderRadius({ topLeft: 16, topRight: 16 })
          .padding({
            left: 16,
            top: 9,
            bottom: 9,
            right: 21
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16 })

        Column() {
          Text('文件转写')
            .fontSize(CommonConfig.fontSize_14)
            .fontColor(CommonConfig.hintTextColor)
            .fontWeight(CommonConfig.fontWeight_400)
            .margin({ bottom: 12 })
          Flex({ space: { main: LengthMetrics.px(30), cross: LengthMetrics.px(12) }, wrap: FlexWrap.Wrap }) {
            this.Product(2, '小时卡')
            this.Product(50, '月卡')
            this.Product(150, '季卡')
            this.Product(450, '年卡')
          }

          Text('音色定制')
            .fontSize(CommonConfig.fontSize_14)
            .fontColor(CommonConfig.hintTextColor)
            .fontWeight(CommonConfig.fontWeight_400)
            .margin({ bottom: 12, top: 16 })
          Flex({ space: { main: LengthMetrics.px(30), cross: LengthMetrics.px(12) }, wrap: FlexWrap.Wrap }) {
            this.Product(9.9, '终身卡')
            Row()
              .padding({
                left: 12,
                right: 12,
                top: 6,
                bottom: 6
              })
              .flexShrink(1)
              .flexGrow(1)
              .width('35%')
              .backgroundImage($r('app.media.Frame_2600'))
              .backgroundImageSize({ width: '100%', height: '100%' })
          }

        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .borderRadius(16)
        .border({ width: 1, color: Color.White })
        .backgroundImage($r('app.media.Rectangle_463'))
        .backgroundImageSize({ width: '100%', height: '100%' })
        .padding(16)
        .margin({ bottom: 12 })

        Column({space:8}) {
          ForEach(this.bottList, (item: bottListType) => {
            Flex({alignItems:ItemAlign.Center}){
              Image($r(`app.media.${item.icon}`))
                .width(24)
                .padding({right:12})
              Text(item.title)
                .fontSize(CommonConfig.fontSize_14)
                .fontWeight(400)
                .fontColor(CommonConfig.hintTextColor_select)
            }
            .backgroundColor(Color.White)
            .borderRadius(8)
            .width('100%')
            .padding({left:12,bottom:10,top:10})
          }, (item: bottListType) => item.name)
        }
        .padding(8)
        .backgroundColor('#F8F8F8')
        .borderRadius(16)
        .border({ width: 1, color: Color.White })

      }
      .flexGrow(1)
      .flexShrink(1)



    }
    .width('100%')
    .height('100%')
    .padding({ top: 16 })
  }
}