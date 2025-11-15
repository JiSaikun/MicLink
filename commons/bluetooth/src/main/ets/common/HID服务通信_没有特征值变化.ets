import { a2dp, ble, constant } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { connection } from '@kit.ConnectivityKit';
import { LengthMetrics } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { getModelInfoModel, keyInfosModel } from 'config'
import {
  DeviceInfo,
  DPI_currInfoModel,
  getModelInfo_Params,
  KeyPressType,
  MouseICType,
  PRODUCT_TYPE,
  SmartMouseAudioProcessor,
  _getModelInfo
} from 'mouse';
import { AudioWebSocketHandler_ble } from './AudioWebSocketHandler_ble';

// // 获取设备连接状态
// try {
//   const a2dpSrc = a2dp.createA2dpSrcProfile();
//   const state = a2dpSrc.getConnectionState('XX:XX:XX:XX:XX:XX'); // 替换为设备MAC
// } catch (err) {
//   console.error(`错误码: ${(err as BusinessError).code}, 错误信息: ${(err as BusinessError).message}`);
// }

const permissions: Array<Permissions> = ['ohos.permission.ACCESS_BLUETOOTH'];

// 使用UIExtensionAbility：将common.UIAbilityContext 替换为common.UIExtensionContext
export function reqPermissionsFromUser(permissions: Array<Permissions>, context: common.UIAbilityContext): void {
  let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  // requestPermissionsFromUser会判断权限的授权状态来决定是否唤起弹窗。
  atManager.requestPermissionsFromUser(context, permissions).then((data) => {
    let grantStatus: Array<number> = data.authResults;
    let length: number = grantStatus.length;
    for (let i = 0; i < length; i++) {
      if (grantStatus[i] === 0) {
        // 用户授权，可以继续访问目标操作。
        // 异步执行设备扫描，避免阻塞主线程
        setTimeout(() => {
          getPairedDevices();
        }, 100);
      } else {
        // 当用户拒绝授权时，系统应提示用户必须授予相应权限才能使用当前页面的功能，并指导用户前往系统设置开启所需权限。
        // 使用 console.warn 替代已弃用的 showToast
        console.warn('请打开蓝牙设备获取权限')
        return;
      }
    }
    // 授权成功
  }).catch((err: BusinessError) => {
    console.error(`Failed to request permissions from user. Code is ${err.code}, message is ${err.message}`);
  })
}

enum connectionmethodType {
  Cloud = 0,
  USB = 1,
  Bluetooth = 2
}


export interface KeymethodConfig {
  key: KeyPressType
  currIndex: number
}

export interface DeviceArrayType_Ble {
  BlueTooth_devices: BlueTooth_devices
  mouseconfig: DeviceInfo | null
  getModelInfo: getModelInfoModel | null
  connectionmethod: connectionmethodType
  KeymethodConfig: KeymethodConfig[]
  DPI_currInfo: DPI_currInfoModel | null
  currLED: boolean
  reportRate_currIndex: number
  isPunctuationRecognition: boolean //语音识别是否带标点
  speech_Recognition_languages: string //语音识别语种
  productImg: string,
  PRODUCT_TYPE: PRODUCT_TYPE //设备类型
  name: string //设备名
}


export class BlueTooth_devices {
  private device_currIndex: number = 0
  public devices: DeviceArrayType_Ble[] = AppStorage.get('devices') as DeviceArrayType_Ble[]
  public gattClient: ble.GattClientDevice | null = null
  public device_address: string = ''
  public BlueTooth_devices: BlueTooth_devices | null = null
  // HID服务UUID
  private HID_SERVICE_UUID: string = "00001812-0000-1000-8000-00805F9B34FB"
  // HID Report特征UUID (用于接收数据和发送数据)
  private HID_REPORT_CHAR_UUID: string = "00002A4D-0000-1000-8000-00805F9B34FB"
  private HID_REPORT_DESCRIPTORS: ble.BLEDescriptor[] = []

  // HID Boot Keyboard Input Report特征UUID (用于兼容性)
  private HID_BOOT_KEYBOARD_INPUT_UUID: string = "00002A22-0000-1000-8000-00805F9B34FB"
  private HID_BOOT_KEYBOARD_INPUT_DESCRIPTORS: ble.BLEDescriptor[] = []
  public audioDataState: boolean = false //是否录入开启
  private isHidReportData: boolean = false //标识当前数据是否来自HID Report特征
  public getModelInfo: getModelInfoModel | null = null
  public deviceInfo: DeviceInfo = {
    sn: '', //SN
    micStatus: false, //麦克风状态
    ledStatus: false, //LED状态
    sampleRate: false, //采样率
    icType: MouseICType.MouseICTypePAW3212, //鼠标光电类型
    dpiLevel: 1, //DPI挡位
    productType: 0, //产品型号
    batteryLevel: 0, //电量
    firmwareVersion: '', //固件版本
    isConnected: false, //连接状态
    reportRate: 125, //回报率
    atmosphereLight: false//氛围灯
  };
  private flax_yuyin: boolean = true //标记：防止鼠标上来直接开启了语音输入————先发送一次0x63命令
  private audioProcessor: SmartMouseAudioProcessor = new SmartMouseAudioProcessor();
  static audioData: Int16Array[] = []

  // 特征值变化超时检测
  private lastCharacteristicChangeTime: number = 0
  private characteristicTimeoutTimer: number | null = null
  private readonly CHARACTERISTIC_TIMEOUT: number = 15000 // 15秒超时
  private audioWebSocketHandler: AudioWebSocketHandler_ble | null = null // 当前的音频WebSocket处理器

  constructor(device_address: string) {
    this.device_address = device_address;
  }

  CharacteristicChange = (characteristicChangeReq: ble.BLECharacteristic) => {
    // 更新最后接收特征值变化的时间
    this.lastCharacteristicChangeTime = Date.now();
    this.resetCharacteristicTimeout();

    let serviceUuid: string = characteristicChangeReq.serviceUuid;
    let characteristicUuid: string = characteristicChangeReq.characteristicUuid;
    let value: Uint8Array = new Uint8Array(characteristicChangeReq.characteristicValue);

    console.warn('HID特征值变化回调被触发!');
    console.log('HID服务UUID:', serviceUuid);
    console.log('HID特征UUID:', characteristicUuid);
    console.log('HID数据长度:', value.length);

    hilog.warn(0x00, 'send',
      '*******************************************************************************接收HID鼠标发送的消息');

    // 根据特征UUID设置数据来源标识
    this.isHidReportData = (characteristicUuid === this.HID_REPORT_CHAR_UUID ||
      characteristicUuid === this.HID_BOOT_KEYBOARD_INPUT_UUID);

    console.log('HID数据来源标识 (isHidReportData):', this.isHidReportData);

    if (value.length > 0) {
      const hexData = Array.from(value.slice(0, value.length)).map(b => b.toString(16).padStart(2, '0')).join(' ');
      console.log('HID接收到的数据展示:', hexData);

      // 检查是否是音频数据（根据帧头或其他标识）
      if (value.length > 0 && value[0] === 0x1b) {
        console.log('HID检测到音频数据帧头 (0x1b)');
      } else {
        console.log('HID接收到非音频数据');
      }

      // 解析设备信息
      this.parseDeviceInfo(value.slice(0, value.length));
    } else {
      console.log('HID未接收到数据');
    }
  }

  public closeconnectDevice() {
    this.gattClient?.close()
    this.stopCharacteristicTimeout();
  }

  // 设置音频WebSocket处理器
  public setAudioWebSocketHandler(handler: AudioWebSocketHandler_ble): void {
    // 如果有旧的处理器，先销毁它
    if (this.audioWebSocketHandler && this.audioWebSocketHandler !== handler) {
      console.log('清理旧的音频WebSocket处理器...');
      this.audioWebSocketHandler.destroy();
    }
    this.audioWebSocketHandler = handler;
  }

  // 清理所有定时器和资源
  public dispose(): void {
    console.log('BlueTooth_devices对象正在清理资源...');

    // 停止特征值变化超时检测
    this.stopCharacteristicTimeout();

    // 清理音频WebSocket处理器
    if (this.audioWebSocketHandler) {
      console.log('清理音频WebSocket处理器...');
      this.audioWebSocketHandler.destroy();
      this.audioWebSocketHandler = null;
    }

    // 关闭蓝牙连接
    this.closeconnectDevice();

    console.log('BlueTooth_devices对象资源清理完成');
  }

  // 启动特征值变化超时检测
  private startCharacteristicTimeout(): void {
    this.lastCharacteristicChangeTime = Date.now();
    this.stopCharacteristicTimeout(); // 确保之前的定时器被清理

    this.characteristicTimeoutTimer = setTimeout(() => {
      try {
        // 检查对象是否仍然有效（防止GC后的访问）
        if (!this || !this.device_address) {
          return;
        }
        console.warn(`蓝牙设备 ${this.device_address} 15秒内未收到特征值变化，移除设备`);
        this.removeDeviceFromList();
      } catch (error) {
        console.error('蓝牙设备超时回调异常:', error);
      }
    }, this.CHARACTERISTIC_TIMEOUT) as number;
  }

  // 重置特征值变化超时检测
  private resetCharacteristicTimeout(): void {
    if (this.characteristicTimeoutTimer !== null) {
      clearTimeout(this.characteristicTimeoutTimer);
      this.characteristicTimeoutTimer = null;
    }

    // 重新启动超时检测
    this.characteristicTimeoutTimer = setTimeout(() => {
      try {
        // 检查对象是否仍然有效（防止GC后的访问）
        if (!this || !this.device_address) {
          return;
        }
        console.warn(`蓝牙设备 ${this.device_address} 15秒内未收到特征值变化，移除设备`);
        this.removeDeviceFromList();
      } catch (error) {
        console.error('蓝牙设备超时回调异常:', error);
      }
    }, this.CHARACTERISTIC_TIMEOUT) as number;
  }

  // 停止特征值变化超时检测
  private stopCharacteristicTimeout(): void {
    if (this.characteristicTimeoutTimer !== null) {
      clearTimeout(this.characteristicTimeoutTimer);
      this.characteristicTimeoutTimer = null;
    }
  }

  // 从设备列表中移除设备
  private removeDeviceFromList(): void {
    try {
      const currentDevices = AppStorage.get('devices') as DeviceArrayType_Ble[] || [];
      const deviceIndex = currentDevices.findIndex(device =>
      device.BlueTooth_devices?.device_address === this.device_address
      );

      if (deviceIndex !== -1) {
        console.log(`从设备列表中移除蓝牙设备: ${this.device_address}`);
        currentDevices.splice(deviceIndex, 1);

        // 更新AppStorage以触发UI更新
        const newDevices = deepCopyDevices(currentDevices);
        AppStorage.setOrCreate('devices', newDevices);

        // 清理连接
        this.closeconnectDevice();
      }
    } catch (error) {
      console.error('移除蓝牙设备时出错:', error);
    }
  }

  public parseDeviceInfo(data: Uint8Array): void {
    // 安全检查设备数组和索引
    const devices = AppStorage.get('devices') as DeviceArrayType_Ble[];
    if (!devices || !Array.isArray(devices) || this.device_currIndex < 0 || this.device_currIndex >= devices.length) {
      console.error('设备数组或索引无效:', { devices: !!devices, deviceIndex: this.device_currIndex, length: devices?.length });
      return;
    }

    {
      const newBuffer = new Uint8Array(data.length + 1);
      if (data.length > 50) {
        newBuffer[0] = 0x1b; // 在前面补的数字，这里以 0x00 为例
      } else {
        newBuffer[0] = 0x00; // 在前面补的数字，这里以 0x00 为例
      }
      newBuffer.set(data, 1); // 从索引1开始设置原始数据
      data = newBuffer
      console.log('接收到的数据展示:', data, data.length, data.length < 21);
      if (data.length < 21) {
        console.log('数据长度不足，期望至少21字节，实际:', data.length);
        return;
      }
      const hexData = Array.from(data).map(b => b.toString(16).padStart(2, '0')).join(' ');
      console.log('补全帧头数据:', hexData);

      try {
        // HID协议数据处理
        // 对于HID Report特征发送的数据，我们需要检查是否是音频数据
        if (this.isHidReportData) {
          console.log('HID Report数据，长度:', data.length);
          // HID数据可能直接包含音频数据，或者有HID特定的格式
          // 这里我们假设HID Report直接发送音频数据（类似原有0x1b帧头后的数据）
          if (this.audioDataState && data.length > 0) {
            console.log('****************************HID语音数据****************************');
            console.log('通过HID Report接收到音频数据');
            // 对于HID数据，我们可能需要添加帧头标识
            const hidAudioData = new Uint8Array(data.length + 1);
            hidAudioData[0] = 0x1b; // 添加帧头标识
            hidAudioData.set(data, 1);
            this.processAudioData(hidAudioData);
          }
          return;
        }

        // 检查原有协议帧头
        if (data.length > 0 && data[0] === 0x1b) {
          if (this.audioDataState) {
            console.log('****************************语音数据****************************');
            console.log('接收到音频数据');
            this.processAudioData(data);
          }
          return;
        }

        if (data.length > 4 && data[1] === 0x4D) {
          const dataLength = data[2];
          const command = data[3];

          console.log(`响应帧: 长度=${dataLength}, 命令=0x${command.toString(16)}`);

          // 原有的设备信息解析逻辑保持不变
          if (command === 0x61) { // 设备信息响应
            console.info('>>> 收到0x61设备信息响应，开始解析设备信息 <<<');
            // SN解析 - 直接使用十六进制表示，不转换为十进制
            const snPrefix = String.fromCharCode(data[4], data[5]); // "ML"
            const snSuffixBytes = data.slice(6, 14);
            console.log('SN后缀原始字节:',
              Array.from(snSuffixBytes).map(b => b.toString(16).padStart(2, '0')).join(' '));

            let snSuffix = '';
            for (let i = 0; i < snSuffixBytes.length; i++) {
              snSuffix += snSuffixBytes[i].toString(16).padStart(2, '0');
            }

            this.deviceInfo.sn = snPrefix + snSuffix;
            console.log('SN:', this.deviceInfo.sn);

            // 2. 状态字节（协议：byte14）
            const statusByte = data[14];
            this.deviceInfo.micStatus = !!(statusByte & 0x01); // bit0=mic
            this.deviceInfo.ledStatus = !!(statusByte & 0x02); // bit1=LED
            this.deviceInfo.sampleRate = !!(statusByte & 0x04); // bit2=采样率

            // 3. 光电类型（协议：byte15）
            this.deviceInfo.icType = data[15];

            // 4. DPI档位（协议：byte16）
            this.deviceInfo.dpiLevel = data[16];

            // 5. 产品型号（协议：byte17=低八位，byte20=高八位）
            const productTypeLow = data[17]; // 低八位
            const productTypeHigh = data[20]; // 高八位
            this.deviceInfo.productType = (productTypeHigh << 8) | productTypeLow;

            // 6. 电量（协议：byte18）
            this.deviceInfo.batteryLevel = data[18];

            // 7. 固件版本（协议：byte19）
            this.deviceInfo.firmwareVersion = data[19].toString();
            devices[this.device_currIndex].mouseconfig = this.deviceInfo;

            if (!devices[this.device_currIndex].getModelInfo) {
              // 深拷贝更新设备列表以触发UI更新
              const currentDevices = AppStorage.get('devices') as DeviceArrayType_Ble[];
              const newList: DeviceArrayType_Ble[] = deepCopyDevices(currentDevices);
              AppStorage.setOrCreate('devices', newList);
              this.devices = newList;
            } else {
              if (!devices[this.device_currIndex].KeymethodConfig.length) {
                devices[this.device_currIndex].KeymethodConfig = [
                  { key: KeyPressType.VOICE_CLICK, currIndex: 0 },
                  { key: KeyPressType.VOICE_LONG_PRESS_DOWN, currIndex: 0 },
                  { key: KeyPressType.SEARCH_CLICK, currIndex: 0 },
                  { key: KeyPressType.SEARCH_LONG_PRESS_DOWN, currIndex: 0 },
                  { key: KeyPressType.TRANSLATE_CLICK, currIndex: 0 },
                  { key: KeyPressType.TRANSLATE_LONG_PRESS_DOWN, currIndex: 0 },
                  { key: KeyPressType.AI_CLICK, currIndex: 0 },
                  { key: KeyPressType.TRANSLATE_LONG_PRESS_DOWN, currIndex: 0 },
                  { key: KeyPressType.CUSTOM_CLICK, currIndex: 0 },
                  { key: KeyPressType.CUSTOM_LONG_PRESS_DOWN, currIndex: 0 },
                ];

                const keyInfos = devices[this.device_currIndex]?.getModelInfo?.keyInfos as keyInfosModel[];
                if (!keyInfos || !Array.isArray(keyInfos)) {
                  console.warn('keyInfos无效或为空，跳过配置初始化');
                  return;
                }

                for (let item of keyInfos) {
                  if (!item.childs || !Array.isArray(item.childs)) {
                    console.warn('item.childs无效，跳过此项');
                    continue;
                  }
                  for (let childs of item.childs) {
                    if (!childs.childs || !Array.isArray(childs.childs)) {
                      console.warn('childs.childs无效，跳过此项');
                      continue;
                    }
                    childs.childs.forEach((keyInfos_childs_childsModel, index) => {
                      if (!keyInfos_childs_childsModel) {
                        console.warn('keyInfos_childs_childsModel为undefined，跳过');
                        return;
                      }
                      if (keyInfos_childs_childsModel.first === 1) {
                        switch (item.key) {
                          case 'voice_key': //语音键
                            if (childs.operation === 'sk') { //单击
                              devices[this.device_currIndex].KeymethodConfig[0].currIndex =
                                index;
                            }
                            if (childs.operation === 'lk') { //长按
                              devices[this.device_currIndex].KeymethodConfig[1].currIndex =
                                index;
                            }
                            break;
                          case 'search_key': //搜索键
                            if (childs.operation === 'sk') {
                              devices[this.device_currIndex].KeymethodConfig[2].currIndex =
                                index;
                            }
                            if (childs.operation === 'lk') { //长按
                              devices[this.device_currIndex].KeymethodConfig[3].currIndex =
                                index;
                            }
                            break;
                          case 'translate_key': //翻译键
                            if (childs.operation === 'sk') {
                              devices[this.device_currIndex].KeymethodConfig[4].currIndex =
                                index;
                            }
                            if (childs.operation === 'lk') { //长按
                              devices[this.device_currIndex].KeymethodConfig[5].currIndex =
                                index;
                            }
                            break;
                          case 'AI_key': //AI键
                            if (childs.operation === 'sk') {
                              devices[this.device_currIndex].KeymethodConfig[6].currIndex =
                                index;
                            }
                            if (childs.operation === 'lk') { //长按
                              devices[this.device_currIndex].KeymethodConfig[7].currIndex =
                                index;
                            }
                            break;
                          case 'M_key': //AI键
                            if (childs.operation === 'sk') {
                              devices[this.device_currIndex].KeymethodConfig[8].currIndex =
                                index;
                            }
                            if (childs.operation === 'lk') { //长按
                              devices[this.device_currIndex].KeymethodConfig[9].currIndex =
                                index;
                            }
                            break;
                        }
                      }
                    });
                  }
                }
              }
            }
            console.info('>>> 0x61设备信息解析完成 <<<');
          }

          if (command === 0x69) {
            // byte[4]:连接状态
            if (data[4]) {
              this.deviceInfo.isConnected = true;
            } else {
              this.deviceInfo.isConnected = false;
            }
            // byte[5]: 电量
            this.deviceInfo.batteryLevel = data[5];
            // byte[6]: 当前回报率
            const reportRateCode = data[6];
            switch (reportRateCode) {
              case 8:
                this.deviceInfo.reportRate = 125;
                break;
              case 4:
                this.deviceInfo.reportRate = 250;
                break;
              case 2:
                this.deviceInfo.reportRate = 500;
                break;
              case 1:
                this.deviceInfo.reportRate = 1000;
                break;
              default:
                this.deviceInfo.reportRate = 125;
            }

            // byte[7]: 当前氛围灯状态
            if (data[7]) {
              this.deviceInfo.atmosphereLight = true;
            } else {
              this.deviceInfo.atmosphereLight = false;
            }

            devices[this.device_currIndex].mouseconfig = this.deviceInfo;

            if (!devices[this.device_currIndex].getModelInfo) {
              // 深拷贝更新设备列表以触发UI更新
              const currentDevices = AppStorage.get('devices') as DeviceArrayType_Ble[];
              const newList: DeviceArrayType_Ble[] = deepCopyDevices(currentDevices);
              AppStorage.setOrCreate('devices', newList);
              this.devices = newList;
            } else {
              if (!devices[this.device_currIndex].KeymethodConfig.length) {
                devices[this.device_currIndex].KeymethodConfig = [
                  { key: KeyPressType.VOICE_CLICK, currIndex: 0 },
                  { key: KeyPressType.VOICE_LONG_PRESS_DOWN, currIndex: 0 },
                  { key: KeyPressType.SEARCH_CLICK, currIndex: 0 },
                  { key: KeyPressType.SEARCH_LONG_PRESS_DOWN, currIndex: 0 },
                  { key: KeyPressType.TRANSLATE_CLICK, currIndex: 0 },
                  { key: KeyPressType.TRANSLATE_LONG_PRESS_DOWN, currIndex: 0 },
                  { key: KeyPressType.AI_CLICK, currIndex: 0 },
                  { key: KeyPressType.TRANSLATE_LONG_PRESS_DOWN, currIndex: 0 },
                  { key: KeyPressType.CUSTOM_CLICK, currIndex: 0 },
                  { key: KeyPressType.CUSTOM_LONG_PRESS_DOWN, currIndex: 0 },
                ];

                const keyInfos = devices[this.device_currIndex]?.getModelInfo?.keyInfos as keyInfosModel[];
                if (!keyInfos || !Array.isArray(keyInfos)) {
                  console.warn('keyInfos无效或为空，跳过配置初始化');
                  return;
                }

                for (let item of keyInfos) {
                  if (!item.childs || !Array.isArray(item.childs)) {
                    console.warn('item.childs无效，跳过此项');
                    continue;
                  }
                  for (let childs of item.childs) {
                    if (!childs.childs || !Array.isArray(childs.childs)) {
                      console.warn('childs.childs无效，跳过此项');
                      continue;
                    }
                    childs.childs.forEach((keyInfos_childs_childsModel, index) => {
                      if (!keyInfos_childs_childsModel) {
                        console.warn('keyInfos_childs_childsModel为undefined，跳过');
                        return;
                      }
                      if (keyInfos_childs_childsModel.first === 1) {
                        switch (item.key) {
                          case 'voice_key': //语音键
                            if (childs.operation === 'sk') { //单击
                              devices[this.device_currIndex].KeymethodConfig[0].currIndex =
                                index;
                            }
                            if (childs.operation === 'lk') { //长按
                              devices[this.device_currIndex].KeymethodConfig[1].currIndex =
                                index;
                            }
                            break;
                          case 'search_key': //搜索键
                            if (childs.operation === 'sk') {
                              devices[this.device_currIndex].KeymethodConfig[2].currIndex =
                                index;
                            }
                            if (childs.operation === 'lk') { //长按
                              devices[this.device_currIndex].KeymethodConfig[3].currIndex =
                                index;
                            }
                            break;
                          case 'translate_key': //翻译键
                            if (childs.operation === 'sk') {
                              devices[this.device_currIndex].KeymethodConfig[4].currIndex =
                                index;
                            }
                            if (childs.operation === 'lk') { //长按
                              devices[this.device_currIndex].KeymethodConfig[5].currIndex =
                                index;
                            }
                            break;
                          case 'AI_key': //AI键
                            if (childs.operation === 'sk') {
                              devices[this.device_currIndex].KeymethodConfig[6].currIndex =
                                index;
                            }
                            if (childs.operation === 'lk') { //长按
                              devices[this.device_currIndex].KeymethodConfig[7].currIndex =
                                index;
                            }
                            break;
                          case 'M_key': //AI键
                            if (childs.operation === 'sk') {
                              devices[this.device_currIndex].KeymethodConfig[8].currIndex =
                                index;
                            }
                            if (childs.operation === 'lk') { //长按
                              devices[this.device_currIndex].KeymethodConfig[9].currIndex =
                                index;
                            }
                            break;
                        }
                      }
                    });
                  }
                }
              }
            }
          }

          if (command === 0x11) {
            // 处理0x11命令
          }

          if (command === 0x63) {
            this.flax_yuyin = false;
          }

          if (data[3] === 0x33) {
            console.log('****************************语音键单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.VOICE_CLICK)
          }
          if (data[3] === 0x40) {
            console.log('****************************语音键双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.VOICE_DOUBLE_CLICK)
          }
          if (data[3] === 0x37) {
            console.log('****************************语音键长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.VOICE_LONG_PRESS_DOWN)
          }
          if (data[3] === 0x38) {
            console.log('****************************语音键长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.VOICE_LONG_PRESS_UP)
          }
          if (data[3] === 0x35) {
            console.log('****************************搜索键单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SEARCH_CLICK)
          }
          if (data[3] === 0x41) {
            console.log('****************************搜索键双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SEARCH_DOUBLE_CLICK)
          }
          if (data[3] === 0x31) {
            console.log('****************************搜索键长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SEARCH_LONG_PRESS_DOWN)
          }
          if (data[3] === 0x32) {
            console.log('****************************搜索键长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SEARCH_LONG_PRESS_UP)
          }

          if (data[3] === 0x42) {
            console.log('****************************翻译键单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TRANSLATE_CLICK)
          }
          if (data[3] === 0x43) {
            console.log('****************************翻译键双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TRANSLATE_DOUBLE_CLICK)
          }
          if (data[3] === 0x44) {
            console.log('****************************翻译键长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TRANSLATE_LONG_PRESS_DOWN)
          }
          if (data[3] === 0x45) {
            console.log('****************************翻译键长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TRANSLATE_LONG_PRESS_UP)
          }

          if (data[3] === 0x46) {
            console.log('****************************自定义键——M键单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM_CLICK)
          }
          if (data[3] === 0x47) {
            console.log('****************************自定义键——M键双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM_DOUBLE_CLICK)
          }
          if (data[3] === 0x48) {
            console.log('****************************自定义键——M键长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM_LONG_PRESS_DOWN)
          }
          if (data[3] === 0x49) {
            console.log('****************************自定义键——M键长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM_LONG_PRESS_UP)
          }

          if (data[3] === 0x50) {
            console.log('****************************AI键单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.AI_CLICK)
          }
          if (data[3] === 0x51) {
            console.log('****************************AI键双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.AI_DOUBLE_CLICK)
          }
          if (data[3] === 0x52) {
            console.log('****************************AI键长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.AI_LONG_PRESS_DOWN)
          }
          if (data[3] === 0x53) {
            console.log('****************************AI键长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.AI_LONG_PRESS_UP)
          }

          /**
           * 键盘
           */
          // 截图翻译键
          if (data[3] === 0x80) {
            console.log('****************************截图翻译键单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SCREENSHOT_TRANSLATE_CLICK)
          }
          if (data[3] === 0x81) {
            console.log('****************************截图翻译键双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SCREENSHOT_TRANSLATE_DOUBLE_CLICK)
          }
          if (data[3] === 0x82) {
            console.log('****************************截图翻译键长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SCREENSHOT_TRANSLATE_LONG_PRESS_DOWN)
          }
          if (data[3] === 0x83) {
            console.log('****************************截图翻译键长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SCREENSHOT_TRANSLATE_LONG_PRESS_UP)
          }

          // AI绘画键
          if (data[3] === 0x84) {
            console.log('****************************AI绘画键单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.AI_PAINTING_CLICK)
          }
          if (data[3] === 0x85) {
            console.log('****************************AI绘画键双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.AI_PAINTING_DOUBLE_CLICK)
          }
          if (data[3] === 0x86) {
            console.log('****************************AI绘画键长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.AI_PAINTING_LONG_PRESS_DOWN)
          }
          if (data[3] === 0x87) {
            console.log('****************************AI绘画键长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.AI_PAINTING_LONG_PRESS_UP)
          }

          // 图片分析键改文档转换
          if (data[3] === 0x88) {
            console.log('****************************文档转换键单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.DOCUMENT_CONVERSION_CLICK)
          }
          if (data[3] === 0x89) {
            console.log('****************************文档转换键双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.DOCUMENT_CONVERSION_DOUBLE_CLICK)
          }
          if (data[3] === 0x8A) {
            console.log('****************************文档转换键长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.DOCUMENT_CONVERSION_LONG_PRESS_DOWN)
          }
          if (data[3] === 0x8B) {
            console.log('****************************文档转换键长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.DOCUMENT_CONVERSION_LONG_PRESS_UP)
          }

          // 思维导图键
          if (data[3] === 0x8C) {
            console.log('****************************思维导图键单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.MIND_MAP_CLICK)
          }
          if (data[3] === 0x8D) {
            console.log('****************************思维导图键双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.MIND_MAP_DOUBLE_CLICK)
          }
          if (data[3] === 0x8E) {
            console.log('****************************思维导图键长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.MIND_MAP_LONG_PRESS_DOWN)
          }
          if (data[3] === 0x8F) {
            console.log('****************************思维导图键长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.MIND_MAP_LONG_PRESS_UP)
          }

          // 工作总结键
          if (data[3] === 0x90) {
            console.log('****************************工作总结键单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.WORK_SUMMARY_CLICK)
          }
          if (data[3] === 0x91) {
            console.log('****************************工作总结键双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.WORK_SUMMARY_DOUBLE_CLICK)
          }
          if (data[3] === 0x92) {
            console.log('****************************工作总结键长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.WORK_SUMMARY_LONG_PRESS_DOWN)
          }
          if (data[3] === 0x93) {
            console.log('****************************工作总结键长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.WORK_SUMMARY_LONG_PRESS_UP)
          }

          // 模版下载键
          if (data[3] === 0x94) {
            console.log('****************************模版下载键单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TEMPLATE_DOWNLOAD_CLICK)
          }
          if (data[3] === 0x95) {
            console.log('****************************模版下载键双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TEMPLATE_DOWNLOAD_DOUBLE_CLICK)
          }
          if (data[3] === 0x96) {
            console.log('****************************模版下载键长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TEMPLATE_DOWNLOAD_LONG_PRESS_DOWN)
          }
          if (data[3] === 0x97) {
            console.log('****************************模版下载键长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TEMPLATE_DOWNLOAD_LONG_PRESS_UP)
          }

          // 阅读理解键
          if (data[3] === 0x98) {
            console.log('****************************阅读理解键单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.READING_COMPREHENSION_CLICK)
          }
          if (data[3] === 0x99) {
            console.log('****************************阅读理解键双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.READING_COMPREHENSION_DOUBLE_CLICK)
          }
          if (data[3] === 0x9A) {
            console.log('****************************阅读理解键长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.READING_COMPREHENSION_LONG_PRESS_DOWN)
          }
          if (data[3] === 0x9B) {
            console.log('****************************阅读理解键长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.READING_COMPREHENSION_LONG_PRESS_UP)
          }

          // 表格键
          if (data[3] === 0x9C) {
            console.log('****************************表格键单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TABLE_CLICK)
          }
          if (data[3] === 0x9D) {
            console.log('****************************表格键双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TABLE_DOUBLE_CLICK)
          }
          if (data[3] === 0x9E) {
            console.log('****************************表格键长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TABLE_LONG_PRESS_DOWN)
          }
          if (data[3] === 0x9F) {
            console.log('****************************表格键长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TABLE_LONG_PRESS_UP)
          }

          // 代码键
          if (data[3] === 0xA0) {
            console.log('****************************代码键单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CODE_CLICK)
          }
          if (data[3] === 0xA1) {
            console.log('****************************代码键双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CODE_DOUBLE_CLICK)
          }
          if (data[3] === 0xA2) {
            console.log('****************************代码键长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CODE_LONG_PRESS_DOWN)
          }
          if (data[3] === 0xA3) {
            console.log('****************************代码键长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CODE_LONG_PRESS_UP)
          }

          // 演讲稿键
          if (data[3] === 0xA4) {
            console.log('****************************演讲稿键单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SPEECH_CLICK)
          }
          if (data[3] === 0xA5) {
            console.log('****************************演讲稿键双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SPEECH_DOUBLE_CLICK)
          }
          if (data[3] === 0xA6) {
            console.log('****************************演讲稿键长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SPEECH_LONG_PRESS_DOWN)
          }
          if (data[3] === 0xA7) {
            console.log('****************************演讲稿键长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SPEECH_LONG_PRESS_UP)
          }

          // 写作键
          if (data[3] === 0xA8) {
            console.log('****************************写作键单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.WRITING_CLICK)
          }
          if (data[3] === 0xA9) {
            console.log('****************************写作键双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.WRITING_DOUBLE_CLICK)
          }
          if (data[3] === 0xAA) {
            console.log('****************************写作键长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.WRITING_LONG_PRESS_DOWN)
          }
          if (data[3] === 0xAB) {
            console.log('****************************写作键长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.WRITING_LONG_PRESS_UP)
          }

          // PPT键
          if (data[3] === 0xAC) {
            console.log('****************************PPT键单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.PPT_CLICK)
          }
          if (data[3] === 0xAD) {
            console.log('****************************PPT键双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.PPT_DOUBLE_CLICK)
          }
          if (data[3] === 0xAE) {
            console.log('****************************PPT键长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.PPT_LONG_PRESS_DOWN)
          }
          if (data[3] === 0xAF) {
            console.log('****************************PPT键长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.PPT_LONG_PRESS_UP)
          }

          // 自定义键1
          if (data[3] === 0xB0) {
            console.log('****************************自定义键1单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM1_CLICK)
          }
          if (data[3] === 0xB1) {
            console.log('****************************自定义键1双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM1_DOUBLE_CLICK)
          }
          if (data[3] === 0xB2) {
            console.log('****************************自定义键1长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM1_LONG_PRESS_DOWN)
          }
          if (data[3] === 0xB3) {
            console.log('****************************自定义键1长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM1_LONG_PRESS_UP)
          }

          // 自定义键2
          if (data[3] === 0xB4) {
            console.log('****************************自定义键2单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM2_CLICK)
          }
          if (data[3] === 0xB5) {
            console.log('****************************自定义键2双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM2_DOUBLE_CLICK)
          }
          if (data[3] === 0xB6) {
            console.log('****************************自定义键2长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM2_LONG_PRESS_DOWN)
          }
          if (data[3] === 0xB7) {
            console.log('****************************自定义键2长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM2_LONG_PRESS_UP)
          }

          // 自定义键3
          if (data[3] === 0xB8) {
            console.log('****************************自定义键3单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM3_CLICK)
          }
          if (data[3] === 0xB9) {
            console.log('****************************自定义键3双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM3_DOUBLE_CLICK)
          }
          if (data[3] === 0xBA) {
            console.log('****************************自定义键3长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM3_LONG_PRESS_DOWN)
          }
          if (data[3] === 0xBB) {
            console.log('****************************自定义键3长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM3_LONG_PRESS_UP)
          }

          // 朋友圈手册
          if (data[3] === 0xC0) {
            console.log('****************************朋友圈手册单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.FRIENDS_MANUAL_CLICK)
          }
          if (data[3] === 0xC1) {
            console.log('****************************朋友圈手册双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.FRIENDS_MANUAL_DOUBLE_CLICK)
          }
          if (data[3] === 0xC2) {
            console.log('****************************朋友圈手册长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.FRIENDS_MANUAL_LONG_PRESS_DOWN)
          }
          if (data[3] === 0xC3) {
            console.log('****************************朋友圈手册长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.FRIENDS_MANUAL_LONG_PRESS_UP)
          }

          // 长文翻译
          if (data[3] === 0xC4) {
            console.log('****************************长文翻译单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.LONG_TEXT_TRANSLATION_CLICK)
          }
          if (data[3] === 0xC5) {
            console.log('****************************长文翻译双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.LONG_TEXT_TRANSLATION_DOUBLE_CLICK)
          }
          if (data[3] === 0xC6) {
            console.log('****************************长文翻译长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.LONG_TEXT_TRANSLATION_LONG_PRESS_DOWN)
          }
          if (data[3] === 0xC7) {
            console.log('****************************长文翻译长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.LONG_TEXT_TRANSLATION_LONG_PRESS_UP)
          }

          // 一键抠图
          if (data[3] === 0xC8) {
            console.log('****************************一键抠图单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.ONE_CLICK_CUTOUT_CLICK)
          }
          if (data[3] === 0xC9) {
            console.log('****************************一键抠图双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.ONE_CLICK_CUTOUT_DOUBLE_CLICK)
          }
          if (data[3] === 0xCA) {
            console.log('****************************一键抠图长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.ONE_CLICK_CUTOUT_LONG_PRESS_DOWN)
          }
          if (data[3] === 0xCB) {
            console.log('****************************一键抠图长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.ONE_CLICK_CUTOUT_LONG_PRESS_UP)
          }

          // 微博文案小助手
          if (data[3] === 0xCC) {
            console.log('****************************微博文案小助手单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.WEIBO_COPY_ASSISTANT_CLICK)
          }
          if (data[3] === 0xCD) {
            console.log('****************************微博文案小助手双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.WEIBO_COPY_ASSISTANT_DOUBLE_CLICK)
          }
          if (data[3] === 0xCE) {
            console.log('****************************微博文案小助手长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.WEIBO_COPY_ASSISTANT_LONG_PRESS_DOWN)
          }
          if (data[3] === 0xCF) {
            console.log('****************************微博文案小助手长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.WEIBO_COPY_ASSISTANT_LONG_PRESS_UP)
          }

          // 自定义键4
          if (data[3] === 0xE0) {
            console.log('****************************自定义键4单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM4_CLICK)
          }
          if (data[3] === 0xE1) {
            console.log('****************************自定义键4双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM4_DOUBLE_CLICK)
          }
          if (data[3] === 0xE2) {
            console.log('****************************自定义键4长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM4_LONG_PRESS_DOWN)
          }
          if (data[3] === 0xE3) {
            console.log('****************************自定义键4长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM4_LONG_PRESS_UP)
          }

          // 拍照键
          if (data[3] === 0xE5) {
            console.log('****************************拍照键单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.PHOTO_CLICK)
          }
          if (data[3] === 0xE6) {
            console.log('****************************拍照键双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.PHOTO_DOUBLE_CLICK)
          }
          if (data[3] === 0xE7) {
            console.log('****************************拍照键长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.PHOTO_LONG_PRESS_DOWN)
          }
          if (data[3] === 0xE8) {
            console.log('****************************拍照键长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.PHOTO_LONG_PRESS_UP)
          }

          // 文稿校对
          if (data[3] === 0xE9) {
            console.log('****************************文稿校对单击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.DOCUMENT_PROOFREADING_CLICK)
          }
          if (data[3] === 0xEA) {
            console.log('****************************文稿校对双击按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.DOCUMENT_PROOFREADING_DOUBLE_CLICK)
          }
          if (data[3] === 0xEB) {
            console.log('****************************文稿校对长按按下****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.DOCUMENT_PROOFREADING_LONG_PRESS_DOWN)
          }
          if (data[3] === 0xEC) {
            console.log('****************************文稿校对长按抬起****************************')
            AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
            AppStorage.setOrCreate('device_isBle', true)
            AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.DOCUMENT_PROOFREADING_LONG_PRESS_UP)
          }

        } else {
          console.log('无效的响应帧格式');
        }

      } catch (error) {
        try {
          if (devices && this.device_currIndex >= 0 && this.device_currIndex < devices.length) {
            console.warn(JSON.stringify(devices[this.device_currIndex].KeymethodConfig));
          }
        } catch (logError) {
          console.warn('无法记录KeymethodConfig:', logError);
        }
        console.error('解析设备信息错误:', error);
      }

      /**
       * 防止没有接收到鼠标配置信息
       */
      if (this.deviceInfo.sn === '') {
        console.log('没有收到0x61命令,重新获取设备信息');
        this.send();
      } else {
        if (!devices[this.device_currIndex].getModelInfo) {
          console.warn(this.deviceInfo.productType.toString());
          const params: getModelInfo_Params = {
            languageCode: '',
            productCode: this.deviceInfo.productType.toString(),
            sno: this.deviceInfo.sn
          };

          _getModelInfo(params).then((res) => {
            console.log('获取用户按键模式详情数据1111', '\n', JSON.stringify(res.status), JSON.stringify(res.data));
            if ((res.status === 200 || res.statusCode === 200) && res.data) {
              let getModelInfo: getModelInfoModel = res.data;
              console.warn('获取到设备模型信息，开始更新设备数据');

              // 检查设备索引是否有效
              if (this.device_currIndex >= 0 &&
                this.device_currIndex < (AppStorage.get('devices') as DeviceArrayType_Ble[]).length &&
              devices[this.device_currIndex]) {
                // 首先更新本地设备数据
                devices[this.device_currIndex].getModelInfo = getModelInfo;
                console.warn('设备模型信息已设置');

                // 直接更新本地设备数据，然后强制创建全新的AppStorage数据
                console.warn('准备更新AppStorage中的设备数据');

                // 创建一个全新的设备数组，确保引用完全不同
                const freshDevices: DeviceArrayType_Ble[] = [];
                for (let i = 0; i < (AppStorage.get('devices') as DeviceArrayType_Ble[]).length; i++) {
                  const device = (AppStorage.get('devices') as DeviceArrayType_Ble[])[i];
                  const newDevice: DeviceArrayType_Ble = {
                    BlueTooth_devices: device.BlueTooth_devices,
                    mouseconfig: device.mouseconfig,
                    getModelInfo: i === this.device_currIndex ? getModelInfo : device.getModelInfo, // 只更新当前设备
                    connectionmethod: device.connectionmethod,
                    KeymethodConfig: device.KeymethodConfig.map((config: KeymethodConfig): KeymethodConfig => {
                      const newConfig: KeymethodConfig = {
                        key: config.key,
                        currIndex: config.currIndex
                      };
                      return newConfig;
                    }),
                    DPI_currInfo: device.DPI_currInfo,
                    currLED: device.currLED,
                    reportRate_currIndex: device.reportRate_currIndex,
                    isPunctuationRecognition: device.isPunctuationRecognition,
                    speech_Recognition_languages: device.speech_Recognition_languages,
                    productImg: device.productImg,
                    PRODUCT_TYPE: device.PRODUCT_TYPE,
                    name: device.name
                  };
                  freshDevices.push(newDevice);
                }
                AppStorage.setOrCreate('devices', freshDevices);

                // 使用全新的数组更新AppStorage
                // AppStorage.setOrCreate('devices', fres
                // hDevices);
                this.devices = freshDevices;
                console.warn('设备列表已更新');
                AppStorage.setOrCreate('isBluetoothConnect_state', true)
              } else {
                console.error('设备索引无效，无法更新设备信息', this.device_currIndex, this.devices.length);
              }

              // 在索引检查后，判断当前设备是否是键盘
              if (this.device_currIndex >= 0 &&
                this.device_currIndex < (AppStorage.get('devices') as DeviceArrayType_Ble[]).length &&
              devices[this.device_currIndex] &&
              devices[this.device_currIndex].getModelInfo) {
                const currentDevice = devices[this.device_currIndex];
                if ((currentDevice.getModelInfo as getModelInfoModel).functions &&
                  (currentDevice.getModelInfo as getModelInfoModel).functions.length !== 0) {
                  for (let item of (currentDevice.getModelInfo as getModelInfoModel).functions) {
                    if (item.code === 'keyboard') {
                      devices[this.device_currIndex].PRODUCT_TYPE =
                        PRODUCT_TYPE.keyboard;
                      console.warn('设备类型已设置为键盘');
                      break;
                    }
                  }
                }
              }
            }
          }).catch(() => {
            console.log('获取设备模型信息请求失败');
          });
        } else {
          if (this.flax_yuyin) {
            this.send([0x63]);
          }
        }
      }

    }
  }

  // 处理音频数据
  private processAudioData(data: Uint8Array): void {
    try {
      console.log(`蓝牙接收原始音频数据长度: ${data.length}`);
      console.log(`蓝牙原始音频数据前20字节: ${Array.from(data.slice(0, 20))
        .map(b => b.toString(16).padStart(2, '0'))
        .join(' ')}`);

      // 移除帧头(0x1b)
      let audioFrame = data.subarray(1);
      console.log(`蓝牙移除帧头后数据长度: ${audioFrame.length}`);

      if (Number(this.deviceInfo.firmwareVersion) > 23) {
        // 解密音频数据 - 使用实际数据长度而不是固定100字节
        console.log(`蓝牙音频帧长度: ${audioFrame.length}, 将使用此长度进行解密`);
        const decryptedData = this.audioProcessor.miclinkDecrypt(audioFrame, audioFrame.length);
        console.log(`蓝牙解密后数据长度: ${decryptedData.length}`);
        console.log(`蓝牙解密后数据前20字节: ${Array.from(decryptedData.slice(0, 20))
          .map(b => b.toString(16).padStart(2, '0'))
          .join(' ')}`);
        // 这里可以添加播放或保存PCM数据的逻辑
        audioFrame = decryptedData;
      }

      // 解码为PCM
      const pcmData = this.audioProcessor.processVoiceData(audioFrame);

      if (pcmData) {
        // 处理PCM数据（播放或保存）
        console.log(`蓝牙解码得到PCM数据: ${pcmData.length}个样本`);
        console.log(`蓝牙PCM数据前10个样本: ${Array.from(pcmData.slice(0, 10)).join(', ')}`);
        console.log(`蓝牙当前BlueTooth_devices.audioData长度: ${BlueTooth_devices.audioData.length}`);
        // 这里可以添加播放或保存PCM数据的逻辑
        BlueTooth_devices.audioData.push(pcmData);
        console.log(`蓝牙添加后BlueTooth_devices.audioData长度: ${BlueTooth_devices.audioData.length}`);
      } else {
        console.error('蓝牙PCM解码失败，返回null');
      }
    } catch (error) {
      console.error('蓝牙处理音频数据失败:', error);
    }
  }

  /**
   * client端启用或者禁用接收server端特征值内容变更通知的能力
   */
  public setCharacteristicChangeNotification() {
    // 为HID Report特征启用通知
    console.log('开始设置HID特征通知...');
    console.log('HID_SERVICE_UUID:', this.HID_SERVICE_UUID);
    console.log('HID_REPORT_CHAR_UUID:', this.HID_REPORT_CHAR_UUID);
    console.log('HID_REPORT_DESCRIPTORS:', this.HID_REPORT_DESCRIPTORS);

    if (!this.HID_REPORT_DESCRIPTORS || this.HID_REPORT_DESCRIPTORS.length === 0) {
      console.error('HID Report特征描述符为空，无法启用通知');
      return;
    }

    let arrayBufferReport = new ArrayBuffer(8);
    let reportCharacteristic: ble.BLECharacteristic = {
      serviceUuid: this.HID_SERVICE_UUID,
      characteristicUuid: this.HID_REPORT_CHAR_UUID,
      characteristicValue: arrayBufferReport,
      descriptors: this.HID_REPORT_DESCRIPTORS
    };

    try {
      console.log('尝试启用HID Report特征通知...');
      (this.gattClient as ble.GattClientDevice).setCharacteristicChangeNotification(reportCharacteristic, true,
        (err: BusinessError) => {
          if (err) {
            console.error('HID Report特征启用通知失败:', err.code, err.message);
            console.error('错误详情:', JSON.stringify(err));
          } else {
            console.info('HID Report特征启用通知成功');
          }
        });
    } catch (err) {
      console.error('设置HID Report特征通知异常: errCode: ' + (err as BusinessError).code + ', errMessage: ' +
      (err as BusinessError).message);
    }

    // 为Boot Keyboard Input Report启用通知（如果有描述符）
    if (this.HID_BOOT_KEYBOARD_INPUT_DESCRIPTORS && this.HID_BOOT_KEYBOARD_INPUT_DESCRIPTORS.length > 0) {
      let arrayBufferBoot = new ArrayBuffer(8);
      let bootCharacteristic: ble.BLECharacteristic = {
        serviceUuid: this.HID_SERVICE_UUID,
        characteristicUuid: this.HID_BOOT_KEYBOARD_INPUT_UUID,
        characteristicValue: arrayBufferBoot,
        descriptors: this.HID_BOOT_KEYBOARD_INPUT_DESCRIPTORS
      };

      try {
        console.log('尝试启用HID Boot Keyboard Input特征通知...');
        (this.gattClient as ble.GattClientDevice).setCharacteristicChangeNotification(bootCharacteristic, true,
          (err: BusinessError) => {
            if (err) {
              console.error('HID Boot Keyboard Input特征启用通知失败:', err.code, err.message);
            } else {
              console.info('HID Boot Keyboard Input特征启用通知成功');
            }
          });
      } catch (err) {
        console.error('设置HID Boot Keyboard Input特征通知异常: errCode: ' + (err as BusinessError).code + ', errMessage: ' +
        (err as BusinessError).message);
      }
    } else {
      console.log('HID Boot Keyboard Input特征描述符不存在，跳过设置');
    }

    // 手动写入CCCD来启用通知（如果自动设置失败）
    this.writeCCCDToEnableNotifications();
  }

  /**
   * 手动写入Client Characteristic Configuration Descriptor (CCCD) 来启用通知
   */
  private writeCCCDToEnableNotifications(): void {
    console.log('尝试手动写入CCCD来启用通知...');

    // CCCD UUID
    const CCCD_UUID = '00002902-0000-1000-8000-00805F9B34FB';

    // 通知启用值 (0x0001 for notification, 0x0002 for indication, 0x0003 for both)
    const NOTIFICATION_VALUE = new Uint8Array([0x01, 0x00]);

    // 为HID Report特征的CCCD写入通知启用值
    if (this.HID_REPORT_DESCRIPTORS && this.HID_REPORT_DESCRIPTORS.length > 0) {
      console.log('HID Report特征描述符详情:');
      this.HID_REPORT_DESCRIPTORS.forEach((desc, index) => {
        console.log(`  描述符${index}: ${desc.descriptorUuid}`);
      });

      const cccdDescriptor = this.HID_REPORT_DESCRIPTORS.find(desc => desc.descriptorUuid === CCCD_UUID);
      if (cccdDescriptor) {
        const arrayBuffer = new ArrayBuffer(NOTIFICATION_VALUE.length);
        const uint8Array = new Uint8Array(arrayBuffer);
        uint8Array.set(NOTIFICATION_VALUE);

        const descriptorToWrite: ble.BLEDescriptor = {
          serviceUuid: this.HID_SERVICE_UUID,
          characteristicUuid: this.HID_REPORT_CHAR_UUID,
          descriptorUuid: CCCD_UUID,
          descriptorValue: arrayBuffer
        };

        try {
          console.log('写入HID Report特征的CCCD...');
          (this.gattClient as ble.GattClientDevice).writeDescriptorValue(descriptorToWrite).then(() => {
            console.info('HID Report特征CCCD写入成功，通知已启用');
          }).catch((err: BusinessError) => {
            console.error('HID Report特征CCCD写入失败:', err.code, err.message);
          });
        } catch (err) {
          console.error('写入HID Report特征CCCD异常:', err);
        }
      } else {
        console.warn('HID Report特征没有找到CCCD描述符，尝试使用Report Reference描述符');
        // 有些HID设备可能使用不同的描述符结构，尝试写入Report Reference
        const reportRefDescriptor = this.HID_REPORT_DESCRIPTORS.find(desc => desc.descriptorUuid === '00002908-0000-1000-8000-00805F9B34FB');
        if (reportRefDescriptor) {
          console.log('找到Report Reference描述符，尝试写入...');
          const arrayBuffer = new ArrayBuffer(NOTIFICATION_VALUE.length);
          const uint8Array = new Uint8Array(arrayBuffer);
          uint8Array.set(NOTIFICATION_VALUE);

          const descriptorToWrite: ble.BLEDescriptor = {
            serviceUuid: this.HID_SERVICE_UUID,
            characteristicUuid: this.HID_REPORT_CHAR_UUID,
            descriptorUuid: '00002908-0000-1000-8000-00805F9B34FB',
            descriptorValue: arrayBuffer
          };

          try {
            (this.gattClient as ble.GattClientDevice).writeDescriptorValue(descriptorToWrite).then(() => {
              console.info('HID Report特征Report Reference写入成功');
            }).catch((err: BusinessError) => {
              console.error('HID Report特征Report Reference写入失败:', err.code, err.message);
            });
          } catch (err) {
            console.error('写入HID Report特征Report Reference异常:', err);
          }
        }
      }
    }

    // 为Boot Keyboard Input特征的CCCD写入通知启用值
    if (this.HID_BOOT_KEYBOARD_INPUT_DESCRIPTORS && this.HID_BOOT_KEYBOARD_INPUT_DESCRIPTORS.length > 0) {
      const cccdDescriptor = this.HID_BOOT_KEYBOARD_INPUT_DESCRIPTORS.find(desc => desc.descriptorUuid === CCCD_UUID);
      if (cccdDescriptor) {
        const arrayBuffer = new ArrayBuffer(NOTIFICATION_VALUE.length);
        const uint8Array = new Uint8Array(arrayBuffer);
        uint8Array.set(NOTIFICATION_VALUE);

        const descriptorToWrite: ble.BLEDescriptor = {
          serviceUuid: this.HID_SERVICE_UUID,
          characteristicUuid: this.HID_BOOT_KEYBOARD_INPUT_UUID,
          descriptorUuid: CCCD_UUID,
          descriptorValue: arrayBuffer
        };

        try {
          console.log('写入HID Boot Keyboard Input特征的CCCD...');
          (this.gattClient as ble.GattClientDevice).writeDescriptorValue(descriptorToWrite).then(() => {
            console.info('HID Boot Keyboard Input特征CCCD写入成功，通知已启用');
          }).catch((err: BusinessError) => {
            console.error('HID Boot Keyboard Input特征CCCD写入失败:', err.code, err.message);
          });
        } catch (err) {
          console.error('写入HID Boot Keyboard Input特征CCCD异常:', err);
        }
      }
    }
  }

  /**
   * 测试特征通知是否正常工作
   */
  public testNotificationStatus(): void {
    console.log('=== HID特征通知状态测试 ===');
    console.log('设备地址:', this.device_address);
    console.log('GATT客户端存在:', !!this.gattClient);
    console.log('HID服务UUID:', this.HID_SERVICE_UUID);
    console.log('HID Report特征UUID:', this.HID_REPORT_CHAR_UUID);
    console.log('HID Report描述符数量:', this.HID_REPORT_DESCRIPTORS?.length || 0);
    console.log('HID Boot Keyboard Input描述符数量:', this.HID_BOOT_KEYBOARD_INPUT_DESCRIPTORS?.length || 0);
    console.log('音频数据状态:', this.audioDataState);
    console.log('================================');

    // 尝试读取HID Report特征的值
    this.readHidReportValue();
  }

  /**
   * 尝试读取HID Report特征的值
   */
  private readHidReportValue(): void {
    if (!this.gattClient) {
      console.warn('GATT客户端不存在，无法读取HID特征值');
      return;
    }

    const characteristic: ble.BLECharacteristic = {
      serviceUuid: this.HID_SERVICE_UUID,
      characteristicUuid: this.HID_REPORT_CHAR_UUID,
      characteristicValue: new ArrayBuffer(0),
      descriptors: this.HID_REPORT_DESCRIPTORS
    };

    try {
      console.log('尝试读取HID Report特征的值...');
      (this.gattClient as ble.GattClientDevice).readCharacteristicValue(characteristic, (err: BusinessError, data: ble.BLECharacteristic) => {
        if (err) {
          console.error('读取HID Report特征失败:', err.code, err.message);
        } else {
          const value = new Uint8Array(data.characteristicValue);
          console.log('HID Report特征读取成功，数据长度:', value.length);
          if (value.length > 0) {
            console.log('HID Report数据:', Array.from(value).map(b => b.toString(16).padStart(2, '0')).join(' '));
          }
        }
      });
    } catch (err) {
      console.error('读取HID Report特征异常:', err);
    }
  }

  /**
   * client端启用或者禁用接收server端特征值内容变更指示的能力。
   */
  public setCharacteristicChangeIndication() {
    let descriptors: Array<ble.BLEDescriptor> = [];
    let arrayBuffer = new ArrayBuffer(2);
    let descV = new Uint8Array(arrayBuffer);
    descV[0] = 0; // 以Client Characteristic Configuration描述符为例，表示bit0、bit1均为0，notification和indication均不开启
    let descriptor: ble.BLEDescriptor = {
      serviceUuid: this.HID_SERVICE_UUID,
      characteristicUuid: this.HID_REPORT_CHAR_UUID,
      descriptorUuid: '00002902-0000-1000-8000-00805F9B34FB',
      descriptorValue: arrayBuffer
    };
    descriptors[0] = descriptor;
    let arrayBufferC = new ArrayBuffer(8);
    let characteristic: ble.BLECharacteristic = {
      serviceUuid: this.HID_SERVICE_UUID,
      characteristicUuid: this.HID_REPORT_CHAR_UUID,
      characteristicValue: arrayBufferC,
      descriptors: descriptors
    };
    try {
      // (this.gattClient as ble.GattClientDevice).setCharacteristicChangeIndication(characteristic, true,
      //   (err: BusinessError) => {
      //     if (err) {
      //       console.error('client端启用或者禁用接收server端特征值内容变更指示的能力。使用Callback异步回调 callback failed');
      //     } else {
      //       console.info('client端启用或者禁用接收server端特征值内容变更指示的能力。使用Callback异步回调 callback successful');
      //     }
      //   });

    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' +
      (err as BusinessError).message);
    }


  }

  public connectDevice(deviceClass: BlueTooth_devices) {
    try {
      console.info('开始连接BLE设备:', this.device_address);
      this.BlueTooth_devices = deviceClass
      this.gattClient = ble.createGattClientDevice(this.device_address);
      console.info('GATT客户端创建成功');

      // 设置监听器 - 在连接之前设置，确保不会错过状态变化
      this.gattClient.on('BLECharacteristicChange', (changeReq) => this.CharacteristicChange(changeReq));
      this.gattClient.on('BLEConnectionStateChange', (state) => this.ConnectStateChanged(state));

      this.gattClient.connect();
      console.info('发起连接请求');
      // 注意：获取服务现在在ConnectStateChanged中处理，当连接状态变为2（已连接）时
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' +
      (err as BusinessError).message);
    }
  }

  //监听连接状态改变
  ConnectStateChanged(state: ble.BLEConnectionChangeState) {
    let connectState: number = state.state;
    console.info('bluetooth connect state changed', connectState);

    // 连接状态: 0=断开, 1=连接中, 2=已连接, 3=断开中
    if (connectState === 2) {
      console.info('蓝牙设备连接成功，准备获取服务');
      // 连接成功时启动特征值变化超时检测
      this.startCharacteristicTimeout();

      // HID设备连接成功后，暂时不发送0x61命令，先等待设备主动发送数据
      console.info('HID设备连接成功，等待设备主动发送数据，不发送0x61命令');
      // 如果需要发送0x61命令，可以取消下面的注释
      // setTimeout(() => {
      //   this.send([0x61]);
      // }, 50);

      // 连接成功时，延迟一小段时间再获取服务，确保连接完全稳定
      const self = this;
      setTimeout(() => {
        self.getServicesAfterConnection();
      }, 100);

      // 更新设备连接状态
      try {
        if ((AppStorage.get('devices') as DeviceArrayType_Ble[]) &&
          (AppStorage.get('devices') as DeviceArrayType_Ble[]).length > 0 && this.device_currIndex >= 0 &&
          this.device_currIndex < (AppStorage.get('devices') as DeviceArrayType_Ble[]).length) {
          if (this.devices[this.device_currIndex].mouseconfig) {
            this.devices[this.device_currIndex].mouseconfig!.isConnected = true;
          }
        }
      } catch (err) {
        console.error('更新设备连接状态失败:', err);
      }
    } else if (connectState === 0) {
      console.info('检测到蓝牙连接断开');
      // 连接断开时停止特征值变化超时检测
      this.stopCharacteristicTimeout();
      // 连接断开时更新设备连接状态
      try {
        if ((AppStorage.get('devices') as DeviceArrayType_Ble[]) &&
          (AppStorage.get('devices') as DeviceArrayType_Ble[]).length > 0 && this.device_currIndex >= 0 &&
          this.device_currIndex < (AppStorage.get('devices') as DeviceArrayType_Ble[]).length) {
          if (this.devices[this.device_currIndex].mouseconfig) {
            this.devices[this.device_currIndex].mouseconfig!.isConnected =
              false;
          }
        }
      } catch (err) {
        console.error('更新设备断开状态失败:', err);
      }
    }
  }

  // 在连接成功后获取服务
  private getServicesAfterConnection() {
    if (!this.gattClient) {
      console.error('gattClient未初始化，无法获取服务');
      return;
    }

    console.info('连接成功后开始获取BLE服务');
    this.gattClient.getServices()
      .then((result: Array<ble.GattService>) => {
        console.info('获取服务成功，发现', result.length, '个服务');
        for (let item of result) {
          console.log('发现服务:', item.serviceUuid);
          if (item.serviceUuid === this.HID_SERVICE_UUID) {
            console.info('找到HID服务，开始处理特征');
            for (let characteristic of item.characteristics) {
              console.log('发现HID特征:', characteristic.characteristicUuid, '描述符数量:', characteristic.descriptors?.length || 0);

              // 处理HID Report特征 - 可能有多个实例
              if (characteristic.characteristicUuid === this.HID_REPORT_CHAR_UUID) {
                // 选择第一个有CCCD的HID Report特征
                if (characteristic.descriptors && characteristic.descriptors.length >= 2) {
                  const hasCCCD = characteristic.descriptors.some(desc => desc.descriptorUuid === '00002902-0000-1000-8000-00805F9B34FB');
                  if (hasCCCD && !this.HID_REPORT_DESCRIPTORS.length) {
                    this.HID_REPORT_DESCRIPTORS = characteristic.descriptors;
                    console.info('选择HID Report特征（有CCCD），描述符数量:', this.HID_REPORT_DESCRIPTORS.length);
                  }
                } else if (!this.HID_REPORT_DESCRIPTORS.length) {
                  // 如果没有找到有CCCD的特征，先选择第一个
                  this.HID_REPORT_DESCRIPTORS = characteristic.descriptors || [];
                  console.info('选择HID Report特征（无CCCD），描述符数量:', this.HID_REPORT_DESCRIPTORS.length);
                }
              }

              // 处理Boot Keyboard Input特征
              if (characteristic.characteristicUuid === this.HID_BOOT_KEYBOARD_INPUT_UUID) {
                this.HID_BOOT_KEYBOARD_INPUT_DESCRIPTORS = characteristic.descriptors || [];
                console.info('找到HID Boot Keyboard Input特征，描述符数量:', this.HID_BOOT_KEYBOARD_INPUT_DESCRIPTORS.length);
              }
            }

            console.log('最终选择的HID特征:');
            console.log('- HID Report特征描述符数量:', this.HID_REPORT_DESCRIPTORS.length);
            console.log('- HID Boot Keyboard Input特征描述符数量:', this.HID_BOOT_KEYBOARD_INPUT_DESCRIPTORS.length);
          }
        }

        if (this.gattClient) {
          this.gattClient.getDeviceName((err: BusinessError, data: string) => {
            console.info('device name err ' + JSON.stringify(err));
            console.error('device name' + data);
            // 安全检查设备索引
            if ((AppStorage.get('devices') as DeviceArrayType_Ble[]) && this.device_currIndex >= 0 &&
              this.device_currIndex < (AppStorage.get('devices') as DeviceArrayType_Ble[]).length) {
              this.devices[this.device_currIndex].name = data
            }
          })
        }

        let device: DeviceArrayType_Ble = {
          BlueTooth_devices: this.BlueTooth_devices as BlueTooth_devices,
          mouseconfig: null,
          getModelInfo: null,
          connectionmethod: connectionmethodType.Bluetooth,
          KeymethodConfig: [],
          DPI_currInfo: null,
          currLED: true,
          reportRate_currIndex: 0,
          isPunctuationRecognition: true,
          speech_Recognition_languages: 'ZH_CN',
          productImg: '',
          PRODUCT_TYPE: PRODUCT_TYPE.DEFAULT,
          name: ''
        }
        // 更新设备列表，确保UI正确显示
        const currentDevices = AppStorage.get('devices') as DeviceArrayType_Ble[] || [];
        currentDevices.push(device);
        // 使用深拷贝确保UI更新
        const newDevices = deepCopyDevices(currentDevices);
        AppStorage.setOrCreate('devices', newDevices);
        this.devices = newDevices;
        this.device_currIndex = this.devices.length - 1;

        // 立即触发UI更新，确保新设备立即显示
        console.info('新设备添加完成，立即触发UI更新');
        setTimeout(() => {
          // 再次更新AppStorage以触发@Watch监听器
          AppStorage.setOrCreate('devices', deepCopyDevices(newDevices));
        }, 100);

        //client端启用或者禁用接收server端特征值内容变更通知的能力
        console.info('开始设置特征值变更通知');
        this.setCharacteristicChangeNotification();

        // 添加延迟后测试通知状态
        setTimeout(() => {
          this.testNotificationStatus();
        }, 2000);
      }).catch((err: BusinessError) => {
      console.error('获取服务失败:', err.code, err.message);
      if (this.gattClient) {
        this.gattClient.getDeviceName((err: BusinessError, data: string) => {
          console.warn('设备暂未连接设备蓝牙:', data)
        })
      }
    })
  }

  /**
   * client端从指定的server端描述符读取数据
   */
  readCcc(code: BusinessError, BLEDescriptor: ble.BLEDescriptor) {
    console.error('client端从指定的server端描述符读取数据：', JSON.stringify(code), JSON.stringify(BLEDescriptor))
    if (code.code != 0) {
      return;
    }
    console.info('bluetooth descriptor uuid: ' + BLEDescriptor.descriptorUuid);
    let value = new Uint8Array(BLEDescriptor.descriptorValue);
    console.info('bluetooth descriptor value: ' + value[0]);
  }

  public readDescriptorValue() {
    let bufferDesc = new ArrayBuffer(2);
    let descV = new Uint8Array(bufferDesc);
    descV[0] = 0; // 以Client Characteristic Configuration描述符为例，表示bit0、bit1均为0，notification和indication均不开启
    let descriptor: ble.BLEDescriptor = {
      serviceUuid: '00001812-0000-1000-8000-00805F9B34FB',
      characteristicUuid: '00002A22-0000-1000-8000-00805F9B34FB',
      descriptorUuid: '00002902-0000-1000-8000-00805F9B34FB',
      descriptorValue: bufferDesc
    };

    (this.gattClient as ble.GattClientDevice).readDescriptorValue(descriptor, this.readCcc);
  }

  /**
   * client端从指定的server端特征值读取数据
   */
  readCcc1(code: BusinessError, BLECharacteristic: ble.BLECharacteristic) {
    console.error('client端从指定的server端特征值读取数据：', JSON.stringify(code), JSON.stringify(BLECharacteristic))
    if (code.code != 0) {
      return;
    }
    console.info('bluetooth characteristic uuid: ' + BLECharacteristic.characteristicUuid);
    let value = new Uint8Array(BLECharacteristic.characteristicValue);
    console.info('bluetooth characteristic value: ' + value[0]);
  }

  public readCharacteristicValue() {
    let descriptors: Array<ble.BLEDescriptor> = [];
    let bufferDesc = new ArrayBuffer(2);
    let descV = new Uint8Array(bufferDesc);
    descV[0] =
      0; // 以Client Characteristic Configuration描述符为例，表示bit0、bit1均为0，notification和indication均不开启
    let descriptor: ble.BLEDescriptor = {
      serviceUuid: '00001812-0000-1000-8000-00805F9B34FB',
      characteristicUuid: '00002A22-0000-1000-8000-00805F9B34FB',
      descriptorUuid: '00002902-0000-1000-8000-00805F9B34FB',
      descriptorValue: bufferDesc
    };
    descriptors[0] = descriptor;

    let bufferCCC = new ArrayBuffer(8);
    let cccV = new Uint8Array(bufferCCC);
    cccV[0] = 1;
    let characteristic: ble.BLECharacteristic = {
      serviceUuid: '00001812-0000-1000-8000-00805F9B34FB',
      characteristicUuid: '00002A22-0000-1000-8000-00805F9B34FB',
      characteristicValue: bufferCCC,
      descriptors: descriptors
    };

    (this.gattClient as ble.GattClientDevice).readCharacteristicValue(characteristic, this.readCcc1);
  }

  /**
   * client端向指定的server端特征值写入数据
   */

  public async send(command: number[] = [0x61]) {
    try {
      // 特别记录0x61命令（设备信息获取）
      if (command[0] === 0x61) {
        console.info('>>> 发送0x61设备信息获取命令 <<<');
      }

      let bufferCCC = this.buildCommandFrame(command);
      const hexString = Array.from(bufferCCC).map(b => b.toString(16).padStart(2, '0')).join(' ');
      console.log(`HID发送命令 0x${command[0].toString(16)}:`, hexString, '\t发送数据长度', bufferCCC.length);

      // 创建 ArrayBuffer
      let arrayBuffer = new ArrayBuffer(bufferCCC.length);
      let dataView = new Uint8Array(arrayBuffer);
      dataView.set(bufferCCC);

      let characteristic: ble.BLECharacteristic = {
        serviceUuid: this.HID_SERVICE_UUID,
        characteristicUuid: this.HID_REPORT_CHAR_UUID,
        characteristicValue: arrayBuffer,
        descriptors: this.HID_REPORT_DESCRIPTORS
      };

      // HID Report特征支持writeNoResponse，使用WRITE_NO_RESPONSE以提高性能
      (this.gattClient as ble.GattClientDevice).writeCharacteristicValue(
        characteristic,
        ble.GattWriteType.WRITE_NO_RESPONSE
      ).then(() => {
        if (command[0] === 0x61) {
          console.info('>>> 0x61设备信息获取命令发送成功 <<<');
        } else {
          console.info('HID Report特征写入成功');
        }
      }).catch((err: BusinessError) => {
        if (command[0] === 0x61) {
          console.error(`>>> 0x61设备信息获取命令发送失败: errCode: ${err.code}, errMessage: ${err.message} <<<`);
        } else {
          console.error(`HID Report特征写入失败: errCode: ${err.code}, errMessage: ${err.message}`);
        }

        // 如果 WRITE_NO_RESPONSE 失败，尝试使用 WRITE
        (this.gattClient as ble.GattClientDevice).writeCharacteristicValue(
          characteristic,
          ble.GattWriteType.WRITE
        ).then(() => {
          if (command[0] === 0x61) {
            console.info('>>> 使用WRITE方式发送0x61命令成功 <<<');
          } else {
            console.info('使用 WRITE 方式写入HID Report成功');
          }
        }).catch((err2: BusinessError) => {
          if (command[0] === 0x61) {
            console.error(`>>> WRITE方式发送0x61命令也失败: errCode: ${err2.code}, errMessage: ${err2.message} <<<`);
          } else {
            console.error(`WRITE 方式写入HID Report也失败: errCode: ${err2.code}, errMessage: ${err2.message}`);
          }
        });
      });

    } catch (err) {
      console.error('HID发送命令异常: errCode: ' + (err as BusinessError).code + ', errMessage: ' +
      (err as BusinessError).message);
    }
  }

  /**
   * client端向指定的server端描述符写入数据。使用Promise异步回调。
   */
  public writeDescriptorValue() {
    let descriptors: Array<ble.BLEDescriptor> = [];
    let bufferDesc = new ArrayBuffer(2);
    let descV = new Uint8Array(bufferDesc);
    descV[0] = 0; // 以Client Characteristic Configuration描述符为例，表示bit0、bit1均为0，notification和indication均不开启
    let descriptor: ble.BLEDescriptor = {
      serviceUuid: '00001812-0000-1000-8000-00805F9B34FB',
      characteristicUuid: '00002A22-0000-1000-8000-00805F9B34FB',
      descriptorUuid: '00002902-0000-1000-8000-00805F9B34FB',
      descriptorValue: bufferDesc
    };

    try {
      (this.gattClient as ble.GattClientDevice).writeDescriptorValue(descriptor).then(() => {
        console.info('writeDescriptorValue promise success');
      });
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  // 构建命令帧的通用方法
  private buildCommandFrame(cmd: number[], length: number = 21): Uint8Array {
    const frame = new Uint8Array(length);

    // 帧头固定
    frame[0] = 0x0C; // 帧头高位
    frame[1] = 0x4D; // 帧头低位

    // 处理命令参数（支持单个数字或数组）
    let cmdData: number[];
    cmdData = cmd;

    // 设置数据长度（数据域的长度，不包括结束标志）
    frame[2] = cmdData.length + 3;

    if (cmd[0] === 0x6f) {
      frame[2] = 0x12;
    }

    // 填充命令数据
    for (let i = 0; i < cmdData.length; i++) {
      if (3 + i < length) {
        frame[3 + i] = cmdData[i];
      }
    }
    // 结束标志位置（根据命令数据长度动态调整）
    const endFlagPosition = 3 + cmdData.length;
    if (endFlagPosition < length) {
      frame[endFlagPosition] = 0x4C; // 结束标志
    }
    // 剩余字节填充0
    for (let i = endFlagPosition + 1; i < length; i++) {
      frame[i] = 0x00;
    }
    // 去除第一帧（帧头部分），返回从索引1开始的数据
    return frame.slice(1);
    // return frame;
  }
}

// 深拷贝设备数组
function deepCopyDevices(devices: DeviceArrayType_Ble[]): DeviceArrayType_Ble[] {
  return devices.map(device => {
    const newDevice: DeviceArrayType_Ble = {
      BlueTooth_devices: device.BlueTooth_devices,
      mouseconfig: device.mouseconfig,
      getModelInfo: device.getModelInfo,
      connectionmethod: device.connectionmethod,
      KeymethodConfig: device.KeymethodConfig.map(config => {
        const newConfig: KeymethodConfig = {
          key: config.key,
          currIndex: config.currIndex
        };
        return newConfig;
      }),
      DPI_currInfo: device.DPI_currInfo,
      currLED: device.currLED,
      reportRate_currIndex: device.reportRate_currIndex,
      isPunctuationRecognition: device.isPunctuationRecognition,
      speech_Recognition_languages: device.speech_Recognition_languages,
      productImg: device.productImg,
      PRODUCT_TYPE: device.PRODUCT_TYPE,
      name: device.name
    };
    return newDevice;
  });
}

//获取已配对的蓝牙连接列表
function getPairedDevices() {
  try {
    // 获取已配对设备的地址数组
    let pairedDevices: Array<string> = connection.getPairedDevices();
    console.log('Paired devices:', pairedDevices); // 例如：['11:22:33:AA:BB:FF', '68:13:24:79:4C:8C']

    for (let i = 0; i < pairedDevices.length; i++) {
      const item = pairedDevices[i];

      // 延迟连接，避免同时连接太多设备
      setTimeout(() => {
        try {
          // 获取对端蓝牙设备的名称
          let remoteDeviceName: string = connection.getRemoteDeviceName(item, true);
          console.log('获取对端蓝牙设备的名称:', remoteDeviceName);

          try {
            connection.getRemoteProfileUuids(item, (err: BusinessError, data: Array<connection.ProfileUuids>) => {
              console.error('getRemoteProfileUuids, err: ' + JSON.stringify(err) + '\n' + item +
                '\t蓝牙Profile协议的UUID: ' + JSON.stringify(data));
            });
          } catch (err) {
            console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' +
            (err as BusinessError).message);
          }

          let device = new BlueTooth_devices(item);

          /**
           * 连接设备
           */
          device.connectDevice(device);

        } catch (deviceErr) {
          console.error('处理设备连接失败:', item, deviceErr);
        }
      }, i * 200); // 每个设备间隔200ms
    }

  } catch (err) {
    console.error('Error getting paired devices. Code: ' + (err as BusinessError).code + ', Message: ' +
    (err as BusinessError).message);
  }
}

export function connectDevice(context: common.UIAbilityContext) {
  // 使用UIExtensionAbility：将common.UIAbilityContext 替换为common.UIExtensionContext
  // const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  console.error('进入蓝牙连接：')
  reqPermissionsFromUser(permissions, context);
}
