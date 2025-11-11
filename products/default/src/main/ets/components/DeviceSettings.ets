import { LengthMetrics } from "@kit.ArkUI"
import { connectDevice, DeviceArrayType_Ble } from "bluetooth"
import { getModelInfoModel, imagesDataModel, imagesModel, Languages } from "config"
import { DeviceArrayType, DeviceInfo, MouseICType, ConnectDevice } from 'mouse'
import { DevicesConfig } from './DevicesConfig'
import { common } from "@kit.AbilityKit"

// 鼠标连接方式
interface connectionmethod_Model {
  Cloud: boolean
  USB: boolean
  Bluetooth: boolean
}

@Component
export struct DeviceSettings {
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State isShowConfig: boolean = false
  // @StorageLink("mouseconfig") mouseconfig: DeviceInfo | null = null //鼠标信息
  @StorageLink('getModelInfo') getModelInfo: getModelInfoModel =
    AppStorage.get('getModelInfo') as getModelInfoModel
  @Watch('a') @StorageLink('devicesList') devicesList: DeviceArrayType[] = []
  @StorageLink('devices') devices: DeviceArrayType_Ble[] = []
  @Provide device_isBle: boolean = false //该设备是否是蓝牙连接

  a() {
    console.error('设备长度', this.devicesList.length)
    if (this.devicesList.length) {
      console.error('设备长度::', this.devicesList[0].getModelInfo)
    }
  }

  build() {
    Stack() {
      Scroll() {
        Column() {
          Row() {
            // Text('设备')
            Text(Languages.device[this.languages])
              .fontWeight(600)
              .lineHeight(32)
              .fontSize(32)
              .fontColor('#31373d')
            Blank()
            Image($r('app.media.Frame_2129'))
              .width(32)
              .height(32)
              .onClick(() => {
                if (!AppStorage.get('isShow_bluetoothConnect_pop')) {
                  AppStorage.setOrCreate('isShow_bluetoothConnect_pop', true)
                  //检索与连接蓝牙，之前的连接列表清空    蓝牙检索状态:false
                  for (let item of this.devices) {
                    item.BlueTooth_devices.closeconnectDevice()
                  }
                  AppStorage.setOrCreate('isBluetoothConnect_state', false)
                  AppStorage.setOrCreate('devices', [])
                  const context: common.UIAbilityContext =
                    this.getUIContext().getHostContext() as common.UIAbilityContext;
                  connectDevice(context)

                }
              })
          }
          .alignItems(VerticalAlign.Center)
          .padding({ bottom: 15, left: 5, right: 10 })
          .width('100%')

          // .borderWidth(1)

          Grid() {
            ForEach(this.devicesList, (item: DeviceArrayType, index) => {
              if (item.getModelInfo) {
                GridItem() {
                  Column() {
                    Row() {
                      Text('')
                        .fontSize(18)
                        .fontWeight(500)
                        .lineHeight(18)
                        .fontColor('#31373d')
                      Blank()
                      Row() {
                        if (item.mouseconfig?.batteryLevel as number >= 80) {
                          Image($r('app.media.power_level_full'))
                            .width(20).height(10)
                        } else if (item.mouseconfig?.batteryLevel as number >= 60) {
                          Image($r('app.media.power_level_80'))
                            .width(20).height(10)
                        } else if (item.mouseconfig?.batteryLevel as number >= 40) {
                          Image($r('app.media.power_level_60'))
                            .width(20).height(10)
                        } else if (item.mouseconfig?.batteryLevel as number >= 20) {
                          Image($r('app.media.power_level_40'))
                            .width(20).height(10)
                        } else {
                          Image($r('app.media.power_level_20'))
                            .width(20).height(10)
                        }
                        Text(item.name)
                          .margin({ left: 5 })
                          .fontSize(18)
                          .fontWeight(500)
                          .lineHeight(18)
                          .fontColor('#31373d')
                      }
                      .visibility(item.getModelInfo?.id ? Visibility.Visible : Visibility.None)

                      // Text('未连接')
                      Text(Languages.notConnected[this.languages])
                        .fontSize(14)
                        .fontWeight(400)
                        .lineHeight(14)
                        .fontColor('#eb5e12')
                        .visibility(item.getModelInfo?.id ? Visibility.None : Visibility.Visible)
                    }
                    .width('100%')

                    Image((item.getModelInfo as getModelInfoModel).images.length ?
                    this.getdeviesImage(item.getModelInfo as getModelInfoModel) : $r('app.media.HM_001_white'))
                      .width('100%')
                      .margin({ bottom: 15, top: 15 })

                    Row() {
                      Image($r('app.media.Cloud_true'))
                        .visibility(item.connectionmethod === 0 ? Visibility.Visible : Visibility.None)
                        .margin({ left: 10 }).width(24)
                      Image($r('app.media.Cloud_false'))
                        .visibility(item.connectionmethod === 0 ? Visibility.None : Visibility.Visible)
                        .margin({ left: 10 }).width(24)
                      Image($r('app.media.USB_true'))
                        .visibility(item.connectionmethod === 1 ? Visibility.Visible : Visibility.None)
                        .margin({ left: 10 }).width(24)
                      Image($r('app.media.USB_false'))
                        .visibility(item.connectionmethod === 1 ? Visibility.None : Visibility.Visible)
                        .margin({ left: 10 }).width(24)
                      Image($r('app.media.Bluetooth_true'))
                        .visibility(item.connectionmethod === 2 ? Visibility.Visible : Visibility.None)
                        .margin({ left: 10 }).width(24)
                      Image($r('app.media.Bluetooth_false'))
                        .visibility(item.connectionmethod === 2 ? Visibility.None : Visibility.Visible)
                        .margin({ left: 10 }).width(24)
                    }
                    .justifyContent(FlexAlign.End)
                    .width('100%')
                  }
                  .padding(24)
                  .borderRadius(16)
                  .border({ width: 2, color: '#e6e8eb' })
                  .onMouse((event?: MouseEvent) => {
                    if (event && !item.getModelInfo?.images) {
                      if (event.stopPropagation) {
                        event.stopPropagation();
                      }
                    }
                  })
                  .onClick(() => {
                    if (item.mouseconfig?.sn && item.getModelInfo) {
                      AppStorage.setOrCreate('device_show_currIndex', index)
                      AppStorage.setOrCreate('getModelInfo',
                        ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].getModelInfo)
                      this.device_isBle = false
                      this.isShowConfig = true
                    }
                  })
                }
              }
            }, (item: DeviceArrayType) => JSON.stringify(item.Communication))
            ForEach(this.devices, (item: DeviceArrayType_Ble, index) => {
              if (item.getModelInfo) {
                GridItem() {
                  Column() {
                    Row() {
                      Text('')
                        .fontSize(18)
                        .fontWeight(500)
                        .lineHeight(18)
                        .fontColor('#31373d')
                      Blank()
                      Row() {
                        if (item.mouseconfig?.batteryLevel as number >= 80) {
                          Image($r('app.media.power_level_full'))
                            .width(20).height(10)
                        } else if (item.mouseconfig?.batteryLevel as number >= 60) {
                          Image($r('app.media.power_level_80'))
                            .width(20).height(10)
                        } else if (item.mouseconfig?.batteryLevel as number >= 40) {
                          Image($r('app.media.power_level_60'))
                            .width(20).height(10)
                        } else if (item.mouseconfig?.batteryLevel as number >= 20) {
                          Image($r('app.media.power_level_40'))
                            .width(20).height(10)
                        } else {
                          Image($r('app.media.power_level_20'))
                            .width(20).height(10)
                        }
                        Text(item.name)
                          .margin({ left: 5 })
                          .fontSize(18)
                          .fontWeight(500)
                          .lineHeight(18)
                          .fontColor('#31373d')
                      }
                      .visibility(item.getModelInfo?.id ? Visibility.Visible : Visibility.None)

                      // Text('未连接')
                      Text(Languages.notConnected[this.languages])
                        .fontSize(14)
                        .fontWeight(400)
                        .lineHeight(14)
                        .fontColor('#eb5e12')
                        .visibility(item.getModelInfo?.id ? Visibility.None : Visibility.Visible)
                    }
                    .width('100%')

                    Image((item.getModelInfo as getModelInfoModel).images.length ?
                    this.getdeviesImage(item.getModelInfo as getModelInfoModel) : $r('app.media.HM_001_white'))
                      .width('100%')
                      .margin({ bottom: 15, top: 15 })

                    Row() {
                      Image($r('app.media.Cloud_true'))
                        .visibility(item.connectionmethod === 0 ? Visibility.Visible : Visibility.None)
                        .margin({ left: 10 }).width(24)
                      Image($r('app.media.Cloud_false'))
                        .visibility(item.connectionmethod === 0 ? Visibility.None : Visibility.Visible)
                        .margin({ left: 10 }).width(24)
                      Image($r('app.media.USB_true'))
                        .visibility(item.connectionmethod === 1 ? Visibility.Visible : Visibility.None)
                        .margin({ left: 10 }).width(24)
                      Image($r('app.media.USB_false'))
                        .visibility(item.connectionmethod === 1 ? Visibility.None : Visibility.Visible)
                        .margin({ left: 10 }).width(24)
                      Image($r('app.media.Bluetooth_true'))
                        .visibility(item.connectionmethod === 2 ? Visibility.Visible : Visibility.None)
                        .margin({ left: 10 }).width(24)
                      Image($r('app.media.Bluetooth_false'))
                        .visibility(item.connectionmethod === 2 ? Visibility.None : Visibility.Visible)
                        .margin({ left: 10 }).width(24)
                    }
                    .justifyContent(FlexAlign.End)
                    .width('100%')
                  }
                  .padding(24)
                  .borderRadius(16)
                  .border({ width: 2, color: '#e6e8eb' })
                  .onMouse((event?: MouseEvent) => {
                    if (event && !item.getModelInfo?.images) {
                      if (event.stopPropagation) {
                        event.stopPropagation();
                      }
                    }
                  })
                  .onClick(() => {
                    if (item.mouseconfig?.sn && item.getModelInfo) {
                      AppStorage.setOrCreate('device_show_currIndex', index)
                      AppStorage.setOrCreate('getModelInfo',
                        this.devices[AppStorage.get('device_show_currIndex') as number].getModelInfo)
                      this.device_isBle = true
                      this.isShowConfig = true
                    }
                  })
                }
              }
            }, (item: DeviceArrayType_Ble) => item.BlueTooth_devices.device_address)
          }
          .columnsTemplate('1fr 1fr 1fr') // 每行3个等宽列
          .columnsGap(15) // 列间距
          .rowsGap(30) // 行间距
          .width('100%')
        }
        .padding({
          left: 24,
          top: 90,
          right: 24,
          bottom: 24
        })
        .width('100%')
      }
      .align(Alignment.TopStart)
      .width('100%')
      .height('100%')

      if (this.isShowConfig) {
        Row() {
          DevicesConfig({ isShowConfig: this.isShowConfig })
        }
        .width('100%')
        .height('100%')
        .padding({
          left: 24,
          top: 90,
          right: 24,
          bottom: 24
        })
        .backgroundColor('#fff')
      }
      // .visibility(this.isShowConfig?Visibility.Visible:Visibility.None)
    }

  }

  getdeviesImage(getModelInfo: getModelInfoModel): string {
    for (let item of getModelInfo.images) {
      console.error('设备图片', JSON.stringify((item as imagesModel)[this.languages]))
      if ((item as imagesModel)[this.languages]) {
        // console.log('****************************************1', JSON.stringify(item))
        return ((item as imagesModel)[this.languages][0] as imagesDataModel)['img']
      }
    }
    return ''
    return ((getModelInfo.images[0] as imagesModel)["ZH_CN"][0] as imagesDataModel)['img']
  }
}