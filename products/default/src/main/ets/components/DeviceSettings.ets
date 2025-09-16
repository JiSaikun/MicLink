import { LengthMetrics } from "@kit.ArkUI"
import { it } from "@ohos/hypium"
import { DeviceInfo, MouseICType } from 'mouse'
import {DevicesConfig}from './DevicesConfig'

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
  @State isShowConfig:boolean=false
  @State deviesList: DeviceInfo_Model[] = [
    {
      deviceModel: 'GM009',
      ConnectionStatus: true,
      icon: 'HM_001_white',
      connectionmethod: {
        Cloud: true,
        USB: true,
        Bluetooth: false
      }
    }, {
    deviceModel: 'GM009',
    ConnectionStatus: false,
    icon: 'N95',
    connectionmethod: {
      Cloud: false,
      USB: false,
      Bluetooth: false
    }
  }, {
    deviceModel: 'GM009',
    ConnectionStatus: false,
    icon: 'dockingStation',
    connectionmethod: {
      Cloud: false,
      USB: false,
      Bluetooth: false
    }
  }
  ]
  @StorageLink("mouseconfig") mouseconfig: DeviceInfo | null = null //鼠标信息

  build() {
    Stack(){
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
        .padding({ bottom: 15,left:5,right:10 })
        .width('100%')
        // .borderWidth(1)

        Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.px(30), cross: LengthMetrics.px(30) } }) {
          ForEach(this.deviesList, (item: DeviceInfo_Model) => {
            Column() {
              Row() {
                Text(item.deviceModel)
                  .fontSize(18)
                  .fontWeight(500)
                  .lineHeight(18)
                  .fontColor('#31373d')
                Blank()
                Row() {
                  if (this.mouseconfig?.batteryLevel as number >= 80) {
                    Image($r('app.media.power_level_full'))
                      .width(20).height(10)
                  } else if (this.mouseconfig?.batteryLevel as number >= 60) {
                    Image($r('app.media.power_level_80'))
                      .width(20).height(10)
                  } else if (this.mouseconfig?.batteryLevel as number >= 40) {
                    Image($r('app.media.power_level_60'))
                      .width(20).height(10)
                  } else if (this.mouseconfig?.batteryLevel as number >= 20) {
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
                .visibility(item.ConnectionStatus ? Visibility.Visible : Visibility.None)

                Text('未连接')
                  .fontSize(14)
                  .fontWeight(400)
                  .lineHeight(14)
                  .fontColor('#eb5e12')
                  .visibility(item.ConnectionStatus ? Visibility.None : Visibility.Visible)
              }
              .width('100%')

              Image($r(`app.media.${item.icon}`))
                .width('100%')
                .margin({ bottom: 15, top: 15 })
              Row(){
                Image($r('app.media.Cloud_true'))
                  .visibility(item.connectionmethod.Cloud?Visibility.Visible:Visibility.None)
                  .margin({left:10}).width(24)
                Image($r('app.media.Cloud_false'))
                  .visibility(item.connectionmethod.Cloud?Visibility.None:Visibility.Visible)
                  .margin({left:10}).width(24)
                Image($r('app.media.USB_true'))
                  .visibility(item.connectionmethod.USB?Visibility.Visible:Visibility.None)
                  .margin({left:10}).width(24)
                Image($r('app.media.USB_false'))
                  .visibility(item.connectionmethod.USB?Visibility.None:Visibility.Visible)
                  .margin({left:10}).width(24)
                Image($r('app.media.Bluetooth_true'))
                  .visibility(item.connectionmethod.Bluetooth?Visibility.Visible:Visibility.None)
                  .margin({left:10}).width(24)
                Image($r('app.media.Bluetooth_false'))
                  .visibility(item.connectionmethod.Bluetooth?Visibility.None:Visibility.Visible)
                  .margin({left:10}).width(24)
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
              if (event&&!item.ConnectionStatus) {
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
            .onClick(()=>{
              if (item.ConnectionStatus) {
                //设备连接————点击进入配置页面
                this.isShowConfig=true
              }
            })
          }, (item: DeviceInfo_Model) => item.icon)
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
      if (this.isShowConfig){
        Row(){
          DevicesConfig({isShowConfig:this.isShowConfig})
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
}