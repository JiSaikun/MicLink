import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"
import { TopTitle } from "../common/TopTitle"
import { LengthMetrics, promptAction } from "@kit.ArkUI"
import { OnWXResp, WXApi, WXEventHandler } from "api"
import * as wxopensdk from '@tencent/wechat_open_sdk';
import { common } from "@kit.AbilityKit"

@Builder
export function ProductDetailsBuilder() {
  ProductDetails()
}

interface PackageInfo {
  readonly price: number //价格
  readonly uration: string //时长
  readonly supportedFormats: string //支持的格式
  readonly name: string //套餐名称
}

@Component
struct ProductDetails {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @Consume('pageInfo') pageInfo: NavPathStack
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State productName: string = ''
  @State allPackageDetails: PackageInfo[] = [
    {
      name: '小时卡',
      price: 2,
      uration: '一小时',
      supportedFormats: '支持TXT、Word等格式转换。'
    }, {
    name: '月卡',
    price: 50,
    uration: '月',
    supportedFormats: '支持TXT、Word等格式转换。'
  }, {
    name: '季卡',
    price: 150,
    uration: '季',
    supportedFormats: '支持TXT、Word等格式转换。'
  }, {
    name: '年卡',
    price: 450,
    uration: '年',
    supportedFormats: '支持TXT、Word等格式转换。'
  }
  ]
  @State payment: string = 'wx' //支付方式
  @State Selected: boolean = false //同意并接收
  private wxApi = WXApi
  private wxEventHandler = WXEventHandler
  @State payResultText: string = ''
  // 支付结果回调处理
  private onWXResp: OnWXResp = (resp) => {
    this.payResultText = JSON.stringify(resp ?? {}, null, 2)
    if (resp.errCode === 0) {
      promptAction.showToast({
        message: '支付成功'
      })
      this.pageInfo.pushPath({ "name": 'PaymentSuccessful' })
    } else if (resp.errCode === -1) {
      promptAction.showToast({
        message: '支付失败'
      })
    } else if (resp.errCode === -2) {
      promptAction.showToast({
        message: '取消支付'
      })
    }
  }

  aboutToAppear(): void {
    this.productName = this.pageInfo.getParamByName('ProductDetails')[0] as string
    // 注册的支付回调
    this.wxEventHandler.registerOnWXRespCallback(this.onWXResp)
  }

  aboutToDisappear(): void {
    this.wxEventHandler.unregisterOnWXRespCallback(this.onWXResp)
  }

  build() {
    NavDestination() {
      Column() {
        TopTitle({ title: Languages.membershipPackage[this.languages], isback: false })
          .margin({ left: 16, right: 16, bottom: 12 })
        Scroll() {
          Column({ space: 16 }) {
            Text('文件转写')
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor)
              .fontWeight(CommonConfig.fontWeight_400)
            ForEach(this.allPackageDetails, (item: PackageInfo) => {
              Row() {
                Column() {
                  Text(item.name)
                    .fontSize(CommonConfig.fontSize_16)
                    .fontColor(CommonConfig.hintTextColor_select)
                    .fontWeight(CommonConfig.fontWeight_700)
                    .padding({ bottom: 12 })
                  Text(item.supportedFormats)
                    .fontSize(CommonConfig.fontSize_12)
                    .fontColor(CommonConfig.secondaryTextColor)
                    .fontWeight(CommonConfig.fontWeight_400)
                }
                .alignItems(HorizontalAlign.Start)

                Blank()
                Text(item.price + '￥/' + item.uration)
                  .fontSize(CommonConfig.fontSize_16)
                  .fontColor(CommonConfig.hintTextColor_select)
                  .fontWeight(CommonConfig.fontWeight_700)
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              .borderRadius(16)
              .padding({
                left: 16,
                top: 24,
                right: 16,
                bottom: 24
              })
              .backgroundColor(this.productName !== item.name ? CommonConfig.commonBackgroundColor : '')
              .border({ width: this.productName !== item.name ? 1 : 0, color: Color.White })
              .backgroundImage(this.productName === item.name ? $r('app.media.Rectangle_459') : '')
              .backgroundImageSize({ width: '100%', height: '100%' })
              .onClick(() => this.productName = item.name)
            }, (item: PackageInfo) => item.name)
            Text('文件转写')
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor)
              .fontWeight(CommonConfig.fontWeight_400)
              .margin({ top: 8 })
            Row() {
              Column() {
                Text('终身卡')
                  .fontSize(CommonConfig.fontSize_16)
                  .fontColor(CommonConfig.hintTextColor_select)
                  .fontWeight(CommonConfig.fontWeight_700)
                  .padding({ bottom: 12 })
                Text('支持TXT、Word等格式转换。')
                  .fontSize(CommonConfig.fontSize_12)
                  .fontColor(CommonConfig.secondaryTextColor)
                  .fontWeight(CommonConfig.fontWeight_400)
              }
              .alignItems(HorizontalAlign.Start)

              Blank()
              Text(9.9 + '￥/终身')
                .fontSize(CommonConfig.fontSize_16)
                .fontColor(CommonConfig.hintTextColor_select)
                .fontWeight(CommonConfig.fontWeight_700)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .borderRadius(16)
            .padding({
              left: 16,
              top: 24,
              right: 16,
              bottom: 24
            })
            .backgroundImage(this.productName === '终身卡' ? $r('app.media.Rectangle_459') : '')
            .backgroundImageSize({ width: '100%', height: '100%' })
            .backgroundColor(this.productName !== '终身卡' ? CommonConfig.commonBackgroundColor : '')
            .border({ width: this.productName !== '终身卡' ? 1 : 0, color: Color.White })
            .onClick(() => this.productName = '终身卡')

          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .padding({ left: 16, right: 16, bottom: 24 })
        .layoutWeight(1)
        .align(Alignment.TopStart)

        Column() {
          Row() {
            Text(Languages.paymentMethod[this.languages])
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
              .fontWeight(CommonConfig.fontWeight_400)
            Blank()
            Image(this.payment === 'wx' ? $r('app.media.Payment_wx_true') : $r('app.media.Payment_wx_false'))
              .width(32)
              .onClick(() => {
                this.payment = 'wx'
              })
              .margin({ right: 10 })
            Image(this.payment === 'zfb' ? $r('app.media.Payment_zfb_true') : $r('app.media.Payment_zfb_false'))
              .width(32)
              .onClick(() => {
                this.payment = 'zfb'
              })
          }
          .width('100%')
          .margin({ bottom: 12 })

          Flex({ space: { main: LengthMetrics.px(8) } }) {
            Image(this.Selected ? $r('app.media.Property1_Variant3') : $r('app.media.Property1_Variant2'))
              .width(16)
              .onClick(() => this.Selected = !this.Selected)
              .margin({ right: 4 })
            // Text('同意并接受')
            Text(Languages.agreeAndAccept[this.languages])
              .fontSize(CommonConfig.fontSize_12)
              .fontColor(CommonConfig.secondaryTextColor)
              .fontWeight(CommonConfig.fontWeight_400)
            // Text('自动续费服务协议')
            Text(Languages.autoRenewalAgreement[this.languages])
              .fontSize(CommonConfig.fontSize_12)
              .fontColor(this.paletteTheme)
              .fontWeight(CommonConfig.fontWeight_400)
            Text('|')
              .fontSize(CommonConfig.fontSize_12)
              .fontColor(CommonConfig.secondaryTextColor)
              .fontWeight(CommonConfig.fontWeight_400)
            // Text('个人订阅服务协议')
            Text(Languages.personalSubscriptionAgreement[this.languages])
              .fontSize(CommonConfig.fontSize_12)
              .fontColor(this.paletteTheme)
              .fontWeight(CommonConfig.fontWeight_400)

          }
          .margin({ bottom: 12 })

          Text(Languages.payOrder[this.languages])
            .width('100%')
            .textAlign(TextAlign.Center)
            .fontColor(Color.White)
            .fontWeight(CommonConfig.fontWeight_400)
            .fontSize(CommonConfig.fontSize_14)
            .backgroundColor(this.paletteTheme)
            .borderRadius(12)
            .padding(12)
            .onClick(() => {
              if (this.Selected) {
                if (this.payment === 'wx') {
                  // 微信支付
                  async () => {
                    // 组装支付订单参数，发送包裹给微信api，唤起微信   ，参数具体信息参见自己的接口文档写入
                    let req = new wxopensdk.PayReq
                    req.partnerId = 'xxxxxxxx'
                    req.appId = 'xxxxxxxxxxxx'
                    req.packageValue = 'Sign=WXPay'
                    req.prepayId = 'xxxxxxxxxxxxxxxxxxxxx'
                    req.nonceStr = 'xxxxxxxxxxxxx'
                    req.timeStamp = '1727338524'
                    req.sign = 'xxxxxxxxxxxxxxxxxxx'
                    req.extData = 'extData'

                    let finished = await this.wxApi.sendReq(getContext(this) as common.UIAbilityContext, req)
                    console.log("微信支付", finished)
                  }
                } else {
                  // 支付宝支付
                }

              } else {
                promptAction.showToast({
                  message: '请同意自动续费服务协议和个人订阅服务协议',
                  duration: 1000,
                  alignment: Alignment.Center
                });
              }
            })

        }
        .padding({ top: 16, left: 16, right: 16 })
        .backgroundColor(Color.White)
      }
      .width('100%')
      .height('100%')

    }
    .backgroundColor(CommonConfig.commonBackgroundColor)
    .backgroundImage($r('app.media.background_1'))
    .backgroundImageSize({ width: '100%', height: '100%' })
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}