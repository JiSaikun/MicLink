import { CommonConfig } from "components_phone"
import { LengthMetrics } from "@kit.ArkUI"
import { getModelInfoModel, imagesDataModel, imagesModel } from "../common/config/GetModelInfoModel"
import { ConnectDevice, DeviceArrayType } from "mouse"
import { DeviceArrayType_Ble } from "bluetooth"

@Component
export struct Tab_device {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @Consume('pageInfo') pageInfo: NavPathStack
  @StorageLink('languages') languages: string = 'ZH_CN'
  @StorageLink('getModelInfo') getModelInfo: getModelInfoModel =
    AppStorage.get('getModelInfo') as getModelInfoModel
  @State forceUpdateTrigger: number = 0 // 专门用于强制UI更新的触发器
  @StorageLink('devicesList') devicesList: DeviceArrayType[] = []
  @Watch('onDevicesChange') @StorageLink('devices') devicesLink: DeviceArrayType_Ble[] = []
  @State devices: DeviceArrayType_Ble[] = []
  @Provide device_isBle: boolean = false //该设备是否是蓝牙连接

  build() {
    Column() {
      Row() {
        Image($r('app.media.MicLink_title'))
          .width(100)
        Blank()
        Image($r('app.media.Group_137'))
          .width(40)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 51 })

      Text('设备')
        .fontWeight(CommonConfig.fontWeight_700)
        .fontColor(CommonConfig.hintTextColor_select)
        .fontSize(CommonConfig.fontSize_16)
        .margin({ bottom: 29 })
      if (!(this.devicesList.length + this.devicesLink.length)) {
          Column() {
            /**
             * 没有设备连接
             */
            Image($r('app.media.VacancyPage'))
              .width(171)
              .margin({ top: 18, bottom: 23 })
            Row() {
              Text('未连接设备，前往连接')
                .fontColor(Color.White)
                .fontSize(CommonConfig.fontSize_14)
                .fontWeight(CommonConfig.fontWeight_400)
            }
            .width('100%')
            .borderRadius(12)
            .backgroundColor(this.paletteTheme)
            .justifyContent(FlexAlign.Center)
            .padding(12)

          }
          .width('100%')
          .borderRadius(16)
          .padding(12)
          .backgroundColor(CommonConfig.commonBackgroundColor)
          .border({ width: 1, color: Color.White })
          .margin({bottom:16})

          Column({ space: 8 }) {
            Row() {
              Image($r('app.media.Frame_2133'))
                .width(24)
                .margin({ right: 12 })
              Text('AI 服务器连接')
                .fontWeight(CommonConfig.fontWeight_400)
                .fontSize(CommonConfig.fontSize_14)
                .fontColor(CommonConfig.hintTextColor_select)
              Blank()
              Image($r('app.media.fork'))
                .width(16)
            }
            .width('100%')
            .borderRadius(8)
            .padding({
              left: 12,
              top: 10,
              right: 12,
              bottom: 10
            })
            .backgroundColor(Color.White)
            .alignItems(VerticalAlign.Center)

            Row() {
              Image($r('app.media.Frame_1'))
                .width(24)
                .margin({ right: 12 })
              Text('设备连接')
                .fontWeight(CommonConfig.fontWeight_400)
                .fontSize(CommonConfig.fontSize_14)
                .fontColor(CommonConfig.hintTextColor_select)
              Blank()
              Image($r('app.media.fork'))
                .width(16)
            }
            .width('100%')
            .borderRadius(8)
            .padding({
              left: 12,
              top: 10,
              right: 12,
              bottom: 10
            })
            .backgroundColor(Color.White)
            .alignItems(VerticalAlign.Center)

            Row() {
              Image($r('app.media.smartphone'))
                .width(24)
                .margin({ right: 12 })
              Text('设备设置')
                .fontWeight(CommonConfig.fontWeight_400)
                .fontSize(CommonConfig.fontSize_14)
                .fontColor(CommonConfig.hintTextColor_select)
              Blank()
              Text('去设置')
                .fontWeight(CommonConfig.fontWeight_400)
                .fontSize(CommonConfig.fontSize_11)
                .fontColor(CommonConfig.hintTextColor)
                .backgroundColor('#EAEAEA')
                .padding(8)
                .borderRadius(16)

            }
            .width('100%')
            .borderRadius(8)
            .padding({
              left: 12,
              top: 10,
              right: 12,
              bottom: 10
            })
            .backgroundColor(Color.White)
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .borderRadius(16)
          .padding(8)
          .backgroundColor(CommonConfig.commonBackgroundColor)
          .border({ width: 1, color: Color.White })
          .margin({ bottom: 16 })

      } else {
        List() {
          ForEach(this.devicesList, (item: DeviceArrayType, index) => {
            if (item.getModelInfo) {
              ListItem() {
                Column() {
                  Column() {
                    Flex() {
                      Column() {
                        Row() {
                          Text(item.name)
                            .fontSize(CommonConfig.fontSize_14)
                            .fontWeight(CommonConfig.fontWeight_700)
                            .fontColor(CommonConfig.hintTextColor_select)
                          Blank()
                          Text('已连接2.4G')
                            .fontSize(CommonConfig.fontSize_11)
                            .fontWeight(CommonConfig.fontWeight_400)
                            .fontColor(CommonConfig.hintTextColor)
                        }
                        .width('100%')
                        .margin({ bottom: 13 })

                        Image(item.getModelInfo && (item.getModelInfo as getModelInfoModel).images &&
                        (item.getModelInfo as getModelInfoModel).images.length ?
                        this.getdeviesImage(item.getModelInfo as getModelInfoModel) : $r('app.media.HM_001_white'))
                          .width('100%')
                          .margin({ left: 20, right: 20 })
                          .layoutWeight(1)
                      }
                      .width(200)
                      .margin({ right: 16 })
                      .height('100%')

                      Flex({ direction: FlexDirection.Column }) {
                        Column({ space: 4 }) {
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
                          Text('剩余电量')
                            .fontWeight(CommonConfig.fontWeight_400)
                            .fontSize(CommonConfig.fontSize_12)
                            .fontColor(CommonConfig.hintTextColor)
                        }
                        .flexGrow(1)
                        .flexShrink(1)

                        Column({ space: 4 }) {
                          Image($r('app.media.USB_true'))
                            .visibility(item.connectionmethod === 1 ? Visibility.Visible : Visibility.None)
                            .margin({ left: 10 }).width(24)
                          Image($r('app.media.USB_false'))
                            .visibility(item.connectionmethod === 1 ? Visibility.None : Visibility.Visible)
                            .margin({ left: 10 }).width(24)
                          Text('剩余电量')
                            .fontWeight(CommonConfig.fontWeight_400)
                            .fontSize(CommonConfig.fontSize_12)
                            .fontColor(item.connectionmethod === 1 ? CommonConfig.hintTextColor_select :
                            CommonConfig.hintTextColor)
                        }
                        .flexGrow(1)
                        .flexShrink(1)

                        Column({ space: 4 }) {
                          Image($r('app.media.Bluetooth_true'))
                            .visibility(item.connectionmethod === 2 ? Visibility.Visible : Visibility.None)
                            .margin({ left: 10 }).width(24)
                          Image($r('app.media.Bluetooth_false'))
                            .visibility(item.connectionmethod === 2 ? Visibility.None : Visibility.Visible)
                            .margin({ left: 10 }).width(24)
                          Text('蓝牙模式')
                            .fontWeight(CommonConfig.fontWeight_400)
                            .fontSize(CommonConfig.fontSize_12)
                            .fontColor(item.connectionmethod === 2 ? CommonConfig.hintTextColor_select :
                            CommonConfig.hintTextColor)
                        }
                        .flexGrow(1)
                        .flexShrink(1)
                      }
                      .layoutWeight(1)
                      .height('100%')
                      .border({ width: 1, color: '#EAEAEA', style: BorderStyle.Dashed })
                      .padding({ left: 16 })
                    }
                    .width('100%')
                    .height('100%')

                  }
                  .width('100%')
                  .borderRadius(16)
                  .padding(12)
                  .backgroundColor(CommonConfig.commonBackgroundColor)
                  .border({ width: 1, color: Color.White })
                  .margin({bottom:16})

                  Column({ space: 8 }) {
                    Row() {
                      Image($r('app.media.Frame_2133'))
                        .width(24)
                        .margin({ right: 12 })
                      Text('AI 服务器连接')
                        .fontWeight(CommonConfig.fontWeight_400)
                        .fontSize(CommonConfig.fontSize_14)
                        .fontColor(CommonConfig.hintTextColor_select)
                      Blank()
                      Image($r('app.media.Frame_2531'))
                        .width(16)
                    }
                    .width('100%')
                    .borderRadius(8)
                    .padding({
                      left: 12,
                      top: 10,
                      right: 12,
                      bottom: 10
                    })
                    .backgroundColor(Color.White)
                    .alignItems(VerticalAlign.Center)

                    Row() {
                      Image($r('app.media.Frame_1'))
                        .width(24)
                        .margin({ right: 12 })
                      Text('设备连接')
                        .fontWeight(CommonConfig.fontWeight_400)
                        .fontSize(CommonConfig.fontSize_14)
                        .fontColor(CommonConfig.hintTextColor_select)
                      Blank()
                      Image($r('app.media.Frame_2531'))
                        .width(16)
                    }
                    .width('100%')
                    .borderRadius(8)
                    .padding({
                      left: 12,
                      top: 10,
                      right: 12,
                      bottom: 10
                    })
                    .backgroundColor(Color.White)
                    .alignItems(VerticalAlign.Center)

                    Row() {
                      Image($r('app.media.smartphone'))
                        .width(24)
                        .margin({ right: 12 })
                      Text('设备设置')
                        .fontWeight(CommonConfig.fontWeight_400)
                        .fontSize(CommonConfig.fontSize_14)
                        .fontColor(CommonConfig.hintTextColor_select)
                      Blank()
                      Text('去设置')
                        .fontWeight(CommonConfig.fontWeight_400)
                        .fontSize(CommonConfig.fontSize_11)
                        .fontColor(CommonConfig.hintTextColor)
                        .backgroundColor(this.paletteTheme)
                        .padding(8)
                        .borderRadius(16)
                        .onClick(() => {
                          if (this.getModelInfo) {
                            AppStorage.setOrCreate('device_show_currIndex', index)
                            AppStorage.setOrCreate('getModelInfo',
                              ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].getModelInfo)
                            this.device_isBle = false
                            this.pageInfo.pushPath({ "name": 'DevicesConfig', param: this.device_isBle })
                          }
                        })

                    }
                    .width('100%')
                    .borderRadius(8)
                    .padding({
                      left: 12,
                      top: 10,
                      right: 12,
                      bottom: 10
                    })
                    .backgroundColor(Color.White)
                    .alignItems(VerticalAlign.Center)
                  }
                  .width('100%')
                  .borderRadius(16)
                  .padding(8)
                  .backgroundColor(CommonConfig.commonBackgroundColor)
                  .border({ width: 1, color: Color.White })
                  .margin({ bottom: 16 })
                }

              }
            }
          }, (item: DeviceArrayType) => JSON.stringify(item.Communication))
          ForEach(this.devices, (item: DeviceArrayType_Ble, index) => {
            if (item.getModelInfo) {
              ListItem() {
                Column() {
                  Column() {
                    Flex() {
                      Column() {
                        Row() {
                          Text(item.name)
                            .fontSize(CommonConfig.fontSize_14)
                            .fontWeight(CommonConfig.fontWeight_700)
                            .fontColor(CommonConfig.hintTextColor_select)
                          Blank()
                          Text('已连接蓝牙')
                            .fontSize(CommonConfig.fontSize_11)
                            .fontWeight(CommonConfig.fontWeight_400)
                            .fontColor(CommonConfig.hintTextColor)
                        }
                        .width('100%')
                        .margin({ bottom: 13 })

                        Image(item.getModelInfo && (item.getModelInfo as getModelInfoModel).images &&
                        (item.getModelInfo as getModelInfoModel).images.length ?
                        this.getdeviesImage(item.getModelInfo as getModelInfoModel) : $r('app.media.HM_001_white'))
                          .width('100%')
                          .margin({ left: 20, right: 20 })
                          .layoutWeight(1)
                      }
                      .width(200)
                      .margin({ right: 16 })
                      .height('100%')

                      Flex({ direction: FlexDirection.Column }) {
                        Column({ space: 4 }) {
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
                          Text('剩余电量')
                            .fontWeight(CommonConfig.fontWeight_400)
                            .fontSize(CommonConfig.fontSize_12)
                            .fontColor(CommonConfig.hintTextColor)
                        }
                        .flexGrow(1)
                        .flexShrink(1)

                        Column({ space: 4 }) {
                          Image($r('app.media.USB_true'))
                            .visibility(item.connectionmethod === 1 ? Visibility.Visible : Visibility.None)
                            .margin({ left: 10 }).width(24)
                          Image($r('app.media.USB_false'))
                            .visibility(item.connectionmethod === 1 ? Visibility.None : Visibility.Visible)
                            .margin({ left: 10 }).width(24)
                          Text('剩余电量')
                            .fontWeight(CommonConfig.fontWeight_400)
                            .fontSize(CommonConfig.fontSize_12)
                            .fontColor(item.connectionmethod === 1 ? CommonConfig.hintTextColor_select :
                            CommonConfig.hintTextColor)
                        }
                        .flexGrow(1)
                        .flexShrink(1)

                        Column({ space: 4 }) {
                          Image($r('app.media.Bluetooth_true'))
                            .visibility(item.connectionmethod === 2 ? Visibility.Visible : Visibility.None)
                            .margin({ left: 10 }).width(24)
                          Image($r('app.media.Bluetooth_false'))
                            .visibility(item.connectionmethod === 2 ? Visibility.None : Visibility.Visible)
                            .margin({ left: 10 }).width(24)
                          Text('蓝牙模式')
                            .fontWeight(CommonConfig.fontWeight_400)
                            .fontSize(CommonConfig.fontSize_12)
                            .fontColor(item.connectionmethod === 2 ? CommonConfig.hintTextColor_select :
                            CommonConfig.hintTextColor)
                        }
                        .flexGrow(1)
                        .flexShrink(1)
                      }
                      .layoutWeight(1)
                      .height('100%')
                      .border({ width: 1, color: '#EAEAEA', style: BorderStyle.Dashed })
                      .padding({ left: 16 })
                    }
                    .width('100%')
                    .height('100%')

                  }
                  .width('100%')
                  .borderRadius(16)
                  .padding(12)
                  .backgroundColor(CommonConfig.commonBackgroundColor)
                  .border({ width: 1, color: Color.White })
                  .margin({bottom:16})

                  Column({ space: 8 }) {
                    Row() {
                      Image($r('app.media.Frame_2133'))
                        .width(24)
                        .margin({ right: 12 })
                      Text('AI 服务器连接')
                        .fontWeight(CommonConfig.fontWeight_400)
                        .fontSize(CommonConfig.fontSize_14)
                        .fontColor(CommonConfig.hintTextColor_select)
                      Blank()
                      Image($r('app.media.Frame_2531'))
                        .width(16)
                    }
                    .width('100%')
                    .borderRadius(8)
                    .padding({
                      left: 12,
                      top: 10,
                      right: 12,
                      bottom: 10
                    })
                    .backgroundColor(Color.White)
                    .alignItems(VerticalAlign.Center)

                    Row() {
                      Image($r('app.media.Frame_1'))
                        .width(24)
                        .margin({ right: 12 })
                      Text('设备连接')
                        .fontWeight(CommonConfig.fontWeight_400)
                        .fontSize(CommonConfig.fontSize_14)
                        .fontColor(CommonConfig.hintTextColor_select)
                      Blank()
                      Image($r('app.media.Frame_2531'))
                        .width(16)
                    }
                    .width('100%')
                    .borderRadius(8)
                    .padding({
                      left: 12,
                      top: 10,
                      right: 12,
                      bottom: 10
                    })
                    .backgroundColor(Color.White)
                    .alignItems(VerticalAlign.Center)

                    Row() {
                      Image($r('app.media.smartphone'))
                        .width(24)
                        .margin({ right: 12 })
                      Text('设备设置')
                        .fontWeight(CommonConfig.fontWeight_400)
                        .fontSize(CommonConfig.fontSize_14)
                        .fontColor(CommonConfig.hintTextColor_select)
                      Blank()
                      Text('去设置')
                        .fontWeight(CommonConfig.fontWeight_400)
                        .fontSize(CommonConfig.fontSize_11)
                        .fontColor(CommonConfig.hintTextColor)
                        .backgroundColor(this.paletteTheme)
                        .padding(8)
                        .borderRadius(16)
                        .onClick(() => {
                          if (this.getModelInfo) {
                            AppStorage.setOrCreate('device_show_currIndex', index)
                            AppStorage.setOrCreate('getModelInfo',
                              this.devices[AppStorage.get('device_show_currIndex') as number].getModelInfo)
                            this.device_isBle = true
                            this.pageInfo.pushPath({ "name": 'DevicesConfig', param: this.device_isBle })
                          }
                        })

                    }
                    .width('100%')
                    .borderRadius(8)
                    .padding({
                      left: 12,
                      top: 10,
                      right: 12,
                      bottom: 10
                    })
                    .backgroundColor(Color.White)
                    .alignItems(VerticalAlign.Center)
                  }
                  .width('100%')
                  .borderRadius(16)
                  .padding(8)
                  .backgroundColor(CommonConfig.commonBackgroundColor)
                  .border({ width: 1, color: Color.White })
                  .margin({ bottom: 16 })
                }

              }
            }
          }, (item: DeviceArrayType_Ble) => JSON.stringify(item.BlueTooth_devices.device_address))
        }

      }


      Flex({ space: { main: LengthMetrics.px(17) } }) {
        Row() {
          Column() {
            Text('使用说明')
              .fontColor('#EE4278')
              .fontSize(CommonConfig.fontSize_14)
              .fontWeight(CommonConfig.fontWeight_700)
              .margin({ bottom: 4 })
            Text('功能使用说明')
              .fontColor(CommonConfig.hintTextColor)
              .fontSize(CommonConfig.fontSize_11)
              .fontWeight(CommonConfig.fontWeight_400)
          }
          .alignItems(HorizontalAlign.Start)

          Blank()
          Image($r("app.media.pink_book_floating"))
            .height(54)
        }
        .width(100)
        .flexGrow(1)
        .flexShrink(1)
        .borderRadius(16)
        .alignItems(VerticalAlign.Center)
        .padding({
          left: 16,
          right: 16,
          top: 13,
          bottom: 13
        })
        .backgroundImage($r('app.media.Rectangle_529'))
        .backgroundImageSize({ width: '100%', height: '100%' })

        Row() {
          Column() {
            Text('联系方式')
              .fontColor('#E74C3A')
              .fontSize(CommonConfig.fontSize_14)
              .fontWeight(CommonConfig.fontWeight_700)
              .margin({ bottom: 4 })
            Text('咨询更多详情')
              .fontColor(CommonConfig.hintTextColor)
              .fontSize(CommonConfig.fontSize_11)
              .fontWeight(CommonConfig.fontWeight_400)
          }
          .alignItems(HorizontalAlign.Start)


          Blank()
          Image($r("app.media.contacts"))
            .height(54)
        }
        .width(100)
        .flexGrow(1)
        .flexShrink(1)
        .borderRadius(16)
        .alignItems(VerticalAlign.Center)
        .padding({
          left: 16,
          right: 16,
          top: 13,
          bottom: 13
        })
        .backgroundImage($r('app.media.Rectangle_530'))
        .backgroundImageSize({ width: '100%', height: '100%' })
        .onClick(()=>{
          this.pageInfo.pushPath({"name":'ContactInformation'})
        })
      }

    }
    .alignItems(HorizontalAlign.Start)
    .height('100%')
    .width('100%')
    .padding({ top: 8 })

  }

  // 强制更新方法
  private forceUpdate() {
    // 通过改变专门的触发器状态来强制重新渲染，避免影响弹窗显示
    this.forceUpdateTrigger += 1
  }

  aboutToAppear() {
    console.log('DeviceSettings: 页面即将显示，当前设备数量:', this.devices.length)
    // 确保设备列表数据同步
    if (this.devicesLink && Array.isArray(this.devicesLink)) {
      this.devices = [...this.devicesLink]
    } else {
      this.devices = []
    }
  }

  onDevicesChange() {
    console.log('DeviceSettings: 设备列表发生变化，当前设备数量:', this.devicesLink ? this.devicesLink.length : 0)
    // 将StorageLink的值同步到State，触发UI重新渲染
    if (this.devicesLink && Array.isArray(this.devicesLink)) {
      this.devices = [...this.devicesLink]
    } else {
      this.devices = []
    }
    // 强制触发UI更新
    this.forceUpdate()
  }

  getdeviesImage(getModelInfo: getModelInfoModel): string {
    if (!getModelInfo || !getModelInfo.images) {
      return ''
    }
    for (let item of getModelInfo.images) {
      console.error('设备图片', JSON.stringify((item as imagesModel)[this.languages]))
      if ((item as imagesModel)[this.languages]) {
        // console.log('****************************************1', JSON.stringify(item))
        return ((item as imagesModel)[this.languages][0] as imagesDataModel)['img']
      }
    }
    return ''
  }
}