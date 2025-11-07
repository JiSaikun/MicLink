import { a2dp, ble } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { connection } from '@kit.ConnectivityKit';

// // 获取设备连接状态
// try {
//   const a2dpSrc = a2dp.createA2dpSrcProfile();
//   const state = a2dpSrc.getConnectionState('XX:XX:XX:XX:XX:XX'); // 替换为设备MAC
// } catch (err) {
//   console.error(`错误码: ${(err as BusinessError).code}, 错误信息: ${(err as BusinessError).message}`);
// }

const permissions: Array<Permissions> = ['ohos.permission.ACCESS_BLUETOOTH'];
// 使用UIExtensionAbility：将common.UIAbilityContext 替换为common.UIExtensionContext
function reqPermissionsFromUser(permissions: Array<Permissions>, context: common.UIAbilityContext): void {
  let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  // requestPermissionsFromUser会判断权限的授权状态来决定是否唤起弹窗。
  atManager.requestPermissionsFromUser(context, permissions).then((data) => {
    let grantStatus: Array<number> = data.authResults;
    let length: number = grantStatus.length;
    for (let i = 0; i < length; i++) {
      if (grantStatus[i] === 0) {
        // 用户授权，可以继续访问目标操作。
      } else {
        // 当用户拒绝授权时，系统应提示用户必须授予相应权限才能使用当前页面的功能，并指导用户前往系统设置开启所需权限。
        return;
      }
    }
    // 授权成功
  }).catch((err: BusinessError) => {
    console.error(`Failed to request permissions from user. Code is ${err.code}, message is ${err.message}`);
  })
}



@Entry
@Component
struct I {
  aboutToAppear() {
    // 使用UIExtensionAbility：将common.UIAbilityContext 替换为common.UIExtensionContext
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    reqPermissionsFromUser(permissions, context);
  }
  build() {
    Button('获取蓝牙连接列表')
      .onClick(()=>{
        try {
          // 获取已配对设备的地址数组
          let pairedDevices: Array<string> = connection.getPairedDevices();
          console.log('Paired devices:', pairedDevices); // 例如：['11:22:33:AA:BB:FF', '68:13:24:79:4C:8C']
          for (let item of pairedDevices){
            // 获取对端蓝牙设备的名称
            let remoteDeviceName: string = connection.getRemoteDeviceName(item, true);
            console.log('Paired devices1:', remoteDeviceName); // 例如：['11:22:33:AA:BB:FF', '68:13:24:79:4C:8C']
            try {
              connection.getRemoteProfileUuids(item, (err: BusinessError, data: Array<connection.ProfileUuids>) => {
                console.info('getRemoteProfileUuids, err: ' + JSON.stringify(err) +'\n'+item+ '\t蓝牙Profile协议的UUID: ' + JSON.stringify(data));
              });
            } catch (err) {
              console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
            }
          }

        } catch (err) {
          console.error('Error getting paired devices. Code: ' + (err as BusinessError).code + ', Message: ' + (err as BusinessError).message);
        }
      })
  }
}