import { deviceManager } from '@kit.DriverDevelopmentKit';
import {Device} from '@kit.BasicServicesKit';
import { inputDevice } from '@kit.InputKit';
interface devicesModel{
  busType:number,
  deviceId:number,
  description:string,
  vendorId:number,
  productId:number,
}
@Entry
@Component
struct Index {
  aboutToAppear(): void {
    console.log('================================0')
    const devices:Array<Readonly<Device>>= deviceManager.queryDevices()
    console.log('================================获取设备id',JSON.stringify(devices))
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
