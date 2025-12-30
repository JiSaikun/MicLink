import { DeviceArrayType_Ble } from "bluetooth"
import { getModelInfoModel } from "config"
import { ConnectDevice, DeviceInfo, DPI_currInfoModel, MouseICType } from "mouse"
import { CommonConfig } from "../common/CommonConfig"
import { Languages_params } from "./SmartSettings"
import { Languages } from "../common/Languages"

@Component
export struct DeviceSettings {
  @Link device_isBle: boolean
  @Consume('pageInfo') pageInfo: NavPathStack
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @StorageLink('devices') devices: DeviceArrayType_Ble[] = []
  // @StorageLink("mouseconfig") mouseconfig: DeviceInfo | null = null //鼠标信息
  @StorageLink('DPI_currInfo') DPI_currInfo: DPI_currInfoModel | null = null //DPI信息
  @StorageLink("lowPowerAlertEnabled") lowPowerAlertEnabled: boolean = true //是否开启低电量提醒
  @State getModelInfo: getModelInfoModel = AppStorage.get('getModelInfo') as getModelInfoModel
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State reportRate: SelectOption[] = [{ value: '125' }, { value: '250' }, { value: '500' }, { value: '1000' }]
  @State DPI: SelectOption[] = []
  @Prop currportRate: number
  @Watch('change_LEDstate') @State currLED: boolean = false
  @Watch('change_reportRate') @StorageLink("reportRate_currIndex") reportRate_currIndex: number = 0
  @Watch('change_DPI') @StorageLink('DPI_currIndex') DPI_currIndex: number = 0

  // @Link pageshow:boolean
  change_reportRate() {
    setTimeout(() => {
      if (this.device_isBle) {
        this.devices[AppStorage.get('device_show_currIndex') as number||
          0].BlueTooth_devices.send([0x13, this.reportRate_currIndex])
      } else {
        ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number||
          0].Communication.getDeviceInfo([0x13, this.reportRate_currIndex])
      }
    }, 50)
  }

  change_DPI() {
    setTimeout(() => {
      if (this.device_isBle) {
        this.devices[AppStorage.get('device_show_currIndex') as number].BlueTooth_devices.send([0x68,
          this.DPI_currIndex + 1]).then(() => {
          (this.devices[AppStorage.get('device_show_currIndex') as number].mouseconfig as DeviceInfo).dpiLevel =
            this.DPI_currIndex
        })
      } else {
        ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].Communication.getDeviceInfo([0x68,
          this.DPI_currIndex + 1]).then(() => {
          (ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].mouseconfig as DeviceInfo).dpiLevel =
            this.DPI_currIndex
        })
      }
    }, 50)
    let currDPI_Info: DPI_currInfoModel = {
      length: this.DPI.length,
      curr: this.DPI_currIndex
    }
    this.DPI_currInfo = currDPI_Info
    if (this.device_isBle) {
      this.devices[AppStorage.get('device_show_currIndex') as number].DPI_currInfo = currDPI_Info
    } else {
      ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].DPI_currInfo = currDPI_Info
    }
    // console.error(JSON.stringify(currDPI_Info), '00000000000000000000000000000000000000000000000000')
  }

  change_LEDstate() {
    setTimeout(() => {
      if (this.currLED) {
        if (this.device_isBle) {
          this.devices[AppStorage.get('device_show_currIndex') as number].BlueTooth_devices.send([0x83])
        } else {
          ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].Communication.getDeviceInfo([0x83])
        }
      } else {
        if (this.device_isBle) {
          this.devices[AppStorage.get('device_show_currIndex') as number].BlueTooth_devices.send([0x84])
        } else {
          ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].Communication.getDeviceInfo([0x84])
        }
      }
      if (this.device_isBle) {
        this.devices[AppStorage.get('device_show_currIndex') as number].currLED = this.currLED
      } else {
        ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].currLED = this.currLED
      }
    }, 50)

  }

  isShowDPI(): boolean {
    for (let item of this.getModelInfo.functions) {
      if (item.name === "HideDPI"&&item.code==="YES") {
        return false
      }
    }
    return true
  }
  isShowReportRate(): boolean {
    for (let item of this.getModelInfo.functions) {
      if (item.name === 'HideReportRate'&&item.code==="YES") {
        return false
      }
    }
    return true
  }
  isShowAmbientLightSwitch(): boolean {
    for (let item of this.getModelInfo.functions) {
      if (item.name === 'HideAmbientLightSwitch'&&item.code==="YES") {
        return false
      }
    }
    return true
  }
  aboutToAppear(): void {
    if (this.device_isBle) {
      this.currLED = this.devices[AppStorage.get('device_show_currIndex') as number].currLED
    } else {
      this.currLED = ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].currLED
    }
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Text(Languages.deviceSetup[this.languages])
          .fontSize(CommonConfig.fontSize_14)
          .fontWeight(CommonConfig.fontWeight_400)
          .fontColor(CommonConfig.hintTextColor)

        Column() {
          if (this.isShowDPI()) {

            Row() {
              Text("DPI")
                .fontSize(CommonConfig.fontSize_14)
                .fontColor(CommonConfig.hintTextColor_select)
                .fontWeight(CommonConfig.fontWeight_400)
              Blank()
              Row() {
                Text(this.DPI && this.DPI.length > 0 ?
                  this.DPI[Math.min(Math.max(0, this.DPI_currIndex), this.DPI.length - 1)]?.value : '')
                  .fontSize(CommonConfig.fontSize_12)
                  .fontColor(CommonConfig.hintTextColor)
                  .fontWeight(CommonConfig.fontWeight_400)
                  .margin({ right: 8 })
                Image($r('app.media.Arrow_to_the_right'))
                  .width(16)
                  .height(16)
              }.onClick(() => {
                let params: Languages_params = {
                  ListData: this.DPI,
                  OperationType: 'DPI_currIndex',
                  currLanguages: this.DPI && this.DPI.length > 0 ?
                  Math.min(Math.max(0, this.DPI_currIndex), this.DPI.length - 1) : 0,
                  device_isBle: this.device_isBle,
                  title: "DPI"
                }
                this.pageInfo.pushPath({ "name": 'Changelanguage', param: params })
              })

            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .padding({ top: 12, bottom: 12 })

          }
          if (this.isShowReportRate()) {
            Row() {
              Text(Languages.return[this.languages])
                .fontSize(CommonConfig.fontSize_14)
                .fontColor(CommonConfig.hintTextColor_select)
                .fontWeight(CommonConfig.fontWeight_400)
              Blank()
              Row() {
                Text(this.reportRate && this.reportRate.length > 0 ?
                  this.reportRate[Math.max(0, Math.min(this.reportRate_currIndex, this.reportRate.length - 1))]?.value :
                  '')
                  .fontSize(CommonConfig.fontSize_12)
                  .fontColor(CommonConfig.hintTextColor)
                  .fontWeight(CommonConfig.fontWeight_400)
                  .margin({ right: 8 })
                Image($r('app.media.Arrow_to_the_right'))
                  .width(16)
                  .height(16)
              }.onClick(() => {
                let params: Languages_params = {
                  ListData: this.reportRate,
                  OperationType: 'reportRate_currIndex',
                  currLanguages: this.reportRate && this.reportRate.length > 0 ?
                  Math.max(0, Math.min(this.reportRate_currIndex, this.reportRate.length - 1)) : 0,
                  device_isBle: this.device_isBle,
                  title: Languages.return[this.languages]
                }
                this.pageInfo.pushPath({ "name": 'Changelanguage', param: params })
              })

            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .padding({ top: 12, bottom: 12 })

          }
          if (this.isShowAmbientLightSwitch()) {
            Row() {
              Text(Languages.lighting[this.languages])
                .fontSize(CommonConfig.fontSize_14)
                .fontColor(CommonConfig.hintTextColor_select)
                .fontWeight(CommonConfig.fontWeight_400)
              Blank()
              Toggle({ type: ToggleType.Switch, isOn: true }).onChange((value: boolean) => {
                // 处理开关逻辑
                if (value) {
                  console.log('*****************************打开氛围灯****************************************')
                  this.currLED = true
                } else {
                  console.log('*****************************关闭氛围灯****************************************')
                  this.currLED = false
                }
              })
                .selectedColor(this.paletteTheme)
                .height(22)
                .width(44)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .padding({ top: 12, bottom: 12 })
            .border({ width: { bottom: 1 }, color: CommonConfig.commonBackgroundColor })
          }


          Row() {
            Text(Languages.battery_Low_Warning[this.languages])
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
              .fontWeight(CommonConfig.fontWeight_400)
            Blank()
            Toggle({ type: ToggleType.Switch, isOn: true }).onChange((value: boolean) => {
              // 处理开关逻辑
              if (value) {
                console.log('*****************************打开低电量提醒****************************************')
              } else {
                console.log('*****************************打关闭低电量提醒****************************************')
              }
            })
              .selectedColor(this.paletteTheme)
              .height(22)
              .width(44)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding({ top: 12, bottom: 12 })
          .border({ width: { bottom: 1 }, color: CommonConfig.commonBackgroundColor })

        }
        .padding({ left: 12, right: 12 })
        .borderRadius(12)
        .backgroundColor(Color.White)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .height('100%')
    .scrollBarWidth(0)
    .align(Alignment.TopStart)

  }

  onDidBuild(): void {
    // Ensure DPI array is initialized with default values
    this.DPI =
      [{ value: '1000' }, { value: '1200' }, { value: '1600' }, { value: '2400' }, { value: '4000' }, { value: '4800' },
        { value: '6000' }]

    const icType =
      this.device_isBle ? this.devices[AppStorage.get('device_show_currIndex') as number||0].mouseconfig?.icType :
        ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number||0].mouseconfig?.icType
    switch (icType) {
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
      default: {
        // Keep the default DPI values if icType doesn't match any case
        this.DPI = [{ value: '1000' }, { value: '1200' }, { value: '1600' }, { value: '2400' }, { value: '4000' },
          { value: '4800' }, { value: '6000' }];
      }
        break;
    }
    //防止重设按键设置————再次校验
    const reportRate =
      this.device_isBle ? this.devices[AppStorage.get('device_show_currIndex') as number||0].mouseconfig?.reportRate :
        ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number||0].mouseconfig?.reportRate
    switch (reportRate) {
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
    if (this.device_isBle) {
      this.DPI_currIndex =
        this.devices[AppStorage.get('device_show_currIndex') as number].DPI_currInfo as DPI_currInfoModel ?
        (this.devices[AppStorage.get('device_show_currIndex') as number].DPI_currInfo as DPI_currInfoModel).curr :
          this.devices[AppStorage.get('device_show_currIndex') as number||
            0].mouseconfig?.dpiLevel as number - 1
      this.currLED = this.devices[AppStorage.get('device_show_currIndex') as number||
        0].mouseconfig?.atmosphereLight as boolean
    } else {
      this.DPI_currIndex =
        ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].DPI_currInfo as DPI_currInfoModel ?
        (ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].DPI_currInfo as DPI_currInfoModel).curr :
          ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number||
            0].mouseconfig?.dpiLevel as number - 1
      this.currLED = ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number||
        0].mouseconfig?.atmosphereLight as boolean
    }


    let currDPI_Info: DPI_currInfoModel = {
      length: this.DPI.length,
      curr: this.DPI_currIndex
    }
    this.DPI_currInfo = currDPI_Info
    if (this.device_isBle) {
      this.devices[AppStorage.get('device_show_currIndex') as number].DPI_currInfo = currDPI_Info
      // console.error(JSON.stringify(currDPI_Info), '00000000000000000000000000000000000000000000000000')
    } else {
      ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].DPI_currInfo = currDPI_Info
      // console.error(JSON.stringify(currDPI_Info), '00000000000000000000000000000000000000000000000000')
    }

  }
}