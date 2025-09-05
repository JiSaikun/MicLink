import { deviceManager } from '@kit.DriverDevelopmentKit';
import {Device,BusinessError} from '@kit.BasicServicesKit';
import { rpc } from '@kit.IPCKit';
import { inputDevice } from '@kit.InputKit';
interface devicesModel{
  busType:number,
  deviceId:number,
  description:string,
  vendorId:number,
  productId:number,
}
interface DataType {
  deviceId : number;
  remote : rpc.IRemoteObject;
}
@Entry
@Component
struct Index {
  @State devices:devicesModel[] =[]
  build() {
    Row() {
      Column() {
        Button('获取USB设备列表')
          .onClick(()=>{
            console.log('================================0')
            const devices:Array<Readonly<Device>>= deviceManager.queryDevices()
            console.log('================================获取设备id',JSON.stringify(devices))
            this.devices =devices as devicesModel[]
          })
        ForEach(this.devices,(item:devicesModel)=>{
          Text(JSON.stringify(item))
        },(item:devicesModel)=>item.deviceId.toString())
        Button('绑定设备')
          .onClick(()=>{
            try {
              deviceManager.bindDevice(this.devices[0].deviceId, (error : BusinessError, data : number) => {
                console.error(`绑定设备断开`);
              }, (error : BusinessError, data : DataType) => {
                console.log(this.devices[0].deviceId.toString())
                if (error) {
                  console.error(`bindDevice async fail. Code is ${error.code}, message is ${error.message}`);
                  return;
                }
                console.info(`bindDevice success`);
              });
            } catch (error) {
              console.error(`bindDevice fail. Code is ${error.code}, message is ${error.message}`);
            }
          })

      }
      .width('100%')
    }
    .height('100%')
  }
}
