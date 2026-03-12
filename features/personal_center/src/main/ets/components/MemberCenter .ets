import { LengthMetrics, promptAction } from "@kit.ArkUI"
import { ThemeConfig, UserLoginInfo } from "common"
import { Languages } from "config"
import { goodsSpecsItem, goods_Response, pay_Params, pay_Response } from "../model/UserModel"
import { _goods, _pay, _queryOrderStatus } from "../viewmodel/UserViewModel"

@Component
export struct MemberCenter {
  @StorageLink('languages') languages: string = 'ZH_CN'
  @StorageLink("paletteTheme") paletteTheme: string = ThemeConfig.PaletteTheme
  @State allPackageDetails: goods_Response | null = null
  @Watch('changePackage') @State goodsInfo: goodsSpecsItem | null = null
  //value用来计数，初始化的值是1
  @State value: number = 1
  @State payment: string = 'wx'
  @State Selected: boolean = false
  @State payState: boolean = false
  @Watch('getPayState') @State payStateInfo: pay_Response | null = null
  @State interval: number | null = null

  getPayState() {
    if (this.payStateInfo) {
      this.interval = setInterval(() => {
        _queryOrderStatus({ orderNo: this.payStateInfo?.orderId as string }).then((res) => {
          if (res.data?.orderStatus === 'SUCCESS') {
            this.payStateInfo = null
          }
        })
      }, 3000)
    } else {
      clearInterval(this.interval)
    }
  }

  aboutToAppear(): void {
    _goods().then((res) => {
      if (res.statusCode === 200) {
        this.allPackageDetails = (res.data as goods_Response[])[0]
      }
    })
  }

  changePackage() {
    this.value = 1
    this.payState = false
  }

  // 方法：为16进制颜色添加透明度
  addOpacityToHex(hexColor: string, opacity: number): string {
    // 如果颜色值无效，返回默认值
    if (!hexColor || typeof hexColor !== 'string') {
      return `rgba(0, 174, 204, ${opacity})` // 默认颜色 #00aecc
    }

    // 移除 # 号
    let cleanHex = hexColor.replace('#', '');

    // 检查长度
    if (cleanHex.length !== 3 && cleanHex.length !== 6) {
      return `rgba(0, 174, 204, ${opacity})`
    }

    // 处理3位简写格式
    if (cleanHex.length === 3) {
      cleanHex = cleanHex.split('').map(char => char + char).join('');
    }

    // 解析RGB值
    const r = parseInt(cleanHex.substring(0, 2), 16);
    const g = parseInt(cleanHex.substring(2, 4), 16);
    const b = parseInt(cleanHex.substring(4, 6), 16);

    // 检查解析结果
    if (isNaN(r) || isNaN(g) || isNaN(b)) {
      return `rgba(0, 174, 204, ${opacity})`
    }

    return `rgba(${r}, ${g}, ${b}, ${opacity})`
  }

  // 获取带透明度的颜色
  getPaletteThemeWithOpacity(): string {
    return this.addOpacityToHex(this.paletteTheme, 0.1)
  }

  build() {
    Flex({ space: { main: LengthMetrics.px(24) }, direction: FlexDirection.Column }) {
      // Text(Languages.displaySettings[this.languages])
      Text(this.allPackageDetails?.name)
        .fontSize(ThemeConfig.TextSize_14)
        .fontWeight(ThemeConfig.TextWeight_400)
        .fontColor(ThemeConfig.SecondaryTextColor)
      Grid() {
        ForEach(this.allPackageDetails?.goodsSpecs, (item: goodsSpecsItem) => {
          GridItem() {
            Column({ space: 20 }) {
              Text(item.name)
                .fontSize(ThemeConfig.TextSize_14)
                .fontWeight(ThemeConfig.TextWeight_400)
                .fontColor(ThemeConfig.TextBodyColor)
              Flex({ alignItems: ItemAlign.End }) {
                Text(item.priceShow)
                  .fontSize(ThemeConfig.TextSize_24)
                  .fontWeight(ThemeConfig.TextWeight_500)
                  .fontColor(ThemeConfig.TextBodyColor)
                  .margin({ right: 10 })

                Text('人民币')
                  .fontSize(ThemeConfig.TextSize_12)
                  .fontWeight(ThemeConfig.TextWeight_400)
                  .fontColor(ThemeConfig.SecondaryTextColor)

                Blank()
                Text(item.remark)
                  .fontSize(ThemeConfig.TextSize_14)
                  .fontWeight(ThemeConfig.TextWeight_400)
                  .fontColor(this.paletteTheme)
              }

              Flex() {
                Text()
                  .fontSize(ThemeConfig.TextSize_12)
                  .fontWeight(ThemeConfig.TextWeight_400)
                  .fontColor(ThemeConfig.SecondaryTextColor)
                  .flexGrow(1)
                  .flexShrink(1)
              }

              Text('购买套餐')
                .width('100%')
                .borderRadius(4)
                .fontSize(ThemeConfig.TextSize_14)
                .fontWeight(ThemeConfig.TextWeight_400)
                .fontColor(Color.White)
                .backgroundColor(this.paletteTheme)
                .textAlign(TextAlign.Center)
                .padding(9)
                .onClick(() => {
                  this.goodsInfo = item
                })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
          }
          .border({ width: 1, color: item.remark === this.goodsInfo?.remark ? this.paletteTheme : '#EAEAEA' })
          .borderRadius(8)
          .padding(20)
          .backgroundColor(item.remark === this.goodsInfo?.remark ? this.getPaletteThemeWithOpacity() : '#fff')
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr') // 每行3个等宽列
      // .rowsTemplate('auto') // 行高自适应内容
      .columnsGap(24) // 列间距
      .rowsGap(24) // 行间距

      // Text(Languages.toneCustomization[this.languages])
      //   .fontSize(ThemeConfig.TextSize_14)
      //   .fontWeight(ThemeConfig.TextWeight_400)
      //   .fontColor(ThemeConfig.SecondaryTextColor)
      // Grid() {
      //   GridItem() {
      //     Column({ space: 20 }) {
      //       Text('终身卡')
      //         .fontSize(ThemeConfig.TextSize_14)
      //         .fontWeight(ThemeConfig.TextWeight_400)
      //         .fontColor(ThemeConfig.TextBodyColor)
      //       Flex({ alignItems: ItemAlign.End }) {
      //         Text('￥9.9')
      //           .fontSize(ThemeConfig.TextSize_24)
      //           .fontWeight(ThemeConfig.TextWeight_500)
      //           .fontColor(ThemeConfig.TextBodyColor)
      //           .margin({ right: 10 })
      //
      //         Text('人民币')
      //           .fontSize(ThemeConfig.TextSize_12)
      //           .fontWeight(ThemeConfig.TextWeight_400)
      //           .fontColor(ThemeConfig.SecondaryTextColor)
      //
      //         Blank()
      //         Text('终身')
      //           .fontSize(ThemeConfig.TextSize_14)
      //           .fontWeight(ThemeConfig.TextWeight_400)
      //           .fontColor(this.paletteTheme)
      //       }
      //
      //       Flex() {
      //         Text()
      //           .fontSize(ThemeConfig.TextSize_12)
      //           .fontWeight(ThemeConfig.TextWeight_400)
      //           .fontColor(ThemeConfig.SecondaryTextColor)
      //           .flexGrow(1)
      //           .flexShrink(1)
      //       }
      //
      //       Text('购买套餐')
      //         .width('100%')
      //         .borderRadius(4)
      //         .fontSize(ThemeConfig.TextSize_14)
      //         .fontWeight(ThemeConfig.TextWeight_400)
      //         .fontColor(Color.White)
      //         .backgroundColor(this.paletteTheme)
      //         .textAlign(TextAlign.Center)
      //         .padding(9)
      //     }
      //     .alignItems(HorizontalAlign.Start)
      //     .width('100%')
      //   }
      //   .border({ width: 1, color: this.packageName === '终身卡' ? this.paletteTheme : '#EAEAEA' })
      //   .borderRadius(8)
      //   .padding(20)
      //   .onClick(() => {
      //     this.packageName = '终身卡'
      //     this.packagePrice = 9.9
      //   })
      //   .backgroundColor(this.packageName === '终身卡' ? this.getPaletteThemeWithOpacity() : '#fff')
      //
      // }
      // .columnsTemplate('1fr 1fr 1fr 1fr') // 每行3个等宽列
      // // .rowsTemplate('auto') // 行高自适应内容
      // .columnsGap(24) // 列间距
      // .rowsGap(24) // 行间距


      Text(Languages.purchasePackage[this.languages])
        .fontColor(ThemeConfig.TextBodyColor)
        .fontSize(ThemeConfig.TextSize_18)
        .fontWeight(ThemeConfig.TextWeight_500)
        .visibility(this.goodsInfo ? Visibility.Visible : Visibility.None)

      Row() {
        if (this.payState) {
          if (this.payStateInfo) {
            QRCode(this.payStateInfo.codeUrl)
              .width(300)
          } else {
            Text('支付成功')
              .width(300)
              .height(300)
              .textAlign(TextAlign.Center)
          }
        } else {
          Text('去支付')
            .width(300)
            .height(300)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              if (!this.Selected) {
                promptAction.showToast({
                  message: '请同意自动续费服务协议和个人订阅服务协议',
                  duration: 1000,
                  alignment: Alignment.Center
                });
                return
              }
              this.payStateInfo = null
              let param: pay_Params = {
                goodsId: this.goodsInfo?.goodsId as number,
                goodsSpecsId: this.goodsInfo?.id as number,
                goodsType: this.goodsInfo?.unit as string,
                payType: this.payment === 'wx' ? "WECHAT" : 'ALIPAY',
                token: (AppStorage.get('userLoginInfo') as UserLoginInfo).token
              }
              console.log('token', JSON.stringify(param))
              _pay(param).then((res) => {
                console.warn(JSON.stringify(res))
                if (res.statusCode === 200) {
                  this.payStateInfo = res.data
                  this.payState = true
                }
              })
            })
        }
        Flex({
          direction: FlexDirection.Column,
          space: { main: LengthMetrics.px(30) },
          justifyContent: FlexAlign.Start
        }) {
          // Text('订单详情')
          Text(Languages.orderDetails[this.languages])
            .fontSize(ThemeConfig.TextSize_14)
            .fontColor(ThemeConfig.TextBodyColor)
            .fontWeight(ThemeConfig.TextWeight_600)
          Row() {
            // Text('选择套餐：')
            Text(Languages.selectPackage[this.languages] + '：')
              .fontSize(ThemeConfig.TextSize_14)
              .fontWeight(ThemeConfig.TextWeight_400)
              .fontColor(ThemeConfig.TextBodyColor)
            Blank()
            Text(this.goodsInfo?.name)
              .fontSize(ThemeConfig.TextSize_14)
              .fontWeight(ThemeConfig.TextWeight_400)
              .fontColor(ThemeConfig.TextBodyColor)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Row() {
            // Text('购买数量：')
            Text(Languages.purchaseQuantity[this.languages] + '：')
              .fontSize(ThemeConfig.TextSize_14)
              .fontWeight(ThemeConfig.TextWeight_400)
              .fontColor(ThemeConfig.TextBodyColor)
            Blank()
            Counter() {
              // 减号和加号中间显示的文本
              // 因为Text的内容必须是字符串型，而value是number型，所以用toString()把number类型转为字符串类型
              Text(this.value.toString())
            }
            // 当单击加号时
            .onInc(() => {
              this.value++
            })
            // 当单击减号时
            .onDec(() => {
              if (this.value > 1) {
                this.value--
              }
            })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Row() {
            // Text('自动续费套餐：')
            Text(Languages.autoRenewPackage[this.languages] + '：')
              .fontSize(ThemeConfig.TextSize_14)
              .fontWeight(ThemeConfig.TextWeight_400)
              .fontColor(ThemeConfig.TextBodyColor)
            Blank()
            Toggle({ type: ToggleType.Switch, isOn: true }).onChange((value: boolean) => {
              if (value) {
                // this.buttonEnabled = true;
              } else {
                // this.buttonEnabled = false;
              }
            })
              .selectedColor(this.paletteTheme)
              .height(22)
              .width(44)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Row() {
            // Text('付款方式：')
            Text(Languages.paymentMethod[this.languages] + '：')
              .fontSize(ThemeConfig.TextSize_14)
              .fontWeight(ThemeConfig.TextWeight_400)
              .fontColor(ThemeConfig.TextBodyColor)
            Blank()
            Image(this.payment === 'wx' ? $r('app.media.Payment_wx_true') : $r('app.media.Payment_wx_false'))
              .width(32)
              .onClick(() => {
                if (this.payState && this.payment !== 'wx') {
                  if (this.Selected) {
                    this.payment = 'wx'
                    let param: pay_Params = {
                      goodsId: this.goodsInfo?.goodsId as number,
                      goodsSpecsId: this.goodsInfo?.id as number,
                      goodsType: this.goodsInfo?.unit as string,
                      payType: this.payment === 'wx' ? "WECHAT" : 'ALIPAY',
                      token: (AppStorage.get('userLoginInfo') as UserLoginInfo).token
                    }
                    console.log('token', JSON.stringify(param))
                    _pay(param).then((res) => {
                      console.warn(JSON.stringify(res))
                      if (res.statusCode === 200) {
                        this.payStateInfo = res.data
                        this.payState = true
                      }
                    })
                  } else {
                    promptAction.showToast({
                      message: '请同意自动续费服务协议和个人订阅服务协议',
                      duration: 1000,
                      alignment: Alignment.Center
                    });
                  }
                } else {
                  this.payment = 'wx'
                }
              })
              .margin({ right: 10 })
            Image(this.payment === 'zfb' ? $r('app.media.Payment_zfb_true') : $r('app.media.Payment_zfb_false'))
              .width(32)
              .onClick(() => {
                if (this.payState && this.payment !== 'zfb') {
                  if (this.Selected) {
                    this.payment = 'zfb'
                    let param: pay_Params = {
                      goodsId: this.goodsInfo?.goodsId as number,
                      goodsSpecsId: this.goodsInfo?.id as number,
                      goodsType: this.goodsInfo?.unit as string,
                      payType: this.payment === 'wx' ? "WECHAT" : 'ALIPAY',
                      token: (AppStorage.get('userLoginInfo') as UserLoginInfo).token
                    }
                    console.log('token', JSON.stringify(param))
                    _pay(param).then((res) => {
                      console.warn(JSON.stringify(res))
                      if (res.statusCode === 200) {
                        this.payStateInfo = res.data
                        this.payState = true
                      }
                    })
                  } else {
                    promptAction.showToast({
                      message: '请同意自动续费服务协议和个人订阅服务协议',
                      duration: 1000,
                      alignment: Alignment.Center
                    });
                  }
                } else {
                  this.payment = 'zfb'
                }
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 40 })

          Row() {
            // Text('应付款：')
            Text(Languages.payableAmount[this.languages] + '：')
              .fontSize(ThemeConfig.TextSize_14)
              .fontWeight(ThemeConfig.TextWeight_400)
              .fontColor(ThemeConfig.TextBodyColor)
            Blank()
            Text((Number((this.goodsInfo?.priceShow)?.replace("￥", '')) * this.value).toFixed(2) + '￥')
              .fontSize(ThemeConfig.TextSize_18)
              .fontWeight(ThemeConfig.TextWeight_500)
              .fontColor(ThemeConfig.TextBodyColor)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Flex({ space: { main: LengthMetrics.px(20) } }) {
            Image(this.Selected ? $r('app.media.Property1_Variant3') : $r('app.media.Property1_Variant2'))
              .width(16)
              .onClick(() => this.Selected = !this.Selected)
            // Text('同意并接受')
            Text(Languages.agreeAndAccept[this.languages])
              .fontSize(ThemeConfig.TextSize_14)
              .fontColor(ThemeConfig.SecondaryTextColor)
              .fontWeight(ThemeConfig.TextWeight_400)
            // Text('自动续费服务协议')
            Text(Languages.autoRenewalAgreement[this.languages])
              .fontSize(ThemeConfig.TextSize_14)
              .fontColor(this.paletteTheme)
              .fontWeight(ThemeConfig.TextWeight_400)
            Text('|')
              .fontSize(ThemeConfig.TextSize_14)
              .fontColor(ThemeConfig.SecondaryTextColor)
              .fontWeight(ThemeConfig.TextWeight_400)
            // Text('个人订阅服务协议')
            Text(Languages.personalSubscriptionAgreement[this.languages])
              .fontSize(ThemeConfig.TextSize_14)
              .fontColor(this.paletteTheme)
              .fontWeight(ThemeConfig.TextWeight_400)

          }

        }
        .layoutWeight(1)
        .margin({ left: 30 })
      }
      .visibility(this.goodsInfo ? Visibility.Visible : Visibility.None)
      .alignItems(VerticalAlign.Top)
      .width('100%')
      .padding({ bottom: 20 })

    }
  }
}