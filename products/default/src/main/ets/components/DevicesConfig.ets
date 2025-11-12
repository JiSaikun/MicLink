import { ConnectDevice, _getModelInfo, DeviceInfo, KeyPressType, getModelInfo_Params, DeviceArrayType } from 'mouse'
import { ConfigPage1 } from './ConfigPage1'
import { ConfigPage2 } from './ConfigPage2'
import { ConfigPage3 } from './ConfigPage3'
import { resetCustomerKey_Params } from '../model/UserModel'
import { _resetCustomerKey } from '../viewmodel/UserViewModel'

import {
  getModelInfoModel, imagesModel, imagesDataModel, Languages
} from 'config' //获取设备按键信息
import { DeviceArrayType_Ble } from 'bluetooth'

@Component
export struct DevicesConfig {
  @Link isShowConfig: boolean //控制显隐状态
  @StorageLink('devices') devices: DeviceArrayType_Ble[] = []
  @Consume device_isBle: boolean //该设备是否是蓝牙连接
  @State mouseconfig: DeviceInfo | null = null //鼠标信息
  @State currIndex: number = 0
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State configsList: string[] =
    [Languages.smartSetup[this.languages], Languages.keySetup[this.languages], Languages.deviceSetup[this.languages]]
  @State reportRate_currIndex: number = 0
  @State DPI_currIndex: number = 0
  @State currLED: boolean = true
  @State getModelInfo: getModelInfoModel =
    AppStorage.get('getModelInfo') as getModelInfoModel

  onDidBuild(): void {
    this.data_init()
  }

  aboutToAppear(): void {
    const deviceIndex = AppStorage.get('device_show_currIndex') as number || 0

    if (this.device_isBle) { //蓝牙设备信息
      if (this.devices && deviceIndex >= 0 && deviceIndex < this.devices.length && this.devices[deviceIndex]) {
        this.mouseconfig = this.devices[deviceIndex].mouseconfig as DeviceInfo //鼠标信息
      } else {
        console.error('蓝牙设备索引无效或设备不存在:', deviceIndex, this.devices?.length)
        this.mouseconfig = null
      }
    } else {
      if (ConnectDevice.Communication && deviceIndex >= 0 && deviceIndex < ConnectDevice.Communication.length && ConnectDevice.Communication[deviceIndex]) {
        this.mouseconfig = ConnectDevice.Communication[deviceIndex].mouseconfig as DeviceInfo
      } else {
        console.error('2.4G设备索引无效或设备不存在:', deviceIndex, ConnectDevice.Communication?.length)
        this.mouseconfig = null
      }
    }
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
          .objectFit(ImageFit.Contain)
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
            this.handleKeyReset()
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
            ConfigPage2({ isShowConfig: this.isShowConfig })
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
    .width('100%')
    .height('100%')
  }

  getdeviesImage(): string {
    for (let item of this.getModelInfo.images) {
      if ((item as imagesModel)[this.languages]) {
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
    this.DPI_currIndex = this.mouseconfig?.dpiLevel as number - 1
    this.currLED = this.mouseconfig?.atmosphereLight as boolean
  }

  // 新增：处理按键重置的独立方法
  private handleKeyReset() {
    let param: resetCustomerKey_Params = {
      sno: this.mouseconfig?.sn as string, //设备号
      userModelId: this.getModelInfo.id.toString()//按鍵模式ID
    }

    _resetCustomerKey(param)
      .then(res => {
        console.log('重设按键模式', JSON.stringify(res))
        this.refreshModelInfo()
      })
      .catch(() => {
        console.error('重设按键模式失败:')
      })
  }

  // 新增：刷新模型信息的独立方法
  private refreshModelInfo() {
    const params: getModelInfo_Params = {
      languageCode: '',
      productCode: this.device_isBle ?
      this.devices[AppStorage.get('device_show_currIndex') as number].BlueTooth_devices.deviceInfo.productType.toString() :
      ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].Communication.deviceInfo.productType.toString(),
      sno: this.device_isBle ?
      this.devices[AppStorage.get('device_show_currIndex') as number].BlueTooth_devices.deviceInfo.sn :
      ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].Communication.deviceInfo.sn
    }

    _getModelInfo(params).then((res) => {
      console.log('获取用户按键模式详情数据', JSON.stringify(res.data))
      if (res.status === 200) {
        let getModelInfo: getModelInfoModel = res.data as getModelInfoModel
        // 更新数据
        if (this.device_isBle) {
          this.devices[AppStorage.get('device_show_currIndex') as number].getModelInfo = getModelInfo
        } else {
          ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].getModelInfo = getModelInfo
        }
        AppStorage.setOrCreate('getModelInfo', getModelInfo)
        if (this.device_isBle) {
          this.devices[AppStorage.get('device_show_currIndex') as number].KeymethodConfig = []
        } else {
          // 重置 KeymethodConfig，让 ConfigPage2 重新初始化
          ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].KeymethodConfig = []
        }

        console.log('数据重置完成，ConfigPage2 将自动重新初始化')
      }
    }).catch(() => {
      console.error('获取模型信息失败:',)
    })
  }
}