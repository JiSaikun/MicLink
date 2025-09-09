// 导入usbManager模块。
import { usbManager } from '@kit.BasicServicesKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct Index {
  @State deviceList: usbManager.USBDevice[] = []
  @State pipe: usbManager.USBDevicePipe | null ={"busNum":2,"devAddress":9}
  @State interface1: usbManager.USBInterface | null = {"id":0,"protocol":2,"clazz":3,"subClass":1,"alternateSetting":0,"name":" ","endpoints":[{"address":130,"attributes":3,"interval":1,"maxPacketSize":8,"direction":128,"number":2,"type":3,"interfaceId":0}]}

  build() {
    Row() {
      Column() {
        Button('获取USB设备列表')
          .onClick(() => {
            // 获取设备列表。
            let deviceList: Array<usbManager.USBDevice> = usbManager.getDevices();
            console.info(`deviceList: ${deviceList}`, JSON.stringify(deviceList));
            if (deviceList.length === 0) {
              console.error('deviceList is empty');
              return;
            }
            this.deviceList = deviceList
          })
        Button('获取设备操作权限。')
          .onClick(() => {
            let deviceName: string = this.deviceList[0].name;
            // 申请操作指定的device的操作权限。
            usbManager.requestRight(deviceName).then((hasRight: boolean) => {
              console.info("usb device request right result: " + hasRight);
            }).catch((error: BusinessError) => {
              console.error(`usb device request right failed : ${error}`);
            });
          })
        Button('打开Device设备。')
          .onClick(() => {
            try {
              // 打开设备，获取数据传输通道。
              this.pipe = usbManager.connectDevice(this.deviceList[0]);
              this.interface1 = this.deviceList[0].configs[0].interfaces[0];
              console.log('===================', JSON.stringify(this.pipe))
              console.log('===================', JSON.stringify(this.interface1))
              /*
               打开对应接口，在设备信息（deviceList）中选取对应的interface。
              interface1为设备配置中的一个接口。
              */
              usbManager.claimInterface(this.pipe, this.interface1, true);
            } catch (e) {
              console.log(e, '==============================失败')
            }
          })
        Button('数据传输。')
          .onClick(() => {
            try {
              /*
                构造控制传输参数
              */
              let param: usbManager.USBDeviceRequestParams = {
                bmRequestType: 0x61, //0x80指一次由设备到主机的标准请求命令
                bRequest: 0x06, //0x06指获取描述符
                wValue: 0x01 << 8 | 0, //该值为2个字节，高字节指描述符类型，此处0x01指设备描述符；低字节指描述符索引，设备描述符不涉及，填0
                wIndex: 0, //索引值，可填0
                wLength: 18, //描述符的长度，此处18表示设备描述符长度，最大支持1024
                data: new Uint8Array(100000)
              };

              usbManager.usbControlTransfer(this.pipe, param).then((ret: number) => {
                console.info(`usbControlTransfer = ${ret}`);
              })
            } catch (e) {
              console.log(e, '==============================失败')
            }
          })
        Button('释放接口，关闭设备。')
          .onClick(() => {
            try {
              usbManager.releaseInterface(this.pipe, this.interface1);
              usbManager.closePipe(this.pipe);
            } catch (e) {
              console.log(e, '==============================失败')
            }
          })

      }
      .width('100%')
    }
    .height('100%')
  }
}
