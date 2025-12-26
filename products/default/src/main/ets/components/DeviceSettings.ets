import { CursorController, LengthMetrics } from "@kit.ArkUI"
import { connectDevice, DeviceArrayType_Ble } from "bluetooth"
import { getModelInfoModel, imagesDataModel, imagesModel, Languages, sideFunctionList } from "config"
import { DeviceArrayType, DeviceInfo, MouseICType, ConnectDevice } from 'mouse'
import { DevicesConfig } from './DevicesConfig'
import { common } from "@kit.AbilityKit"
import { pointer } from "@kit.InputKit"

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
  @State forceUpdateTrigger: number = 0 // 专门用于强制UI更新的触发器
  // @StorageLink("mouseconfig") mouseconfig: DeviceInfo | null = null //鼠标信息
  @StorageLink('getModelInfo') getModelInfo: getModelInfoModel =
    AppStorage.get('getModelInfo') as getModelInfoModel
  @StorageLink('devicesList') devicesList: DeviceArrayType[] = []
  @Watch('onDevicesChange') @StorageLink('devices') devicesLink: DeviceArrayType_Ble[] = []
  @State devices: DeviceArrayType_Ble[] = []
  @Provide device_isBle: boolean = false //该设备是否是蓝牙连接
  cursorCustom: CursorController = this.getUIContext().getCursorController();
  @StorageLink("Unconnected") Unconnected: boolean = false //是否有设备连接
  @StorageLink("sideFunctionList") sideFunctionList: sideFunctionList | null = null

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
                  console.info('开始重新扫描蓝牙设备，清空现有连接');
                  for (let item of this.devices) {
                    console.info('关闭设备连接:', item.name);
                    item.BlueTooth_devices.closeconnectDevice()
                  }
                  AppStorage.setOrCreate('isBluetoothConnect_state', false)
                  // 延迟一点时间确保连接完全关闭
                  setTimeout(() => {
                    AppStorage.setOrCreate('devices', [])
                    console.info('设备列表已清空，开始重新扫描');

                    // 强制触发设备列表变化监听，确保UI更新
                    const tempDevices = AppStorage.get('devices') as DeviceArrayType_Ble[] || [];
                    AppStorage.setOrCreate('devices', [...tempDevices]);

                    // 在扫描开始后，设置一个定时器来强制更新UI
                    let lastDeviceCount = 0;
                    const updateTimer = setInterval(() => {
                      const currentDevices = AppStorage.get('devices') as DeviceArrayType_Ble[] || [];
                      if (currentDevices.length > lastDeviceCount) {
                        console.log('检测到设备数量增加，强制更新UI', currentDevices.length, '->', lastDeviceCount);
                        this.devices = [...currentDevices];
                        this.forceUpdate();
                        lastDeviceCount = currentDevices.length;
                      }
                      // 如果设备数量没有变化，也强制更新一次确保UI同步
                      if (currentDevices.length > 0 && currentDevices.length === lastDeviceCount) {
                        console.log('设备数量未变，强制同步UI');
                        this.devices = [...currentDevices];
                        this.forceUpdate();
                        clearInterval(updateTimer);
                      }
                    }, 300); // 每300ms检查一次，更频繁

                    // 8秒后停止检查，避免无限循环
                    setTimeout(() => {
                      clearInterval(updateTimer);
                    }, 8000);

                    const context: common.UIAbilityContext =
                      this.getUIContext().getHostContext() as common.UIAbilityContext;
                    connectDevice(context)
                  }, 1000); // 等待1秒确保连接完全关闭
                }
              })
          }
          .alignItems(VerticalAlign.Center)
          .padding({ bottom: 15, left: 5, right: 10 })
          .width('100%')

          // .borderWidth(1)
          if (this.Unconnected && this.sideFunctionList) {
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
                        .visibility(Visibility.Visible) // 总是显示设备名称

                        // Text('未连接')
                        Text(Languages.notConnected[this.languages])
                          .fontSize(14)
                          .fontWeight(400)
                          .lineHeight(14)
                          .fontColor('#eb5e12')
                          .visibility(item.getModelInfo ? Visibility.None : Visibility.Visible)
                      }
                      .width('100%')

                      Image(item.getModelInfo && (item.getModelInfo as getModelInfoModel).images &&
                      (item.getModelInfo as getModelInfoModel).images.length ?
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
                          .padding(4)
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
                    .onHover((flag) => {
                      if (flag) {
                        this.cursorCustom.setCursor(pointer.PointerStyle.HAND_POINTING);
                      } else {
                        console.info("restoreDefault");
                        this.cursorCustom.restoreDefault();
                      }
                    })
                    .onClick(() => {
                      if (item.getModelInfo) {
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
                        .visibility(Visibility.Visible) // 总是显示设备名称

                        // Text('未连接')
                        Text(Languages.notConnected[this.languages])
                          .fontSize(14)
                          .fontWeight(400)
                          .lineHeight(14)
                          .fontColor('#eb5e12')
                          .visibility(item.getModelInfo ? Visibility.None : Visibility.Visible)
                      }
                      .width('100%')

                      Image(item.getModelInfo && (item.getModelInfo as getModelInfoModel).images &&
                      (item.getModelInfo as getModelInfoModel).images.length ?
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
                    .onHover((flag) => {
                      if (flag) {
                        this.cursorCustom.setCursor(pointer.PointerStyle.HAND_POINTING);
                      } else {
                        console.info("restoreDefault");
                        this.cursorCustom.restoreDefault();
                      }
                    })
                    .onClick(() => {
                      if (item.getModelInfo) { // 只要有设备信息就可以点击
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
          } else {
            Column({space:24}) {
              Image($r('app.media.Unconnected'))
                .width(371)
              Text('未检测到设备')
                .fontColor('#BBBDBF')
                .fontWeight(500)
                .fontSize(18)
              Text('请检查设备是否开启，或连接状态正常。')
                .fontColor('#BBBDBF')
                .fontWeight(400)
                .fontSize(14)
            }.layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          }

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
    }.id(this.forceUpdateTrigger.toString())

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
    for (let item of getModelInfo.images) {
      console.error('设备图片', JSON.stringify((item as imagesModel)[this.languages]))
      if ((item as imagesModel)["EN_US"]) {
        // console.log('****************************************1', JSON.stringify(item))
        return ((item as imagesModel)["EN_US"][0] as imagesDataModel)['img']
      }
    }
    return ''
  }
}