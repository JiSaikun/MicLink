import { Communication, DeviceInfo, MouseICType } from 'mouse'
import { ConfigPage1 } from './ConfigPage1'
import { ConfigPage2 } from './ConfigPage2'
import { ConfigPage3 } from './ConfigPage3'

@Component
export struct DevicesConfig {
  @Link isShowConfig: boolean//控制显隐状态
  @StorageLink("mouseconfig") mouseconfig: DeviceInfo | null = null //鼠标信息
  @State currIndex: number = 0
  @State configsList: string[] = ['智能设置', '按键设置', '设备设置']
  @State reportRate_currIndex: number = 0
  @State DPI_currIndex: number = 0
  @State currLED: boolean = true
  onDidBuild(): void {
    switch (this.mouseconfig?.reportRate){
      case 125:
        this.reportRate_currIndex=0
        break
      case 250:
        this.reportRate_currIndex=1
        break
      case 500:
        this.reportRate_currIndex=2
        break
      case 1000:
        this.reportRate_currIndex=3
        break
    }
    this.DPI_currIndex=this.mouseconfig?.dpiLevel as number
    this.currLED=this.mouseconfig?.atmosphereLight as boolean
  }

  build() {
    Flex() {
      Column() {
        Row() {
          Image($r('app.media.DevicesConfig_back'))
            .width(44)
            .margin({ bottom: 30 })
            .onClick(() => {
              this.isShowConfig = false
            })
        }
        .width('100%')
        .margin({ right: 1 })

        Image($r('app.media.DevicesConfig_HM_001_MIFI'))
          .width('100%')
          .layoutWeight(1)
        // .borderWidth(1)
        Text('重设按键设置')
          .fontSize(12)
          .lineHeight(12)
          .fontWeight(400)
          .fontColor('#31373d')
          .borderRadius(8)
          .border({ width: 1, color: '#eaeaea' })
          .padding({
            left: 14,
            top: 10,
            right: 14,
            bottom: 10
          })
          .margin({ bottom: 20 })
          .onClick(() => {
            try {
              Communication.getDeviceInfo([0x6f])
            } catch (e) {
            }
          })
        Row() {
          Text('固件版本：')
            .fontSize(14)
            .lineHeight(14)
            .fontWeight(400)
            .fontColor('#a4aab2')
          Text(this.mouseconfig?.firmwareVersion)
            .fontSize(14)
            .lineHeight(14)
            .fontWeight(400)
            .fontColor('#a4aab2')
          Text('SN：')
            .fontSize(14)
            .lineHeight(14)
            .fontWeight(400)
            .fontColor('#a4aab2')
            .margin({ left: 15 })
          Text(this.mouseconfig?.sn)
            .fontSize(14)
            .lineHeight(14)
            .fontWeight(400)
            .fontColor('#a4aab2')
          Text('设备型号：')
            .fontSize(14)
            .lineHeight(14)
            .fontWeight(400)
            .fontColor('#a4aab2')
            .margin({ left: 15 })
          Text(this.mouseconfig?.productType.toString())
            .fontSize(14)
            .lineHeight(14)
            .fontWeight(400)
            .fontColor('#a4aab2')
        }

      }
      .alignItems(HorizontalAlign.Center)
      .height('100%')
      .width(558)
      .flexGrow(1)
      .flexShrink(1)

      Column() {
        Row() {
          ForEach(this.configsList, (item: string, index: number) => {
            Text(item)
              .fontColor(this.currIndex === index ? '#00aecc' : '#31373d')
              .fontWeight(400)
              .fontSize(14)
              .lineHeight(14)
              .padding({
                left: 8,
                top: 16,
                right: 8,
                bottom: this.currIndex === index ? 2 : 5
              })
              .border({ width: { bottom: this.currIndex === index ? 3 : 0 }, color: '#00aecc' })
              .onClick(() => {
                this.currIndex = index
              })
          }, (item: string) => item)
        }.width('50%').justifyContent(FlexAlign.SpaceBetween)

        Divider()
          .width('100%')
          .height('1')
          .color('#e6e8eb')
          .margin({ bottom: 10 })
        Scroll() {
          Column() {
            Text(this.configsList[this.currIndex])
              .fontSize(14)
              .lineHeight(14)
              .fontWeight(400)
              .fontColor('#a4aab2')
              .margin({ bottom: 20 })
            ConfigPage1()
              .visibility(this.currIndex === 0 ? Visibility.Visible : Visibility.None)
            ConfigPage2()
              .visibility(this.currIndex === 1 ? Visibility.Visible : Visibility.None)
            if (this.currIndex === 2)
            ConfigPage3({currportRate:this.reportRate_currIndex,DPI_currIndex:this.DPI_currIndex,currLED:this.mouseconfig?.atmosphereLight})
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

        }
        .align(Alignment.TopStart)
        .layoutWeight(1)
        .width('100%')
        .padding(24)
        .border({ width: 1, color: '#eaeaea' })
        .borderRadius(8)
      }
      .alignItems(HorizontalAlign.Start)
      .width(426)
      .height('100%')
      .flexGrow(1)
      .flexShrink(1)

    }
    // .borderWidth(1)
    .width('100%')
    .height('100%')
  }
}