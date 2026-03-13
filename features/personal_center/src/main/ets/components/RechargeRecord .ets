import { LengthMetrics } from "@kit.ArkUI";
import { ThemeConfig, UserLoginInfo } from "common";
import { Languages } from "config";
import { goodsSnapchatInfo, orderList_Response } from "../model/UserModel";
import { _orderList } from "../viewmodel/UserViewModel";

@Component
export struct RechargeRecord {
  @StorageLink('languages') languages: string = 'ZH_CN'
  @StorageLink("paletteTheme") paletteTheme: string = ThemeConfig.PaletteTheme
  @State day: Date = new Date()
  @State data_now: string = `${this.day.getFullYear()}-${this.day.getMonth() + 1}`
  private selectedDate: Date = new Date();
  @State isShowDatePicker: boolean = false
  @State orderList: orderList_Response[] = []
  @State filteredOrderList: orderList_Response[] = []
  @State annualExpenditure: number = 0
  @State monthlyExpenditure: number = 0

  aboutToAppear(): void {
    _orderList({ token: (AppStorage.get('userLoginInfo') as UserLoginInfo).token })
      .then((res) => {
        if (res.statusCode === 200) {
          this.orderList = res.data as orderList_Response[]
          this.filterOrdersByMonth()
          this.calculateExpenditure()
        }
      })
  }

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
        Text(Languages.annualExpenditure[this.languages] + '：' + this.annualExpenditure.toFixed(2) + '￥')
          .fontSize(ThemeConfig.TextSize_14)
          .fontWeight(ThemeConfig.TextWeight_400)
          .fontColor(ThemeConfig.TextBodyColor)
        // Text('月支出：450￥')
        Text(Languages.monthlyExpenditure[this.languages] + '：' + this.monthlyExpenditure.toFixed(2) + '￥')
          .fontSize(ThemeConfig.TextSize_14)
          .fontWeight(ThemeConfig.TextWeight_400)
          .fontColor(ThemeConfig.TextBodyColor)
      }
      .width('100%')

      Stack() {
        Column() {
          ForEach(this.filteredOrderList, (item: orderList_Response) => {
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
                  Text(this.getGoodsSnapchat(item.goodsSnapchat).name)
                    .fontSize(ThemeConfig.TextSize_18)
                    .fontWeight(ThemeConfig.TextWeight_500)
                    .fontColor(ThemeConfig.TextBodyColor)
                  Blank()
                  Text(this.getGoodsSnapchat(item.goodsSnapchat).priceShow)
                    .fontSize(ThemeConfig.TextSize_18)
                    .fontWeight(ThemeConfig.TextWeight_500)
                    .fontColor(ThemeConfig.TextBodyColor)
                }
                .width('100%')

                Text(this.getGoodsSnapchat(item.goodsSnapchat).goodsName)
                  .fontSize(ThemeConfig.TextSize_14)
                  .fontWeight(ThemeConfig.TextWeight_400)
                  .fontColor(ThemeConfig.SecondaryTextColor)
                Text(this.getCreateTime(this.getGoodsSnapchat(item.goodsSnapchat).createTime))
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
            .visibility(item.status === 'SUCCESS' ? Visibility.Visible : Visibility.None)
          }, (item: orderList_Response) => item.createDate.toString())

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
            mode: DatePickerMode.YEAR_AND_MONTH,
            selected: $$this.selectedDate
          })
            .onDateChange((data) => {
              this.data_now = this.selectedDate.getFullYear() + '-' + (this.selectedDate.getMonth() + 1)
              this.filterOrdersByMonth()
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

  getGoodsSnapchat(goodsSnapchat: string): goodsSnapchatInfo {
    return JSON.parse(goodsSnapchat)
  }

  getCreateTime(createTime: Date): string {
    // 处理可能的类型转换问题
    const date = typeof createTime === 'string' ? new Date(createTime) :
      typeof createTime === 'number' ? new Date(createTime) :
        createTime;

    if (!(date instanceof Date) || isNaN(date.getTime())) {
      return '';
    }

    // 格式化日期为 YYYY-MM-DD HH:MM 格式
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');

    return `${year}-${month}-${day} ${hours}:${minutes}`;
  }

  // 根据选择的日期筛选当前月份的订单
  filterOrdersByMonth(): void {
    const selectedYear = this.selectedDate.getFullYear();
    const selectedMonth = this.selectedDate.getMonth();

    this.filteredOrderList = this.orderList.filter((item) => {
      const orderDate = item.createDate instanceof Date ? item.createDate : new Date(item.createDate);
      if (!(orderDate instanceof Date) || isNaN(orderDate.getTime())) {
        return false;
      }
      return orderDate.getFullYear() === selectedYear && orderDate.getMonth() === selectedMonth;
    });

    // 计算支出
    this.calculateExpenditure();
  }

  // 计算年支出和月支出
  calculateExpenditure(): void {
    const selectedYear = this.selectedDate.getFullYear();
    const selectedMonth = this.selectedDate.getMonth();

    let annualTotal = 0;
    let monthlyTotal = 0;

    this.orderList.forEach((item) => {
      // 只计算状态为SUCCESS的订单
      if (item.status !== 'SUCCESS') {
        return;
      }

      // 解析goodsSnapchat获取priceShow
      try {
        const goodsInfo = this.getGoodsSnapchat(item.goodsSnapchat);
        if (goodsInfo.priceShow) {
          // 去掉"￥"符号并转换为数字
          const priceStr = goodsInfo.priceShow.replace('￥', '');
          const price = parseFloat(priceStr);

          if (!isNaN(price)) {
            // 计算年支出
            const orderDate = item.createDate instanceof Date ? item.createDate : new Date(item.createDate);
            if (orderDate instanceof Date && !isNaN(orderDate.getTime())) {
              if (orderDate.getFullYear() === selectedYear) {
                annualTotal += price;

                // 计算月支出
                if (orderDate.getMonth() === selectedMonth) {
                  monthlyTotal += price;
                }
              }
            }
          }
        }
      } catch (error) {
        console.error('解析订单数据失败:', error);
      }
    });

    this.annualExpenditure = annualTotal;
    this.monthlyExpenditure = monthlyTotal;
  }
}