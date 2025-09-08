import { access,connection,hid } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
export class BlueTooth_api{
  // 定义蓝牙开关状态变化函数回调
  static  onReceiveEvent = (data: access.BluetoothState) => {
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
  static  openBluetooth() {
    try {
      access.on('stateChange', BlueTooth_api.onReceiveEvent);
    } catch (err) {
      console.error('errCode: ++++++++++++++++++++++++' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
    try {
      // 主动获取蓝牙当前的开关状态
      let state = access.getState();
      console.log(JSON.stringify(state),'============================================')
      if (state == access.BluetoothState.STATE_OFF) {
        console.log('---------主动发起开启蓝牙')
        // 若蓝牙是关闭的，则主动开启蓝牙
        access.enableBluetooth();
      }
    } catch (err) {
      console.error('errCode:=======================发起开启蓝牙失败 ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  // 关闭蓝牙
  static  closeBluetooth() {
    try {
      // 主动获取蓝牙当前的开关状态
      let state = access.getState();
      if (state == access.BluetoothState.STATE_ON) {
        console.log('---------主动发起关闭蓝牙')
        // 若蓝牙是开启的，则主动关闭蓝牙
        access.disableBluetooth();
      }
    } catch (err) {
      console.error('errCode:=======================发起关闭蓝牙失败  ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }
  // 获取系统蓝牙是否开启
  static  init_bluetoothState() {
      // 主动获取蓝牙当前的开关状态
      let state = access.getState();
      AppStorage.setOrCreate("bluetoothState",state)
    try {
      // 获取已配对设备信息
      let devices = connection.getPairedDevices();
      console.info('pairedDevices: ' + JSON.stringify(devices));
      // // 若已知道设备地址，可主动查询该设备是否是已配对的
      // if (devices.length > 0) {
      //   let pairState = connection.getPairState(devices[0]);
      //   console.info('device: '+ devices[0] + ' pairState is ' + pairState);
      // }
    } catch (err) {
      console.error('errCode:========= ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }

  }

}