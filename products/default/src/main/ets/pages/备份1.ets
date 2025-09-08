import { usbManager } from '@kit.BasicServicesKit';

@Entry
@Component
struct Index {
  @State devicesList: usbManager.USBDevice[] = []
  @State pipe: usbManager.USBDevicePipe | null = null
  @State usbInterface: usbManager.USBInterface | undefined = undefined
  @State usbEndpoint: usbManager.USBEndpoint | undefined = undefined
  @State transferParams: usbManager.UsbDataTransferParams | undefined = undefined

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
          let devicePipe: usbManager.USBDevicePipe = this.pipe as usbManager.USBDevicePipe;
          let usbConfigs: usbManager.USBConfiguration[] = this.devicesList[0].configs;
          let usbInterfaces: usbManager.USBInterface[] = [];
          let usbEndpoints: usbManager.USBEndpoint[] = [];

          for (let i = 0; i < usbConfigs.length; i++) {
            usbInterfaces = usbConfigs[i].interfaces;
            for (let j = 0; j < usbInterfaces.length; j++) {
              usbEndpoints = usbInterfaces[j].endpoints;
              this.usbEndpoint = usbEndpoints.find((value) => {
                return value.direction === 128 && value.type === 3; // 2 表示中断传输
              })
              if (this.usbEndpoint !== undefined) {
                this.usbInterface = usbInterfaces[j];
                break;
              }
            }
          }
          if (this.usbEndpoint === undefined) {
            console.error(`get usbEndpoint error`)
            return;
          }
        })

      Button('连接设备，注册通信接口')
        .onClick(() => {
          // if (!this.pipe || !this.usbInterface) {
          //   console.error('Pipe or interface not initialized');
          //   return;
          // }
          //
          // let claimInterfaceResult: number = usbManager.claimInterface(this.pipe, this.usbInterface, false);
          // if (claimInterfaceResult !== 0) {
          //   console.error(`claimInterface error = ${claimInterfaceResult}`)
          //   return;
          // }
        })

      Button('传输数据')
        .onClick(() => {
          let a=usbManager.getAccessoryList()
          console.log('================================================',JSON.stringify(a))
        })

      Button('释放接口')
        .onClick(() => {
          if (this.transferParams) {
            console.log(JSON.stringify(this.transferParams))
            // usbManager.usbCancelTransfer(this.transferParams);
          }
          if (this.pipe && this.usbInterface) {
            usbManager.releaseInterface(this.pipe, this.usbInterface);
          }
          if (this.pipe) {
            usbManager.closePipe(this.pipe);
          }
        })
    }
  }
}