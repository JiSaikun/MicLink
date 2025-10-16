import { usbManager } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { SmartMouseAudioProcessor } from './SmartMouseAudioProcessor'
import { getModelInfo_Params } from '../model/MouseInfoModel'
import { _getModelInfo } from '../viewmodel/UserViewModel'
import { getModelInfoModel } from 'config'

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

export class Communication {
  static devicePipe: usbManager.USBDevicePipe | null = null;
  static deviceInfo: DeviceInfo = {
    //设备信息
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
  static isPhysicalKeyboardExist: boolean = true //热插拔监听
  static currentDPI: number[] = []
  // 查找输入端点（方向=128）用于接收数据
  static inputEndpoint: usbManager.USBEndpoint | null = null;
  static inputInterface: usbManager.USBInterface | null = null;
  // 查找输出端点（方向=128）用于接收数据
  static outputEndpoint: usbManager.USBEndpoint | null = null;
  static outputInterface: usbManager.USBInterface | null = null;
  static readState: boolean = false //标记现在是否正在接收消息
  static sendState: boolean = false //标记现在是否正在发送消息
  static sendDataList: number[][] = [] //排队发送的数据
  static audioProcessor: SmartMouseAudioProcessor = new SmartMouseAudioProcessor();
  static audioDataState: boolean = false //是否录入开启
  static flax_yuyin: boolean = true //标记：防止鼠标上来直接开启了语音输入————先发送一次0x63命令

  // 构建命令帧的通用方法
  static buildCommandFrame(cmd: number[], length: number): Uint8Array {
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
    // console.log(JSON.stringify(frame), '*******************************************************************')
    return frame;
  }

  // 扫描并连接设备
  static async connectDevice() {
    console.log('========================扫描并连接设备');
    try {
      const devices = usbManager.getDevices();
      console.log('设备列表长度:', devices?.length || 0);
      if (!devices || devices.length === 0) {
        hilog.error(0x0000, 'USB', 'No USB devices found=================没有找到设备');
        Communication.connectDevice()
        return;
      }
      // 显示所有设备信息————遍历
      devices.forEach((device, index) => {
        console.log(`设备 ${index}: VID=0x${device.vendorId.toString(16)}, PID=0x${device.productId.toString(16)}, 名称=${device.name}`);
      });

      // 查找匹配的设备 (VID: 0x248A)————鼠标
      const targetDevice = devices.find(device => device.vendorId === 0x248A);

      if (!targetDevice) {
        hilog.error(0x0000, 'USB', '没找到鼠标设备');
        console.log('未找到VID为0x248A的设备');
        return;
      }

      console.log('找到目标设备:', targetDevice.name);

      const hasRight = await usbManager.hasRight(targetDevice.name)
      console.log('权限检查：——————', hasRight)
      if (!hasRight) {
        hilog.error(0x0000, 'USB', '没有权限访问当前USB设备');
        usbManager.requestRight(targetDevice.name).then((seacon) => {
          // 请求权限
          console.log('请求权限结果:', seacon);
          if (seacon) {
            Communication.connectDevice()
              .then(() => {
                Communication.getDeviceInfo()
              })
          } else {
            hilog.warn(0x0000, 'USB', '用户拒绝了权限请求');
          }
        })
        return;
      }

      /**
       * 与鼠标建立连接
       */
      if (Communication.devicePipe) {
        usbManager.closePipe(Communication.devicePipe)
        Communication.devicePipe = null
      }
      Communication.devicePipe = usbManager.connectDevice(targetDevice);
      console.log('设备连接成功', JSON.stringify(Communication.devicePipe));
      hilog.info(0x0000, 'USB', 'Device connected successfully');

      AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.DEFAULT)

      if (!targetDevice?.configs?.[0]?.interfaces) {
        console.log('无法获取设备接口信息');
        return;
      }

      for (const iface of targetDevice.configs[0].interfaces) {
        if (iface.endpoints) {
          for (const endpoint of iface.endpoints) {
            console.log(`端点 ${endpoint.address.toString(16)}: 类型=${endpoint.type}, 方向=${endpoint.direction}`);

            if (endpoint.direction === 0) { // 输出端点
              Communication.outputEndpoint = endpoint
              Communication.outputInterface = iface
            } else if (endpoint.direction === 128) { // 输入端点
              Communication.inputEndpoint = endpoint
              Communication.inputInterface = iface
            }
          }
        }
      }

    } catch (error) {
      hilog.error(0x0000, 'USB', `Connection failed: ${error.message}`);
      console.error('连接失败:', error);
    }
  }

  // 使用批量传输获取设备信息
  static async getDeviceInfo(command: number[] = [0x61]) {
    if (!Communication.devicePipe) {
      console.log('设备未连接------------------------');
      // Communication.connectDevice().then(() => {
      //   setTimeout(() => {
      //     Communication.getDeviceInfo() //获取鼠标初始信息
      //   }, 2000)
      // })
      return;
    }
    Communication.isPhysicalKeyboardExist = false
    if (Communication.sendState && command[0] !== 0x61) {
      console.log('有消息正在发送------------------------');
      if (command !== Communication.sendDataList[0]) {
        Communication.sendDataList = Communication.sendDataList.filter(item => item[0] !== command[0]);
        Communication.sendDataList.push(command);
      }
      setTimeout(() => {
        Communication.getDeviceInfo(command)
      }, 50)
      return
    }
    if (Communication.sendDataList.length && command !== Communication.sendDataList[0]) {
      console.log('前面消息命令还没发送完：排队------------------------');
      Communication.sendDataList = Communication.sendDataList.filter(item => item[0] !== command[0]);
      Communication.sendDataList.push(command);
      command = Communication.sendDataList[0]
    }
    // if (Communication.readState && command[0] !== 0x61) {
    //   // console.log('有消息正在接收中------------------------');
    //   setTimeout(() => {
    //     Communication.getDeviceInfo(command)
    //   }, 50)
    //   return
    // }
    // // 释放接口
    // if (Communication.devicePipe && Communication.inputInterface) {
    //   // let a = usbManager.releaseInterface(Communication.devicePipe, Communication.inputInterface);
    //   // console.log('hjdashdjiashuuahs', a)
    // }
    console.log('开始获取设备信息');
    try {
      // const devices = usbManager.getDevices();
      // const targetDevice = devices.find(device => device.vendorId === 0x248A);


      if (Communication.outputEndpoint && Communication.outputInterface && Communication.inputEndpoint &&
      Communication.inputInterface) {
        console.log('找到合适的端点，开始通信', JSON.stringify(Communication.outputEndpoint), '+',
          JSON.stringify(Communication.outputInterface),);
        // 1. 首先发送0x61命令
        let a = await Communication.sendCommand(Communication.outputInterface, Communication.outputEndpoint, command);
        console.log('================================', a)
        // 发送命令完成后释放输出接口
        // usbManager.releaseInterface(Communication.devicePipe, Communication.outputInterface);
        /**
         * 命令发送失败判断
         */
        if (a === -1) {
          console.log('****************************************************************发送命令失败：断开设备连接', a)
          usbManager.closePipe(Communication.devicePipe)
          Communication.devicePipe = null
          console.log('****************************************************************发送命令失败：重新连接设备')
          await Communication.connectDevice()
          // console.log('****************************************************************发送命令失败：重新发送0x61，获取设备信息')
          // await Communication.getDeviceInfo()
          console.log(`****************************************************************设备连接完成：重新发送断掉的命令:0x`,
            command[0].toString(16))
          Communication.getDeviceInfo(command)
          return
        }
        Communication.sendDataList.splice(0, 1);
        if (Communication.sendDataList.length) {
          setTimeout(() => {
            Communication.getDeviceInfo(Communication.sendDataList[0])
          }, 1000)
          return
        }
        Communication.isPhysicalKeyboardExist = true
        // 2. 然后读取响应数据
        let b = await Communication.readResponse(Communication.inputInterface, Communication.inputEndpoint);
        console.log('==================b', b)

        console.log('=========================================命令发送成功，并成功读取一次数据，开始执行循环读取',
          '发送的命令是：', JSON.stringify(command), JSON.stringify(Communication.isPhysicalKeyboardExist))
        // 开始持续读取数据
        Communication.startContinuousReading();

        // let c = 0
        // // if (command[0]===0x61){
        // while (Communication.isPhysicalKeyboardExist) {
        //   c++
        //   console.log('循环读取鼠标数据-----', c, '---------------------', JSON.stringify(Communication.inputInterface),
        //     JSON.stringify(Communication.inputEndpoint))
        //   usbManager.releaseInterface(Communication.devicePipe, Communication.inputInterface)
        //   let a = await Communication.readResponse(Communication.inputInterface as usbManager.USBInterface,
        //     Communication.inputEndpoint as usbManager.USBEndpoint);
        //   // Communication.readState = false
        //   if (a === -1) {
        //     let a = await Communication.readResponse(Communication.inputInterface as usbManager.USBInterface,
        //       Communication.inputEndpoint as usbManager.USBEndpoint);
        //     if (a === -1) {
        //       usbManager.closePipe(Communication.devicePipe)
        //       Communication.devicePipe = null
        //       await Communication.connectDevice()
        //       await Communication.getDeviceInfo()
        //       await Communication.readResponse(Communication.inputInterface as usbManager.USBInterface,
        //         Communication.inputEndpoint as usbManager.USBEndpoint);
        //       break
        //     }
        //   }
        // }
        // // }

      } else {
        console.log('未找到合适的端点');
      }

    } catch (error) {
      console.error('获取设备信息失败:', error);
    }
  }

  // 发送命令到输出端点
  static async sendCommand(iface: usbManager.USBInterface, endpoint: usbManager.USBEndpoint,
    command: number[], length: number = 33) {
    Communication.sendState = true
    hilog.warn(0x00, 'send',
      '*******************************************************************************向鼠标发送消息')
    if (!Communication.devicePipe) {
      return;
      /**
       * 没有与设备建立连接
       */
    }
    //通信前先关闭可能未关闭的通信通道
    // let a = usbManager.releaseInterface(Communication.devicePipe, iface);
    // console.log('================================================发送信息前，关闭通道状态显示：', a, '验证起作用，保留')
    try {
      //建立信息发送通道
      const claimResult = usbManager.claimInterface(Communication.devicePipe, iface, true);
      // console.log('发送信息----声明接口结果:', claimResult);
      console.log('================================================发送建立信息发送通道信息前，建立信息发送通道：',
        claimResult,)

      if (claimResult === 0) {
        //   if (a === 0 && claimResult === 0) {
        //     console.log('================================================移除了旧的信息发送通道,并建立起了新的通信通道：')
        //   } else if (a !== 0 && claimResult === 0) {
        //     console.log('================================================没有旧的信息发送通道,只建立起了新的通信通道：')
        //   }

        // 构建命令帧
        const cmdData = Communication.buildCommandFrame(command, length);
        const cmdData_21 = Communication.buildCommandFrame(command, 21);
        const hexString = Array.from(cmdData).map(b => b.toString(16).padStart(2, '0')).join(' ');
        const hexString_21 = Array.from(cmdData_21).map(b => b.toString(16).padStart(2, '0')).join(' ');
        console.log('\n', `发送命令 0x${command[0].toString(16)}:`, hexString, '\n',
          `发送命令 0x${command[0].toString(16)}:`,
          hexString_21);
        console.log('`````````````````````````````````````````````````````````````等待发送的命令:',
          Communication.sendDataList.length)

        // 发送命令
        const result = await usbManager.bulkTransfer(
          Communication.devicePipe,
          endpoint,
          cmdData,
          2000
        );
        const result_21 = await usbManager.bulkTransfer(
          Communication.devicePipe,
          endpoint,
          cmdData_21,
          2000
        );
        console.log('发送命令成功:33-----usbManager.bulkTransfer()返回发送的数据的长度:', result);
        console.log('发送命令成功:21-----usbManager.bulkTransfer()返回发送的数据的长度:', result_21);
        // let b = usbManager.releaseInterface(Communication.devicePipe, iface);
        // console.log('发送命令完毕-----移除通信接口:', b);
        Communication.sendState = false
        if (result !== -1) {
          return result;
        } else if (result_21 !== -1) {
          return result_21;
        }
        return result;
      }
      console.log('命令未成功发送')
      console.log('================================================发送建立信息发送通道信息前，建立信息发送通道不成功：',
        claimResult)

    } catch (error) {
      console.error('发送命令失败:', error);
    }
    return -1;
  }

  // 从输入端点读取响应数据
  static async readResponse(iface: usbManager.USBInterface, endpoint: usbManager.USBEndpoint) {
    hilog.warn(0x00, 'send',
      '*******************************************************************************接收鼠标发送的消息')
    if (!Communication.devicePipe) {
      return;
    }
    Communication.readState = true
    // let a = usbManager.releaseInterface(Communication.devicePipe, iface);
    // console.log('***************************************************************************确保读取前关闭之前开辟的读取信息端口：',
    //   a)
    try {
      const claimResult = usbManager.claimInterface(Communication.devicePipe, iface, true);
      console.log('声明接口结果:', claimResult);
      console.log('***************************************************************************创建通信接口：',
        claimResult)
      if (claimResult === 0) {
        // 读取数据 - 使用足够大的缓冲区
        const buffer = new Uint8Array(64);
        const result = await usbManager.bulkTransfer(
          Communication.devicePipe,
          endpoint,
          buffer,
          5000
        );

        console.log('读取数据结果,读取到的数据的长度:', result);

        if (result > 0) {
          const hexData = Array.from(buffer.slice(0, result)).map(b => b.toString(16).padStart(2, '0')).join(' ');
          console.log('接收到的数据展示:', hexData);

          // 解析设备信息
          Communication.parseDeviceInfo(buffer.slice(0, result));

        } else {
          console.log('未接收到数据');
        }

        // usbManager.releaseInterface(Communication.devicePipe, iface);
        Communication.readState = false
        return result;
      } else {
        // Communication.changPhysicalKeyboardExistState(false)
        // usbManager.releaseInterface(Communication.devicePipe, iface);
        console.log('***************************************************************************创建通信接口失败：',
          claimResult)
      }
    } catch (error) {
      console.error('读取数据失败:', error);
    }
    return -1;
  }

  // 开始持续读取数据
  static startContinuousReading() {
    if (!Communication.devicePipe || !Communication.inputInterface || !Communication.inputEndpoint) {
      return;
    }
    // 使用异步循环持续读取数据
    (async () => {
      let c = 0
      while (Communication.isPhysicalKeyboardExist && Communication.devicePipe) {
        try {
          c++
          console.log('循环读取鼠标数据-----', c, '---------------------')
          // console.log('循环读取鼠标数据-----', c, '---------------------',
          //   JSON.stringify(Communication.inputEndpoint))
          // usbManager.releaseInterface(Communication.devicePipe, Communication.inputInterface)
          let a = await Communication.readResponse(Communication.inputInterface as usbManager.USBInterface,
            Communication.inputEndpoint as usbManager.USBEndpoint);
          if (a === -1) {
            let a = await Communication.readResponse(Communication.inputInterface as usbManager.USBInterface,
              Communication.inputEndpoint as usbManager.USBEndpoint);
            if (a === -1) {
              usbManager.closePipe(Communication.devicePipe)
              Communication.devicePipe = null
              await Communication.connectDevice()
              await Communication.getDeviceInfo()
              await Communication.readResponse(Communication.inputInterface as usbManager.USBInterface,
                Communication.inputEndpoint as usbManager.USBEndpoint);
              return
            }
          }
        } catch (error) {
          console.error('读取数据失败:', error);
          // 如果读取失败，尝试重新连接
          if (Communication.devicePipe) {
            usbManager.closePipe(Communication.devicePipe);
            Communication.devicePipe = null;
          }
          await Communication.connectDevice();
          break;
        }
      }
    })();
  }

  // 设备拔出变化
  static changPhysicalKeyboardExistState(state: boolean) {
    if (!state) {
      usbManager.closePipe(Communication.devicePipe)
      Communication.devicePipe = null
    }
    Communication.isPhysicalKeyboardExist = state
  }

  // 解析设备信息
  static parseDeviceInfo(data: Uint8Array) {
    if (data.length < 21) {
      console.log('数据长度不足，期望至少21字节，实际:', data.length);
      return;
    }
    const hexData = Array.from(data).map(b => b.toString(16).padStart(2, '0')).join(' ');
    // console.log('解析设备数据:', hexData);

    try {
      // 检查帧头F
      if (data.length > 0 && data[0] === 0x1b) {
        if (Communication.audioDataState) {
          console.log('****************************语音数据****************************')
          console.log('接收到音频数据');
          Communication.processAudioData(data);
        }
        return
      }

      if (data.length > 4 && data[0] === 0x0C && data[1] === 0x4D) {
        // console.log(data.toString())
        const dataLength = data[2];
        const command = data[3];

        console.log(`响应帧: 长度=${dataLength}, 命令=0x${command.toString(16)}`);
        // console.log(command.toString(),'=========================',command.toString(16))
        if (command === 0x61) { // 设备信息响应

          // SN解析 - 直接使用十六进制表示，不转换为十进制
          const snPrefix = String.fromCharCode(data[4], data[5]); // "ML"

          const snSuffixBytes = data.slice(6, 14);
          console.log('SN后缀原始字节:', Array.from(snSuffixBytes).map(b => b.toString(16).padStart(2, '0')).join(' '));

          let snSuffix = '';
          for (let i = 0; i < snSuffixBytes.length; i++) {
            // 直接使用十六进制值，不转换为十进制
            snSuffix += snSuffixBytes[i].toString(16).padStart(2, '0');
          }

          Communication.deviceInfo.sn = snPrefix + snSuffix;
          console.log('SN:', Communication.deviceInfo.sn); // 应该输出: ML2024012611000156

          // 2. 状态字节（协议：byte14）
          const statusByte = data[14];
          Communication.deviceInfo.micStatus = !!(statusByte & 0x01); // bit0=mic
          Communication.deviceInfo.ledStatus = !!(statusByte & 0x02); // bit1=LED
          Communication.deviceInfo.sampleRate = !!(statusByte & 0x04); // bit2=采样率

          // 3. 光电类型（协议：byte15）
          Communication.deviceInfo.icType = data[15];

          // 4. DPI档位（协议：byte16）
          Communication.deviceInfo.dpiLevel = data[16];

          // 5. 产品型号（协议：byte17=低八位，byte20=高八位）
          const productTypeLow = data[17]; // 低八位
          const productTypeHigh = data[20]; // 高八位
          Communication.deviceInfo.productType = (productTypeHigh << 8) | productTypeLow;

          // 6. 电量（协议：byte18）
          Communication.deviceInfo.batteryLevel = data[18];

          // 7. 固件版本（协议：byte19）
          Communication.deviceInfo.firmwareVersion = data[19].toString();

          // console.log('设备信息解析成功:');
          // console.log('SN:', Communication.deviceInfo.sn);
          // console.log('麦克风状态:', Communication.deviceInfo.micStatus);
          // console.log('LED状态:', Communication.deviceInfo.ledStatus);
          // console.log('采样率:', Communication.deviceInfo.sampleRate);
          // console.log('光电类型:', Communication.deviceInfo.icType);
          // console.log('DPI档位:', Communication.deviceInfo.dpiLevel);
          // console.log('产品型号:', Communication.deviceInfo.productType);
          // console.log('电量:', Communication.deviceInfo.batteryLevel); // 现在对应协议的byte18
          // console.log('固件版本:', Communication.deviceInfo.firmwareVersion);

          AppStorage.setOrCreate("mouseconfig", Communication.deviceInfo);
        }
        if (command === 0x69) {
          // byte[4]:连接状态
          if (data[4]) {
            Communication.deviceInfo.isConnected = true;
          } else {
            Communication.deviceInfo.isConnected = false;
          }
          // byte[5]: 电量
          Communication.deviceInfo.batteryLevel = data[5];
          // console.log('***********************************************************', data[6].toString())
          // byte[6]: 当前回报率
          const reportRateCode = data[6];
          switch (reportRateCode) {
            case 8:
              Communication.deviceInfo.reportRate = 125;
              break;
            case 4:
              Communication.deviceInfo.reportRate = 250;
              break;
            case 2:
              Communication.deviceInfo.reportRate = 500;
              break;
            case 1:
              Communication.deviceInfo.reportRate = 1000;
              break;
            default:
              Communication.deviceInfo.reportRate = 125;
          }

          // byte[7]: 当前氛围灯状态
          if (data[7]) {
            Communication.deviceInfo.atmosphereLight = true;
          } else {
            Communication.deviceInfo.atmosphereLight = false;
          }
          // AppStorage.setOrCreate("mouseconfig", Communication.deviceInfo)
          // console.log('设备信息解析成功:');
          // console.log('SN:', Communication.deviceInfo.sn);
          // console.log('麦克风状态:', Communication.deviceInfo.micStatus);
          // console.log('LED状态:', Communication.deviceInfo.ledStatus);
          // console.log('采样率:', Communication.deviceInfo.sampleRate);
          // console.log('光电类型:', Communication.deviceInfo.icType);
          // console.log('DPI档位:', Communication.deviceInfo.dpiLevel);
          // console.log('产品型号:', Communication.deviceInfo.productType);
          // console.log('电量:', Communication.deviceInfo.batteryLevel);
          // console.log('固件版本:', Communication.deviceInfo.firmwareVersion);
          // console.log('鼠标连接状态:', Communication.deviceInfo.isConnected);
          // console.log('当前回报率:', Communication.deviceInfo.reportRate, 'Hz/min');
          // console.log('当前氛围灯状态:', Communication.deviceInfo.atmosphereLight);
          AppStorage.setOrCreate("mouseconfig", Communication.deviceInfo)
          // console.log(JSON.stringify(AppStorage.get('mouseconfig')),'===================================================================')
        }
        if (command === 0x11) {

        }
        if (command === 0x63) {
          Communication.flax_yuyin = false
        }
        if (data[3] === 0x33) {
          console.log('****************************语音键单击按下****************************')
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.VOICE_CLICK)
        }
        if (data[3] === 0x40) {
          console.log('****************************语音键双击按下****************************')
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.VOICE_DOUBLE_CLICK)
        }
        if (data[3] === 0x37) {
          console.log('****************************语音键长按按下****************************')
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.VOICE_LONG_PRESS_DOWN)
        }
        if (data[3] === 0x38) {
          console.log('****************************语音键长按抬起****************************')
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.VOICE_LONG_PRESS_UP)
        }
        if (data[3] === 0x35) {
          console.log('****************************搜索键单击按下****************************')
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SEARCH_CLICK)
        }
        if (data[3] === 0x41) {
          console.log('****************************搜索键双击按下****************************')
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SEARCH_DOUBLE_CLICK)
        }
        if (data[3] === 0x31) {
          console.log('****************************搜索键长按按下****************************')
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SEARCH_LONG_PRESS_DOWN)
        }
        if (data[3] === 0x32) {
          console.log('****************************搜索键长按抬起****************************')
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.SEARCH_LONG_PRESS_UP)
        }

        if (data[3] === 0x42) {
          console.log('****************************翻译键单击按下****************************')
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TRANSLATE_CLICK)
        }
        if (data[3] === 0x43) {
          console.log('****************************翻译键双击按下****************************')
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TRANSLATE_DOUBLE_CLICK)
        }
        if (data[3] === 0x44) {
          console.log('****************************翻译键长按按下****************************')
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TRANSLATE_LONG_PRESS_DOWN)
        }
        if (data[3] === 0x45) {
          console.log('****************************翻译键长按抬起****************************')
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.TRANSLATE_LONG_PRESS_UP)
        }

        if (data[3] === 0x46) {
          console.log('****************************自定义键——M键单击按下****************************')
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM_CLICK)
        }
        if (data[3] === 0x47) {
          console.log('****************************自定义键——M键双击按下****************************')
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM_DOUBLE_CLICK)
        }
        if (data[3] === 0x48) {
          console.log('****************************自定义键——M键长按按下****************************')
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM_LONG_PRESS_DOWN)
        }
        if (data[3] === 0x49) {
          console.log('****************************自定义键——M键长按抬起****************************')
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.CUSTOM_LONG_PRESS_UP)
        }

        if (data[3] === 0x50) {
          console.log('****************************AI键单击按下****************************')
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.AI_CLICK)
        }
        if (data[3] === 0x51) {
          console.log('****************************AI键双击按下****************************')
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.AI_DOUBLE_CLICK)
        }
        if (data[3] === 0x52) {
          console.log('****************************AI键长按按下****************************')
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.AI_LONG_PRESS_DOWN)
        }
        if (data[3] === 0x53) {
          console.log('****************************AI键长按抬起****************************')
          AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.AI_LONG_PRESS_UP)
        }

      } else {
        console.log('无效的响应帧格式');
      }


    } catch (error) {
      console.error('解析设备信息错误:', error);
    }

    /**
     * 防止没有接收到鼠标配置信息
     */
    if (Communication.deviceInfo.sn === '') {
      if (Communication.devicePipe) {
        console.log('没有收到0x61命令,重新获取设备信息')
        Communication.getDeviceInfo()
      }
    } else {
      if (!AppStorage.get('getModelInfo')) {
        const params: getModelInfo_Params = {
          languageCode: '',
          productCode: Communication.deviceInfo.productType.toString(),
          sno: Communication.deviceInfo.sn
        }
        _getModelInfo(params).then((res) => {
          console.log('获取用户按键模式详情数据', JSON.stringify(res.data))
          if (res.status === 200) {
            let getModelInfo: getModelInfoModel = res.data as getModelInfoModel
            AppStorage.setOrCreate('getModelInfo', getModelInfo)
          }
        }).catch(() => {
          // console.log('请求失败')
        })
      }
      else {
      // console.error('551215451564564121', JSON.stringify(AppStorage.get('getModelInfo')))
        if (Communication.flax_yuyin) {
          Communication.getDeviceInfo([0x63])
        }
      }

    }
  }

  static audioData: Int16Array[] = []

  // 处理音频数据
  static processAudioData(data: Uint8Array) {
    try {
      // 移除帧头(0x1b)
      let audioFrame = data.subarray(1);
      if (Number(Communication.deviceInfo.firmwareVersion) > 23) {
        // 解密音频数据
        const decryptedData = Communication.audioProcessor.miclinkDecrypt(audioFrame);
        // 这里可以添加播放或保存PCM数据的逻辑
        audioFrame = decryptedData
      }

      // 解码为PCM
      const pcmData = Communication.audioProcessor.processVoiceData(audioFrame);

      if (pcmData) {
        // 处理PCM数据（播放或保存）
        console.log(`解码得到PCM数据: ${pcmData.length}个样本`, '\n', '具体数据：', pcmData);
        // 这里可以添加播放或保存PCM数据的逻辑
        Communication.audioData.push(pcmData)
      }
    } catch (error) {
      console.error('处理音频数据失败:', error);
    }
  }
}

