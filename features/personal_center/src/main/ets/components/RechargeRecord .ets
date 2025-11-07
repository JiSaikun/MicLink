import { LengthMetrics } from "@kit.ArkUI";
import { ThemeConfig } from "common";
import { Languages } from "config";

@Component
export struct RechargeRecord {
  @StorageLink('languages') languages: string = 'ZH_CN'
  @StorageLink("paletteTheme") paletteTheme: string = ThemeConfig.PaletteTheme
  @State day: Date = new Date()
  @State data_now: string = `${this.day.getFullYear()}-${this.day.getMonth() + 1}`
  private selectedDate: Date = new Date();
  @State isShowDatePicker: boolean = false

  build() {
    // Text('充值记录')
    Flex({ space: { main: LengthMetrics.px(24) }, direction: FlexDirection.Column }) {
      Flex({ space: { main: LengthMetrics.px(24) }, alignItems: ItemAlign.Center }) {
        Row() {
          Text(this.data_now)
            .fontSize(ThemeConfig.TextSize_14)
            .fontWeight(ThemeConfig.TextWeight_400)
            .fontColor(ThemeConfig.TextBodyColor)
          Blank()
          Image($r('app.media.datachangePicker'))
            .width(16)
            .onClick(() => {
              this.isShowDatePicker = !this.isShowDatePicker
            })
        }
        .width(230)
        .border({ width: 1, color: this.isShowDatePicker ? this.paletteTheme : '#EAEAEA' })
        .borderRadius(4)
        .padding(8)

        // Text('年支出：450￥')
        Text(Languages.annualExpenditure[this.languages] + '：' + '450￥')
          .fontSize(ThemeConfig.TextSize_14)
          .fontWeight(ThemeConfig.TextWeight_400)
          .fontColor(ThemeConfig.TextBodyColor)
        // Text('月支出：450￥')
        Text(Languages.monthlyExpenditure[this.languages] + '：' + '450￥')
          .fontSize(ThemeConfig.TextSize_14)
          .fontWeight(ThemeConfig.TextWeight_400)
          .fontColor(ThemeConfig.TextBodyColor)
      }
      .width('100%')

      Stack() {
        Column() {
          Row() {
            Row() {
              Image($r('app.media.Vector_1'))
                .width(20)
            }
            .width(40)
            .height(40)
            .justifyContent(FlexAlign.Center)
            .borderRadius(20)
            .backgroundColor(this.paletteTheme)

            Column({ space: 15 }) {
              Row() {
                Text('文件转写-年卡')
                  .fontSize(ThemeConfig.TextSize_18)
                  .fontWeight(ThemeConfig.TextWeight_500)
                  .fontColor(ThemeConfig.TextBodyColor)
                Blank()
                Text('450￥')
                  .fontSize(ThemeConfig.TextSize_18)
                  .fontWeight(ThemeConfig.TextWeight_500)
                  .fontColor(ThemeConfig.TextBodyColor)
              }
              .width('100%')

              Text('会员套餐')
                .fontSize(ThemeConfig.TextSize_14)
                .fontWeight(ThemeConfig.TextWeight_400)
                .fontColor(ThemeConfig.SecondaryTextColor)
              Text('2025-06-30 10:45')
                .fontSize(ThemeConfig.TextSize_14)
                .fontWeight(ThemeConfig.TextWeight_400)
                .fontColor(ThemeConfig.SecondaryTextColor)
            }
            .layoutWeight(1)
            .margin({ left: 20 })
            .padding({ bottom: 9 })
            .alignItems(HorizontalAlign.Start)
            .border({ width: { bottom: 2 }, color: '#F8F8F8' })
          }
          .alignItems(VerticalAlign.Top)
          .padding(9)
        }
        .onClick(() => {
          if (this.isShowDatePicker) {
            this.isShowDatePicker = false
          }
        })

        if (this.isShowDatePicker) {
          DatePicker({
            start: new Date('2010'),
            end: this.day,
            selected: $$this.selectedDate
          })
            .onDateChange((data) => {
              this.data_now = this.selectedDate.getFullYear() + '-' + (this.selectedDate.getMonth() + 1)
            })
            .width(230)
            .height(250)
            .backgroundColor('#fff')
            .borderRadius(4)
            .zIndex(100)
            // 添加多个阴影效果
            .shadow({
              radius: 8,
              color: '#525A6614',
              offsetX: 2,
              offsetY: 2
            })
            .shadow({
              radius: 2,
              color: '#525A660A',
              offsetX: 1,
              offsetY: 1
            })
        }
      }
      .align(Alignment.TopStart)
    }

  }
}