import { DeviceArrayType_Ble } from "bluetooth"
import { getModelInfoModel, imagesDataModel, imagesModel } from "config"
import { ConnectDevice, DeviceInfo } from "mouse"
import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"
import { TopTitle } from "../common/TopTitle"
import { ButtonConfiguration } from "../view/ButtonConfiguration"
import { DeviceSettings } from "../view/DeviceSettings"
import { SmartSettings } from "../view/SmartSettings"

@Builder
export function DevicesConfigBuilder() {
  DevicesConfig()
}

@Preview
@Component
struct DevicesConfig {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @Consume('pageInfo') pageInfo: NavPathStack
  @StorageLink('languages') languages: string = 'ZH_CN'
  @StorageLink('devices') devices: DeviceArrayType_Ble[] = []
  @State device_isBle: boolean = false //该设备是否是蓝牙连接
  @State currIndex: number = 0
  @State TabsData: string[] =
    [Languages.smartSetup[this.languages], Languages.keySetup[this.languages], Languages.deviceSetup[this.languages]]
  private controller: TabsController = new TabsController()
  @State mouseconfig: DeviceInfo | null = null //鼠标信息
  @State reportRate_currIndex: number = 0
  @State DPI_currIndex: number = 0
  @State currLED: boolean = true
  @State getModelInfo: getModelInfoModel =
    AppStorage.get('getModelInfo') as getModelInfoModel
  onDidBuild(): void {
    this.data_init()
  }
  aboutToAppear(): void {
    // console.log(JSON.stringify(this.pageInfo.getParamByName('DevicesConfig')))
    this.device_isBle = this.pageInfo.getParamByName('DevicesConfig')[0] as boolean
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
  getdeviesImage(): string {
    if (!this.getModelInfo || !this.getModelInfo.images) {
      return ''
    }
    for (let item of this.getModelInfo.images) {
      if ((item as imagesModel)[this.languages]) {
        return ((item as imagesModel)[this.languages][0] as imagesDataModel)['img']
      }
    }
    return ''
  }



  build() {
    NavDestination() {
      // TopTitle({ title: Languages.editProfile[this.languages] })
      TopTitle({ title: "设备设置" })
        .margin({ bottom: 12 })
      Flex() {
        ForEach(this.TabsData, (item: string, index) => {
          Text(item)
            .padding(8)
            .fontSize(CommonConfig.fontSize_14)
            .fontColor(CommonConfig.hintTextColor_select)
            .fontWeight(CommonConfig.fontWeight_400)
            .borderRadius(6)
            .backgroundColor(this.currIndex === index ? Color.White : '')
            .flexShrink(1)
            .flexGrow(1)
            .onClick(() => {
              this.currIndex = index
            })
        }, (item: string) => item)
      }
      .backgroundColor("#EAEAEA")
      .padding(2)
      .width('100%')
      .margin({ bottom: 12 })

      Tabs({ controller: this.controller }) {
        TabContent() {
          SmartSettings({device_isBle:this.device_isBle})
        }

        TabContent() {
          ButtonConfiguration({device_isBle:this.device_isBle})
        }

        TabContent() {
          DeviceSettings({device_isBle:this.device_isBle})
        }

      }
      .scrollable(false)
      .barHeight(0)
      .barWidth(0)

    }
    .padding({ left: 16, right: 16, bottom: 16 })
    .backgroundColor(CommonConfig.commonBackgroundColor)
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}
