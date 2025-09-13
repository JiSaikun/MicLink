import { usbManager } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 按键类型枚举
export enum KeyPressType {
  VOICE_CLICK = 11,
  VOICE_DOUBLE_CLICK = 12,
  VOICE_LONG_PRESS_DOWN = 13,
  VOICE_LONG_PRESS_UP = 14,
  SEARCH_CLICK = 21,
  SEARCH_DOUBLE_CLICK = 22,
  SEARCH_LONG_PRESS_DOWN = 23,
  SEARCH_LONG_PRESS_UP = 24,
  TRANSLATE_CLICK = 31,
  TRANSLATE_DOUBLE_CLICK = 32,
  TRANSLATE_LONG_PRESS_DOWN = 33,
  TRANSLATE_LONG_PRESS_UP = 34,
  CUSTOM_CLICK = 41,
  CUSTOM_DOUBLE_CLICK = 42,
  CUSTOM_LONG_PRESS_DOWN = 43,
  CUSTOM_LONG_PRESS_UP = 44,
  AI_CLICK = 51,
  AI_DOUBLE_CLICK = 52,
  AI_LONG_PRESS_DOWN = 53,
  AI_LONG_PRESS_UP = 54,
}

// USB设备类型枚举
export enum MouseICType {
  MouseICTypeError = 0,
  MouseICTypePAW3212 = 1,
  // ... 其他类型
}

// 设备信息接口
export interface DeviceInfo {
  sn: string;
  micStatus: boolean;
  ledStatus: boolean;
  sampleRate: boolean;
  icType: MouseICType;
  dpiLevel: number;
  productType: number;
  batteryLevel: number;
  firmwareVersion: string;
  isConnected: boolean;
  reportRate: number;
  atmosphereLight: boolean;
}

// 音频处理器类
class SmartMouseAudioProcessor {
  private readonly BKEY: Uint8Array = new Uint8Array([
    0x31, 0xec, 0x06, 0xa2, 0x0c, 0x90, 0x12, 0x9d, 0x20, 0xa3,
    0x6b, 0x41, 0xbb, 0x40, 0x68, 0x5a, 0x4b, 0x12, 0xf4, 0x11,
    0x03, 0x9a, 0x4b, 0x12, 0xf6, 0x11, 0x03, 0x76, 0x0a, 0x12,
    0xd4, 0x48, 0x10, 0x49, 0x20, 0xf2, 0x20, 0x03, 0x54, 0x49,
    0x24, 0xf4, 0x20, 0x03, 0x92, 0x12, 0xf6, 0x02, 0x03, 0x20,
    0xa4, 0x91, 0x02, 0xdb, 0xc1, 0xda, 0x49, 0x19, 0x4a, 0x09,
    0x6e, 0xed, 0x6b, 0x49, 0xf8, 0xab, 0x94, 0xc1, 0x77, 0x48,
    0x01, 0xaf, 0x28, 0xc0, 0x2a, 0x39, 0x9f, 0x08, 0x90, 0x01,
    0x9e, 0x01, 0xa0, 0x09, 0x90, 0x74, 0x9a, 0x81, 0x87, 0x2b,
    0x4d, 0xab, 0x20, 0xc0, 0x75, 0x87, 0xbe, 0xec, 0x30, 0xec
  ]);

  // 处理原始音频数据并返回解码后的PCM数据
  processVoiceData(frame: Uint8Array): Int16Array | null {
    if (frame.length < 32) return null;

    try {
      // 解析预测值和索引
      const ps = new Int16Array(2);
      ps[0] = (frame[0] | (frame[1] << 8));      // predict（低字节在前）
      ps[1] = (frame[2] | (frame[3] << 8));      // predictIdx

      // 提取ADPCM编码数据（从第5字节开始）
      const adpcm = frame.subarray(4);

      // 解码为PCM（每字节ADPCM包含2个PCM样本）
      const pcmData = new Int16Array(adpcm.length * 2);
      this.adpcmToPcm(ps, pcmData, adpcm);

      return pcmData;
    } catch (e) {
      console.error('音频处理失败:', e);
      return null;
    }
  }

  // Telink 音频数据解密（逐字节异或）
  miclinkDecrypt(indata: Uint8Array, len: number = 32): Uint8Array {
    if (indata.length < len || this.BKEY.length < len) {
      throw new Error("Data or key length too short");
    }

    const outdata = new Uint8Array(len);
    for (let i = 0; i < len; i++) {
      outdata[i] = indata[i] ^ this.BKEY[i]; // 异或解密
    }
    return outdata;
  }

  // ADPCM解码为PCM的核心算法
  private adpcmToPcm(ps: Int16Array, pd: Int16Array, codes: Uint8Array): void {
    let predict = ps[0];
    let predictIdx = ps[1] & 0xFF;
    let i = 0;

    // 遍历每个ADPCM字节（每个字节包含2个4位编码）
    for (let byteIndex = 0; byteIndex < codes.length && i < pd.length; byteIndex++) {
      const codeByte = codes[byteIndex];

      // 处理低4位（第一个样本）
      let code = codeByte & 0x0F;
      let state = this.processCode(code, predict, predictIdx);
      predict = state.predict;
      predictIdx = state.predictIdx;
      if (i < pd.length) pd[i++] = predict;

      // 处理高4位（第二个样本）
      if (i < pd.length) {
        code = (codeByte >> 4) & 0x0F;
        state = this.processCode(code, predict, predictIdx);
        predict = state.predict;
        predictIdx = state.predictIdx;
        pd[i++] = predict;
      }
    }
  }

  // 处理单个ADPCM编码，返回预测值和新的索引
  private processCode(code: number, predict: number, predictIdx: number): { predict: number, predictIdx: number } {
    // ADPCM解码表（固定值）
    const idxtbl = [
      -1, -1, -1, -1, 2, 4, 6, 8,
      -1, -1, -1, -1, 2, 4, 6, 8
    ];

    const steptbl = [
      7, 8, 9, 10, 11, 12, 13, 14, 16, 17,
      19, 21, 23, 25, 28, 31, 34, 37, 41, 45,
      50, 55, 60, 66, 73, 80, 88, 97, 107, 118,
      130, 143, 157, 173, 190, 209, 230, 253, 279, 307,
      337, 371, 408, 449, 494, 544, 598, 658, 724, 796,
      876, 963, 1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066,
      2272, 2499, 2749, 3024, 3327, 3660, 4026, 4428, 4871, 5358,
      5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487, 12635, 13899,
      15289, 16818, 18500, 20350, 22385, 24623, 27086, 29794, 32767
    ];

    // 计算预测差值
    const step = steptbl[predictIdx];
    let diffq = step >> 3;

    if ((code & 4) !== 0) diffq += step;
    if ((code & 2) !== 0) diffq += step >> 1;
    if ((code & 1) !== 0) diffq += step >> 2;

    // 应用差值到预测值
    if ((code & 8) !== 0) {
      predict -= diffq;
    } else {
      predict += diffq;
    }

    // 限制PCM值范围（-32768 到 32767）
    if (predict > 32767) predict = 32767;
    if (predict < -32768) predict = -32768;

    // 更新索引并限制范围
    predictIdx += idxtbl[code];
    if (predictIdx < 0) predictIdx = 0;
    if (predictIdx > 88) predictIdx = 88;

    return { predict, predictIdx };
  }

  // 将解码后的PCM数据（Int16Array）转换为字节流（Uint8Array）
  int16ArrayToBytes(list: Int16Array): Uint8Array {
    const byteData = new ArrayBuffer(list.length * 2);
    const view = new DataView(byteData);
    for (let i = 0; i < list.length; i++) {
      view.setInt16(i * 2, list[i], true); // 小端字节序
    }
    return new Uint8Array(byteData);
  }
}

// 主通信类
export class Communication {
  static devicePipe: usbManager.USBDevicePipe | null = null;
  static deviceInfo: DeviceInfo = {
    sn: '',
    micStatus: false,
    ledStatus: false,
    sampleRate: false,
    icType: MouseICType.MouseICTypePAW3212,
    dpiLevel: 1,
    productType: 0,
    batteryLevel: 0,
    firmwareVersion: '',
    isConnected: false,
    reportRate: 125,
    atmosphereLight: false
  };
  static isPhysicalKeyboardExist: boolean = true;
  static currentDPI: number[] = [];
  static inputEndpoint: usbManager.USBEndpoint | null = null;
  static inputInterface: usbManager.USBInterface | null = null;
  static outputEndpoint: usbManager.USBEndpoint | null = null;
  static outputInterface: usbManager.USBInterface | null = null;
  static sendState: boolean = true;
  static audioProcessor: SmartMouseAudioProcessor = new SmartMouseAudioProcessor();
  static audioDataBuffer: Uint8Array = new Uint8Array(0);

  // 构建命令帧的通用方法
  static buildCommandFrame(cmd: number[], length: number): Uint8Array {
    const frame = new Uint8Array(length);

    // 帧头固定
    frame[0] = 0x0C;
    frame[1] = 0x4D;

    // 设置数据长度
    frame[2] = cmd.length + 3;

    // 填充命令数据
    for (let i = 0; i < cmd.length; i++) {
      if (3 + i < length) {
        frame[3 + i] = cmd[i];
      }
    }

    // 结束标志位置
    const endFlagPosition = 3 + cmd.length;
    if (endFlagPosition < length) {
      frame[endFlagPosition] = 0x4C;
    }

    // 剩余字节填充0
    for (let i = endFlagPosition + 1; i < length; i++) {
      frame[i] = 0x00;
    }

    return frame;
  }

  // 扫描并连接设备
  static async connectDevice() {
    console.log('开始扫描并连接设备');
    try {
      const devices = usbManager.getDevices();
      if (!devices || devices.length === 0) {
        hilog.error(0x0000, 'USB', '未找到USB设备');
        return;
      }

      // 查找匹配的设备 (VID: 0x248A)
      const targetDevice = devices.find(device => device.vendorId === 0x248A);

      if (!targetDevice) {
        hilog.error(0x0000, 'USB', '未找到鼠标设备');
        return;
      }

      // 检查权限
      const hasRight = await usbManager.hasRight(targetDevice.name);
      if (!hasRight) {
        const requestResult = await usbManager.requestRight(targetDevice.name);
        if (requestResult) {
          await this.connectDevice();
        } else {
          hilog.warn(0x0000, 'USB', '用户拒绝了权限请求');
        }
        return;
      }

      // 关闭现有连接
      if (this.devicePipe) {
        usbManager.closePipe(this.devicePipe);
        this.devicePipe = null;
      }

      // 建立新连接
      this.devicePipe = usbManager.connectDevice(targetDevice);
      hilog.info(0x0000, 'USB', '设备连接成功');

      // 查找输入输出端点
      if (!targetDevice.configs?.[0]?.interfaces) {
        console.log('无法获取设备接口信息');
        return;
      }

      for (const iface of targetDevice.configs[0].interfaces) {
        if (iface.endpoints) {
          for (const endpoint of iface.endpoints) {
            if (endpoint.direction === 0) { // 输出端点
              this.outputEndpoint = endpoint;
              this.outputInterface = iface;
            } else if (endpoint.direction === 128) { // 输入端点
              this.inputEndpoint = endpoint;
              this.inputInterface = iface;
            }
          }
        }
      }

      // 获取设备信息
      await this.getDeviceInfo([0x61]);

    } catch (error) {
      hilog.error(0x0000, 'USB', `连接失败: ${error.message}`);
      console.error('连接失败:', error);
    }
  }

  // 使用批量传输获取设备信息
  static async getDeviceInfo(command: number[] = [0x61]) {
    if (!this.devicePipe) {
      console.log('设备未连接');
      return;
    }

    if (!this.sendState && command[0] !== 0x61) {
      console.log('有消息正在发送中，稍后重试');
      setTimeout(() => {
        this.getDeviceInfo(command);
      }, 5000);
      return;
    }

    try {
      if (this.outputEndpoint && this.outputInterface && this.inputEndpoint && this.inputInterface) {
        // 发送命令
        const sendResult = await this.sendCommand(this.outputInterface, this.outputEndpoint, command);

        if (sendResult === -1) {
          console.log('发送命令失败，重新连接设备');
          usbManager.closePipe(this.devicePipe);
          this.devicePipe = null;
          await this.connectDevice();
          await this.getDeviceInfo(command);
          return;
        }

        // 读取响应
        await this.readResponse(this.inputInterface, this.inputEndpoint);

        // 设置超时检查，如果没有收到设备信息则重新获取
        setTimeout(() => {
          if (this.deviceInfo.sn === '' && this.devicePipe) {
            console.log('未收到设备信息，重新获取');
            this.getDeviceInfo();
          }
        }, 1000);

        // 开始持续读取数据
        this.startContinuousReading();

      } else {
        console.log('未找到合适的端点');
      }
    } catch (error) {
      console.error('获取设备信息失败:', error);
    }
  }

  // 开始持续读取数据
  static startContinuousReading() {
    if (!this.devicePipe || !this.inputInterface || !this.inputEndpoint) {
      return;
    }

    // 使用异步循环持续读取数据
    (async () => {
      while (this.isPhysicalKeyboardExist && this.devicePipe) {
        try {
          await this.readResponse(this.inputInterface, this.inputEndpoint);
        } catch (error) {
          console.error('读取数据失败:', error);
          // 如果读取失败，尝试重新连接
          if (this.devicePipe) {
            usbManager.closePipe(this.devicePipe);
            this.devicePipe = null;
          }
          await this.connectDevice();
          break;
        }
      }
    })();
  }

  // 发送命令到输出端点
  static async sendCommand(iface: usbManager.USBInterface, endpoint: usbManager.USBEndpoint, command: number[], length: number = 33): Promise<number> {
    if (!this.devicePipe) {
      return -1;
    }

    try {
      // 释放接口
      usbManager.releaseInterface(this.devicePipe, iface);

      // 声明接口
      const claimResult = usbManager.claimInterface(this.devicePipe, iface, true);
      if (claimResult !== 0) {
        console.log('声明接口失败');
        return -1;
      }

      // 构建命令帧
      const cmdData = this.buildCommandFrame(command, length);
      const hexString = Array.from(cmdData).map(b => b.toString(16).padStart(2, '0')).join(' ');
      console.log(`发送命令 0x${command[0].toString(16)}:`, hexString);

      // 发送命令
      const result = await usbManager.bulkTransfer(
        this.devicePipe,
        endpoint,
        cmdData,
        1000
      );

      // 释放接口
      usbManager.releaseInterface(this.devicePipe, iface);

      return result;
    } catch (error) {
      console.error('发送命令失败:', error);
      return -1;
    }
  }

  // 从输入端点读取响应数据
  static async readResponse(iface: usbManager.USBInterface, endpoint: usbManager.USBEndpoint): Promise<number> {
    if (!this.devicePipe) {
      return -1;
    }

    this.sendState = false;

    try {
      // 释放接口
      usbManager.releaseInterface(this.devicePipe, iface);

      // 声明接口
      const claimResult = usbManager.claimInterface(this.devicePipe, iface, true);
      if (claimResult !== 0) {
        console.log('声明接口失败');
        return -1;
      }

      // 读取数据
      const buffer = new Uint8Array(64);
      const result = await usbManager.bulkTransfer(
        this.devicePipe,
        endpoint,
        buffer,
        5000
      );

      if (result > 0) {
        const receivedData = buffer.subarray(0, result);
        const hexData = Array.from(receivedData).map(b => b.toString(16).padStart(2, '0')).join(' ');
        console.log('接收到的数据:', hexData);

        // 处理接收到的数据
        this.processReceivedData(receivedData);
      }

      // 释放接口
      usbManager.releaseInterface(this.devicePipe, iface);
      this.sendState = true;

      return result;
    } catch (error) {
      console.error('读取数据失败:', error);
      this.sendState = true;
      return -1;
    }
  }

  // 处理接收到的数据
  static processReceivedData(data: Uint8Array) {
    // 检查是否是音频数据 (帧头0x1b)
    if (data.length > 0 && data[0] === 0x1b) {
      console.log('接收到音频数据');
      this.processAudioData(data);
      return;
    }

    // 检查是否是有效的响应帧
    if (data.length >= 4 && data[0] === 0x0C && data[1] === 0x4D) {
      const dataLength = data[2];
      const command = data[3];

      // 根据命令类型处理不同的响应
      switch (command) {
        case 0x61: // 设备信息响应
          this.parseDeviceInfo(data);
          break;
        case 0x69: // 状态信息响应
          this.parseStatusInfo(data);
          break;
        case 0x33: // 语音键单击
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.VOICE_CLICK);
          break;
        case 0x40: // 语音键双击
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.VOICE_DOUBLE_CLICK);
          break;
        case 0x37: // 语音键长按按下
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.VOICE_LONG_PRESS_DOWN);
          break;
        case 0x38: // 语音键长按抬起
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.VOICE_LONG_PRESS_UP);
          break;
        // 处理其他按键事件...
        default:
          console.log(`未知命令响应: 0x${command.toString(16)}`);
      }
    }
  }

  // 处理音频数据
  static processAudioData(data: Uint8Array) {
    try {
      // 移除帧头(0x1b)
      const audioFrame = data.subarray(1);

      // 解密音频数据
      const decryptedData = this.audioProcessor.miclinkDecrypt(audioFrame);

      // 解码为PCM
      const pcmData = this.audioProcessor.processVoiceData(decryptedData);

      if (pcmData) {
        // 处理PCM数据（播放或保存）
        console.log(`解码得到PCM数据: ${pcmData.length}个样本`);
        // 这里可以添加播放或保存PCM数据的逻辑
      }
    } catch (error) {
      console.error('处理音频数据失败:', error);
    }
  }

  // 解析设备信息
  static parseDeviceInfo(data: Uint8Array) {
    if (data.length < 21) {
      console.log('数据长度不足，期望至少21字节，实际:', data.length);
      return;
    }

    // SN解析
    const snPrefix = String.fromCharCode(data[4], data[5]); // "ML"
    const snSuffixBytes = data.subarray(6, 14);
    let snSuffix = '';
    for (let i = 0; i < snSuffixBytes.length; i++) {
      snSuffix += snSuffixBytes[i].toString(16).padStart(2, '0');
    }
    this.deviceInfo.sn = snPrefix + snSuffix;

    // 状态字节
    const statusByte = data[14];
    this.deviceInfo.micStatus = !!(statusByte & 0x01);
    this.deviceInfo.ledStatus = !!(statusByte & 0x02);
    this.deviceInfo.sampleRate = !!(statusByte & 0x04);

    // 其他设备信息
    this.deviceInfo.icType = data[15];
    this.deviceInfo.dpiLevel = data[16];

    // 产品型号
    const productTypeLow = data[17];
    const productTypeHigh = data[20];
    this.deviceInfo.productType = (productTypeHigh << 8) | productTypeLow;

    // 电量和固件版本
    this.deviceInfo.batteryLevel = data[18];
    this.deviceInfo.firmwareVersion = data[19].toString();

    console.log('设备信息解析成功:', this.deviceInfo);
    AppStorage.setOrCreate("mouseconfig", this.deviceInfo);
  }

  // 解析状态信息
  static parseStatusInfo(data: Uint8Array) {
    if (data.length < 8) {
      console.log('状态数据长度不足');
      return;
    }

    // 连接状态
    this.deviceInfo.isConnected = !!data[4];

    // 电量
    this.deviceInfo.batteryLevel = data[5];

    // 回报率
    const reportRateCode = data[6];
    switch (reportRateCode) {
      case 8: this.deviceInfo.reportRate = 125; break;
      case 4: this.deviceInfo.reportRate = 250; break;
      case 2: this.deviceInfo.reportRate = 500; break;
      case 1: this.deviceInfo.reportRate = 1000; break;
      default: this.deviceInfo.reportRate = 125;
    }

    // 氛围灯状态
    this.deviceInfo.atmosphereLight = !!data[7];

    console.log('状态信息解析成功:', this.deviceInfo);
    AppStorage.setOrCreate("mouseconfig", this.deviceInfo);
  }

  // 设备拔出变化
  static changPhysicalKeyboardExistState(state: boolean) {
    if (!state && this.devicePipe) {
      usbManager.closePipe(this.devicePipe);
      this.devicePipe = null;
    }
    this.isPhysicalKeyboardExist = state;
  }
}

// 应用入口
@Entry
@Component
struct SmartMouseApp {
  @State message: string = '智能鼠标控制';

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)

        Button('连接设备')
          .onClick(() => {
            Communication.connectDevice();
          })
          .margin(10)

        Button('获取设备信息')
          .onClick(() => {
            Communication.getDeviceInfo([0x61]);
          })
          .margin(10)
      }
      .width('100%')
    }
    .height('100%')
  }
}