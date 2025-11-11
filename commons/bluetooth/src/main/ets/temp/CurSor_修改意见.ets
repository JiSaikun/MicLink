import { a2dp, ble, constant } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { connection } from '@kit.ConnectivityKit';
import { LengthMetrics, promptAction } from '@kit.ArkUI';
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
        getPairedDevices()
      } else {
        // 当用户拒绝授权时，系统应提示用户必须授予相应权限才能使用当前页面的功能，并指导用户前往系统设置开启所需权限。
        promptAction.showToast({ message: '请打开蓝牙设备获取权限', duration: 2000 })
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
  private CUSTOM_SERVICE_UUID: string = "00010203-0405-0607-0809-0a0b0c0d1911"
  private NOTIFY_CHAR_UUID: string = "00010203-0405-0607-0809-0a0b0c0d2b18"
  private WRITE_CHAR_UUID: string = "00010203-0405-0607-0809-0a0b0c0d2b19"
  public audioDataState: boolean = false //是否录入开启
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

  constructor(device_address: string) {
    this.device_address = device_address;
  }

  CharacteristicChange = (characteristicChangeReq: ble.BLECharacteristic) => {
    let serviceUuid: string = characteristicChangeReq.serviceUuid;
    let characteristicUuid: string = characteristicChangeReq.characteristicUuid;
    let value: Uint8Array = new Uint8Array(characteristicChangeReq.characteristicValue);
    console.warn('client端订阅server端特征值变化事件', value)
    hilog.warn(0x00, 'send',
      '*******************************************************************************接收鼠标发送的消息');
    console.log('读取数据结果,读取到的数据的长度:', value.length);
    value = new Uint8Array([0, ...value])
    if (value.length > 0) {
      const hexData = Array.from(value.slice(0, value.length)).map(b => b.toString(16).padStart(2, '0')).join(' ');
      console.log('接收到的数据展示:', hexData);
      // 解析设备信息
      this.parseDeviceInfo(value.slice(0, value.length));
    } else {
      console.log('未接收到数据');
    }
  }

  public parseDeviceInfo(data: Uint8Array): void {
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
        // 检查帧头F
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
            this.devices[this.device_currIndex].mouseconfig = this.deviceInfo;

            if (!this.getModelInfo) {
              this.devices = AppStorage.get('devices') as DeviceArrayType_Ble[]
              AppStorage.setOrCreate('devices', null);
              const newList: DeviceArrayType_Ble[] = JSON.parse(JSON.stringify(this.devices));
              AppStorage.setOrCreate('devices', newList);
            } else {
              if (!this.devices[this.device_currIndex].KeymethodConfig.length) {
                this.devices[this.device_currIndex].KeymethodConfig = [
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

                for (let item
                  of this.devices[this.device_currIndex]?.getModelInfo?.keyInfos as keyInfosModel[]) {
                  for (let childs of item.childs) {
                    childs.childs.forEach((keyInfos_childs_childsModel, index) => {
                      if (keyInfos_childs_childsModel.first === 1) {
                        switch (item.key) {
                          case 'voice_key': //语音键
                            if (childs.operation === 'sk') { //单击
                              this.devices[this.device_currIndex].KeymethodConfig[0].currIndex = index;
                            }
                            if (childs.operation === 'lk') { //长按
                              this.devices[this.device_currIndex].KeymethodConfig[1].currIndex = index;
                            }
                            break;
                          case 'search_key': //搜索键
                            if (childs.operation === 'sk') {
                              this.devices[this.device_currIndex].KeymethodConfig[2].currIndex = index;
                            }
                            if (childs.operation === 'lk') { //长按
                              this.devices[this.device_currIndex].KeymethodConfig[3].currIndex = index;
                            }
                            break;
                          case 'translate_key': //翻译键
                            if (childs.operation === 'sk') {
                              this.devices[this.device_currIndex].KeymethodConfig[4].currIndex = index;
                            }
                            if (childs.operation === 'lk') { //长按
                              this.devices[this.device_currIndex].KeymethodConfig[5].currIndex = index;
                            }
                            break;
                          case 'AI_key': //AI键
                            if (childs.operation === 'sk') {
                              this.devices[this.device_currIndex].KeymethodConfig[6].currIndex = index;
                            }
                            if (childs.operation === 'lk') { //长按
                              this.devices[this.device_currIndex].KeymethodConfig[7].currIndex = index;
                            }
                            break;
                          case 'M_key': //AI键
                            if (childs.operation === 'sk') {
                              this.devices[this.device_currIndex].KeymethodConfig[8].currIndex = index;
                            }
                            if (childs.operation === 'lk') { //长按
                              this.devices[this.device_currIndex].KeymethodConfig[9].currIndex = index;
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

            this.devices[this.device_currIndex].mouseconfig = this.deviceInfo;

            if (!this.devices[this.device_currIndex].getModelInfo) {
              this.devices = AppStorage.get('devices') as DeviceArrayType_Ble[]
              AppStorage.setOrCreate('devices', null);
              const newList: DeviceArrayType_Ble[] = JSON.parse(JSON.stringify(this.devices));
              AppStorage.setOrCreate('devices', newList);
            } else {
              if (!this.devices[this.device_currIndex].KeymethodConfig.length) {
                this.devices[this.device_currIndex].KeymethodConfig = [
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

                for (let item
                  of this.devices[this.device_currIndex]?.getModelInfo?.keyInfos as keyInfosModel[]) {
                  for (let childs of item.childs) {
                    childs.childs.forEach((keyInfos_childs_childsModel, index) => {
                      if (keyInfos_childs_childsModel.first === 1) {
                        switch (item.key) {
                          case 'voice_key': //语音键
                            if (childs.operation === 'sk') { //单击
                              this.devices[this.device_currIndex].KeymethodConfig[0].currIndex = index;
                            }
                            if (childs.operation === 'lk') { //长按
                              this.devices[this.device_currIndex].KeymethodConfig[1].currIndex = index;
                            }
                            break;
                          case 'search_key': //搜索键
                            if (childs.operation === 'sk') {
                              this.devices[this.device_currIndex].KeymethodConfig[2].currIndex = index;
                            }
                            if (childs.operation === 'lk') { //长按
                              this.devices[this.device_currIndex].KeymethodConfig[3].currIndex = index;
                            }
                            break;
                          case 'translate_key': //翻译键
                            if (childs.operation === 'sk') {
                              this.devices[this.device_currIndex].KeymethodConfig[4].currIndex = index;
                            }
                            if (childs.operation === 'lk') { //长按
                              this.devices[this.device_currIndex].KeymethodConfig[5].currIndex = index;
                            }
                            break;
                          case 'AI_key': //AI键
                            if (childs.operation === 'sk') {
                              this.devices[this.device_currIndex].KeymethodConfig[6].currIndex = index;
                            }
                            if (childs.operation === 'lk') { //长按
                              this.devices[this.device_currIndex].KeymethodConfig[7].currIndex = index;
                            }
                            break;
                          case 'M_key': //AI键
                            if (childs.operation === 'sk') {
                              this.devices[this.device_currIndex].KeymethodConfig[8].currIndex = index;
                            }
                            if (childs.operation === 'lk') { //长按
                              this.devices[this.device_currIndex].KeymethodConfig[9].currIndex = index;
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
        console.warn(JSON.stringify(this.devices[this.device_currIndex].KeymethodConfig));
        console.error('解析设备信息错误:', error);
      }

      /**
       * 防止没有接收到鼠标配置信息
       */
      if (this.deviceInfo.sn === '') {
        console.log('没有收到0x61命令,重新获取设备信息');
        this.send();
      } else {
        if (!this.devices[this.device_currIndex].getModelInfo) {
          console.warn(this.deviceInfo.productType.toString());
          const params: getModelInfo_Params = {
            languageCode: '',
            productCode: this.deviceInfo.productType.toString(),
            sno: this.deviceInfo.sn
          };

          _getModelInfo(params).then((res) => {
            console.log('获取用户按键模式详情数据', JSON.stringify(res.data));
            if (res.status === 200) {
              let getModelInfo: getModelInfoModel = res.data as getModelInfoModel;
              this.devices[this.device_currIndex].getModelInfo = getModelInfo;
              this.devices = AppStorage.get('devices') as DeviceArrayType_Ble[]
              const newList: DeviceArrayType_Ble[] = JSON.parse(JSON.stringify(this.devices));
              AppStorage.setOrCreate('devices', newList);

              /**
               * 判断当前设备是否是键盘
               */
              if ((this.devices[this.device_currIndex].getModelInfo as getModelInfoModel).functions.length !==
                0) {
                for (let item
                  of (this.devices[this.device_currIndex].getModelInfo as getModelInfoModel).functions) {
                  if (item.code === 'keyboard') {
                    this.devices[this.device_currIndex].PRODUCT_TYPE = PRODUCT_TYPE.keyboard;
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
      // 移除帧头(0x1b)
      let audioFrame = data.subarray(1);
      if (Number(this.deviceInfo.firmwareVersion) > 23) {
        // 解密音频数据
        const decryptedData = this.audioProcessor.miclinkDecrypt(audioFrame);
        // 这里可以添加播放或保存PCM数据的逻辑
        audioFrame = decryptedData;
      }

      // 解码为PCM
      const pcmData = this.audioProcessor.processVoiceData(audioFrame);

      if (pcmData) {
        // 处理PCM数据（播放或保存）
        console.log(`解码得到PCM数据: ${pcmData.length}个样本`, '\n', '具体数据：', pcmData);
        // 这里可以添加播放或保存PCM数据的逻辑
        BlueTooth_devices.audioData.push(pcmData);
      }
    } catch (error) {
      console.error('处理音频数据失败:', error);
    }
  }

  /**
   * client端启用或者禁用接收server端特征值内容变更通知的能力
   */
  public setCharacteristicChangeNotification() {
    let descriptors: Array<ble.BLEDescriptor> = [];
    let arrayBuffer = new ArrayBuffer(2);
    let descV = new Uint8Array(arrayBuffer);
    descV[0] = 0; // 以Client Characteristic Configuration描述符为例，表示bit0、bit1均为0，notification和indication均不开启
    let descriptor: ble.BLEDescriptor = {
      serviceUuid: this.CUSTOM_SERVICE_UUID,
      characteristicUuid: this.NOTIFY_CHAR_UUID,
      descriptorUuid: '00002902-0000-1000-8000-00805F9B34FB',
      descriptorValue: arrayBuffer
    };
    descriptors[0] = descriptor;
    let arrayBufferC = new ArrayBuffer(8);
    let characteristic: ble.BLECharacteristic = {
      serviceUuid: this.CUSTOM_SERVICE_UUID,
      characteristicUuid: this.NOTIFY_CHAR_UUID,
      characteristicValue: arrayBufferC,
      descriptors: descriptors
    };
    try {
      (this.gattClient as ble.GattClientDevice).setCharacteristicChangeNotification(characteristic, true,
        (err: BusinessError) => {
          if (err) {
            console.error('client端启用或者禁用接收server端特征值内容变更通知的能力。使用Callback异步回调 callback failed');
          } else {
            console.info('client端启用或者禁用接收server端特征值内容变更通知的能力。使用Callback异步回调 callback successful');
          }
        });
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' +
      (err as BusinessError).message);
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
      serviceUuid: this.CUSTOM_SERVICE_UUID,
      characteristicUuid: this.NOTIFY_CHAR_UUID,
      descriptorUuid: '00002902-0000-1000-8000-00805F9B34FB',
      descriptorValue: arrayBuffer
    };
    descriptors[0] = descriptor;
    let arrayBufferC = new ArrayBuffer(8);
    let characteristic: ble.BLECharacteristic = {
      serviceUuid: this.CUSTOM_SERVICE_UUID,
      characteristicUuid: this.NOTIFY_CHAR_UUID,
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
      this.BlueTooth_devices = deviceClass
      this.gattClient = ble.createGattClientDevice(this.device_address);
      this.gattClient.connect();
      setTimeout(() => {
        (this.gattClient as ble.GattClientDevice).getServices()
          .then((result: Array<ble.GattService>) => {
            // console.warn('getServices successfully:' + JSON.stringify(result));
            // for (let index = 0; index < result.length; index++) {
            //   console.warn('ssss',JSON.stringify(result[index]))
            // }
            (this.gattClient as ble.GattClientDevice).getDeviceName((err: BusinessError, data: string) => {
              console.info('device name err ' + JSON.stringify(err));
              console.error('device name' + data);
              this.devices[this.device_currIndex].name = data
            })
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
            this.devices = AppStorage.get('devices') as DeviceArrayType_Ble[]
            this.devices.push(device)
            AppStorage.setOrCreate('devices', this.devices)
            this.device_currIndex = this.devices.length - 1;

            //client端启用或者禁用接收server端特征值内容变更通知的能力
            this.setCharacteristicChangeNotification()
            // setTimeout(() => {
            //   this.setCharacteristicChangeIndication()
            // }, 500)
          }).catch(() => {
          (this.gattClient as ble.GattClientDevice).getDeviceName((err: BusinessError, data: string) => {
            console.warn('设备暂未连接设备蓝牙:', data)
          })
        })
      }, 20)
      this.gattClient.on('BLECharacteristicChange', this.CharacteristicChange);
      this.gattClient.on('BLEConnectionStateChange', this.ConnectStateChanged);
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' +
      (err as BusinessError).message);
    }
  }

  //监听连接状态改变
  ConnectStateChanged(state: ble.BLEConnectionChangeState) {
    let connectState: ble.ProfileConnectionState = state.state;
    console.info('bluetooth connect state changed', connectState);
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

  public async send(command: number[] = [0x61]): Promise<boolean> {
    // 检查 gattClient 是否已初始化
    if (!this.gattClient) {
      console.error('GATT客户端未初始化，无法发送数据');
      return false;
    }

    let descriptors: Array<ble.BLEDescriptor> = [];
    let bufferDesc = new ArrayBuffer(2);
    let descV = new Uint8Array(bufferDesc);
    descV[0] = 0; // 以Client Characteristic Configuration描述符为例，表示bit0、bit1均为0，notification和indication均不开启
    let descriptor: ble.BLEDescriptor = {
      serviceUuid: this.CUSTOM_SERVICE_UUID,
      characteristicUuid: this.WRITE_CHAR_UUID,
      descriptorUuid: '',
      descriptorValue: bufferDesc
    };
    descriptors[0] = descriptor;

    let bufferCCC = this.buildCommandFrame(command);
    const hexString = Array.from(bufferCCC).map(b => b.toString(16).padStart(2, '0')).join(' ');
    console.log(`发送命令 0x${command[0].toString(16)}:`, hexString, '\t发送数据长度', bufferCCC.length)
    console.error(bufferCCC.length + JSON.stringify(bufferCCC))
    // let cccV = new Uint8Array(bufferCCC);
    // cccV[0] = 1;
    let characteristic: ble.BLECharacteristic = {
      serviceUuid: this.CUSTOM_SERVICE_UUID,
      characteristicUuid: this.WRITE_CHAR_UUID,
      characteristicValue: bufferCCC,
      descriptors: []
    };
    try {
      // 发送第一帧数据（21字节）
      await this.gattClient.writeCharacteristicValue(characteristic, ble.GattWriteType.WRITE);
      console.log('第一帧数据发送成功');

      // 发送第二帧数据（33字节）
      bufferCCC = this.buildCommandFrame(command, 33);
      console.log('准备发送第二帧:', JSON.stringify(bufferCCC));
      let characteristic2: ble.BLECharacteristic = {
        serviceUuid: this.CUSTOM_SERVICE_UUID,
        characteristicUuid: this.WRITE_CHAR_UUID,
        characteristicValue: bufferCCC,
        descriptors: []
      };
      await this.gattClient.writeCharacteristicValue(characteristic2, ble.GattWriteType.WRITE);
      console.log('第二帧数据发送成功');
      return true;
    } catch (err) {
      console.error('发送数据失败 - errCode: ' + (err as BusinessError).code + ', errMessage: ' +
      (err as BusinessError).message);
      return false;
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

//获取已配对的蓝牙连接列表
function getPairedDevices() {
  try {
    // 获取已配对设备的地址数组
    let pairedDevices: Array<string> = connection.getPairedDevices();
    console.log('Paired devices:', pairedDevices); // 例如：['11:22:33:AA:BB:FF', '68:13:24:79:4C:8C']
    for (let item of pairedDevices) {
      // 获取对端蓝牙设备的名称
      let remoteDeviceName: string = connection.getRemoteDeviceName(item, true);
      console.log('获取对端蓝牙设备的名称:', remoteDeviceName); // 例如：['11:22:33:AA:BB:FF', '68:13:24:79:4C:8C']
      try {
        connection.getRemoteProfileUuids(item, (err: BusinessError, data: Array<connection.ProfileUuids>) => {
          console.error('getRemoteProfileUuids, err: ' + JSON.stringify(err) + '\n' + item +
            '\t蓝牙Profile协议的UUID: ' + JSON.stringify(data));
        });
      } catch (err) {
        console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' +
        (err as BusinessError).message);
      }
      let device = new BlueTooth_devices(item)

      /**
       * 连接设备
       */
      device.connectDevice(device)

    }

  } catch (err) {
    console.error('Error getting paired devices. Code: ' + (err as BusinessError).code + ', Message: ' +
    (err as BusinessError).message);
  }
}

@Entry
@Component
struct I {
  @State gattClient: ble.GattClientDevice | null = null
  @StorageLink('devices') devices: BlueTooth_devices[] = []

  aboutToAppear() {
    // 使用UIExtensionAbility：将common.UIAbilityContext 替换为common.UIExtensionContext
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    reqPermissionsFromUser(permissions, context);
  }

  build() {
    Flex({ direction: FlexDirection.Column, space: { main: LengthMetrics.px(30) } }) {
      ForEach(this.devices, (item: BlueTooth_devices, index) => {
        Column() {
          Text('蓝牙连接设备：' + item.device_address)
          Button('client端从指定的server端特征值读取数据')
            .onClick(() => {
              item.readCharacteristicValue()
            })
          Button('client端从指定的server端描述符读取数据')
            .onClick(() => {
              item.readDescriptorValue()
            })
          Button('向指定的server端特征值写入数据')
            .onClick(() => {
              item.send()
            })
            .margin(20)
          Button('client端从指定的server端描述符读取数据')
            .onClick(() => {
              item.writeDescriptorValue()
            })
        }

      }, (item: BlueTooth_devices) => JSON.stringify(item.gattClient))
    }

  }
}
