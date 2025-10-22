import { LengthMetrics } from "@kit.ArkUI"
import { getModelInfoModel, imagesDataModel, imagesModel } from "config"
import { DeviceArrayType, DeviceInfo, MouseICType, ConnectDevice } from 'mouse'
import { DevicesConfig } from './DevicesConfig'

interface DeviceInfo_Model {
  deviceModel: string, //设备型号
  ConnectionStatus: boolean, //连接状态
  icon: string, //设备图片
  connectionmethod: connectionmethod_Model //连接方式
}

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

  a() {
    console.error('设备长度', this.devicesList.length)
    if (this.devicesList.length) {
      console.error('设备长度::', this.devicesList[0].getModelInfo)
    }
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Text('设备')
            .fontWeight(600)
            .lineHeight(32)
            .fontSize(32)
            .fontColor('#31373d')
          Blank()
          Image($r('app.media.Frame_2129'))
            .width(32)
            .height(32)
        }
        .alignItems(VerticalAlign.Center)
        .padding({ bottom: 15, left: 5, right: 10 })
        .width('100%')

        // .borderWidth(1)

        Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.px(30), cross: LengthMetrics.px(30) } }) {
          ForEach(this.devicesList, (item: DeviceArrayType, index) => {
            if (item.getModelInfo) {
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
                    Text("MIFI-无线")
                      .margin({ left: 5 })
                      .fontSize(18)
                      .fontWeight(500)
                      .lineHeight(18)
                      .fontColor('#31373d')
                  }
                  .visibility(item.getModelInfo?.id ? Visibility.Visible : Visibility.None)

                  Text('未连接')
                    .fontSize(14)
                    .fontWeight(400)
                    .lineHeight(14)
                    .fontColor('#eb5e12')
                    .visibility(item.getModelInfo?.id ? Visibility.None : Visibility.Visible)
                }
                .width('100%')

                Image(this.getdeviesImage(item.getModelInfo as getModelInfoModel))
                // Image($r('app.media.HM_001_white'))
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
              .flexGrow(1)
              .flexShrink(1)
              .width(230)
              .border({ width: 2, color: '#e6e8eb' })
              .onMouse((event?: MouseEvent) => { // 设置Button的onMouse回调
                if (event && !item.getModelInfo?.images) {
                  if (event.stopPropagation) {
                    event.stopPropagation(); // 在Button的onMouse事件中设置阻止冒泡
                  }
                  // console.log('============',JSON.stringify(event))
                  // if (event.button===1) {
                  //   /**
                  //    * 单击左键
                  //    */
                  // }
                }
              })
              .onClick(() => {
                // console.error(this.mouseconfig?.sn,'\n',item.ConnectionStatus,'\n',this.getModelInfo?.images.length)
                // if (item.ConnectionStatus) {
                if (item.mouseconfig?.sn && item.getModelInfo && item.getModelInfo?.images.length) {
                  AppStorage.setOrCreate('device_show_currIndex', index)
                  AppStorage.setOrCreate('getModelInfo',
                    ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].getModelInfo)
                  //设备连接————点击进入配置页面
                  this.isShowConfig = true
                }
              })
            }

          }, (item: DeviceInfo_Model) => item.icon)
          if (ConnectDevice.Communication.length % 3 !== 0) {
            Column()
            // .padding(24)
            // .borderRadius(16)
              .flexGrow(1)
              .flexShrink(1)
              .width(230)
            // .border({ width: 2, color: '#e6e8eb' })
          }
          if (ConnectDevice.Communication.length % 3 === 1) {
            Column()
            // .padding(24)
            // .borderRadius(16)
              .flexGrow(1)
              .flexShrink(1)
              .width(230)
          }
        }
        .width('100%')
        .layoutWeight(1)
      }
      .padding({
        left: 24,
        top: 90,
        right: 24,
        bottom: 24
      })
      .width('100%')
      .height('100%')

      /**
       * 设备详情配置
       */
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
      if ((item as imagesModel)[this.languages]) {
        // console.log('****************************************1', JSON.stringify(item))
        return ((item as imagesModel)[this.languages][0] as imagesDataModel)['img']
      }
    }
    return ''
  }
}