import { deviceManager } from '@kit.DriverDevelopmentKit';
import {Device,BusinessError} from '@kit.BasicServicesKit';
import { inputDevice } from '@kit.InputKit';
interface devicesModel{
  busType:number,
  deviceId:number,
  description:string,
  vendorId:number,
  productId:number,
}
// @Entry
// @Component
// struct Index {
//   aboutToAppear(): void {
//     console.log('================================0')
//     const devices:Array<Readonly<Device>>= deviceManager.queryDevices()
//     console.log('================================获取设备id',JSON.stringify(devices))
//   }
//   build() {
//     Row() {
//       Column() {
//         Text('Hello') // 显示"Hello"
//           .fontSize(60)
//           .fontWeight(FontWeight.Bold)
//           .onClick(() => { // 点击"Hello"，与远程对象通信，显示"Hello World"
//           })
//       }
//       .width('100%')
//     }
//     .height('100%')
//   }
// }
@Entry
@Component
struct Index {
  @State devices:devicesModel[]=[
    {
      busType: 0,
      deviceId: 0,
      description: '',
      vendorId: 0,
      productId: 0,
    }
  ]
  aboutToAppear(): void {
    // 获取输入设备id为1的设备信息。
    try {
      console.log('================================USB设备列表')
      const devices:Array<Readonly<Device>>= deviceManager.queryDevices()
      this.devices=devices as devicesModel[]
      console.log('================================获取设备id',JSON.stringify(this.devices))

      inputDevice.getDeviceInfo((this.devices[0] as devicesModel).deviceId)
        .then((deviceData: inputDevice.InputDeviceData) => {
        console.log('获取指定id的输入设备信息，使用Promise异步回调',`Device info: ${JSON.stringify(deviceData)}`);
      });
    } catch (error) {
      console.error(`Failed to get device info, error: ${JSON.stringify(error, [`code`, `message`])}`);
    }

    let isPhysicalKeyboardExist = true;
    /*
    热插拔:检测鼠标的插入与拔出
     */
    try {
      inputDevice.on("change", (data: inputDevice.DeviceListener) => {
        console.log(`Device event info: ${JSON.stringify(data)}`);
        inputDevice.getKeyboardType(data.deviceId, (err: Error, type: inputDevice.KeyboardType) => {
          console.log("The keyboard type is: " + type);
          if (type == inputDevice.KeyboardType.ALPHABETIC_KEYBOARD && data.type == 'add') {
            // 监听物理键盘已连接。
            isPhysicalKeyboardExist = true;
          } else if (type == inputDevice.KeyboardType.ALPHABETIC_KEYBOARD && data.type == 'remove') {
            // 监听物理键盘已断开。
            isPhysicalKeyboardExist = false;
          }
        });
      });
      // 根据isPhysicalKeyboardExist的值决定软键盘是否弹出。
    } catch (error) {
      console.error(`Get device info failed, error: ${JSON.stringify(error, [`code`, `message`])}`);
    }
    /*
    查询指定输入设备是否支持指定按键，使用Callback异步回调。
     */
    // 查询id为1的输入设备对于17、22和2055按键的支持情况。
    try {
      inputDevice.supportKeys((this.devices[0] as devicesModel).deviceId, [17, 22, 2055], (error: Error, supportResult: Array<Boolean>) => {
        console.log(`Query result: ${JSON.stringify(supportResult)}`);
      });
    } catch (error) {
      console.error(`Query failed, error: ${JSON.stringify(error, [`code`, `message`])}`);
    }
    /*
    获取输入设备的键盘类型，如全键盘、小键盘等，使用callback异步回调。输入设备的键盘类型以接口返回结果为准。
     */
    // 查询id为1的输入设备的键盘类型。
    try {
      inputDevice.getKeyboardType((this.devices[0] as devicesModel).deviceId, (error: Error, type: Number) => {
        if (error) {
          console.error(`Failed to get keyboard type, error: ${JSON.stringify(error, [`code`, `message`])}`);
          return;
        }
        console.log(`Keyboard type: ${JSON.stringify(type)}`);
      });
    } catch (error) {
      console.error(`Failed to get keyboard type, error: ${JSON.stringify(error, [`code`, `message`])}`);
    }
    /*
    检查功能键（如：CapsLock键）是否使能。使用Promise异步回调。
     */
    try {
      inputDevice.setFunctionKeyEnabled(inputDevice.FunctionKey.CAPS_LOCK, true).then(() => {
        console.info(`Set capslock state success`);
      }).catch((error: BusinessError) => {
        console.error(`Set capslock state failed, error=${JSON.stringify(error)}`);
      });
    } catch (error) {
      console.error(`Set capslock enable error`);
    }

  }
  build() {
    Row() {
      Column() {
        Text('Hello') // 显示"Hello"
          .fontSize(60)
          .fontWeight(FontWeight.Bold)
          .onClick(() => { // 点击"Hello"，与远程对象通信，显示"Hello World"
          })
      }
      .width('100%')
    }
    .height('100%')
  }
}