import { ble } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 自定义UUID服务（与您提供的Java代码对应）
const CUSTOM_SERVICE_UUID: string = '00010203-0405-0607-0809-0a0b0c0d1911';
const NOTIFY_CHAR_UUID: string = '00010203-0405-0607-0809-0a0b0c0d2b18';
const WRITE_CHAR_UUID: string = '00010203-0405-0607-0809-0a0b0c0d2b19';

@Component
struct BLEClientDemo {
  @State device: ble.GattClientDevice | null = null;
  @State isConnected: boolean = false;
  @State isScanning: boolean = false;
  @State deviceList: Array<string> = [];
  @State selectedDevice: string = '';
  @State receivedData: string = '';
  @State sendText: string = '';
  @State logMessages: Array<string> = [];
  @State services: Array<ble.GattService> = [];

  // 添加日志
  private addLog(message: string): void {
    const timestamp: string = new Date().toLocaleTimeString();
    this.logMessages.unshift(`[${timestamp}] ${message}`);
    if (this.logMessages.length > 50) {
      this.logMessages.pop();
    }
  }

  // 扫描BLE设备
  startScan(): void {
    try {
      this.isScanning = true;
      this.deviceList = [];
      this.addLog('开始扫描BLE设备...');

      // 监听设备发现
      ble.on('BLEDeviceFind', (devices: Array<ble.ScanResult>) => {
        devices.forEach((device: ble.ScanResult) => {
          if (!this.deviceList.includes(device.deviceId)) {
            this.deviceList.push(device.deviceId);
            this.addLog(`发现设备: ${device.deviceId} (${device.deviceName || '未知'})`);
          }
        });
      });

      // 开始扫描（无过滤条件，扫描所有设备）
      ble.startBLEScan([], {
        interval: 1000,
        dutyMode: ble.ScanDuty.SCAN_MODE_LOW_POWER,
        matchMode: ble.MatchMode.MATCH_MODE_AGGRESSIVE
      });

      // 10秒后自动停止扫描
      setTimeout(() => {
        this.stopScan();
      }, 10000);

    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      this.addLog(`扫描失败: ${businessError.message}`);
      this.isScanning = false;
    }
  }

  // 停止扫描
  stopScan(): void {
    try {
      ble.stopBLEScan();
      ble.off('BLEDeviceFind');
      this.isScanning = false;
      this.addLog('扫描已停止');
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      this.addLog(`停止扫描失败: ${businessError.message}`);
    }
  }

  // 连接设备
  async connectToDevice(deviceId: string): Promise<void> {
    if (this.device) {
      this.addLog('请先断开当前连接');
      return;
    }

    try {
      this.addLog(`正在连接设备: ${deviceId}`);
      this.device = ble.createGattClientDevice(deviceId);
      this.selectedDevice = deviceId;

      // 监听连接状态变化
      this.device.on('BLEConnectionStateChange', (state: ble.BLEConnectionChangeState) => {
        this.isConnected = state.state === 2; // 2 = STATE_CONNECTED

        if (this.isConnected) {
          this.addLog('设备连接成功');
          this.discoverServices();
        } else {
          this.addLog('设备已断开连接');
          this.cleanup();
        }
      });

      // 监听特征值变化（通知）
      this.device.on('BLECharacteristicChange', (characteristic: ble.BLECharacteristic) => {
        this.handleCharacteristicChange(characteristic);
      });

      // 监听MTU变化
      this.device.on('BLEMtuChange', (mtu: number) => {
        this.addLog(`MTU协商完成: ${mtu} bytes`);
      });

      // 发起连接
      this.device.connect();

    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      this.addLog(`连接失败: ${businessError.message}`);
      this.cleanup();
    }
  }

  // 发现服务
  async discoverServices(): Promise<void> {
    if (!this.device) return;

    try {
      this.addLog('正在发现服务...');
      this.services = await this.device.getServices();
      this.addLog(`发现 ${this.services.length} 个服务`);

      // 查找自定义服务
      const customService: ble.GattService | undefined = this.services.find((service: ble.GattService) =>
      service.serviceUuid.toLowerCase() === CUSTOM_SERVICE_UUID.toLowerCase()
      );

      if (customService) {
        this.addLog('找到自定义服务');
        this.setupCustomService(customService);
      } else {
        this.addLog('未找到自定义服务');
        // 显示所有服务信息用于调试
        this.services.forEach((service: ble.GattService) => {
          this.addLog(`服务UUID: ${service.serviceUuid}`);
          if (service.characteristics) {
            service.characteristics.forEach((char: ble.BLECharacteristic) => {
              this.addLog(`  - 特征值: ${char.characteristicUuid}`);
            });
          }
        });
      }

    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      this.addLog(`发现服务失败: ${businessError.message}`);
    }
  }

  // 设置自定义服务
  setupCustomService(service: ble.GattService): void {
    if (!service.characteristics || !this.device) return;

    // 查找通知特征值
    const notifyChar: ble.BLECharacteristic | undefined = service.characteristics.find((char: ble.BLECharacteristic) =>
    char.characteristicUuid.toLowerCase() === NOTIFY_CHAR_UUID.toLowerCase()
    );

    // 查找写入特征值
    const writeChar: ble.BLECharacteristic | undefined = service.characteristics.find((char: ble.BLECharacteristic) =>
    char.characteristicUuid.toLowerCase() === WRITE_CHAR_UUID.toLowerCase()
    );

    if (notifyChar) {
      this.enableNotifications(notifyChar);
    } else {
      this.addLog('未找到通知特征值');
    }

    if (!writeChar) {
      this.addLog('未找到写入特征值');
    }

    // 设置MTU以获得更好的传输性能
    this.device.setBLEMtuSize(128);
  }

  // 启用通知
  async enableNotifications(characteristic: ble.BLECharacteristic): Promise<void> {
    if (!this.device) return;

    try {
      await this.device.setCharacteristicChangeNotification(characteristic, true);
      this.addLog('已启用特征值通知');
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      this.addLog(`启用通知失败: ${businessError.message}`);
    }
  }

  // 处理特征值变化
  handleCharacteristicChange(characteristic: ble.BLECharacteristic): void {
    if (characteristic.characteristicUuid.toLowerCase() === NOTIFY_CHAR_UUID.toLowerCase()) {
      this.processReceivedData(characteristic.characteristicValue);
    }
  }

  // 处理接收到的数据
  processReceivedData(data: ArrayBuffer): void {
    try {
      const bytes: Uint8Array = new Uint8Array(data);

      // 尝试将字节数组转换为字符串
      const text: string = this.uint8ArrayToString(bytes);

      if (this.isValidUtf8(text)) {
        this.receivedData = text;
        this.addLog(`收到文本数据: ${text}`);
      } else {
        // 显示为十六进制
        this.receivedData = this.bytesToHexString(bytes);
        this.addLog(`收到十六进制数据: ${this.receivedData}`);
      }
    } catch (error) {
      this.addLog('数据解析失败');
    }
  }

  // 将Uint8Array转换为字符串
  private uint8ArrayToString(uint8Array: Uint8Array): string {
    let result: string = '';
    for (let i: number = 0; i < uint8Array.length; i++) {
      result += String.fromCharCode(uint8Array[i]);
    }
    return result;
  }

  // 将字节数组转换为十六进制字符串
  private bytesToHexString(bytes: Uint8Array): string {
    return Array.from(bytes)
      .map((b: number) => b.toString(16).padStart(2, '0'))
      .join(' ');
  }

  // 检查是否为有效的UTF-8文本
  isValidUtf8(str: string): boolean {
    // 简单的UTF-8验证：检查字符串是否包含无效字符
    for (let i: number = 0; i < str.length; i++) {
      const charCode: number = str.charCodeAt(i);
      // 检查是否在有效的Unicode范围内（基本多文种平面）
      if (charCode > 0xD7FF && charCode < 0xE000) {
        return false; // 代理对区域，需要更复杂的检查
      }
      // 检查是否为控制字符（除了常见的制表符、换行符等）
      if (charCode < 32 && charCode !== 9 && charCode !== 10 && charCode !== 13) {
        return false;
      }
    }
    return true;
  }

  // 写入数据到特征值
  async writeData(data: string): Promise<void> {
    if (!this.device || !this.services.length) {
      this.addLog('设备未连接');
      return;
    }

    try {
      // 查找自定义服务
      const customService: ble.GattService | undefined = this.services.find((service: ble.GattService) =>
      service.serviceUuid.toLowerCase() === CUSTOM_SERVICE_UUID.toLowerCase()
      );

      if (!customService?.characteristics) {
        this.addLog('自定义服务未找到');
        return;
      }

      // 查找写入特征值
      const writeChar: ble.BLECharacteristic | undefined = customService.characteristics.find((char: ble.BLECharacteristic) =>
      char.characteristicUuid.toLowerCase() === WRITE_CHAR_UUID.toLowerCase()
      );

      if (!writeChar) {
        this.addLog('写入特征值未找到');
        return;
      }

      // 准备写入数据 - 将字符串转换为ArrayBuffer
      const dataBuffer: ArrayBuffer = this.stringToArrayBuffer(data);

      const writeCharacteristic: ble.BLECharacteristic = {
        serviceUuid: writeChar.serviceUuid,
        characteristicUuid: writeChar.characteristicUuid,
        characteristicValue: dataBuffer,
        descriptors: writeChar.descriptors
      };

      // 写入数据（需要响应）
      await this.device.writeCharacteristicValue(writeCharacteristic, ble.GattWriteType.WRITE);
      this.addLog(`数据发送成功: ${data}`);
      this.sendText = '';

    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      this.addLog(`发送数据失败: ${businessError.message}`);
    }
  }

  // 将字符串转换为ArrayBuffer
  private stringToArrayBuffer(str: string): ArrayBuffer {
    const buffer: ArrayBuffer = new ArrayBuffer(str.length);
    const view: Uint8Array = new Uint8Array(buffer);
    for (let i: number = 0; i < str.length; i++) {
      view[i] = str.charCodeAt(i);
    }
    return buffer;
  }

  // 发送十六进制数据
  async sendHexData(hexString: string): Promise<void> {
    if (!this.device || !this.services.length) return;

    try {
      // 清理十六进制字符串
      const cleanHex: string = hexString.replace(/\s+/g, '');

      // 验证十六进制格式
      if (!/^[0-9A-Fa-f]+$/.test(cleanHex) || cleanHex.length % 2 !== 0) {
        this.addLog('无效的十六进制格式');
        return;
      }

      // 转换十六进制字符串为ArrayBuffer
      const buffer: ArrayBuffer = new ArrayBuffer(cleanHex.length / 2);
      const bytes: Uint8Array = new Uint8Array(buffer);
      for (let i: number = 0; i < cleanHex.length; i += 2) {
        bytes[i / 2] = parseInt(cleanHex.substr(i, 2), 16);
      }

      // 查找自定义服务和写入特征值
      const customService: ble.GattService | undefined = this.services.find((service: ble.GattService) =>
      service.serviceUuid.toLowerCase() === CUSTOM_SERVICE_UUID.toLowerCase()
      );

      if (!customService?.characteristics) return;

      const writeChar: ble.BLECharacteristic | undefined = customService.characteristics.find((char: ble.BLECharacteristic) =>
      char.characteristicUuid.toLowerCase() === WRITE_CHAR_UUID.toLowerCase()
      );

      if (!writeChar) return;

      const writeCharacteristic: ble.BLECharacteristic = {
        serviceUuid: writeChar.serviceUuid,
        characteristicUuid: writeChar.characteristicUuid,
        characteristicValue: buffer,
        descriptors: writeChar.descriptors
      };

      await this.device.writeCharacteristicValue(writeCharacteristic, ble.GattWriteType.WRITE);
      this.addLog(`十六进制数据发送成功: ${hexString}`);

    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      this.addLog(`发送十六进制数据失败: ${businessError.message}`);
    }
  }

  // 断开连接
  disconnect(): void {
    if (this.device) {
      try {
        this.device.disconnect();
        this.addLog('正在断开连接...');
      } catch (error) {
        const businessError: BusinessError = error as BusinessError;
        this.addLog(`断开连接失败: ${businessError.message}`);
      }
    }
    this.cleanup();
  }

  // 清理资源
  cleanup(): void {
    if (this.device) {
      try {
        this.device.off('BLEConnectionStateChange');
        this.device.off('BLECharacteristicChange');
        this.device.off('BLEMtuChange');
        this.device.close();
      } catch (error) {
        // 忽略关闭时的错误
      }
      this.device = null;
    }

    this.isConnected = false;
    this.services = [];
    this.selectedDevice = '';
  }

  aboutToDisappear(): void {
    this.stopScan();
    this.disconnect();
    ble.off('BLEDeviceFind');
  }

  build() {
    Column() {
      // 标题
      Text('BLE客户端Demo - 自定义服务')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin(20)

      // 连接状态
      Row() {
        Text('连接状态:')
          .fontSize(16)
        Text(this.isConnected ? '已连接' : '未连接')
          .fontSize(16)
          .fontColor(this.isConnected ? Color.Green : Color.Red)
          .margin({ left: 10 })
      }
      .margin(10)

      // 设备选择区域
      Column() {
        Text('设备列表:')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)

        if (this.deviceList.length === 0) {
          Text('未发现设备')
            .fontSize(14)
            .fontColor(Color.Gray)
            .margin(10)
        } else {
          List({ space: 5 }) {
            ForEach(this.deviceList, (deviceId: string) => {
              ListItem() {
                Row() {
                  Text(deviceId)
                    .fontSize(14)
                  Blank()
                  Button(this.selectedDevice === deviceId && this.isConnected ? '已连接' : '连接')
                    .onClick(() => {
                      if (!(this.selectedDevice === deviceId && this.isConnected)) {
                        this.connectToDevice(deviceId);
                      }
                    })
                    .enabled(!(this.selectedDevice === deviceId && this.isConnected))
                }
                .padding(10)
                .width('100%')
              }
            })
          }
          .height(150)
        }

        Row() {
          Button(this.isScanning ? '停止扫描' : '开始扫描')
            .onClick(() => {
              if (this.isScanning) {
                this.stopScan();
              } else {
                this.startScan();
              }
            })
            .backgroundColor(this.isScanning ? Color.Orange : Color.Blue)

          Button('清空列表')
            .onClick(() => {
              this.deviceList = [];
            })
            .margin({ left: 10 })
            .backgroundColor(Color.Gray)
        }
        .margin(10)
      }
      .padding(10)
      .borderRadius(10)
      .backgroundColor('#f5f5f5')
      .margin(10)
      .width('95%')

      // 数据收发区域
      Column() {
        Text('数据通信:')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)

        // 接收数据显示
        Text('接收数据:')
          .fontSize(14)
          .alignSelf(ItemAlign.Start)
          .margin({ top: 10 })

        Text(this.receivedData || '暂无数据')
          .fontSize(14)
          .textAlign(TextAlign.Start)
          .padding(10)
          .backgroundColor(Color.White)
          .borderRadius(5)
          .width('100%')

        // 发送数据输入
        Text('发送数据:')
          .fontSize(14)
          .alignSelf(ItemAlign.Start)
          .margin({ top: 10 })

        TextInput({ placeholder: '输入要发送的文本', text: this.sendText })
          .onChange((value: string) => {
            this.sendText = value;
          })
          .padding(10)
          .backgroundColor(Color.White)
          .borderRadius(5)
          .width('100%')

        Row() {
          Button('发送文本')
            .onClick(() => {
              if (this.sendText.trim()) {
                this.writeData(this.sendText.trim());
              }
            })
            .enabled(this.isConnected && this.sendText.trim().length > 0)

          Button('发送测试数据')
            .onClick(() => {
              this.writeData(`Hello BLE! ${Date.now()}`);
            })
            .margin({ left: 10 })
            .enabled(this.isConnected)

          Button('断开连接')
            .onClick(() => {
              this.disconnect();
            })
            .margin({ left: 10 })
            .backgroundColor(Color.Red)
            .enabled(this.isConnected)
        }
        .margin({ top: 10 })
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .padding(10)
      .borderRadius(10)
      .backgroundColor('#f5f5f5')
      .margin(10)
      .width('95%')

      // 日志区域
      Column() {
        Text('操作日志:')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)

        Scroll() {
          Column() {
            ForEach(this.logMessages, (log: string, index?: number) => {
              Text(log)
                .fontSize(12)
                .textAlign(TextAlign.Start)
                .padding(5)
                .width('100%')
                .backgroundColor(index! % 2 === 0 ? '#f9f9f9' : '#ffffff')
            })
          }
          .width('100%')
        }
        .height(200)
        .margin({ top: 10 })
        .border({ width: 1, color: '#e0e0e0' })
        .borderRadius(5)

        Button('清空日志')
          .onClick(() => {
            this.logMessages = [];
          })
          .margin({ top: 10 })
          .backgroundColor(Color.Gray)
      }
      .padding(10)
      .borderRadius(10)
      .backgroundColor('#f5f5f5')
      .margin(10)
      .width('95%')

    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#f0f0f0')
  }
}