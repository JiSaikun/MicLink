import { usbManager } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { SmartMouseAudioProcessor } from './SmartMouseAudioProcessor'
import { getModelInfo_Params, productImg_Params } from '../model/MouseInfoModel'
import { _getModelInfo, _productImg } from '../viewmodel/UserViewModel'
import { getModelInfoModel, keyInfosModel } from 'config'
import { AudioWebSocketHandler } from 'api';

// 按键类型枚举
export enum KeyPressType {
  DEFAULT = 0,
  VOICE_CLICK = 11, //语音键-单击
  VOICE_DOUBLE_CLICK = 12, //语音键-双击
  VOICE_LONG_PRESS_DOWN = 13, //语音键-长按按下
  VOICE_LONG_PRESS_UP = 14, //语音键-长按抬起
  SEARCH_CLICK = 21, //搜索键-单击
  SEARCH_DOUBLE_CLICK = 22, //搜索键-双击
  SEARCH_LONG_PRESS_DOWN = 23, //搜索键-长按按下
  SEARCH_LONG_PRESS_UP = 24, //搜索键-长按抬起
  TRANSLATE_CLICK = 31, //翻译键-单击
  TRANSLATE_DOUBLE_CLICK = 32, //翻译键-双击
  TRANSLATE_LONG_PRESS_DOWN = 33, //翻译键-长按按下
  TRANSLATE_LONG_PRESS_UP = 34, //翻译键-长按抬起
  CUSTOM_CLICK = 41, //自定义键-单击
  CUSTOM_DOUBLE_CLICK = 42, //自定义键-双击
  CUSTOM_LONG_PRESS_DOWN = 43, //自定义键-长按按下
  CUSTOM_LONG_PRESS_UP = 44, //自定义键-长按抬起
  AI_CLICK = 51, //AI键-单击
  AI_DOUBLE_CLICK = 52, //AI键-双击
  AI_LONG_PRESS_DOWN = 53, //AI键-长按按下
  AI_LONG_PRESS_UP = 54, //AI键-长按抬起
  //*************************************键盘按键******************************
  // 新增按键类型
  SCREENSHOT_TRANSLATE_CLICK = 61, //截图翻译键-单击
  SCREENSHOT_TRANSLATE_DOUBLE_CLICK = 62, //截图翻译键-双击
  SCREENSHOT_TRANSLATE_LONG_PRESS_DOWN = 63, //截图翻译键-长按按下
  SCREENSHOT_TRANSLATE_LONG_PRESS_UP = 64, //截图翻译键-长按抬起

  AI_PAINTING_CLICK = 65, //AI绘画键-单击
  AI_PAINTING_DOUBLE_CLICK = 66, //AI绘画键-双击
  AI_PAINTING_LONG_PRESS_DOWN = 67, //AI绘画键-长按按下
  AI_PAINTING_LONG_PRESS_UP = 68, //AI绘画键-长按抬起

  DOCUMENT_CONVERSION_CLICK = 69, //图片分析键改文档转换-单击
  DOCUMENT_CONVERSION_DOUBLE_CLICK = 70, //图片分析键改文档转换-双击
  DOCUMENT_CONVERSION_LONG_PRESS_DOWN = 71, //图片分析键改文档转换-长按按下
  DOCUMENT_CONVERSION_LONG_PRESS_UP = 72, //图片分析键改文档转换-长按抬起

  MIND_MAP_CLICK = 73, //思维导图键-单击
  MIND_MAP_DOUBLE_CLICK = 74, //思维导图键-双击
  MIND_MAP_LONG_PRESS_DOWN = 75, //思维导图键-长按按下
  MIND_MAP_LONG_PRESS_UP = 76, //思维导图键-长按抬起

  WORK_SUMMARY_CLICK = 77, //工作总结键-单击
  WORK_SUMMARY_DOUBLE_CLICK = 78, //工作总结键-双击
  WORK_SUMMARY_LONG_PRESS_DOWN = 79, //工作总结键-长按按下
  WORK_SUMMARY_LONG_PRESS_UP = 80, //工作总结键-长按抬起

  TEMPLATE_DOWNLOAD_CLICK = 81, //模版下载键-单击
  TEMPLATE_DOWNLOAD_DOUBLE_CLICK = 82, //模版下载键-双击
  TEMPLATE_DOWNLOAD_LONG_PRESS_DOWN = 83, //模版下载键-长按按下
  TEMPLATE_DOWNLOAD_LONG_PRESS_UP = 84, //模版下载键-长按抬起

  READING_COMPREHENSION_CLICK = 85, //阅读理解键-单击
  READING_COMPREHENSION_DOUBLE_CLICK = 86, //阅读理解键-双击
  READING_COMPREHENSION_LONG_PRESS_DOWN = 87, //阅读理解键-长按按下
  READING_COMPREHENSION_LONG_PRESS_UP = 88, //阅读理解键-长按抬起

  TABLE_CLICK = 89, //表格键-单击
  TABLE_DOUBLE_CLICK = 90, //表格键-双击
  TABLE_LONG_PRESS_DOWN = 91, //表格键-长按按下
  TABLE_LONG_PRESS_UP = 92, //表格键-长按抬起

  CODE_CLICK = 93, //代码键-单击
  CODE_DOUBLE_CLICK = 94, //代码键-双击
  CODE_LONG_PRESS_DOWN = 95, //代码键-长按按下
  CODE_LONG_PRESS_UP = 96, //代码键-长按抬起

  SPEECH_CLICK = 97, //演讲稿键-单击
  SPEECH_DOUBLE_CLICK = 98, //演讲稿键-双击
  SPEECH_LONG_PRESS_DOWN = 99, //演讲稿键-长按按下
  SPEECH_LONG_PRESS_UP = 100, //演讲稿键-长按抬起

  WRITING_CLICK = 101, //写作键-单击
  WRITING_DOUBLE_CLICK = 102, //写作键-双击
  WRITING_LONG_PRESS_DOWN = 103, //写作键-长按按下
  WRITING_LONG_PRESS_UP = 104, //写作键-长按抬起

  PPT_CLICK = 105, //PPT键-单击
  PPT_DOUBLE_CLICK = 106, //PPT键-双击
  PPT_LONG_PRESS_DOWN = 107, //PPT键-长按按下
  PPT_LONG_PRESS_UP = 108, //PPT键-长按抬起

  CUSTOM1_CLICK = 109, //自定义键1-单击
  CUSTOM1_DOUBLE_CLICK = 110, //自定义键1-双击
  CUSTOM1_LONG_PRESS_DOWN = 111, //自定义键1-长按按下
  CUSTOM1_LONG_PRESS_UP = 112, //自定义键1-长按抬起

  CUSTOM2_CLICK = 113, //自定义键2-单击
  CUSTOM2_DOUBLE_CLICK = 114, //自定义键2-双击
  CUSTOM2_LONG_PRESS_DOWN = 115, //自定义键2-长按按下
  CUSTOM2_LONG_PRESS_UP = 116, //自定义键2-长按抬起

  CUSTOM3_CLICK = 117, //自定义键3-单击
  CUSTOM3_DOUBLE_CLICK = 118, //自定义键3-双击
  CUSTOM3_LONG_PRESS_DOWN = 119, //自定义键3-长按按下
  CUSTOM3_LONG_PRESS_UP = 120, //自定义键3-长按抬起

  FRIENDS_MANUAL_CLICK = 121, //朋友圈手册-单击
  FRIENDS_MANUAL_DOUBLE_CLICK = 122, //朋友圈手册-双击
  FRIENDS_MANUAL_LONG_PRESS_DOWN = 123, //朋友圈手册-长按按下
  FRIENDS_MANUAL_LONG_PRESS_UP = 124, //朋友圈手册-长按抬起

  LONG_TEXT_TRANSLATION_CLICK = 125, //长文翻译-单击
  LONG_TEXT_TRANSLATION_DOUBLE_CLICK = 126, //长文翻译-双击
  LONG_TEXT_TRANSLATION_LONG_PRESS_DOWN = 127, //长文翻译-长按按下
  LONG_TEXT_TRANSLATION_LONG_PRESS_UP = 128, //长文翻译-长按抬起

  ONE_CLICK_CUTOUT_CLICK = 129, //一键抠图-单击
  ONE_CLICK_CUTOUT_DOUBLE_CLICK = 130, //一键抠图-双击
  ONE_CLICK_CUTOUT_LONG_PRESS_DOWN = 131, //一键抠图-长按按下
  ONE_CLICK_CUTOUT_LONG_PRESS_UP = 132, //一键抠图-长按抬起

  WEIBO_COPY_ASSISTANT_CLICK = 133, //微博文案小助手-单击
  WEIBO_COPY_ASSISTANT_DOUBLE_CLICK = 134, //微博文案小助手-双击
  WEIBO_COPY_ASSISTANT_LONG_PRESS_DOWN = 135, //微博文案小助手-长按按下
  WEIBO_COPY_ASSISTANT_LONG_PRESS_UP = 136, //微博文案小助手-长按抬起

  CUSTOM4_CLICK = 137, //自定义键4-单击
  CUSTOM4_DOUBLE_CLICK = 138, //自定义键4-双击
  CUSTOM4_LONG_PRESS_DOWN = 139, //自定义键4-长按按下
  CUSTOM4_LONG_PRESS_UP = 140, //自定义键4-长按抬起

  PHOTO_CLICK = 141, //拍照键-单击
  PHOTO_DOUBLE_CLICK = 142, //拍照键-双击
  PHOTO_LONG_PRESS_DOWN = 143, //拍照键-长按按下
  PHOTO_LONG_PRESS_UP = 144, //拍照键-长按抬起

  DOCUMENT_PROOFREADING_CLICK = 145, //文稿校对-单击
  DOCUMENT_PROOFREADING_DOUBLE_CLICK = 146, //文稿校对-双击
  DOCUMENT_PROOFREADING_LONG_PRESS_DOWN = 147, //文稿校对-长按按下
  DOCUMENT_PROOFREADING_LONG_PRESS_UP = 148, //文稿校对-长按抬起
}

export enum PRODUCT_TYPE {
  DEFAULT = 0,
  keyboard = 1, //键盘
}

// USB设备类型枚举————鼠标光电类型
export enum MouseICType {
  MouseICTypeError = 0,
  MouseICTypePAW3212 = 1,
  MouseICTypePAW3205 = 2,
  MouseICTypeS201 = 3,
  MouseICTypeFCT3065 = 4,
  MouseICTypeFCT3065XY = 5,
  MouseICTypeLS8650 = 6,
  MouseICTypeS201Height = 7, //S201B接地高档位
  MouseICTypeKA8G2 = 8, //KA8G2
  MouseICTypeKA8 = 9, //KA8
  MouseICTypeFCT3065_X = 15, //3065带插值
  MouseICTypeLS8650_X = 16, //8650带插值
  MouseICTypePAW3205_X = 17, //3205带插值
  MouseICTypeFCT3065XY_X = 18, //3065XY带插值
  MouseICTypePAW3212_X = 19, //3212带插值
  MouseICTypeFCT3065XY_X2 = 0x18, //3065XY带插值
  MouseICTypePAW3220 = 20, //3220
  MouseICTypePAW3220_X = 21, //3220带插值
  MouseICTypeKA8G2_inphic = 22, //KA8G2
  MouseICTypePAW3212_X_A4Tech = 25, //3212带插值 双飞燕
  MouseICTypePAW3325 = 26, //3325
  MouseICTypePAW3104 = 27, //3104
  MouseICTypePAW3212_G7 = 28, //G7
  MouseICTypeFCT3065XY_M3S = 29, //铭键M3S
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

export interface DeviceArrayType {
  Communication: Communication
  mouseconfig: DeviceInfo | null
  getModelInfo: getModelInfoModel | null
  connectionmethod: connectionmethodType //连接方式
  KeymethodConfig: KeymethodConfig[]
  DPI_currInfo: DPI_currInfoModel | null
  currLED: boolean
  reportRate_currIndex: number
  isPunctuationRecognition: boolean //语音识别是否带标点
  speech_Recognition_languages: string //语音识别语种
  productImg: string,
  PRODUCT_TYPE: PRODUCT_TYPE, //设备类型
  name: string
}

export interface KeymethodConfig {
  key: KeyPressType
  currIndex: number
}

enum connectionmethodType {
  Cloud = 0,
  USB = 1,
  Bluetooth = 2
}

export interface DPI_currInfoModel {
  length: number
  curr: number
}

export class ConnectDevice {
  static Communication: DeviceArrayType[] = []
  static targetDevice: Readonly<usbManager.USBDevice>[] = []

  static async connectDevice() {
    ConnectDevice.Communication = []
    console.log('========================扫描并连接设备');
    try {
      const devices = usbManager.getDevices();
      console.log('设备列表长度:', devices?.length || 0);
      if (!devices || devices.length === 0) {
        hilog.error(0x0000, 'USB', 'No USB devices found=================没有找到设备');
        // // 延迟后重试连接
        // setTimeout((): void => {
        //   ConnectDevice.connectDevice()
        // }, 3000);
        return;
      }
      // 显示所有设备信息————遍历
      devices.forEach((device, index) => {
        console.log(`设备 ${index}: VID=0x${device.vendorId.toString(16)}, PID=0x${device.productId.toString(16)}, 名称=${device.name}`);
      });

      // 查找匹配的设备 (VID: 0x248A)————鼠标
      const targetDevice = devices.filter(device => device.vendorId === 0x248A);
      console.error('匹配成功的设备状态：', JSON.stringify(targetDevice))
      targetDevice.forEach((targetDevice, index) => {
        console.log(`设备 ${index}: VID=0x${targetDevice.vendorId.toString(16)}, PID=0x${targetDevice.productId.toString(16)}, 名称=${targetDevice.name}`);
      });
      ConnectDevice.targetDevice = targetDevice
      if (!targetDevice || targetDevice.length === 0) {
        hilog.error(0x0000, 'USB', '没找到鼠标设备');
        console.log('未找到VID为0x248A的设备');
        // 延迟后重试连接
        setTimeout((): void => {
          ConnectDevice.connectDevice()
        }, 3000);
        return;
      }

      for (let index = 0; index < targetDevice.length; index++) {
        console.log('找到目标设备:', targetDevice[index].name);
        const hasRight = await usbManager.hasRight(targetDevice[index].name)
        console.log('权限检查：——————', hasRight)
        if (!hasRight) {
          hilog.error(0x0000, 'USB', '没有权限访问当前USB设备');
          usbManager.requestRight(targetDevice[index].name).then((seacon) => {
            // 请求权限
            console.log('请求权限结果:', seacon);
            if (seacon) {
              ConnectDevice.connectDevice()
                .then(() => {
                  let Communication_ = new Communication(index, ConnectDevice.targetDevice[index])
                  let device: DeviceArrayType = {
                    Communication: Communication_,
                    mouseconfig: null,
                    getModelInfo: null,
                    connectionmethod: connectionmethodType.USB,
                    KeymethodConfig: [],
                    DPI_currInfo: null,
                    currLED: true,
                    reportRate_currIndex: 0,
                    isPunctuationRecognition: true,
                    speech_Recognition_languages: 'ZH_CN',
                    productImg: '',
                    PRODUCT_TYPE: PRODUCT_TYPE.DEFAULT,
                    name: ConnectDevice.targetDevice[index].productName
                  }
                  ConnectDevice.Communication.push(device)
                  Communication_.connectDevice()
                })
            } else {
              hilog.warn(0x0000, 'USB', '用户拒绝了权限请求');
              // 权限被拒绝，延迟后重试
              setTimeout((): void => {
                ConnectDevice.connectDevice()
              }, 5000);
            }
          })
          return;
        } else {
          let Communication_ = new Communication(index, ConnectDevice.targetDevice[index])
          let device: DeviceArrayType = {
            Communication: Communication_,
            mouseconfig: null,
            getModelInfo: null,
            connectionmethod: connectionmethodType.USB,
            KeymethodConfig: [],
            DPI_currInfo: null,
            currLED: true,
            reportRate_currIndex: 0,
            isPunctuationRecognition: true,
            speech_Recognition_languages: 'ZH_CN',
            productImg: '',
            PRODUCT_TYPE: PRODUCT_TYPE.DEFAULT,
            name: ConnectDevice.targetDevice[index].productName
          }
          ConnectDevice.Communication.push(device)
          Communication_.connectDevice()
        }
      }

    } catch (error) {
      hilog.error(0x0000, 'USB', `Connection failed: ${error.message}`);
      console.error('连接失败:', error);
      // 连接失败，延迟后重试
      setTimeout((): void => {
        ConnectDevice.connectDevice()
      }, 5000);
    }
  }

  // 静态方法用于断开所有设备连接
  static disconnectAllDevices(): void {
    console.log('断开所有设备连接');
    ConnectDevice.Communication.forEach(device => {
      device.Communication.destroy();
    });
    ConnectDevice.Communication = [];
    ConnectDevice.targetDevice = [];
  }
}

export class Communication {
  private device_currIndex: number = 0
  private devicePipe: usbManager.USBDevicePipe | null = null;
  private targetDevice: Readonly<usbManager.USBDevice> | null = null;
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
  private isPhysicalKeyboardExist: boolean = true //热插拔监听
  private currentDPI: number[] = []
  // 查找输入端点（方向=128）用于接收数据
  private inputEndpoint: usbManager.USBEndpoint | null = null;
  private inputInterface: usbManager.USBInterface | null = null;
  // 查找输出端点（方向=128）用于接收数据
  private outputEndpoint: usbManager.USBEndpoint | null = null;
  private outputInterface: usbManager.USBInterface | null = null;
  private readState: boolean = false //标记现在是否正在接收消息
  private sendState: boolean = false //标记现在是否正在发送消息
  private sendDataList: number[][] = [] //排队发送的数据
  private audioProcessor: SmartMouseAudioProcessor = new SmartMouseAudioProcessor();
  public audioDataState: boolean = false //是否录入开启
  private flax_yuyin: boolean = true //标记：防止鼠标上来直接开启了语音输入————先发送一次0x63命令

  // 心跳重连机制相关属性 - 使用 number 类型代替 NodeJS.Timeout
  private heartbeatTimer: number | null = null;
  private lastReceivedTime: number = 0;
  private readonly HEARTBEAT_CHECK_INTERVAL: number = 5000; // 5秒检查一次
  private readonly HEARTBEAT_TIMEOUT: number = 15000; // 15秒超时
  private isHeartbeatRunning: boolean = false;
  private reconnectAttempts: number = 0;
  private readonly MAX_RECONNECT_ATTEMPTS: number = 5;
  // 新增属性 - 防止重复重连
  private isReconnecting: boolean = false;

  // 构建命令帧的通用方法
  private buildCommandFrame(cmd: number[], length: number): Uint8Array {
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
    return frame;
  }

  public async connectDevice(): Promise<void> {
    /**
     * 与鼠标建立连接
     */
    if (this.devicePipe) {
      usbManager.closePipe(this.devicePipe)
      this.devicePipe = null
    }

    try {
      this.devicePipe = usbManager.connectDevice(this.targetDevice);
      console.log('设备连接成功', JSON.stringify(this.devicePipe));
      hilog.info(0x0000, 'USB', 'Device connected successfully');

      // 重置重连尝试次数
      this.reconnectAttempts = 0;

      AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.DEFAULT)

      if (!(this.targetDevice as Readonly<usbManager.USBDevice>)?.configs?.[0]?.interfaces) {
        console.log('无法获取设备接口信息');
        return;
      }

      for (const iface of (this.targetDevice as Readonly<usbManager.USBDevice>).configs[0].interfaces) {
        if (iface.endpoints) {
          for (const endpoint of iface.endpoints) {
            if (endpoint.direction === 0) { // 输出端点
              this.outputEndpoint = endpoint
              this.outputInterface = iface
            } else if (endpoint.direction === 128) { // 输入端点
              if (iface.endpoints.length > 1) {
                this.inputEndpoint = endpoint
                this.inputInterface = iface
              }
            }
          }
        }
      }

      // 连接成功后启动心跳检测
      this.startHeartbeatCheck();
      this.getDeviceInfo()
    } catch (error) {
      console.error('设备连接失败:', error);
      await this.handleConnectionError();
    }
  }

  constructor(device_currIndex: number, targetDevice: Readonly<usbManager.USBDevice> | null) {
    this.device_currIndex = device_currIndex;
    this.targetDevice = targetDevice;
    this.lastReceivedTime = Date.now(); // 初始化最后接收时间
  }

  // 启动心跳检测
  private startHeartbeatCheck(): void {
    if (this.isHeartbeatRunning) {
      console.log('心跳检测已经在运行中');
      return;
    }

    this.lastReceivedTime = Date.now();
    this.isHeartbeatRunning = true;

    // 清除现有的定时器
    if (this.heartbeatTimer !== null) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }

    this.heartbeatTimer = setInterval((): void => {
      this.checkHeartbeat();
    }, this.HEARTBEAT_CHECK_INTERVAL) as number;

    console.log('心跳检测已启动');
  }

  // 停止心跳检测
  private stopHeartbeatCheck(): void {
    this.isHeartbeatRunning = false;

    if (this.heartbeatTimer !== null) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }
    console.log('心跳检测已停止');
  }

  // 检查心跳
  private async checkHeartbeat(): Promise<void> {
    // 如果设备未连接，不进行检查
    if (!this.devicePipe || !this.isPhysicalKeyboardExist) {
      console.log('设备未连接，跳过心跳检查');
      this.stopHeartbeatCheck();
      return;
    }

    const currentTime = Date.now();
    const timeSinceLastReceive = currentTime - this.lastReceivedTime;

    console.log(`心跳检查: 上次接收时间 ${timeSinceLastReceive}ms 前`);

    if (timeSinceLastReceive > this.HEARTBEAT_TIMEOUT) {
      console.log(`心跳超时（${timeSinceLastReceive}ms 未收到消息），开始重新连接设备`);
      this.stopHeartbeatCheck();
      await this.reconnectDevice();
    } else {
      // 可选：发送心跳包测试连接
      console.log('连接正常，发送心跳测试包');
      // this.sendHeartbeatTest();
    }
  }

  // 发送心跳测试包
  private sendHeartbeatTest(): void {
    if (!this.sendState && this.devicePipe) {
      this.getDeviceInfo([0x61]); // 使用查询设备状态作为心跳测试
    }
  }

  // 更新接收时间戳
  private updateLastReceivedTime(): void {
    this.lastReceivedTime = Date.now();
    console.log(`更新最后接收时间: ${new Date(this.lastReceivedTime).toISOString()}`);
  }

  // 处理连接错误
  private async handleConnectionError(): Promise<void> {
    this.reconnectAttempts++;

    if (this.reconnectAttempts <= this.MAX_RECONNECT_ATTEMPTS) {
      console.log(`连接错误，尝试重新连接 (${this.reconnectAttempts}/${this.MAX_RECONNECT_ATTEMPTS})`);
      const delay = Math.min(1000 * Math.pow(2, this.reconnectAttempts), 30000); // 指数退避，最大30秒

      setTimeout(async (): Promise<void> => {
        await this.reconnectDevice();
      }, delay);
    } else {
      console.log('达到最大重连尝试次数，停止重连');
      this.stopHeartbeatCheck();
    }
  }

  // 重新连接设备 - 优化版本
  private async reconnectDevice(): Promise<void> {
    // 防止重复重连
    if (this.isReconnecting) {
      console.log('重连操作正在进行中，跳过此次请求');
      return;
    }

    this.isReconnecting = true;
    console.log('开始优化重连流程，当前重连尝试次数:', this.reconnectAttempts);

    try {
      // 停止心跳检测
      this.stopHeartbeatCheck();

      // 使用更安全的关闭方式
      await this.safeClosePipe();

      // 指数退避策略
      const delay = Math.min(1000 * Math.pow(2, this.reconnectAttempts), 30000);
      console.log(`重连延迟: ${delay}ms`);
      await new Promise<void>(resolve => setTimeout(resolve, delay));

      // 执行重连
      await this.connectDevice();
      this.reconnectAttempts = 0;
      console.log('重连成功完成');

    } catch (error) {
      console.error('重连过程出错:', error);
      this.reconnectAttempts++;
      console.log('重连失败，当前重连尝试次数:', this.reconnectAttempts);

      // 重连失败后继续处理错误
      if (this.reconnectAttempts <= this.MAX_RECONNECT_ATTEMPTS) {
        await this.handleConnectionError();
      } else {
        console.log('达到最大重连尝试次数，停止重连');
        this.stopHeartbeatCheck();
      }
    } finally {
      this.isReconnecting = false;
      console.log('重连流程结束');
    }
  }

  private async safeClosePipe(): Promise<void> {
    if (!this.devicePipe) {
      console.log('设备管道为空，无需关闭');
      return;
    }

    return new Promise<void>((resolve) => {
      console.log('开始安全关闭USB管道');
      const timeoutId = setTimeout(() => {
        console.warn('USB关闭超时，强制清理并继续执行重连');
        this.devicePipe = null;
        resolve();
      }, 2000);

      try {
        usbManager.closePipe(this.devicePipe);
        console.log('USB管道成功关闭');
        clearTimeout(timeoutId);
        this.devicePipe = null;
        resolve();
      } catch (error) {
        console.error('关闭USB管道失败:', error);
        clearTimeout(timeoutId);
        this.devicePipe = null;
        resolve();
      }
    });
  }

  // 使用批量传输获取设备信息
  public async getDeviceInfo(command: number[] = [0x61]): Promise<void> {
    if (!this.devicePipe) {
      console.log('设备未连接------------------------');
      await this.reconnectDevice();
      return;
    }

    this.isPhysicalKeyboardExist = false;

    if (this.sendState && command[0] !== 0x61) {
      console.log('有消息正在发送------------------------');
      if (command !== this.sendDataList[0]) {
        this.sendDataList = this.sendDataList.filter(item => item[0] !== command[0]);
        this.sendDataList.push(command);
      }
      setTimeout((): void => {
        this.getDeviceInfo(command)
      }, 50);
      return;
    }

    if (this.sendDataList.length && command !== this.sendDataList[0]) {
      console.log('前面消息命令还没发送完：排队------------------------');
      this.sendDataList = this.sendDataList.filter(item => item[0] !== command[0]);
      this.sendDataList.push(command);
      command = this.sendDataList[0];
    }

    console.log('开始获取设备信息');
    try {
      if (this.outputEndpoint && this.outputInterface && this.inputEndpoint && this.inputInterface) {
        console.log('找到合适的端点，开始通信', JSON.stringify(this.outputEndpoint), '+',
          JSON.stringify(this.outputInterface));

        // 1. 首先发送命令
        let a = await this.sendCommand(this.outputInterface, this.outputEndpoint, command);
        console.log('================================', a);

        /**
         * 命令发送失败判断
         */
        if (a === -1) {
          console.log('****************************************************************发送命令失败：断开设备连接', a);
          await this.reconnectDevice();
          console.log(`****************************************************************设备连接完成：重新发送断掉的命令:0x`,
            command[0].toString(16));
          this.getDeviceInfo(command);
          return;
        }

        this.sendDataList.splice(0, 1);
        if (this.sendDataList.length) {
          setTimeout((): void => {
            this.getDeviceInfo(this.sendDataList[0]);
          }, 1000);
          return;
        }

        this.isPhysicalKeyboardExist = true;

        // 2. 然后读取响应数据
        let b = await this.readResponse(this.inputInterface, this.inputEndpoint);
        console.log('==================b', b);

        console.log('=========================================命令发送成功，并成功读取一次数据，开始执行循环读取',
          '发送的命令是：', JSON.stringify(command), JSON.stringify(this.isPhysicalKeyboardExist));

        // 确保心跳检测在持续读取前启动
        if (!this.isHeartbeatRunning) {
          this.startHeartbeatCheck();
        }

        // 开始持续读取数据
        this.startContinuousReading();

      } else {
        console.log('未找到合适的端点');
        await this.reconnectDevice();
      }

    } catch (error) {
      console.error('获取设备信息失败:', error);
      await this.handleConnectionError();
    }
  }

  // 发送命令到输出端点
  private async sendCommand(iface: usbManager.USBInterface, endpoint: usbManager.USBEndpoint, command: number[],
    length: number = 33): Promise<number> {
    this.sendState = true;
    hilog.warn(0x00, 'send',
      '*******************************************************************************向鼠标发送消息');

    if (!this.devicePipe) {
      this.sendState = false;
      return -1;
    }

    try {
      const claimResult = usbManager.claimInterface(this.devicePipe, iface, true);
      console.log('================================================发送建立信息发送通道信息前，建立信息发送通道：',
        claimResult);

      if (claimResult === 0) {
        const cmdData = this.buildCommandFrame(command, length);
        const cmdData_21 = this.buildCommandFrame(command, 21);
        const hexString = Array.from(cmdData).map(b => b.toString(16).padStart(2, '0')).join(' ');
        const hexString_21 = Array.from(cmdData_21).map(b => b.toString(16).padStart(2, '0')).join(' ');
        console.log('\n', `发送命令 0x${command[0].toString(16)}:`, hexString, '\n',
          `发送命令 0x${command[0].toString(16)}:`, hexString_21);
        console.log('`````````````````````````````````````````````````````````````等待发送的命令:',
          this.sendDataList.length);

        const result = await usbManager.bulkTransfer(this.devicePipe, endpoint, cmdData, 2000);
        const result_21 = await usbManager.bulkTransfer(this.devicePipe, endpoint, cmdData_21, 2000);

        console.log('发送命令成功:33-----usbManager.bulkTransfer()返回发送的数据的长度:', result);
        console.log('发送命令成功:21-----usbManager.bulkTransfer()返回发送的数据的长度:', result_21);

        this.sendState = false;

        if (result !== -1) {
          return result;
        } else if (result_21 !== -1) {
          return result_21;
        }
        return result;
      }

      console.log('命令未成功发送');
      console.log('================================================发送建立信息发送通道信息前，建立信息发送通道不成功：',
        claimResult);
      this.sendState = false;

    } catch (error) {
      console.error('发送命令失败:', error);
      this.sendState = false;
    }
    return -1;
  }

  // 从输入端点读取响应数据
  private async readResponse(iface: usbManager.USBInterface, endpoint: usbManager.USBEndpoint): Promise<number> {
    hilog.warn(0x00, 'send',
      '*******************************************************************************接收鼠标发送的消息');

    if (!this.devicePipe) {
      this.readState = false;
      return -1;
    }

    this.readState = true;

    try {
      const claimResult = usbManager.claimInterface(this.devicePipe, iface, true);
      console.log('声明接口结果:', claimResult);
      console.log('***************************************************************************创建通信接口：',
        claimResult);

      if (claimResult === 0) {
        const buffer = new Uint8Array(64);
        const result = await usbManager.bulkTransfer(this.devicePipe, endpoint, buffer, 5000);

        console.log('读取数据结果,读取到的数据的长度:', result);

        if (result > 0) {
          const hexData = Array.from(buffer.slice(0, result)).map(b => b.toString(16).padStart(2, '0')).join(' ');
          console.log('接收到的数据展示:', hexData);

          // 更新最后接收时间 - 重要：每次成功接收数据都更新
          this.updateLastReceivedTime();

          // 解析设备信息
          this.parseDeviceInfo(buffer.slice(0, result));
        } else {
          console.log('未接收到数据');
        }

        this.readState = false;
        return result;
      } else {
        console.log('***************************************************************************创建通信接口失败：',
          claimResult);
        this.readState = false;
      }
    } catch (error) {
      console.error('读取数据失败:', error);
      this.readState = false;
    }
    return -1;
  }

  // 开始持续读取数据
  private startContinuousReading(): void {
    if (!this.devicePipe || !this.inputInterface || !this.inputEndpoint) {
      console.log('无法开始持续读取：缺少必要的接口或端点');
      return;
    }

    // 确保心跳检测在持续读取前启动
    if (!this.isHeartbeatRunning) {
      this.startHeartbeatCheck();
    }

    // 使用异步循环持续读取数据
    (async (): Promise<void> => {
      let c = 0;
      while (this.isPhysicalKeyboardExist && this.devicePipe) {
        try {
          c++;
          console.log('循环读取鼠标数据-----', c, '---------------------');

          let a = await this.readResponse(this.inputInterface as usbManager.USBInterface,
            this.inputEndpoint as usbManager.USBEndpoint);

          if (a === -1) {
            console.log('第一次读取失败，尝试第二次读取');
            let a = await this.readResponse(this.inputInterface as usbManager.USBInterface,
              this.inputEndpoint as usbManager.USBEndpoint);
            if (a === -1) {
              console.log('连续两次读取失败，重新连接设备');
              await this.reconnectDevice();
              return;
            }
          }
        } catch (error) {
          console.error('读取数据失败:', error);
          await this.reconnectDevice();
          break;
        }
      }
    })();
  }

  // 设备拔出变化
  public changPhysicalKeyboardExistState(state: boolean): void {
    if (!state) {
      // 设备拔出时停止心跳检测
      this.stopHeartbeatCheck();
      if (this.devicePipe) {
        usbManager.closePipe(this.devicePipe);
        this.devicePipe = null;
      }
    } else {
      // 设备重新插入时重新启动心跳检测
      this.startHeartbeatCheck();
    }
    this.isPhysicalKeyboardExist = state;
  }

  // 添加销毁方法，在不再需要时清理资源
  public destroy(): void {
    console.log(`销毁设备通信实例: ${this.device_currIndex}`);
    this.stopHeartbeatCheck();
    this.isReconnecting = false; // 重置重连状态

    // 使用安全关闭
    this.safeClosePipe().then(() => {
      console.log('设备资源安全清理完成');
    }).catch(() => {
      console.error('设备资源安全清理失败:');
    });
  }

  // 解析设备信息
  private parseDeviceInfo(data: Uint8Array): void {
    if (data.length < 21) {
      console.log('数据长度不足，期望至少21字节，实际:', data.length);
      return;
    }

    const hexData = Array.from(data).map(b => b.toString(16).padStart(2, '0')).join(' ');

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

      if (data.length > 4 && data[0] === 0x0C && data[1] === 0x4D) {
        const dataLength = data[2];
        const command = data[3];

        console.log(`响应帧: 长度=${dataLength}, 命令=0x${command.toString(16)}`);

        // 原有的设备信息解析逻辑保持不变
        if (command === 0x61) { // 设备信息响应
          // SN解析 - 直接使用十六进制表示，不转换为十进制
          const snPrefix = String.fromCharCode(data[4], data[5]); // "ML"
          const snSuffixBytes = data.slice(6, 14);
          console.log('SN后缀原始字节:', Array.from(snSuffixBytes).map(b => b.toString(16).padStart(2, '0')).join(' '));

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

          if (ConnectDevice.Communication[this.device_currIndex].productImg === '') {
            // let param: productImg_Params = {}
            // _productImg(param)
            //   .then((res) => {
            //     console.log('产品图片' + JSON.stringify(res))
            //     ConnectDevice.Communication[this.device_currIndex].productImg
            //   })
          }

          // 6. 电量（协议：byte18）
          this.deviceInfo.batteryLevel = data[18];

          // 7. 固件版本（协议：byte19）
          this.deviceInfo.firmwareVersion = data[19].toString();

          ConnectDevice.Communication[this.device_currIndex].mouseconfig = this.deviceInfo;

          if (!(AppStorage.get('devicesList') as DeviceArrayType[])[this.device_currIndex].getModelInfo) {
            AppStorage.setOrCreate('devicesList', null);
            const newList: DeviceArrayType[] = JSON.parse(JSON.stringify(ConnectDevice.Communication));
            AppStorage.setOrCreate('devicesList', newList);
          } else {
            if (!ConnectDevice.Communication[this.device_currIndex].KeymethodConfig.length) {
              ConnectDevice.Communication[this.device_currIndex].KeymethodConfig = [
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
                of (AppStorage.get('devicesList') as DeviceArrayType[])[this.device_currIndex]?.getModelInfo?.keyInfos as keyInfosModel[]) {
                for (let childs of item.childs) {
                  childs.childs.forEach((keyInfos_childs_childsModel, index) => {
                    if (keyInfos_childs_childsModel.first === 1) {
                      switch (item.key) {
                        case 'voice_key': //语音键
                          if (childs.operation === 'sk') { //单击
                            ConnectDevice.Communication[this.device_currIndex].KeymethodConfig[0].currIndex = index;
                          }
                          if (childs.operation === 'lk') { //长按
                            ConnectDevice.Communication[this.device_currIndex].KeymethodConfig[1].currIndex = index;
                          }
                          break;
                        case 'search_key': //搜索键
                          if (childs.operation === 'sk') {
                            ConnectDevice.Communication[this.device_currIndex].KeymethodConfig[2].currIndex = index;
                          }
                          if (childs.operation === 'lk') { //长按
                            ConnectDevice.Communication[this.device_currIndex].KeymethodConfig[3].currIndex = index;
                          }
                          break;
                        case 'translate_key': //翻译键
                          if (childs.operation === 'sk') {
                            ConnectDevice.Communication[this.device_currIndex].KeymethodConfig[4].currIndex = index;
                          }
                          if (childs.operation === 'lk') { //长按
                            ConnectDevice.Communication[this.device_currIndex].KeymethodConfig[5].currIndex = index;
                          }
                          break;
                        case 'AI_key': //AI键
                          if (childs.operation === 'sk') {
                            ConnectDevice.Communication[this.device_currIndex].KeymethodConfig[6].currIndex = index;
                          }
                          if (childs.operation === 'lk') { //长按
                            ConnectDevice.Communication[this.device_currIndex].KeymethodConfig[7].currIndex = index;
                          }
                          break;
                        case 'M_key': //AI键
                          if (childs.operation === 'sk') {
                            ConnectDevice.Communication[this.device_currIndex].KeymethodConfig[8].currIndex = index;
                          }
                          if (childs.operation === 'lk') { //长按
                            ConnectDevice.Communication[this.device_currIndex].KeymethodConfig[9].currIndex = index;
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

          ConnectDevice.Communication[this.device_currIndex].mouseconfig = this.deviceInfo;

          if (!(AppStorage.get('devicesList') as DeviceArrayType[])[this.device_currIndex].getModelInfo) {
            AppStorage.setOrCreate('devicesList', null);
            const newList: DeviceArrayType[] = JSON.parse(JSON.stringify(ConnectDevice.Communication));
            AppStorage.setOrCreate('devicesList', newList);
          } else {
            if (!ConnectDevice.Communication[this.device_currIndex].KeymethodConfig.length) {
              ConnectDevice.Communication[this.device_currIndex].KeymethodConfig = [
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
                of (AppStorage.get('devicesList') as DeviceArrayType[])[this.device_currIndex]?.getModelInfo?.keyInfos as keyInfosModel[]) {
                for (let childs of item.childs) {
                  childs.childs.forEach((keyInfos_childs_childsModel, index) => {
                    if (keyInfos_childs_childsModel.first === 1) {
                      switch (item.key) {
                        case 'voice_key': //语音键
                          if (childs.operation === 'sk') { //单击
                            ConnectDevice.Communication[this.device_currIndex].KeymethodConfig[0].currIndex = index;
                          }
                          if (childs.operation === 'lk') { //长按
                            ConnectDevice.Communication[this.device_currIndex].KeymethodConfig[1].currIndex = index;
                          }
                          break;
                        case 'search_key': //搜索键
                          if (childs.operation === 'sk') {
                            ConnectDevice.Communication[this.device_currIndex].KeymethodConfig[2].currIndex = index;
                          }
                          if (childs.operation === 'lk') { //长按
                            ConnectDevice.Communication[this.device_currIndex].KeymethodConfig[3].currIndex = index;
                          }
                          break;
                        case 'translate_key': //翻译键
                          if (childs.operation === 'sk') {
                            ConnectDevice.Communication[this.device_currIndex].KeymethodConfig[4].currIndex = index;
                          }
                          if (childs.operation === 'lk') { //长按
                            ConnectDevice.Communication[this.device_currIndex].KeymethodConfig[5].currIndex = index;
                          }
                          break;
                        case 'AI_key': //AI键
                          if (childs.operation === 'sk') {
                            ConnectDevice.Communication[this.device_currIndex].KeymethodConfig[6].currIndex = index;
                          }
                          if (childs.operation === 'lk') { //长按
                            ConnectDevice.Communication[this.device_currIndex].KeymethodConfig[7].currIndex = index;
                          }
                          break;
                        case 'M_key': //AI键
                          if (childs.operation === 'sk') {
                            ConnectDevice.Communication[this.device_currIndex].KeymethodConfig[8].currIndex = index;
                          }
                          if (childs.operation === 'lk') { //长按
                            ConnectDevice.Communication[this.device_currIndex].KeymethodConfig[9].currIndex = index;
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
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.VOICE_CLICK)
        }
        if (data[3] === 0x40) {
          console.log('****************************语音键双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.VOICE_DOUBLE_CLICK)
        }
        if (data[3] === 0x37) {
          console.log('****************************语音键长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.VOICE_LONG_PRESS_DOWN)
        }
        if (data[3] === 0x38) {
          console.log('****************************语音键长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.VOICE_LONG_PRESS_UP)
        }
        if (data[3] === 0x35) {
          console.log('****************************搜索键单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SEARCH_CLICK)
        }
        if (data[3] === 0x41) {
          console.log('****************************搜索键双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SEARCH_DOUBLE_CLICK)
        }
        if (data[3] === 0x31) {
          console.log('****************************搜索键长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SEARCH_LONG_PRESS_DOWN)
        }
        if (data[3] === 0x32) {
          console.log('****************************搜索键长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SEARCH_LONG_PRESS_UP)
        }

        if (data[3] === 0x42) {
          console.log('****************************翻译键单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TRANSLATE_CLICK)
        }
        if (data[3] === 0x43) {
          console.log('****************************翻译键双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TRANSLATE_DOUBLE_CLICK)
        }
        if (data[3] === 0x44) {
          console.log('****************************翻译键长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TRANSLATE_LONG_PRESS_DOWN)
        }
        if (data[3] === 0x45) {
          console.log('****************************翻译键长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TRANSLATE_LONG_PRESS_UP)
        }

        if (data[3] === 0x46) {
          console.log('****************************自定义键——M键单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM_CLICK)
        }
        if (data[3] === 0x47) {
          console.log('****************************自定义键——M键双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM_DOUBLE_CLICK)
        }
        if (data[3] === 0x48) {
          console.log('****************************自定义键——M键长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM_LONG_PRESS_DOWN)
        }
        if (data[3] === 0x49) {
          console.log('****************************自定义键——M键长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM_LONG_PRESS_UP)
        }

        if (data[3] === 0x50) {
          console.log('****************************AI键单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.AI_CLICK)
        }
        if (data[3] === 0x51) {
          console.log('****************************AI键双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.AI_DOUBLE_CLICK)
        }
        if (data[3] === 0x52) {
          console.log('****************************AI键长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.AI_LONG_PRESS_DOWN)
        }
        if (data[3] === 0x53) {
          console.log('****************************AI键长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.AI_LONG_PRESS_UP)
        }

        /**
         * 键盘
         */
        // 截图翻译键
        if (data[3] === 0x80) {
          console.log('****************************截图翻译键单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SCREENSHOT_TRANSLATE_CLICK)
        }
        if (data[3] === 0x81) {
          console.log('****************************截图翻译键双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SCREENSHOT_TRANSLATE_DOUBLE_CLICK)
        }
        if (data[3] === 0x82) {
          console.log('****************************截图翻译键长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SCREENSHOT_TRANSLATE_LONG_PRESS_DOWN)
        }
        if (data[3] === 0x83) {
          console.log('****************************截图翻译键长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SCREENSHOT_TRANSLATE_LONG_PRESS_UP)
        }

        // AI绘画键
        if (data[3] === 0x84) {
          console.log('****************************AI绘画键单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.AI_PAINTING_CLICK)
        }
        if (data[3] === 0x85) {
          console.log('****************************AI绘画键双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.AI_PAINTING_DOUBLE_CLICK)
        }
        if (data[3] === 0x86) {
          console.log('****************************AI绘画键长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.AI_PAINTING_LONG_PRESS_DOWN)
        }
        if (data[3] === 0x87) {
          console.log('****************************AI绘画键长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.AI_PAINTING_LONG_PRESS_UP)
        }

        // 图片分析键改文档转换
        if (data[3] === 0x88) {
          console.log('****************************文档转换键单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.DOCUMENT_CONVERSION_CLICK)
        }
        if (data[3] === 0x89) {
          console.log('****************************文档转换键双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.DOCUMENT_CONVERSION_DOUBLE_CLICK)
        }
        if (data[3] === 0x8A) {
          console.log('****************************文档转换键长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.DOCUMENT_CONVERSION_LONG_PRESS_DOWN)
        }
        if (data[3] === 0x8B) {
          console.log('****************************文档转换键长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.DOCUMENT_CONVERSION_LONG_PRESS_UP)
        }

        // 思维导图键
        if (data[3] === 0x8C) {
          console.log('****************************思维导图键单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.MIND_MAP_CLICK)
        }
        if (data[3] === 0x8D) {
          console.log('****************************思维导图键双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.MIND_MAP_DOUBLE_CLICK)
        }
        if (data[3] === 0x8E) {
          console.log('****************************思维导图键长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.MIND_MAP_LONG_PRESS_DOWN)
        }
        if (data[3] === 0x8F) {
          console.log('****************************思维导图键长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.MIND_MAP_LONG_PRESS_UP)
        }

        // 工作总结键
        if (data[3] === 0x90) {
          console.log('****************************工作总结键单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.WORK_SUMMARY_CLICK)
        }
        if (data[3] === 0x91) {
          console.log('****************************工作总结键双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.WORK_SUMMARY_DOUBLE_CLICK)
        }
        if (data[3] === 0x92) {
          console.log('****************************工作总结键长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.WORK_SUMMARY_LONG_PRESS_DOWN)
        }
        if (data[3] === 0x93) {
          console.log('****************************工作总结键长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.WORK_SUMMARY_LONG_PRESS_UP)
        }

        // 模版下载键
        if (data[3] === 0x94) {
          console.log('****************************模版下载键单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TEMPLATE_DOWNLOAD_CLICK)
        }
        if (data[3] === 0x95) {
          console.log('****************************模版下载键双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TEMPLATE_DOWNLOAD_DOUBLE_CLICK)
        }
        if (data[3] === 0x96) {
          console.log('****************************模版下载键长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TEMPLATE_DOWNLOAD_LONG_PRESS_DOWN)
        }
        if (data[3] === 0x97) {
          console.log('****************************模版下载键长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TEMPLATE_DOWNLOAD_LONG_PRESS_UP)
        }

        // 阅读理解键
        if (data[3] === 0x98) {
          console.log('****************************阅读理解键单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.READING_COMPREHENSION_CLICK)
        }
        if (data[3] === 0x99) {
          console.log('****************************阅读理解键双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.READING_COMPREHENSION_DOUBLE_CLICK)
        }
        if (data[3] === 0x9A) {
          console.log('****************************阅读理解键长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.READING_COMPREHENSION_LONG_PRESS_DOWN)
        }
        if (data[3] === 0x9B) {
          console.log('****************************阅读理解键长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.READING_COMPREHENSION_LONG_PRESS_UP)
        }

        // 表格键
        if (data[3] === 0x9C) {
          console.log('****************************表格键单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TABLE_CLICK)
        }
        if (data[3] === 0x9D) {
          console.log('****************************表格键双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TABLE_DOUBLE_CLICK)
        }
        if (data[3] === 0x9E) {
          console.log('****************************表格键长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TABLE_LONG_PRESS_DOWN)
        }
        if (data[3] === 0x9F) {
          console.log('****************************表格键长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TABLE_LONG_PRESS_UP)
        }

        // 代码键
        if (data[3] === 0xA0) {
          console.log('****************************代码键单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CODE_CLICK)
        }
        if (data[3] === 0xA1) {
          console.log('****************************代码键双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CODE_DOUBLE_CLICK)
        }
        if (data[3] === 0xA2) {
          console.log('****************************代码键长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CODE_LONG_PRESS_DOWN)
        }
        if (data[3] === 0xA3) {
          console.log('****************************代码键长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CODE_LONG_PRESS_UP)
        }

        // 演讲稿键
        if (data[3] === 0xA4) {
          console.log('****************************演讲稿键单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SPEECH_CLICK)
        }
        if (data[3] === 0xA5) {
          console.log('****************************演讲稿键双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SPEECH_DOUBLE_CLICK)
        }
        if (data[3] === 0xA6) {
          console.log('****************************演讲稿键长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SPEECH_LONG_PRESS_DOWN)
        }
        if (data[3] === 0xA7) {
          console.log('****************************演讲稿键长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SPEECH_LONG_PRESS_UP)
        }

        // 写作键
        if (data[3] === 0xA8) {
          console.log('****************************写作键单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.WRITING_CLICK)
        }
        if (data[3] === 0xA9) {
          console.log('****************************写作键双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.WRITING_DOUBLE_CLICK)
        }
        if (data[3] === 0xAA) {
          console.log('****************************写作键长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.WRITING_LONG_PRESS_DOWN)
        }
        if (data[3] === 0xAB) {
          console.log('****************************写作键长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.WRITING_LONG_PRESS_UP)
        }

        // PPT键
        if (data[3] === 0xAC) {
          console.log('****************************PPT键单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.PPT_CLICK)
        }
        if (data[3] === 0xAD) {
          console.log('****************************PPT键双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.PPT_DOUBLE_CLICK)
        }
        if (data[3] === 0xAE) {
          console.log('****************************PPT键长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.PPT_LONG_PRESS_DOWN)
        }
        if (data[3] === 0xAF) {
          console.log('****************************PPT键长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.PPT_LONG_PRESS_UP)
        }

        // 自定义键1
        if (data[3] === 0xB0) {
          console.log('****************************自定义键1单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM1_CLICK)
        }
        if (data[3] === 0xB1) {
          console.log('****************************自定义键1双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM1_DOUBLE_CLICK)
        }
        if (data[3] === 0xB2) {
          console.log('****************************自定义键1长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM1_LONG_PRESS_DOWN)
        }
        if (data[3] === 0xB3) {
          console.log('****************************自定义键1长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM1_LONG_PRESS_UP)
        }

        // 自定义键2
        if (data[3] === 0xB4) {
          console.log('****************************自定义键2单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM2_CLICK)
        }
        if (data[3] === 0xB5) {
          console.log('****************************自定义键2双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM2_DOUBLE_CLICK)
        }
        if (data[3] === 0xB6) {
          console.log('****************************自定义键2长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM2_LONG_PRESS_DOWN)
        }
        if (data[3] === 0xB7) {
          console.log('****************************自定义键2长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM2_LONG_PRESS_UP)
        }

        // 自定义键3
        if (data[3] === 0xB8) {
          console.log('****************************自定义键3单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM3_CLICK)
        }
        if (data[3] === 0xB9) {
          console.log('****************************自定义键3双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM3_DOUBLE_CLICK)
        }
        if (data[3] === 0xBA) {
          console.log('****************************自定义键3长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM3_LONG_PRESS_DOWN)
        }
        if (data[3] === 0xBB) {
          console.log('****************************自定义键3长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM3_LONG_PRESS_UP)
        }

        // 朋友圈手册
        if (data[3] === 0xC0) {
          console.log('****************************朋友圈手册单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.FRIENDS_MANUAL_CLICK)
        }
        if (data[3] === 0xC1) {
          console.log('****************************朋友圈手册双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.FRIENDS_MANUAL_DOUBLE_CLICK)
        }
        if (data[3] === 0xC2) {
          console.log('****************************朋友圈手册长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.FRIENDS_MANUAL_LONG_PRESS_DOWN)
        }
        if (data[3] === 0xC3) {
          console.log('****************************朋友圈手册长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.FRIENDS_MANUAL_LONG_PRESS_UP)
        }

        // 长文翻译
        if (data[3] === 0xC4) {
          console.log('****************************长文翻译单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.LONG_TEXT_TRANSLATION_CLICK)
        }
        if (data[3] === 0xC5) {
          console.log('****************************长文翻译双击按下****************************')
          AppStorage.setOrCreate('设备_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.LONG_TEXT_TRANSLATION_DOUBLE_CLICK)
        }
        if (data[3] === 0xC6) {
          console.log('****************************长文翻译长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.LONG_TEXT_TRANSLATION_LONG_PRESS_DOWN)
        }
        if (data[3] === 0xC7) {
          console.log('****************************长文翻译长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.LONG_TEXT_TRANSLATION_LONG_PRESS_UP)
        }

        // 一键抠图
        if (data[3] === 0xC8) {
          console.log('****************************一键抠图单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.ONE_CLICK_CUTOUT_CLICK)
        }
        if (data[3] === 0xC9) {
          console.log('****************************一键抠图双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.ONE_CLICK_CUTOUT_DOUBLE_CLICK)
        }
        if (data[3] === 0xCA) {
          console.log('****************************一键抠图长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.ONE_CLICK_CUTOUT_LONG_PRESS_DOWN)
        }
        if (data[3] === 0xCB) {
          console.log('****************************一键抠图长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.ONE_CLICK_CUTOUT_LONG_PRESS_UP)
        }

        // 微博文案小助手
        if (data[3] === 0xCC) {
          console.log('****************************微博文案小助手单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.WEIBO_COPY_ASSISTANT_CLICK)
        }
        if (data[3] === 0xCD) {
          console.log('****************************微博文案小助手双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.WEIBO_COPY_ASSISTANT_DOUBLE_CLICK)
        }
        if (data[3] === 0xCE) {
          console.log('****************************微博文案小助手长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.WEIBO_COPY_ASSISTANT_LONG_PRESS_DOWN)
        }
        if (data[3] === 0xCF) {
          console.log('****************************微博文案小助手长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.WEIBO_COPY_ASSISTANT_LONG_PRESS_UP)
        }

        // 自定义键4
        if (data[3] === 0xE0) {
          console.log('****************************自定义键4单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM4_CLICK)
        }
        if (data[3] === 0xE1) {
          console.log('****************************自定义键4双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM4_DOUBLE_CLICK)
        }
        if (data[3] === 0xE2) {
          console.log('****************************自定义键4长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM4_LONG_PRESS_DOWN)
        }
        if (data[3] === 0xE3) {
          console.log('****************************自定义键4长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM4_LONG_PRESS_UP)
        }

        // 拍照键
        if (data[3] === 0xE5) {
          console.log('****************************拍照键单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.PHOTO_CLICK)
        }
        if (data[3] === 0xE6) {
          console.log('****************************拍照键双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.PHOTO_DOUBLE_CLICK)
        }
        if (data[3] === 0xE7) {
          console.log('****************************拍照键长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.PHOTO_LONG_PRESS_DOWN)
        }
        if (data[3] === 0xE8) {
          console.log('****************************拍照键长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.PHOTO_LONG_PRESS_UP)
        }

        // 文稿校对
        if (data[3] === 0xE9) {
          console.log('****************************文稿校对单击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.DOCUMENT_PROOFREADING_CLICK)
        }
        if (data[3] === 0xEA) {
          console.log('****************************文稿校对双击按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.DOCUMENT_PROOFREADING_DOUBLE_CLICK)
        }
        if (data[3] === 0xEB) {
          console.log('****************************文稿校对长按按下****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.DOCUMENT_PROOFREADING_LONG_PRESS_DOWN)
        }
        if (data[3] === 0xEC) {
          console.log('****************************文稿校对长按抬起****************************')
          AppStorage.setOrCreate('device_currIndex', this.device_currIndex)
          AppStorage.setOrCreate('device_isBle', false)
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.DOCUMENT_PROOFREADING_LONG_PRESS_UP)
        }

      } else {
        console.log('无效的响应帧格式');
      }

    } catch (error) {
      console.warn(JSON.stringify(ConnectDevice.Communication[this.device_currIndex].KeymethodConfig));
      console.error('解析设备信息错误:', error);
    }

    /**
     * 防止没有接收到鼠标配置信息
     */
    if (this.deviceInfo.sn === '') {
      if (this.devicePipe) {
        console.log('没有收到0x61命令,重新获取设备信息');
        this.getDeviceInfo();
      }
    } else {
      if (!ConnectDevice.Communication[this.device_currIndex].getModelInfo) {
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
            ConnectDevice.Communication[this.device_currIndex].getModelInfo = getModelInfo;
            const newList: DeviceArrayType[] = JSON.parse(JSON.stringify(ConnectDevice.Communication));
            AppStorage.setOrCreate('devicesList', newList);

            /**
             * 判断当前设备是否是键盘
             */
            if ((ConnectDevice.Communication[this.device_currIndex].getModelInfo as getModelInfoModel).functions.length !==
              0) {
              for (let item
                of (ConnectDevice.Communication[this.device_currIndex].getModelInfo as getModelInfoModel).functions) {
                if (item.code === 'keyboard') {
                  ConnectDevice.Communication[this.device_currIndex].PRODUCT_TYPE = PRODUCT_TYPE.keyboard;
                }
              }
            }
          }
        }).catch(() => {
          console.log('获取设备模型信息请求失败');
        });
      } else {
        if (this.flax_yuyin) {
          this.getDeviceInfo([0x63]);
        }
      }
    }
  }

  static audioData: Int16Array[] = []

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
        Communication.audioData.push(pcmData);
      }
    } catch (error) {
      console.error('处理音频数据失败:', error);
    }
  }
}