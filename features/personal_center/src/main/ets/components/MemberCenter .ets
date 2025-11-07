import { LengthMetrics } from "@kit.ArkUI"
import { ThemeConfig } from "common"
import { Languages } from "config"

interface PackageInfo {
  readonly price: number //价格
  readonly uration: string //时长
  readonly supportedFormats: string //支持的格式
  readonly name: string //套餐名称
}

@Component
export struct MemberCenter {
  @StorageLink('languages') languages: string = 'ZH_CN'
  @StorageLink("paletteTheme") paletteTheme: string = ThemeConfig.PaletteTheme
  @State allPackageDetails: PackageInfo[] = [
    {
      name: '小时卡',
      price: 2,
      uration: '一小时',
      supportedFormats: '支持TXT、Word等格式转换。'
    }, {
    name: '月卡',
    price: 50,
    uration: '时长',
    supportedFormats: '支持TXT、Word等格式转换。'
  }, {
    name: '季卡',
    price: 150,
    uration: '时长',
    supportedFormats: '支持TXT、Word等格式转换。'
  }, {
    name: '年卡',
    price: 450,
    uration: '时长',
    supportedFormats: '支持TXT、Word等格式转换。'
  }
  ]
  @Watch('changePackage') @State packageName: string = ''
  @State packagePrice: number = 0
  //value用来计数，初始化的值是1
  @State value: number = 1
  @State payment: string = 'wx'
  @State Selected: boolean = false

  changePackage() {
    this.value = 1
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
      Text(Languages.fileTranscription[this.languages])
        .fontSize(ThemeConfig.TextSize_14)
        .fontWeight(ThemeConfig.TextWeight_400)
        .fontColor(ThemeConfig.SecondaryTextColor)
      Grid() {
        ForEach(this.allPackageDetails, (item: PackageInfo) => {
          GridItem() {
            Column({ space: 20 }) {
              Text(item.name)
                .fontSize(ThemeConfig.TextSize_14)
                .fontWeight(ThemeConfig.TextWeight_400)
                .fontColor(ThemeConfig.TextBodyColor)
              Flex({ alignItems: ItemAlign.End }) {
                Text('￥' + item.price)
                  .fontSize(ThemeConfig.TextSize_24)
                  .fontWeight(ThemeConfig.TextWeight_500)
                  .fontColor(ThemeConfig.TextBodyColor)
                  .margin({ right: 10 })

                Text('人民币')
                  .fontSize(ThemeConfig.TextSize_12)
                  .fontWeight(ThemeConfig.TextWeight_400)
                  .fontColor(ThemeConfig.SecondaryTextColor)

                Blank()
                Text(item.uration)
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
                  this.packageName = item.name
                  this.packagePrice = item.price
                })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
          }
          .border({ width: 1, color: item.name === this.packageName ? this.paletteTheme : '#EAEAEA' })
          .borderRadius(8)
          .padding(20)

          .backgroundColor(this.packageName === item.name ? this.getPaletteThemeWithOpacity() : '#fff')
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr') // 每行3个等宽列
      // .rowsTemplate('auto') // 行高自适应内容
      .columnsGap(24) // 列间距
      .rowsGap(24) // 行间距
      Text(Languages.toneCustomization[this.languages])
        .fontSize(ThemeConfig.TextSize_14)
        .fontWeight(ThemeConfig.TextWeight_400)
        .fontColor(ThemeConfig.SecondaryTextColor)
      Grid() {
        GridItem() {
          Column({ space: 20 }) {
            Text('终身卡')
              .fontSize(ThemeConfig.TextSize_14)
              .fontWeight(ThemeConfig.TextWeight_400)
              .fontColor(ThemeConfig.TextBodyColor)
            Flex({ alignItems: ItemAlign.End }) {
              Text('￥9.9')
                .fontSize(ThemeConfig.TextSize_24)
                .fontWeight(ThemeConfig.TextWeight_500)
                .fontColor(ThemeConfig.TextBodyColor)
                .margin({ right: 10 })

              Text('人民币')
                .fontSize(ThemeConfig.TextSize_12)
                .fontWeight(ThemeConfig.TextWeight_400)
                .fontColor(ThemeConfig.SecondaryTextColor)

              Blank()
              Text('终身')
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
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
        }
        .border({ width: 1, color: this.packageName === '终身卡' ? this.paletteTheme : '#EAEAEA' })
        .borderRadius(8)
        .padding(20)
        .onClick(() => {
          this.packageName = '终身卡'
          this.packagePrice = 9.9
        })
        .backgroundColor(this.packageName === '终身卡' ? this.getPaletteThemeWithOpacity() : '#fff')

      }
      .columnsTemplate('1fr 1fr 1fr 1fr') // 每行3个等宽列
      // .rowsTemplate('auto') // 行高自适应内容
      .columnsGap(24) // 列间距
      .rowsGap(24) // 行间距


      Text(Languages.purchasePackage[this.languages])
        .fontColor(ThemeConfig.TextBodyColor)
        .fontSize(ThemeConfig.TextSize_18)
        .fontWeight(ThemeConfig.TextWeight_500)
        .visibility(this.packageName ? Visibility.Visible : Visibility.None)

      Row() {
        Image($r('app.media.Rectangle_489'))
          .width(300)
          .margin({ right: 30 })
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
            Text(this.packageName)
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
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 40 })

          Row() {
            // Text('应付款：')
            Text(Languages.payableAmount[this.languages] + '：')
              .fontSize(ThemeConfig.TextSize_14)
              .fontWeight(ThemeConfig.TextWeight_400)
              .fontColor(ThemeConfig.TextBodyColor)
            Blank()
            Text((this.packagePrice * this.value).toFixed(2) + '￥')
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
      }
      .visibility(this.packageName ? Visibility.Visible : Visibility.None)
      .alignItems(VerticalAlign.Top)
      .width('100%')
      .padding({ bottom: 20 })

    }
  }
}