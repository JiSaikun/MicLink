import { usbManager } from '@kit.BasicServicesKit';

@Entry
@Component
struct Index {
  @State devicesList: usbManager.USBDevice[] = []
  @State pipe: usbManager.USBDevicePipe | null = null

  build() {
    Column() {
      Button('获取设备')
        .onClick(() => {
          this.devicesList = usbManager.getDevices()
          console.log(JSON.stringify(this.devicesList))
        })

      Button('判断是否有权访问该设备')
        .onClick(() => {
          if (this.devicesList.length > 0) {
            let hasRight = usbManager.hasRight(this.devicesList[0].name)
            console.log(JSON.stringify(hasRight))
            if (!hasRight) {
              usbManager.requestRight(this.devicesList[0].name)
            }
          }
        })

      Button('打开USB设备')
        .onClick(() => {
          if (this.devicesList.length > 0) {
            this.pipe = usbManager.connectDevice(this.devicesList[0])
            console.log(JSON.stringify(this.pipe))
          }
        })

      Button('声明接口控制权')
        .onClick(() => {
          if (this.pipe && this.devicesList.length > 0 && this.devicesList[0].configs) {
            const config = this.devicesList[0].configs[0]; // 获取第一个配置
            if (config && config.interfaces && config.interfaces.length > 0) {
              let a = usbManager.claimInterface(this.pipe, config.interfaces[0], false)
              console.log(JSON.stringify(a))
            }
          }
        })

      Button('控制传输')
        .onClick(() => {
          if (this.pipe) {
            let param: usbManager.USBDeviceRequestParams = {
              bmRequestType: 0x40,
              bRequest: 0x01,
              wValue:0,
              wIndex: 0,
              wLength: 18,
              data: new Uint8Array(18)
            };

            usbManager.usbControlTransfer(this.pipe, param).then((ret: number) => {
              console.info("usbControlTransfer = " + ret);
            })
          }
        })

      Button('释放接口')
        .onClick(() => {
          if (this.pipe && this.devicesList.length > 0 && this.devicesList[0].configs) {
            const config = this.devicesList[0].configs[0]; // 获取第一个配置
            if (config && config.interfaces && config.interfaces.length > 0) {
              usbManager.releaseInterface(this.pipe, config.interfaces[0]);
              usbManager.closePipe(this.pipe);
              this.pipe = null; // 清空pipe引用
            }
          }
        })
    }
  }
}