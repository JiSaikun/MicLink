import { usbManager } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

// USB设备类型枚举
enum MouseICType {
  PAW3212 = 1,
  PAW3205 = 2,
  FCT3065 = 4,
  FCT3065XY = 5,
  LS8650 = 6,
  PAW3220 = 20,
  PAW3325 = 26,
  PAW3104 = 27
}

// 设备信息接口
interface DeviceInfo {
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

@Entry
@Component
struct UsbDeviceManager {

  private devicePipe: usbManager.USBDevicePipe | null = null;
  // 查找输出端点（方向=0）用于发送命令
  @State  outputEndpoint: usbManager.USBEndpoint | null = null;
  @State  outputInterface: usbManager.USBInterface | null = null;

  // 查找输入端点（方向=128）用于接收数据
  @State  inputEndpoint: usbManager.USBEndpoint | null = null;
  @State  inputInterface: usbManager.USBInterface | null = null;
  private deviceInfo: DeviceInfo = {
    sn: '',
    micStatus: false,
    ledStatus: false,
    sampleRate: false,
    icType: MouseICType.PAW3212,
    dpiLevel: 1,
    productType: 0,
    batteryLevel: 0,
    firmwareVersion: '',
    isConnected: false,
    reportRate: 125,
    atmosphereLight: false
  };

  // 构建0x61命令帧：0c4d04614c00000000000000000000000000000000
  private buildGetInfoCommand(): Uint8Array {
    const frame = new Uint8Array(33); // 固定21字节长度
    // 帧头
    frame[0] = 0x0C;  // 帧头高位
    frame[1] = 0x4D;  // 帧头低位
    frame[2] = 0x04;  // 数据长度
    frame[3] = 0x61;  // 命令字 (获取设备信息)
    frame[4] = 0x4C;  // 结束标志

    // 剩余字节填充0
    for (let i = 5; i < 33; i++) {
      frame[i] = 0x00;
    }

    return frame;
  }

  // 构建其他命令帧的通用方法
  private buildCommandFrame(cmd: number): Uint8Array {
    const frame = new Uint8Array(33);
    frame[0] = 0x0C;  // 帧头高位
    frame[1] = 0x4D;  // 帧头低位
    frame[2] = 0x04;  // 数据长度固定为4
    frame[3] = cmd;   // 命令字
    frame[4] = 0x4C;  // 结束标志

    // 剩余字节填充0
    for (let i = 5; i < 33; i++) {
      frame[i] = 0x00;
    }

    return frame;
  }

  // 扫描并连接设备
  private async connectDevice() {
    console.log('扫描并连接设备');
    try {
      const devices = usbManager.getDevices();
      console.log('设备列表长度:', devices?.length || 0);

      if (!devices || devices.length === 0) {
        hilog.error(0x0000, 'USB', 'No USB devices found');
        return;
      }

      // 显示所有设备信息
      devices.forEach((device, index) => {
        console.log(`设备 ${index}: VID=0x${device.vendorId.toString(16)}, PID=0x${device.productId.toString(16)}, 名称=${device.name}`);
      });

      // 查找匹配的设备 (VID: 0x248A)
      const targetDevice = devices.find(device => device.vendorId === 0x248A);

      if (!targetDevice) {
        hilog.error(0x0000, 'USB', 'Target device not found');
        console.log('未找到VID为0x248A的设备');
        return;
      }

      console.log('找到目标设备:', targetDevice.name);

      // 请求权限
      const hasRight = await usbManager.requestRight(targetDevice.name);
      console.log('请求权限结果:', hasRight);

      if (!hasRight) {
        hilog.error(0x0000, 'USB', '没有权限访问当前USB设备');
        return;
      }

      // 连接设备
      this.devicePipe = usbManager.connectDevice(targetDevice);
      console.log('设备连接成功');
      hilog.info(0x0000, 'USB', 'Device connected successfully');

      for (const iface of targetDevice.configs[0].interfaces) {
        if (iface.endpoints) {
          for (const endpoint of iface.endpoints) {
            console.log(`端点 ${endpoint.address.toString(16)}: 类型=${endpoint.type}, 方向=${endpoint.direction}`);

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

    } catch (error) {
      hilog.error(0x0000, 'USB', `Connection failed: ${error.message}`);
      console.error('连接失败:', error);
    }
  }

  // 使用批量传输获取设备信息
  private async getDeviceInfo() {
    if (!this.devicePipe) {
      console.log('设备未连接');
      return;
    }

    console.log('开始获取设备信息');

    try {
      const devices = usbManager.getDevices();
      const targetDevice = devices.find(device => device.vendorId === 0x248A);

      if (!targetDevice?.configs?.[0]?.interfaces) {
        console.log('无法获取设备接口信息');
        return;
      }

      // 查找输出端点（方向=0）用于发送命令
      let outputEndpoint: usbManager.USBEndpoint | null = null;
      let outputInterface: usbManager.USBInterface | null = null;

      // 查找输入端点（方向=128）用于接收数据
      let inputEndpoint: usbManager.USBEndpoint | null = null;
      let inputInterface: usbManager.USBInterface | null = null;

      for (const iface of targetDevice.configs[0].interfaces) {
        if (iface.endpoints) {
          for (const endpoint of iface.endpoints) {
            console.log(`端点 ${endpoint.address.toString(16)}: 类型=${endpoint.type}, 方向=${endpoint.direction}`);

            if (endpoint.direction === 0) { // 输出端点
              outputEndpoint = endpoint;
              outputInterface = iface;
            } else if (endpoint.direction === 128) { // 输入端点
              inputEndpoint = endpoint;
              inputInterface = iface;
            }
          }
        }
      }

      if (outputEndpoint && outputInterface && inputEndpoint && inputInterface) {
        console.log('找到合适的端点，开始通信');

        // 1. 首先发送0x61命令
        await this.sendCommand(outputInterface, outputEndpoint, 0x83);
        // 2. 然后读取响应数据
        await this.readResponse(inputInterface, inputEndpoint);
        while (true){
           await this.readResponse(this.inputInterface as usbManager.USBInterface, this.inputEndpoint as usbManager.USBEndpoint);
        }


      } else {
        console.log('未找到合适的端点');
      }

    } catch (error) {
      console.error('获取设备信息失败:', error);
    }
  }

  // 发送命令到输出端点
  private async sendCommand(iface: usbManager.USBInterface, endpoint: usbManager.USBEndpoint, command: number) {
    if (!this.devicePipe) return;

    try {
      const claimResult = usbManager.claimInterface(this.devicePipe, iface, true);
      console.log('声明接口结果:', claimResult);

      if (claimResult === 0) {
        // 构建命令帧
        const cmdData = this.buildCommandFrame(command);
        const hexString = Array.from(cmdData).map(b => b.toString(16).padStart(2, '0')).join(' ');
        console.log(`发送命令 0x${command.toString(16)}:`, hexString);

        // 发送命令
        const result = await usbManager.bulkTransfer(
          this.devicePipe,
          endpoint,
          cmdData,
          1000
        );

        console.log('发送命令结果:', result);
        // usbManager.releaseInterface(this.devicePipe, iface);
        console.log('==================================================================================================')

        return result;
      }
    } catch (error) {
      console.error('发送命令失败:', error);
    }
    return -1;
  }

  // 从输入端点读取响应数据
  private async readResponse(iface: usbManager.USBInterface, endpoint: usbManager.USBEndpoint) {
    console.log('========================================================================')
    if (!this.devicePipe) return;

    try {
      const claimResult = usbManager.claimInterface(this.devicePipe, iface, true);
      console.log('声明接口结果:', claimResult);

      if (claimResult === 0) {
        // 读取数据 - 使用足够大的缓冲区
        const buffer = new Uint8Array(64);
        const result = await usbManager.bulkTransfer(
          this.devicePipe,
          endpoint,
          buffer,
          1000
        );

        console.log('读取数据结果:', result);

        if (result > 0) {
          const hexData = Array.from(buffer.slice(0, result)).map(b => b.toString(16).padStart(2, '0')).join(' ');
          console.log('接收到的数据:', hexData);

          // 解析设备信息
          this.parseDeviceInfo(buffer.slice(0, result));
        } else {
          console.log('未接收到数据');
        }

        // usbManager.releaseInterface(this.devicePipe, iface);

        return result;
      }
    } catch (error) {
      console.error('读取数据失败:', error);
    }
    return -1;
  }

  // 解析设备信息
  private parseDeviceInfo(data: Uint8Array) {
    if (data.length < 21) {
      console.log('数据长度不足，期望至少21字节，实际:', data.length);
      return;
    }

    const hexData = Array.from(data).map(b => b.toString(16).padStart(2, '0')).join(' ');
    console.log('解析设备数据:', hexData);

    try {
      // 检查帧头
      if (data[0] === 0x0C && data[1] === 0x4D) {
        const dataLength = data[2];
        const command = data[3];

        console.log(`响应帧: 长度=${dataLength}, 命令=0x${command.toString(16)}`);

        if (command === 0x61) { // 设备信息响应
          // 根据协议文档解析数据
          // bytes[4-5]: SN前两位 ASCII
          const snPrefix = String.fromCharCode(data[4], data[5]);

          // bytes[6-13]: SN后16位字符串
          const snSuffixBytes = data.slice(6, 14);
          const snSuffix = String.fromCharCode(...snSuffixBytes.filter(b => b !== 0));

          this.deviceInfo.sn = snPrefix + snSuffix;

          // byte[14]: 状态字节
          const statusByte = data[14];
          this.deviceInfo.micStatus = !!(statusByte & 0x01);
          this.deviceInfo.ledStatus = !!(statusByte & 0x02);
          this.deviceInfo.sampleRate = !!(statusByte & 0x04);

          // byte[15]: 光电类型
          this.deviceInfo.icType = data[15];

          // byte[16]: DPI档位
          this.deviceInfo.dpiLevel = data[16];

          // bytes[17-18]: 产品型号
          this.deviceInfo.productType = (data[18] << 8) | data[17];

          // byte[19]: 电量
          this.deviceInfo.batteryLevel = data[19];

          // byte[20]: 固件版本
          this.deviceInfo.firmwareVersion = data[20].toString();

          console.log('设备信息解析成功:');
          console.log('SN:', this.deviceInfo.sn);
          console.log('麦克风状态:', this.deviceInfo.micStatus);
          console.log('LED状态:', this.deviceInfo.ledStatus);
          console.log('采样率:', this.deviceInfo.sampleRate);
          console.log('光电类型:', this.deviceInfo.icType);
          console.log('DPI档位:', this.deviceInfo.dpiLevel);
          console.log('产品型号:', this.deviceInfo.productType);
          console.log('电量:', this.deviceInfo.batteryLevel);
          console.log('固件版本:', this.deviceInfo.firmwareVersion);
        }
      } else {
        console.log('无效的响应帧格式');
      }
    } catch (error) {
      console.error('解析设备信息错误:', error);
    }
  }

  // 测试其他命令
  private async testOtherCommands() {
    if (!this.devicePipe) return;

    try {
      const devices = usbManager.getDevices();
      const targetDevice = devices.find(device => device.vendorId === 0x248A);

      if (!targetDevice?.configs?.[0]?.interfaces) return;

      // 查找输出端点
      for (const iface of targetDevice.configs[0].interfaces) {
        if (iface.endpoints) {
          for (const endpoint of iface.endpoints) {
            if (endpoint.direction === 0) {
              // 测试打开麦克风命令 (0x62)
              await this.sendCommand(iface, endpoint, 0x63);
              break;
            }
          }
        }
      }
    } catch (error) {
      console.error('测试命令失败:', error);
    }
  }

  build() {
    Column({ space: 20 }) {
      Text('USB设备管理器')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 30 })
      Text(`SN: ${this.deviceInfo.sn}`).fontSize(14)
      Text(`固件版本: v${this.deviceInfo.firmwareVersion}`).fontSize(14)
      Text(`电量: ${this.deviceInfo.batteryLevel}%`).fontSize(14)
      Text(`DPI档位: ${this.deviceInfo.dpiLevel}`).fontSize(14)
      Text(`光电类型: ${this.deviceInfo.icType}`).fontSize(14)
      Text(`产品型号: 0x${this.deviceInfo.productType.toString(16)}`).fontSize(14)
      Text(`麦克风: ${this.deviceInfo.micStatus ? '开启' : '关闭'}`).fontSize(14)
      Text(`LED: ${this.deviceInfo.ledStatus ? '开启' : '关闭'}`).fontSize(14)

      Button('连接设备')
        .width('80%')
        .onClick(() => this.connectDevice())

      Button('获取设备信息 (0x61)')
        .width('80%')
        .onClick(() => this.getDeviceInfo())

      Button('打开麦克风 (0x62)')
        .width('80%')
        .onClick(() => this.testOtherCommands())

    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor(Color.Gray)
  }
}