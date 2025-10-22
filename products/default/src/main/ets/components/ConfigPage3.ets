import { DPI_currInfoModel, ConnectDevice, DeviceInfo, MouseICType } from 'mouse'
import { LengthMetrics } from '@kit.ArkUI'
import { getModelInfoModel, Languages } from 'config'

PersistentStorage.persistProp("lowPowerAlertEnabled", true)
PersistentStorage.persistProp("DPI_currInfo", null)

// interface DPI_currInfoModel {
//   length: number
//   curr: number
// }

/**
 * 设备设置
 */
@Component
export struct ConfigPage3 {
  // @StorageLink("mouseconfig") mouseconfig: DeviceInfo | null = null //鼠标信息
  @StorageLink('DPI_currInfo') DPI_currInfo: DPI_currInfoModel | null = null //DPI信息
  @StorageLink("lowPowerAlertEnabled") lowPowerAlertEnabled: boolean = true //是否开启低电量提醒
  @State getModelInfo: getModelInfoModel =
    ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].getModelInfo as getModelInfoModel
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State reportRate: SelectOption[] = [{ value: '125' }, { value: '250' }, { value: '500' }, { value: '1000' }]
  @State DPI: SelectOption[] =
    [{ value: '1000' }, { value: '1200' }, { value: '1600' }, { value: '2400' }, { value: '4000' }, { value: '4800' },
      { value: '6000' }]
  @Prop currportRate: number
  @Watch('change_LEDstate') @State currLED: boolean =
    ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].currLED
  @Watch('change_reportRate') @State reportRate_currIndex: number = 0
  @Watch('change_DPI') @State DPI_currIndex: number = 0

  // @Link pageshow:boolean
  change_reportRate() {
    setTimeout(() => {
      ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number||
        0].Communication.getDeviceInfo([0x13, this.reportRate_currIndex])
    }, 50)
  }

  change_DPI() {
    setTimeout(() => {
      ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].Communication.getDeviceInfo([0x68,
        this.DPI_currIndex + 1]).then(() => {
        (ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].mouseconfig as DeviceInfo).dpiLevel =
          this.DPI_currIndex
      })
    }, 50)
    let currDPI_Info: DPI_currInfoModel = {
      length: this.DPI.length,
      curr: this.DPI_currIndex
    }
    this.DPI_currInfo = currDPI_Info
    ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].DPI_currInfo = currDPI_Info
    // console.error(JSON.stringify(currDPI_Info), '00000000000000000000000000000000000000000000000000')
  }

  change_LEDstate() {
    setTimeout(() => {
      if (this.currLED) {
        ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].Communication.getDeviceInfo([0x83])
      } else {
        ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].Communication.getDeviceInfo([0x84])
      }
      ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].currLED = this.currLED
    }, 50)

  }

  isShow(name: string): boolean {
    if (this.getModelInfo.functions.length === 0) {
      return true
    }
    for (let item of this.getModelInfo.functions) {
      if (item.name === name) {
        return true
      }
    }
    return false
  }

  build() {
    Flex({ space: { main: LengthMetrics.px(15) }, direction: FlexDirection.Column }) {
      Text(Languages.deviceSetup[this.languages])
        .fontSize(14)
        .lineHeight(14)
        .fontWeight(400)
        .fontColor('#a4aab2')
        .margin({ bottom: 20 })
      if (this.isShow('DPI')) {
        Text("DPI")
          .fontSize($r('app.float.default_text_font_size_14'))
          .fontWeight(400)
          .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        Select(this.DPI)
          .value(this.DPI[this.DPI_currInfo ? this.DPI_currInfo?.curr : this.DPI_currIndex].value)
          .onSelect((index: number) => {
            this.DPI_currIndex = index
          })
          .selected(this.DPI_currInfo ? this.DPI_currInfo?.curr : this.DPI_currIndex)
          .width('100%')
          .font({ size: $r('app.float.default_text_font_size_14'), weight: 400 })
          .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
          .borderRadius(4)
          .border({ width: 1, color: $r('app.string.DEFAULT_BORDER_COLOR') })
          .backgroundColor(Color.White)
      }

      if (this.isShow('ReportRate')) {
        Text(Languages.return[this.languages])
          .fontSize($r('app.float.default_text_font_size_14'))
          .fontWeight(400)
          .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        Select(this.reportRate)
          .value(this.reportRate[this.reportRate_currIndex].value)
          .onSelect((index: number) => {
            this.reportRate_currIndex = index
          })
          .selected(this.reportRate_currIndex)
          .width('100%')
          .font({ size: $r('app.float.default_text_font_size_14'), weight: 400 })
          .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
          .borderRadius(4)
          .border({ width: 1, color: $r('app.string.DEFAULT_BORDER_COLOR') })
          .backgroundColor(Color.White)

      }
      if (this.isShow("AmbientLightSwitch")) {
        Row() {
          Text(Languages.lighting[this.languages])
            .fontSize($r('app.float.default_text_font_size_14'))
            .fontWeight(400)
            .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
          Blank()
          Row() {
            Radio({
              value: 'Radio2', group: 'radioGroup',
              indicatorType: RadioIndicatorType.DOT
            }).checked(this.currLED)
              .height(14)
              .width(14)
              .onChange((isChecked: boolean) => {
                if (isChecked) {
                  console.log('*****************************打开氛围灯****************************************')
                  this.currLED = true
                }
              })
            Text(Languages.on_common[this.languages])
              .fontSize($r('app.float.default_text_font_size_14'))
              .fontWeight(400)
              .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
          }
          .onClick(() => {
            this.currLED = true
          })

          Row() {
            Radio({
              value: 'Radio2', group: 'radioGroup',
              indicatorType: RadioIndicatorType.DOT
            }).checked(!this.currLED)
              .height(14)
              .width(14)
              .onChange((isChecked: boolean) => {
                if (isChecked) {
                  console.log('*****************************关闭氛围灯****************************************')
                  this.currLED = false

                }
              })
            Text(Languages.off_common[this.languages])
              .fontSize($r('app.float.default_text_font_size_14'))
              .fontWeight(400)
              .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
          }
          .onClick(() => {
            this.currLED = false
          })
        }
        .width('100%')
      }

      Row() {
        Text(Languages.battery_Low_Warning[this.languages])
          .fontSize($r('app.float.default_text_font_size_14'))
          .fontWeight(400)
          .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        Blank()
        Row() {
          Radio({
            value: 'Radio2', group: 'lowPowerAlertEnabled',
            indicatorType: RadioIndicatorType.DOT
          }).checked(this.lowPowerAlertEnabled)
            .height(14)
            .width(14)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                console.log('*****************************打开低电量提醒****************************************')
              }
            })
          Text(Languages.on_common[this.languages])
            .fontSize($r('app.float.default_text_font_size_14'))
            .fontWeight(400)
            .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        }
        .onClick(() => {
          this.lowPowerAlertEnabled = true
        })

        Row() {
          Radio({
            value: 'Radio2', group: 'lowPowerAlertEnabled',
            indicatorType: RadioIndicatorType.DOT
          }).checked(!this.lowPowerAlertEnabled)
            .height(14)
            .width(14)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                console.log('*****************************关闭低电量提醒****************************************')
              }
            })
          Text(Languages.off_common[this.languages])
            .fontSize($r('app.float.default_text_font_size_14'))
            .fontWeight(400)
            .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        }
        .onClick(() => {
          this.lowPowerAlertEnabled = false
        })

      }
      .width('100%')

    }
    .width('100%')
  }

  onDidBuild(): void {
    switch (ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number||0].mouseconfig?.icType) {
      case MouseICType.MouseICTypeLS8650:
      case MouseICType.MouseICTypePAW3205:
      case MouseICType.MouseICTypeFCT3065:
      case MouseICType.MouseICTypeFCT3065XY: {
        this.DPI = [{ value: '800' }, { value: '1000' }, { value: '1300' }, { value: '1600' }];
      }
        break;
      case MouseICType.MouseICTypePAW3212: {
        this.DPI = [{ value: '1000' }, { value: '1200' }, { value: '1600' }, { value: '2400' }];
      }
        break;
      case MouseICType.MouseICTypeFCT3065_X:
      case MouseICType.MouseICTypeLS8650_X:
      case MouseICType.MouseICTypePAW3205_X:
      case MouseICType.MouseICTypeFCT3065XY_X:
      case MouseICType.MouseICTypePAW3212_X:
      case MouseICType.MouseICTypeFCT3065XY_X2: {
        this.DPI = [{ value: '1000' }, { value: '1200' }, { value: '1600' }, { value: '2400' }, { value: '4000' }];
      }
        break;
      case MouseICType.MouseICTypePAW3212_X_A4Tech: {
        this.DPI = [{ value: '1200' }, { value: '1600' }, { value: '1800' }, { value: '2000' }, { value: '2400' },
          { value: '4000' }];
      }
        break;
      case MouseICType.MouseICTypePAW3220: {
        this.DPI = [{ value: '1000' }, { value: '1200' }, { value: '1600' }, { value: '2400' }, { value: '4000' },
          { value: '4800' }];
      }
        break;
      case MouseICType.MouseICTypePAW3220_X: {
        this.DPI = [{ value: '1000' }, { value: '1200' }, { value: '1600' }, { value: '2400' }, { value: '4000' },
          { value: '4800' }, { value: '6000' }];
      }
        break;
      case MouseICType.MouseICTypeKA8G2: {
        this.DPI = [{ value: '1000' }, { value: '2400' }, { value: '4000' }];
      }
        break;
      case MouseICType.MouseICTypeKA8G2_inphic: {
        this.DPI = [{ value: '800' }, { value: '1200' }, { value: '1600' }, { value: '2000' }, { value: '2400' }];
      }
        break;
      case MouseICType.MouseICTypePAW3325: {
        this.DPI = [{ value: '800' }, { value: '1600' }, { value: '2400' }, { value: '4800' }, { value: '6400' },
          { value: '10000' }];
      }
        break;
      case MouseICType.MouseICTypePAW3104: {
        this.DPI = [{ value: '800' }, { value: '1600' }, { value: '2400' }, { value: '3200' }, { value: '4000' },
          { value: '8000' }];
      }
        break;
      case MouseICType.MouseICTypePAW3212_G7: {
        this.DPI = [{ value: '800' }, { value: '1600' }, { value: '2400' }, { value: '3200' }];
      }
        break;
      case MouseICType.MouseICTypeFCT3065XY_M3S: {
        this.DPI = [{ value: '800' }, { value: '1200' }, { value: '1600' }];
      }
        break;
    }
    //防止重设按键设置————再次校验
    switch (ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number||0].mouseconfig?.reportRate) {
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
    this.DPI_currIndex =
      ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].DPI_currInfo as DPI_currInfoModel ?
      (ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].DPI_currInfo as DPI_currInfoModel).curr :
        ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number||
          0].mouseconfig?.dpiLevel as number - 1
    this.currLED = ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number||
      0].mouseconfig?.atmosphereLight as boolean

    let currDPI_Info: DPI_currInfoModel = {
      length: this.DPI.length,
      curr: this.DPI_currIndex
    }
    this.DPI_currInfo = currDPI_Info
    ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].DPI_currInfo = currDPI_Info
    // console.error(JSON.stringify(currDPI_Info), '00000000000000000000000000000000000000000000000000')

  }
}