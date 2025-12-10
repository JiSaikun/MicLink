import { access } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';

/**
 * 蓝牙状态开关管理
 */
export class AdapterManager {
  // 定义蓝牙开关状态变化函数回调
  onReceiveEvent = (data: access.BluetoothState) => {
    let btStateMessage = '';
    switch (data) {
      case access.BluetoothState.STATE_OFF:
        // 表示蓝牙是关闭的
        btStateMessage += 'STATE_OFF';
        break;
      case access.BluetoothState.STATE_TURNING_ON:
        btStateMessage += 'STATE_TURNING_ON';
        break;
      case access.BluetoothState.STATE_ON:
        // 表示蓝牙是开启的，此时应用才可以使用蓝牙其他功能
        btStateMessage += 'STATE_ON';
        break;
      case access.BluetoothState.STATE_TURNING_OFF:
        btStateMessage += 'STATE_TURNING_OFF';
        break;
      case access.BluetoothState.STATE_BLE_TURNING_ON:
        btStateMessage += 'STATE_BLE_TURNING_ON';
        break;
      case access.BluetoothState.STATE_BLE_ON:
        btStateMessage += 'STATE_BLE_ON';
        break;
      case access.BluetoothState.STATE_BLE_TURNING_OFF:
        btStateMessage += 'STATE_BLE_TURNING_OFF';
        break;
      default:
        btStateMessage += 'unknown state';
        break;
    }
    console.info('bluetooth state: ' + btStateMessage);
  };

  // 开启蓝牙
  public openBluetooth(getUIContext: UIContext) {
    try {
      access.on('stateChange', this.onReceiveEvent);
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
    try {
      // 主动获取蓝牙当前的开关状态
      let state = access.getState();
      if (state == access.BluetoothState.STATE_OFF) {
        // 若蓝牙是关闭的，则主动开启蓝牙
        access.enableBluetooth();
      }
      if (state == access.BluetoothState.STATE_ON) {
        getUIContext.getPromptAction().showDialog({
          title: ('手机蓝牙已处于开启状态，请建立手机与设备的蓝牙连接'),
          buttons: [{ text: '去连接', color: '#007DFF'}, { text: '关闭提醒', color: '#FF3B30' },]
        }).then((res:promptAction.ShowDialogSuccessResponse)=>{
          if (res.index===0) {
            let context = getContext() as common.UIAbilityContext
            context.startAbility({
              bundleName: "com.huawei.hmos.settings",//被拉起方的应用包名。
              abilityName: "com.huawei.hmos.settings.MainAbility", //abilityName 必须完整匹配
              uri: 'bluetooth_entry', //决定具体子页面，不可省略
            })
          }
        })
      }
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  // 关闭蓝牙
  public closeBluetooth() {
    try {
      // 主动获取蓝牙当前的开关状态
      let state = access.getState();
      if (state == access.BluetoothState.STATE_ON) {
        // 若蓝牙是开启的，则主动关闭蓝牙
        access.disableBluetooth();
      }
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }
}

export let adapterManager = new AdapterManager();
