import { Communication, DeviceInfo, KeyPressType } from 'mouse'
import { ConfigPage1 } from './ConfigPage1'
import { ConfigPage2 } from './ConfigPage2'
import { ConfigPage3 } from './ConfigPage3'

import {
  getModelInfoModel, imagesModel, imagesDataModel, Languages
} from 'config' //获取设备按键信息

@Component
export struct DevicesConfig {
  @Link isShowConfig: boolean //控制显隐状态
  @StorageLink("mouseconfig") mouseconfig: DeviceInfo | null = null //鼠标信息
  @State currIndex: number = 0
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State configsList: string[] =
    [Languages.smartSetup[this.languages], Languages.keySetup[this.languages], Languages.deviceSetup[this.languages]]
  @State reportRate_currIndex: number = 0
  @State DPI_currIndex: number = 0
  @State currLED: boolean = true
  @State getModelInfo: getModelInfoModel = AppStorage.get('getModelInfo') as getModelInfoModel

  onDidBuild(): void {
    this.data_init()
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

        Image(this.getdeviesImage())
          .width('100%')
          .layoutWeight(1)
        // .borderWidth(1)
        Text(Languages.keyReset[this.languages])
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
            // try {
            //   Communication.getDeviceInfo([0x6f])
            //   if (this.currIndex === 2) {
            //     setTimeout(() => {
            //       this.data_init()
            //       this.currIndex = 11111
            //       this.currIndex = 2
            //     }, 20000)
            //   }
            // } catch (e) {
            // }
            AppStorage.setOrCreate('KeymethodConfig', [
              { key: KeyPressType.VOICE_CLICK, currIndex: 0 }, { key: KeyPressType.VOICE_LONG_PRESS_DOWN, currIndex: 0 },
              { key: KeyPressType.SEARCH_CLICK, currIndex: 0 },
              { key: KeyPressType.SEARCH_LONG_PRESS_DOWN, currIndex: 0 },
              { key: KeyPressType.TRANSLATE_CLICK, currIndex: 0 },
              { key: KeyPressType.TRANSLATE_LONG_PRESS_DOWN, currIndex: 0 },
              { key: KeyPressType.AI_CLICK, currIndex: 0 }, { key: KeyPressType.TRANSLATE_LONG_PRESS_DOWN, currIndex: 0 },
            ])
          })
        Row() {
          Text(Languages.firmwareVersion[this.languages])
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
          Text(Languages.modelNumber[this.languages])
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
            ConfigPage1()
              .visibility(this.currIndex === 0 ? Visibility.Visible : Visibility.None)
            ConfigPage2()
              .visibility(this.currIndex === 1 ? Visibility.Visible : Visibility.None)
            if (this.currIndex === 2) {
              ConfigPage3({
                reportRate_currIndex: this.reportRate_currIndex,
                DPI_currIndex: this.DPI_currIndex,
                currLED: this.mouseconfig?.atmosphereLight
              })
            }
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

  getdeviesImage(): string {
    for (let item of this.getModelInfo.images) {
      if ((item as imagesModel)[this.languages]) {
        // console.log('****************************************1', JSON.stringify(item))
        return ((item as imagesModel)[this.languages][0] as imagesDataModel)['img']
      }
    }
    return ''
  }

  data_init() {
    switch (this.mouseconfig?.reportRate) {
      case 125:
        this.reportRate_currIndex = 0
        break
      case 250:
        this.reportRate_currIndex = 1
        break
      case 500:
        this.reportRate_currIndex = 2
        break
      case 1000:
        this.reportRate_currIndex = 3
        break
    }
    this.DPI_currIndex = this.mouseconfig?.dpiLevel as number-1
    this.currLED = this.mouseconfig?.atmosphereLight as boolean
  }
}