import { hilog } from '@kit.PerformanceAnalysisKit';
import { deviceManager } from '@kit.DriverDevelopmentKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { rpc } from '@kit.IPCKit';


const REQUEST_CODE: number = 99; // 自定义通信Code，此处仅供参考
const productId: number = 4258;  // 请声明连接的USB设备的productId
const vendorId: number = 4817;   // 请声明连接的USB设备的vendorId

@Entry
@Component
struct Index {
  @State message: string = 'Hello';
  private remote: rpc.IRemoteObject | null = null;
  private async queryTargetDeviceId(): Promise<number> {//定义查询设备接口，通过queryDevices获取目标设备ID
    try {
      const devices:   Array<deviceManager.Device> = deviceManager.queryDevices(deviceManager.BusType.USB);
      console.log('============所有USB外设设备列表',typeof devices,JSON.stringify(devices),devices.length)
      const index = devices.findIndex((item: deviceManager.Device) => {
        let usbDevice = item as deviceManager.USBDevice;
        // 如果不知道设备productId和vendorId，可以通过该日志查看连接的usb设备的相关信息
        hilog.info(0, 'USB设备列表====',
          `usbDevice.productId = ${usbDevice.productId}, usbDevice.vendorId = ${usbDevice.vendorId}`);
        return usbDevice.productId === productId && usbDevice.vendorId === vendorId;
      });
      if (index < 0) {
        hilog.error(0, 'testTag', 'can not find device','没有找到指定设备');
        return -1;
      }
      return devices[index].deviceId;
    } catch (error) {
      hilog.error(0, 'testTag', `queryDevice failed, err: ${JSON.stringify(error)}`);
    }
    return -1;
  }

  private async getDriverRemote(deviceId: number): Promise<rpc.IRemoteObject | null> {
    try {
      let remoteDeviceDriver: deviceManager.RemoteDeviceDriver = await deviceManager.bindDevice(deviceId,
        (err: BusinessError, id: number) => {
          hilog.info(0, 'testTag', `device[${id}] id disconnect, err: ${JSON.stringify(err)}`);
        });
      return remoteDeviceDriver.remote;
    } catch (error) {
      hilog.error(0, 'testTag', `bindDriverWithDeviceId failed, err: ${JSON.stringify(error)}`);
    }
    return null;
  }

  private async communicateWithRemote(): Promise<void> {
    const deviceId: number = await this.queryTargetDeviceId();
    if (deviceId < 0) {
      hilog.error(0, 'testTag', 'can not find target device');
      return;
    }
    this.remote = await this.getDriverRemote(deviceId);
    if (this.remote === null) {
      hilog.error(0, 'testTag', `getDriverRemote failed`);
      return;
    }

    let option = new rpc.MessageOption();
    let data = new rpc.MessageSequence();
    let reply = new rpc.MessageSequence();

    // 向驱动发送信息"Hello"
    data.writeString(this.message);

    try {
      await this.remote.sendMessageRequest(REQUEST_CODE, data, reply, option);
      console.log('返回结果',reply.readString())
      // 获取驱动返回信息"Hello world"
      this.message = reply.readString();
      hilog.info(0, 'testTag', `sendMessageRequest, message: ${this.message}`);
    } catch (error) {
      hilog.error(0, 'testTag', `sendMessageRequest failed, err: ${JSON.stringify(error)}`);
    }
  }

  build() {
    Row() {
      Column() {
        Text(this.message) // 显示"Hello"
          .fontSize(60)
          .fontWeight(FontWeight.Bold)
          .onClick(() => { // 点击"Hello"，与远程对象通信，显示"Hello World"
            this.communicateWithRemote();
          })
      }
      .width('100%')
    }
    .height('100%')
  }
}
