import { usbManager } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { BusinessError } from '@ohos.base';
import common from '@ohos.app.ability.common';

// import { AppStorage } from '@ohos.data.AppStorage'; // 修正AppStorage导入路径

// 按键类型枚举
export enum KeyPressType {
  VOICE_CLICK = 11, // 语音键-单击
  VOICE_DOUBLE_CLICK = 12, // 语音键-双击
  VOICE_LONG_PRESS_DOWN = 13, // 语音键-长按按下
  VOICE_LONG_PRESS_UP = 14, // 语音键-长按抬起
  SEARCH_CLICK = 21, // 搜索键-单击
  SEARCH_DOUBLE_CLICK = 22, // 搜索键-双击
  SEARCH_LONG_PRESS_DOWN = 23, // 搜索键-长按按下
  SEARCH_LONG_PRESS_UP = 24, // 搜索键-长按抬起
  TRANSLATE_CLICK = 31, // 翻译键-单击
  TRANSLATE_DOUBLE_CLICK = 32, // 翻译键-双击
  TRANSLATE_LONG_PRESS_DOWN = 33, // 翻译键-长按按下
  TRANSLATE_LONG_PRESS_UP = 34, // 翻译键-长按抬起
  CUSTOM_CLICK = 41, // 自定义键-单击
  CUSTOM_DOUBLE_CLICK = 42, // 自定义键-双击
  CUSTOM_LONG_PRESS_DOWN = 43, // 自定义键-长按按下
  CUSTOM_LONG_PRESS_UP = 44, // 自定义键-长按抬起
  AI_CLICK = 51, // AI键-单击
  AI_DOUBLE_CLICK = 52, // AI键-双击
  AI_LONG_PRESS_DOWN = 53, // AI键-长按按下
  AI_LONG_PRESS_UP = 54 // AI键-长按抬起
}

// USB设备类型枚举（鼠标光电类型）
export enum MouseICType {
  MouseICTypeError = 0,
  MouseICTypePAW3212 = 1,
  MouseICTypePAW3205 = 2,
  MouseICTypeS201 = 3,
  MouseICTypeFCT3065 = 4,
  MouseICTypeFCT3065XY = 5,
  MouseICTypeLS8650 = 6,
  MouseICTypeS201Height = 7, // S201B接地高档位
  MouseICTypeKA8G2 = 8, // KA8G2
  MouseICTypeKA8 = 9, // KA8
  MouseICTypeFCT3065_X = 15, // 3065带插值
  MouseICTypeLS8650_X = 16, // 8650带插值
  MouseICTypePAW3205_X = 17, // 3205带插值
  MouseICTypeFCT3065XY_X = 18, // 3065XY带插值
  MouseICTypePAW3212_X = 19, // 3212带插值
  MouseICTypeFCT3065XY_X2 = 0x18, // 3065XY带插值（重复值优化）
  MouseICTypePAW3220 = 20, // 3220
  MouseICTypePAW3220_X = 21, // 3220带插值
  MouseICTypeKA8G2_inphic = 22, // KA8G2（英菲克定制）
  MouseICTypePAW3212_X_A4Tech = 25, // 3212带插值（双飞燕定制）
  MouseICTypePAW3325 = 26, // 3325
  MouseICTypePAW3104 = 27, // 3104
  MouseICTypePAW3212_G7 = 28, // G7定制
  MouseICTypeFCT3065XY_M3S = 29 // 铭键M3S定制
}

// 设备信息接口
export interface DeviceInfo {
  sn: string; // 设备序列号
  micStatus: boolean; // 麦克风状态（true=开启）
  ledStatus: boolean; // LED状态（true=亮）
  sampleRate: boolean; // 采样率（true=高采样率）
  icType: MouseICType; // 光电IC型号
  dpiLevel: number; // DPI挡位（1-5）
  productType: number; // 产品型号
  batteryLevel: number; // 电量（0-100）
  firmwareVersion: string; // 固件版本
  isConnected: boolean; // 连接状态
  reportRate: number; // 回报率（125/250/500/1000Hz）
  atmosphereLight: boolean; // 氛围灯状态
}

// ADPCM解码状态模型
export class ADPCMDecodeState {
  predict: number; // 预测值
  predictIdx: number; // 预测索引

  constructor(predict: number, predictIdx: number) {
    this.predict = predict;
    this.predictIdx = predictIdx;
  }
}

// 按键映射项接口
interface KeyMapping {
  code: number;
  type: KeyPressType;
}

// 按键映射项实现类
class KeyMappingItem implements KeyMapping {
  code: number;
  type: KeyPressType;

  constructor(code: number, type: KeyPressType) {
    this.code = code;
    this.type = type;
  }
}

// 回报率映射类
class ReportRateMap {
  eight: number = 125;
  four: number = 250;
  two: number = 500;
  one: number = 1000;

  getRate(code: number): number {
    switch (code) {
      case 8:
        return this.eight;
      case 4:
        return this.four;
      case 2:
        return this.two;
      case 1:
        return this.one;
      default:
        return 125;
    }
  }
}

// 按键事件映射类
class KeyEventMap {
  // 使用接口和实现类替代对象字面量
  private mappings: Array<KeyMapping> = [
    new KeyMappingItem(0x33, KeyPressType.VOICE_CLICK),
    new KeyMappingItem(0x40, KeyPressType.VOICE_DOUBLE_CLICK),
    new KeyMappingItem(0x37, KeyPressType.VOICE_LONG_PRESS_DOWN),
    new KeyMappingItem(0x38, KeyPressType.VOICE_LONG_PRESS_UP),
    new KeyMappingItem(0x35, KeyPressType.SEARCH_CLICK),
    new KeyMappingItem(0x41, KeyPressType.SEARCH_DOUBLE_CLICK),
    new KeyMappingItem(0x31, KeyPressType.SEARCH_LONG_PRESS_DOWN),
    new KeyMappingItem(0x32, KeyPressType.SEARCH_LONG_PRESS_UP),
    new KeyMappingItem(0x42, KeyPressType.CUSTOM_CLICK),
    new KeyMappingItem(0x43, KeyPressType.CUSTOM_DOUBLE_CLICK),
    new KeyMappingItem(0x44, KeyPressType.CUSTOM_LONG_PRESS_DOWN),
    new KeyMappingItem(0x45, KeyPressType.CUSTOM_LONG_PRESS_UP),
    new KeyMappingItem(0x46, KeyPressType.AI_CLICK),
    new KeyMappingItem(0x47, KeyPressType.AI_DOUBLE_CLICK),
    new KeyMappingItem(0x48, KeyPressType.AI_LONG_PRESS_DOWN),
    new KeyMappingItem(0x49, KeyPressType.AI_LONG_PRESS_UP)
  ];

  getKeyType(code: number): KeyPressType | undefined {
    for (const mapping of this.mappings) {
      if (mapping.code === code) {
        return mapping.type;
      }
    }
    return undefined;
  }

  getKeyName(type: KeyPressType): string {
    switch (type) {
      case KeyPressType.VOICE_CLICK:
        return "VOICE_CLICK";
      case KeyPressType.VOICE_DOUBLE_CLICK:
        return "VOICE_DOUBLE_CLICK";
      case KeyPressType.VOICE_LONG_PRESS_DOWN:
        return "VOICE_LONG_PRESS_DOWN";
      case KeyPressType.VOICE_LONG_PRESS_UP:
        return "VOICE_LONG_PRESS_UP";
      case KeyPressType.SEARCH_CLICK:
        return "SEARCH_CLICK";
      case KeyPressType.SEARCH_DOUBLE_CLICK:
        return "SEARCH_DOUBLE_CLICK";
      case KeyPressType.SEARCH_LONG_PRESS_DOWN:
        return "SEARCH_LONG_PRESS_DOWN";
      case KeyPressType.SEARCH_LONG_PRESS_UP:
        return "SEARCH_LONG_PRESS_UP";
      case KeyPressType.CUSTOM_CLICK:
        return "CUSTOM_CLICK";
      case KeyPressType.CUSTOM_DOUBLE_CLICK:
        return "CUSTOM_DOUBLE_CLICK";
      case KeyPressType.CUSTOM_LONG_PRESS_DOWN:
        return "CUSTOM_LONG_PRESS_DOWN";
      case KeyPressType.CUSTOM_LONG_PRESS_UP:
        return "CUSTOM_LONG_PRESS_UP";
      case KeyPressType.AI_CLICK:
        return "AI_CLICK";
      case KeyPressType.AI_DOUBLE_CLICK:
        return "AI_DOUBLE_CLICK";
      case KeyPressType.AI_LONG_PRESS_DOWN:
        return "AI_LONG_PRESS_DOWN";
      case KeyPressType.AI_LONG_PRESS_UP:
        return "AI_LONG_PRESS_UP";
      default:
        return "UNKNOWN";
    }
  }
}

/**
 * 音频处理器类（负责鼠标音频数据解密、ADPCM解码、PCM格式转换）
 */
export class SmartMouseAudioProcessor {
  // 解密密钥（固定值，与鼠标固件匹配）
  private readonly DECRYPT_KEY: Uint8Array = new Uint8Array([
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
  // ADPCM解码表（Telink标准协议）
  private readonly ADPCM_IDX_TABLE: number[] = [
    -1, -1, -1, -1, 2, 4, 6, 8,
    -1, -1, -1, -1, 2, 4, 6, 8
  ];
  private readonly ADPCM_STEP_TABLE: number[] = [
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

  /**
   * 解密鼠标音频帧（逐字节异或）
   * @param rawFrame 原始音频帧（去掉0x1b帧头后的数据）
   * @param frameLen 帧长度（默认32字节，与鼠标固件约定）
   * @returns 解密后的音频数据
   */
  miclinkDecrypt(rawFrame: Uint8Array, frameLen: number = 32): Uint8Array {
    if (rawFrame.length < frameLen || this.DECRYPT_KEY.length < frameLen) {
      throw new Error(`音频解密失败：数据长度不足（需${frameLen}字节，实际${rawFrame.length}字节）`);
    }

    const decrypted = new Uint8Array(frameLen);
    for (let i = 0; i < frameLen; i++) {
      decrypted[i] = rawFrame[i] ^ this.DECRYPT_KEY[i];
    }
    hilog.info(0x0000, 'AudioProcessor',
      `音频解密完成：${Array.from(decrypted).map(b => b.toString(16).padStart(2, '0')).join(' ')}`);
    return decrypted;
  }

  /**
   * 处理音频帧并解码为PCM
   * @param decryptedFrame 解密后的音频帧
   * @returns 解码后的PCM数据（Int16Array，单声道16bit）
   */
  processVoiceData(decryptedFrame: Uint8Array): Int16Array | null {
    // 音频帧格式：前4字节=预测值+索引，后28字节=ADPCM数据（共32字节）
    if (decryptedFrame.length !== 32) {
      hilog.error(0x0000, 'AudioProcessor', `音频帧长度错误（需32字节，实际${decryptedFrame.length}字节）`);
      return null;
    }

    try {
      // 解析ADPCM初始状态（小端字节序）
      const initState: ADPCMDecodeState = new ADPCMDecodeState(
        (decryptedFrame[0] | (decryptedFrame[1] << 8)) as number, // 预测值（16bit）
        decryptedFrame[2] | (decryptedFrame[3] << 8) & 0xFF// 预测索引（8bit）
      );
      const adpcmData = decryptedFrame.subarray(4); // ADPCM编码数据（28字节）
      const pcmLength = adpcmData.length * 2; // 每个ADPCM字节解码为2个PCM样本
      const pcmData = new Int16Array(pcmLength);

      // 逐字节解码ADPCM
      let decodeState: ADPCMDecodeState = new ADPCMDecodeState(initState.predict, initState.predictIdx);
      let pcmIndex = 0;
      for (const byte of adpcmData) {
        // 处理低4位（第一个PCM样本）
        decodeState = this.decodeADPCMSample(byte & 0x0F, decodeState);
        if (pcmIndex < pcmLength) {
          pcmData[pcmIndex++] = decodeState.predict;
        }

        // 处理高4位（第二个PCM样本）
        decodeState = this.decodeADPCMSample((byte >> 4) & 0x0F, decodeState);
        if (pcmIndex < pcmLength) {
          pcmData[pcmIndex++] = decodeState.predict;
        }
      }

      hilog.info(0x0000, 'AudioProcessor', `ADPCM解码完成：${pcmData.length}个PCM样本`);
      return pcmData;
    } catch (error) {
      hilog.error(0x0000, 'AudioProcessor', `音频解码失败：${(error as BusinessError).message}`);
      return null;
    }
  }

  /**
   * 单个ADPCM样本解码
   * @param code 4位ADPCM编码
   * @param state 当前解码状态
   * @returns 更新后的解码状态
   */
  private decodeADPCMSample(code: number, state: ADPCMDecodeState): ADPCMDecodeState {
    // 创建新状态对象而非使用扩展运算符
    const newState: ADPCMDecodeState = new ADPCMDecodeState(state.predict, state.predictIdx);

    // 计算当前步长
    let step = this.ADPCM_STEP_TABLE[newState.predictIdx];
    // 计算差值
    let diff = step >> 3;
    if (code & 0x04) {
      diff += step;
    }
    if (code & 0x02) {
      diff += step >> 1;
    }
    if (code & 0x01) {
      diff += step >> 2;
    }
    // 应用符号（0x08为符号位）
    if (code & 0x08) {
      newState.predict -= diff;
    } else {
      newState.predict += diff;
    }
    // 限制PCM范围（16bit有符号）
    newState.predict = Math.max(-32768, Math.min(32767, newState.predict));
    // 更新预测索引
    newState.predictIdx += this.ADPCM_IDX_TABLE[code];
    newState.predictIdx = Math.max(0, Math.min(88, newState.predictIdx)); // 索引范围0-88

    return newState;
  }

  /**
   * Int16 PCM转换为Uint8字节流（小端序）
   * @param pcmData 16bit PCM数据
   * @returns 小端序字节流
   */
  pcmToByteStream(pcmData: Int16Array): Uint8Array {
    const byteLength = pcmData.length * 2;
    const byteStream = new ArrayBuffer(byteLength);
    const dataView = new DataView(byteStream);

    for (let i = 0; i < pcmData.length; i++) {
      dataView.setInt16(i * 2, pcmData[i], true); // 小端序写入
    }
    return new Uint8Array(byteStream);
  }

  /**
   * 合并PCM片段并生成WAV文件（含WAV头）
   * @param pcmSegments PCM片段数组
   * @param sampleRate 采样率（默认16000Hz，鼠标音频常用）
   * @param channels 声道数（默认1，单声道）
   * @returns WAV文件字节流
   */
  mergePcmToWav(pcmSegments: Int16Array[], sampleRate: number = 16000, channels: number = 1): Uint8Array {
    // 合并所有PCM片段
    const totalSamples = pcmSegments.reduce((sum, seg) => sum + seg.length, 0);
    const pcmData = new Int16Array(totalSamples);

    let offset = 0;
    for (const segment of pcmSegments) {
      pcmData.set(segment, offset);
      offset += segment.length;
    }

    // 计算WAV文件大小
    const byteRate = sampleRate * channels * 2; // 16bit = 2字节
    const blockAlign = channels * 2;
    const dataSize = totalSamples * 2;
    const fileSize = 44 + dataSize; // 44字节WAV头 + 数据大小

    // 创建WAV头（标准RIFF格式）
    const wavBuffer = new ArrayBuffer(fileSize);
    const view = new DataView(wavBuffer);

    // RIFF Chunk
    this.writeString(view, 0, 'RIFF');
    view.setUint32(4, fileSize - 8, true);
    this.writeString(view, 8, 'WAVE');

    // fmt Subchunk
    this.writeString(view, 12, 'fmt ');
    view.setUint32(16, 16, true); // PCM格式固定为16
    view.setUint16(20, 1, true); // 1 = PCM
    view.setUint16(22, channels, true);
    view.setUint32(24, sampleRate, true);
    view.setUint32(28, byteRate, true);
    view.setUint16(32, blockAlign, true);
    view.setUint16(34, 16, true); // 16bit

    // data Subchunk
    this.writeString(view, 36, 'data');
    view.setUint32(40, dataSize, true);

    // 写入PCM数据（小端序）
    for (let i = 0; i < pcmData.length; i++) {
      view.setInt16(44 + i * 2, pcmData[i], true);
    }

    return new Uint8Array(wavBuffer);
  }

  /**
   * 向DataView写入字符串
   */
  private writeString(view: DataView, offset: number, str: string): void {
    for (let i = 0; i < str.length; i++) {
      view.setUint8(offset + i, str.charCodeAt(i));
    }
  }
}

/**
 * 通信管理类（负责USB设备连接、命令收发、数据解析）
 */
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
  static readState: boolean = false;
  static sendState: boolean = false;
  static sendDataList: number[][] = [];
  static audioProcessor: SmartMouseAudioProcessor = new SmartMouseAudioProcessor();
  static audioData: Int16Array[] = [];
  static isRecording: boolean = false; // 音频录制状态标记
  static reconnectAttempts: number = 0; // 重连尝试次数
  static maxReconnectAttempts: number = 5; // 最大重连次数
  private static reportRateMap: ReportRateMap = new ReportRateMap();
  private static keyEventMap: KeyEventMap = new KeyEventMap();
  static context = getContext(this) as common.UIAbilityContext;

  /**
   * 构建0x61命令帧（获取设备信息）
   */
  static buildGetInfoCommand(length: number = 33): Uint8Array {
    const frame = new Uint8Array(length);
    frame[0] = 0x0C; // 帧头高位
    frame[1] = 0x4D; // 帧头低位
    frame[2] = 0x04; // 数据长度
    frame[3] = 0x61; // 命令字
    frame[4] = 0x4C; // 结束标志

    // 剩余字节填充0
    for (let i = 5; i < length; i++) {
      frame[i] = 0x00;
    }
    return frame;
  }

  /**
   * 构建通用命令帧
   */
  static buildCommandFrame(cmd: number[], length: number): Uint8Array {
    const frame = new Uint8Array(length);
    frame[0] = 0x0C; // 帧头高位
    frame[1] = 0x4D; // 帧头低位

    // 处理命令参数
    let cmdData: number[] = cmd;

    // 设置数据长度（特殊命令0x6f固定长度0x12）
    frame[2] = cmd[0] === 0x6f ? 0x12 : cmdData.length + 3;

    // 填充命令数据
    for (let i = 0; i < cmdData.length && 3 + i < length; i++) {
      frame[3 + i] = cmdData[i];
    }

    // 设置结束标志
    const endFlagPosition = 3 + cmdData.length;
    if (endFlagPosition < length) {
      frame[endFlagPosition] = 0x4C;
    }

    // 剩余字节填充0
    for (let i = endFlagPosition + 1; i < length; i++) {
      frame[i] = 0x00;
    }
    return frame;
  }

  /**
   * 扫描并连接设备
   */
  static async connectDevice(): Promise<boolean> {
    console.log('开始扫描并连接设备');
    try {
      const devices = usbManager.getDevices();
      if (!devices || devices.length === 0) {
        hilog.error(0x0000, 'USB', '未找到任何USB设备');
        return false;
      }

      // 查找目标设备 (VID: 0x248A)
      const targetDevice = devices.find(device => device.vendorId === 0x248A);
      if (!targetDevice) {
        hilog.error(0x0000, 'USB', '未找到目标鼠标设备(VID=0x248A)');
        return false;
      }

      // 检查并请求权限
      const hasRight = await usbManager.hasRight(targetDevice.name);
      if (!hasRight) {
        hilog.warn(0x0000, 'USB', '没有设备访问权限，请求授权');
        const requestResult = await usbManager.requestRight(targetDevice.name);
        if (!requestResult) {
          hilog.error(0x0000, 'USB', '用户拒绝权限请求');
          return false;
        }
      }

      // 关闭现有连接
      if (Communication.devicePipe) {
        usbManager.closePipe(Communication.devicePipe);
        Communication.devicePipe = null;
      }

      // 建立新连接
      Communication.devicePipe = usbManager.connectDevice(targetDevice);
      if (!Communication.devicePipe) {
        hilog.error(0x0000, 'USB', '设备连接失败');
        return false;
      }

      // 查找输入输出端点
      Communication.findEndpoints(targetDevice);

      // 重置重连计数
      Communication.reconnectAttempts = 0;
      Communication.deviceInfo.isConnected = true;
      AppStorage.setOrCreate("mouseconfig", Communication.deviceInfo);
      hilog.info(0x0000, 'USB', '设备连接成功');
      return true;
    } catch (error) {
      hilog.error(0x0000, 'USB', `连接失败: ${(error as BusinessError).message}`);
      return false;
    }
  }

  /**
   * 查找设备的输入输出端点
   */
  static findEndpoints(device: usbManager.USBDevice): void {
    if (!device.configs?.[0]?.interfaces) {
      console.log('无法获取设备接口信息');
      return;
    }

    // 重置端点信息
    Communication.inputEndpoint = null;
    Communication.inputInterface = null;
    Communication.outputEndpoint = null;
    Communication.outputInterface = null;

    // 遍历接口查找端点
    for (const iface of device.configs[0].interfaces) {
      if (iface.endpoints) {
        for (const endpoint of iface.endpoints) {
          console.log(`端点 ${endpoint.address.toString(16)}: 类型=${endpoint.type}, 方向=${endpoint.direction}`);

          if (endpoint.direction === 0) { // 输出端点
            Communication.outputEndpoint = endpoint;
            Communication.outputInterface = iface;
          } else if (endpoint.direction === 128) { // 输入端点
            Communication.inputEndpoint = endpoint;
            Communication.inputInterface = iface;
          }
        }
      }
    }
  }

  /**
   * 获取设备信息（带重试机制）
   */
  static async getDeviceInfo(command: number[] = [0x61]): Promise<boolean> {
    if (!Communication.devicePipe) {
      console.log('设备未连接，尝试重连');
      const reconnectSuccess = await Communication.connectDevice();
      if (!reconnectSuccess) {
        return false;
      }
    }

    // 命令队列管理
    if (Communication.sendState) {
      console.log('有消息正在发送，加入队列');
      Communication.sendDataList = Communication.sendDataList.filter(item => item[0] !== command[0]);
      Communication.sendDataList.push(command);
      return false;
    }

    if (Communication.sendDataList.length) {
      command = Communication.sendDataList[0];
    }

    try {
      // 释放接口
      if (Communication.devicePipe && Communication.inputInterface) {
        usbManager.releaseInterface(Communication.devicePipe, Communication.inputInterface);
      }

      // 发送命令
      if (!Communication.outputInterface || !Communication.outputEndpoint) {
        throw new Error('未找到输出端点');
      }

      const sendResult = await Communication.sendCommand(
        Communication.outputInterface,
        Communication.outputEndpoint,
        command
      );

      if (sendResult === -1) {
        throw new Error('命令发送失败');
      }

      // 移除已处理命令
      Communication.sendDataList.shift();

      // 处理下一个命令
      if (Communication.sendDataList.length) {
        setTimeout(() => {
          Communication.getDeviceInfo(Communication.sendDataList[0]);
        }, 100);
      }

      // 读取响应
      if (Communication.inputInterface && Communication.inputEndpoint) {
        await Communication.readResponse(Communication.inputInterface, Communication.inputEndpoint);
      }

      // 启动持续读取
      Communication.startContinuousReading();
      return true;
    } catch (error) {
      console.error('获取设备信息失败:', error);
      await Communication.handleConnectionError();
      return false;
    }
  }

  /**
   * 发送命令到设备
   */
  static async sendCommand(
    iface: usbManager.USBInterface,
    endpoint: usbManager.USBEndpoint,
    command: number[],
    length: number = 33
  ): Promise<number> {
    Communication.sendState = true;
    if (!Communication.devicePipe) {
      Communication.sendState = false;
      return -1;
    }

    try {
      // 释放接口
      usbManager.releaseInterface(Communication.devicePipe, iface);

      // 声明接口
      const claimResult = usbManager.claimInterface(Communication.devicePipe, iface, true);
      if (claimResult !== 0) {
        throw new Error(`接口声明失败，错误码: ${claimResult}`);
      }

      // 构建并发送命令
      const cmdData = Communication.buildCommandFrame(command, length);
      const hexString = Array.from(cmdData).map(b => b.toString(16).padStart(2, '0')).join(' ');
      console.log(`发送命令 0x${command[0].toString(16)}:`, hexString);

      // 尝试33字节和21字节两种帧长
      const result33 = await usbManager.bulkTransfer(Communication.devicePipe, endpoint, cmdData, 2000);
      if (result33 !== -1) {
        return result33;
      }

      const cmdData21 = Communication.buildCommandFrame(command, 21);
      const result21 = await usbManager.bulkTransfer(Communication.devicePipe, endpoint, cmdData21, 2000);
      return result21;
    } catch (error) {
      console.error('发送命令失败:', error);
      return -1;
    } finally {
      // 释放接口
      if (Communication.devicePipe) {
        usbManager.releaseInterface(Communication.devicePipe, iface);
      }
      Communication.sendState = false;
    }
  }

  /**
   * 从设备读取响应
   */
  static async readResponse(
    iface: usbManager.USBInterface,
    endpoint: usbManager.USBEndpoint
  ): Promise<number> {
    if (!Communication.devicePipe) {
      return -1;
    }

    Communication.readState = true;
    try {
      // 释放并重新声明接口
      usbManager.releaseInterface(Communication.devicePipe, iface);
      const claimResult = usbManager.claimInterface(Communication.devicePipe, iface, true);
      if (claimResult !== 0) {
        throw new Error(`读取接口声明失败，错误码: ${claimResult}`);
      }

      // 读取数据
      const buffer = new Uint8Array(64);
      const result = await usbManager.bulkTransfer(Communication.devicePipe, endpoint, buffer, 5000);

      if (result > 0) {
        const hexData = Array.from(buffer.slice(0, result)).map(b => b.toString(16).padStart(2, '0')).join(' ');
        console.log('接收到数据:', hexData);
        Communication.parseDeviceInfo(buffer.slice(0, result));
      }

      return result;
    } catch (error) {
      console.error('读取数据失败:', error);
      return -1;
    } finally {
      // 释放接口
      if (Communication.devicePipe) {
        usbManager.releaseInterface(Communication.devicePipe, iface);
      }
      Communication.readState = false;
    }
  }

  /**
   * 开始持续读取设备数据
   */
  static startContinuousReading(): void {
    if (!Communication.devicePipe || !Communication.inputInterface || !Communication.inputEndpoint) {
      return;
    }

    // 异步循环读取，明确指定Promise类型
    (async () => {
      let readCount = 0;
      while (Communication.isPhysicalKeyboardExist && Communication.devicePipe) {
        try {
          readCount++;
          const result = await Communication.readResponse(
            Communication.inputInterface as usbManager.USBInterface,
            Communication.inputEndpoint as usbManager.USBEndpoint
          );

          // 读取失败处理
          if (result === -1) {
            throw new Error(`连续读取失败，计数: ${readCount}`);
          }

          // 每100次读取重置计数，避免溢出
          if (readCount >= 100) {
            readCount = 0;
          }

          // 短暂延迟，避免CPU占用过高，明确指定Promise类型
          await new Promise<void>((resolve) => setTimeout(resolve, 10));
        } catch (error) {
          console.error('持续读取异常:', error);
          await Communication.handleConnectionError();
          break;
        }
      }
    })();
  }

  /**
   * 处理连接错误（重连机制）
   */
  static async handleConnectionError(): Promise<boolean> {
    if (Communication.reconnectAttempts >= Communication.maxReconnectAttempts) {
      hilog.error(0x0000, 'USB', `已达最大重连次数(${Communication.maxReconnectAttempts})，停止尝试`);
      Communication.deviceInfo.isConnected = false;
      AppStorage.setOrCreate("mouseconfig", Communication.deviceInfo);
      return false;
    }

    // 递增重连计数
    Communication.reconnectAttempts++;
    hilog.warn(0x0000, 'USB', `尝试重连(${Communication.reconnectAttempts}/${Communication.maxReconnectAttempts})`);

    // 关闭现有连接
    if (Communication.devicePipe) {
      usbManager.closePipe(Communication.devicePipe);
      Communication.devicePipe = null;
    }

    // 延迟重连，避免频繁尝试，明确指定Promise类型
    await new Promise<void>((resolve) =>
    setTimeout(resolve, 1000 * Communication.reconnectAttempts)
    );

    // 尝试重连
    const reconnectSuccess = await Communication.connectDevice();
    if (reconnectSuccess) {
      // 重连成功后获取设备信息
      await Communication.getDeviceInfo();
      return true;
    }

    return false;
  }

  /**
   * 处理设备插拔状态变化
   */
  static changPhysicalKeyboardExistState(state: boolean): void {
    if (!state) {
      console.log('设备已断开连接');
      if (Communication.devicePipe) {
        usbManager.closePipe(Communication.devicePipe);
        Communication.devicePipe = null;
      }
      Communication.deviceInfo.isConnected = false;
      AppStorage.setOrCreate("mouseconfig", Communication.deviceInfo);
    } else {
      console.log('设备已连接，尝试初始化');
      Communication.connectDevice().then(success => {
        if (success) {
          Communication.getDeviceInfo();
        }
      });
    }
    Communication.isPhysicalKeyboardExist = state;
  }

  /**
   * 解析设备信息数据
   */
  static parseDeviceInfo(data: Uint8Array): void {
    if (data.length < 5) {
      console.log('数据长度不足，无法解析');
      return;
    }

    try {
      // 处理音频数据（帧头0x1b）
      if (data[0] === 0x1b) {
        console.log('收到音频数据帧');
        Communication.processAudioData(data);
        return;
      }

      // 处理标准命令响应（帧头0x0C 0x4D）
      if (data[0] === 0x0C && data[1] === 0x4D) {
        const command = data[3];
        console.log(`解析命令响应: 0x${command.toString(16)}`);

        // 设备基本信息响应（0x61）
        if (command === 0x61 && data.length >= 21) {
          Communication.parseBaseInfo(data);
        }

        // 设备状态信息响应（0x69）
        if (command === 0x69 && data.length >= 8) {
          Communication.parseStatusInfo(data);
        }

        // 按键事件响应
        Communication.parseKeyEvent(command);
      }
    } catch (error) {
      console.error('解析设备信息错误:', error);
    }
  }

  /**
   * 解析设备基本信息（0x61命令响应）
   */
  static parseBaseInfo(data: Uint8Array): void {
    // 解析SN（ML前缀 + 8字节十六进制）
    const snPrefix = String.fromCharCode(data[4], data[5]);
    const snSuffixBytes = data.slice(6, 14);
    let snSuffix = '';
    snSuffixBytes.forEach(b => snSuffix += b.toString(16).padStart(2, '0'));
    Communication.deviceInfo.sn = snPrefix + snSuffix;

    // 解析状态字节（byte14）
    const statusByte = data[14];
    Communication.deviceInfo.micStatus = !!(statusByte & 0x01);
    Communication.deviceInfo.ledStatus = !!(statusByte & 0x02);
    Communication.deviceInfo.sampleRate = !!(statusByte & 0x04);

    // 解析其他信息
    Communication.deviceInfo.icType = data[15];
    Communication.deviceInfo.dpiLevel = data[16];
    Communication.deviceInfo.productType = (data[20] << 8) | data[17];
    Communication.deviceInfo.batteryLevel = data[18];
    Communication.deviceInfo.firmwareVersion = data[19].toString();

    console.log('设备基本信息解析完成:', JSON.stringify(Communication.deviceInfo));
    AppStorage.setOrCreate("mouseconfig", Communication.deviceInfo);
  }

  /**
   * 解析设备状态信息（0x69命令响应）
   */
  static parseStatusInfo(data: Uint8Array): void {
    // 连接状态（byte4）
    Communication.deviceInfo.isConnected = !!data[4];

    // 电量（byte5）
    Communication.deviceInfo.batteryLevel = data[5];

    // 回报率（byte6）- 使用专门的映射类替代对象字面量
    Communication.deviceInfo.reportRate = Communication.reportRateMap.getRate(data[6]);

    // 氛围灯状态（byte7）
    Communication.deviceInfo.atmosphereLight = !!data[7];

    console.log('设备状态信息解析完成:', JSON.stringify(Communication.deviceInfo));
    AppStorage.setOrCreate("mouseconfig", Communication.deviceInfo);
  }

  /**
   * 解析按键事件 - 使用专门的映射类替代对象字面量
   */
  static parseKeyEvent(command: number): void {
    const keyType = Communication.keyEventMap.getKeyType(command);

    if (keyType !== undefined) {
      console.log(`按键事件: ${Communication.keyEventMap.getKeyName(keyType)}`);
      AppStorage.setOrCreate('mouse_KeyPressType', keyType);

      // 处理录音状态（AI键长按）
      if (keyType === KeyPressType.AI_LONG_PRESS_DOWN) {
        Communication.startAudioRecording();
      } else if (keyType === KeyPressType.AI_LONG_PRESS_UP) {
        Communication.stopAudioRecording();
      }
    }
  }

  /**
   * 开始音频录制
   */
  static startAudioRecording(): void {
    console.log('开始录音');
    Communication.isRecording = true;
    Communication.audioData = []; // 清空之前的音频数据
  }

  /**
   * 停止音频录制并保存为WAV
   */
  static stopAudioRecording(): void {
    console.log('停止录音，处理音频数据');
    Communication.isRecording = false;

    if (Communication.audioData.length === 0) {
      console.log('未录制到音频数据');
      return;
    }

    // 合并PCM数据并生成WAV
    try {
      const context = Communication.context
      const wavData = Communication.audioProcessor.mergePcmToWav(Communication.audioData);

      // 保存WAV文件
      const timestamp = new Date().getTime();
      const filePath = `${context.filesDir}/audio_${timestamp}.wav`;
      const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      fs.writeSync(file.fd, wavData.buffer);
      fs.closeSync(file.fd);

      console.log(`音频文件保存成功: ${filePath}，大小: ${wavData.length}字节`);
      AppStorage.setOrCreate('lastRecordedAudio', filePath);
    } catch (error) {
      console.error('音频保存失败:', error);
    }
  }

  /**
   * 处理音频数据
   */
  static processAudioData(data: Uint8Array): void {
    // 仅在录音状态下处理音频
    if (!Communication.isRecording) {
      return;
    }

    try {
      // 移除帧头(0x1b)并解密
      const audioFrame = data.subarray(1);
      const decryptedData = Communication.audioProcessor.miclinkDecrypt(audioFrame);

      // 解码为PCM并添加到缓冲区
      const pcmData = Communication.audioProcessor.processVoiceData(decryptedData);
      if (pcmData) {
        Communication.audioData.push(pcmData);
      }
    } catch (error) {
      console.error('处理音频数据失败:', error);
    }
  }
}
