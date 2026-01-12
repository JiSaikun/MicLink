import { UserLoginInfo } from "common"
import { LengthMetrics } from "@kit.ArkUI"
import { CommonConfig, Languages } from "components_phone"

interface bottListType {
  icon: string
  title: string
  name: string
}

interface ProductType {
  price: number
  name: string
}

@Component
export struct Tab_profile {
  @StorageLink('userLoginInfo') userLoginInfo: UserLoginInfo = AppStorage.get('userLoginInfo') as UserLoginInfo
  @StorageLink('languages') @Watch('onLanguagesChange') languages: string = 'ZH_CN'
  @Consume('pageInfo') pageInfo: NavPathStack
  @State bottList: bottListType[] = []
  @State fileTranscriptionProducts: ProductType[] = []
  @State voiceCustomizationProducts: ProductType[] = []

  aboutToAppear(): void {
    this.updateBottList()
    this.updateFileTranscriptionProducts()
    this.updateVoiceCustomizationProducts()
  }

  // 监听语言变化
  onLanguagesChange(): void {
    this.updateBottList()
    this.updateFileTranscriptionProducts()
    this.updateVoiceCustomizationProducts()
  }

  updateBottList(): void {
    // 创建新的数组引用以确保UI更新
    const newList: bottListType[] = [
      {
        icon: 'soundSetting',
        title: Languages.soundSetting[this.languages],
        name: 'soundSetting'
      }, {
      icon: 'fileManagement',
      title: Languages.fileManagement[this.languages],
      name: 'fileManagement'
    }, {
      icon: 'userFeedback',
      title: Languages.userFeedback[this.languages],
      name: 'userFeedback'
    }, {
      icon: 'aboutSoftware',
      title: Languages.aboutSoftware[this.languages],
      name: 'aboutSoftware'
    }
    ]
    this.bottList = newList
  }

  updateFileTranscriptionProducts(): void {
    // 创建新的数组引用以确保UI更新
    const newProducts: ProductType[] = [
      { price: 2, name: Languages.hourCard[this.languages] },
      { price: 50, name: Languages.monthCard[this.languages] },
      { price: 150, name: Languages.seasonCard[this.languages] },
      { price: 450, name: Languages.yearCard[this.languages] }
    ]
    this.fileTranscriptionProducts = newProducts
  }

  updateVoiceCustomizationProducts(): void {
    // 创建新的数组引用以确保UI更新
    const newProducts: ProductType[] = [
      { price: 9.9, name: Languages.lifetimeCard[this.languages] }
    ]
    this.voiceCustomizationProducts = newProducts
  }

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
  Product(price: number, name: string, index: number) {
    Row() {
      Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Start, justifyContent: FlexAlign.Center }) {
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
          .width('80')
      }
      .height(41)

      Blank()
      Flex() {
        Text(Languages.view[this.languages])
          .fontSize(CommonConfig.fontSize_12)
          .fontColor('#8C6000')
          .fontWeight(CommonConfig.fontWeight_400)
          .padding({
            left: 8,
            right: 8,
            top: 6,
            bottom: 6
          })
          .flexGrow(1)
          .flexShrink(1)
          .width('100%')
      }
      .width(40)
      .height(24)
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
    .margin({ right: index % 2 === 0 ? 15 : 0 })
    .width('35%')
    .backgroundImage($r('app.media.Frame_2600'))
    .backgroundImageSize({ width: '100%', height: '100%' })
    .onClick(() => {
      this.pageInfo.pushPath({ "name": 'ProductDetails', param: name })
    })
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
          .onClick(() => {
            this.pageInfo.pushPath({ "name": 'Setting' })
          })
      }
      .width('100%')
      .padding({ bottom: 24 })
      .flexGrow(1)
      .flexShrink(1)

      Flex({ alignItems: ItemAlign.Center }) {
        Image(this.userLoginInfo?.avatar ? this.userLoginInfo.avatar : $r('app.media.avatar'))
          .width(60)
          .height(60)
          .margin({ right: 16 })
          .borderRadius(100)
          .objectFit(ImageFit.Fill)
        Column() {
          Row() {
            Text(this.userLoginInfo ? this.userLoginInfo.name : Languages.username[this.languages])
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
            Text(this.userLoginInfo ? this.userLoginInfo.account : '123 **** **89')
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
          .onClick(() => {
            this.pageInfo.pushPath({ "name": 'PersonalProfile' })
          })
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
                this.TextGradient(Languages.growthValue[this.languages])
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
          Text(Languages.fileTranscription[this.languages])
            .fontSize(CommonConfig.fontSize_14)
            .fontColor(CommonConfig.hintTextColor)
            .fontWeight(CommonConfig.fontWeight_400)
            .margin({ bottom: 12 })
          Flex({ space: { cross: LengthMetrics.px(24) }, wrap: FlexWrap.Wrap }) {
            ForEach(this.fileTranscriptionProducts, (product: ProductType, index) => {
              this.Product(product.price, product.name, index)
            }, (product: ProductType) => `${product.price}_${this.languages}`)
          }

          Text(Languages.voiceCustomization[this.languages])
            .fontSize(CommonConfig.fontSize_14)
            .fontColor(CommonConfig.hintTextColor)
            .fontWeight(CommonConfig.fontWeight_400)
            .margin({ bottom: 12, top: 16 })
          Flex({ space: { cross: LengthMetrics.px(24) }, wrap: FlexWrap.Wrap }) {
            ForEach(this.voiceCustomizationProducts, (product: ProductType, index) => {
              this.Product(product.price, product.name, index)
            }, (product: ProductType) => `${product.price}_${this.languages}`)
            if (this.voiceCustomizationProducts.length % 2) {
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

        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .borderRadius(16)
        .border({ width: 1, color: Color.White })
        .backgroundImage($r('app.media.Rectangle_463'))
        .backgroundImageSize({ width: '100%', height: '100%' })
        .padding(16)
        .margin({ bottom: 12 })

        Column({ space: 8 }) {
          ForEach(this.bottList, (item: bottListType) => {
            Flex({ alignItems: ItemAlign.Center }) {
              Image($r(`app.media.${item.icon}`))
                .width(24)
                .margin({ right: 12 })
              Text(item.title)
                .fontSize(CommonConfig.fontSize_14)
                .fontWeight(400)
                .fontColor(CommonConfig.hintTextColor_select)
            }
            .backgroundColor(Color.White)
            .borderRadius(8)
            .width('100%')
            .padding({ left: 12, bottom: 10, top: 10 })
            .onClick(() => this.pageInfo.pushPath({ "name": item.name }))
          }, (item: bottListType) => `${item.name}_${this.languages}`)
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