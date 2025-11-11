/**
 * 写入命令测试工具
 * 用于测试USB和蓝牙设备的命令写入功能
 */

import { ConnectDevice, Communication } from 'mouse';
import { BlueTooth_devices, DeviceArrayType_Ble } from 'bluetooth';

@Entry
@Component
struct CommandTestPage {
  @State testResult: string = '等待测试...'
  @State commandInput: string = '0x61'
  @State isUSB: boolean = true

  // 常用测试命令
  private testCommands = [
    { name: '获取设备信息', cmd: [0x61], desc: '查询设备SN、电量、固件版本等信息' },
    { name: '查询设备状态', cmd: [0x69], desc: '查询连接状态、电量、回报率等' },
    { name: '设置回报率125Hz', cmd: [0x13, 0], desc: '设置回报率为125Hz' },
    { name: '设置回报率250Hz', cmd: [0x13, 1], desc: '设置回报率为250Hz' },
    { name: '设置回报率500Hz', cmd: [0x13, 2], desc: '设置回报率为500Hz' },
    { name: '设置回报率1000Hz', cmd: [0x13, 3], desc: '设置回报率为1000Hz' },
    { name: '开启LED', cmd: [0x83], desc: '开启鼠标LED灯' },
    { name: '关闭LED', cmd: [0x84], desc: '关闭鼠标LED灯' },
    { name: '语音初始化', cmd: [0x63], desc: '初始化语音输入功能' },
  ]

  // 解析命令字符串为数字数组
  private parseCommand(cmdStr: string): number[] {
    try {
      // 支持格式: "0x61", "0x61,0x62", "61,62", "[0x61,0x62]"
      let cleaned = cmdStr.trim()
      if (cleaned.startsWith('[') && cleaned.endsWith(']')) {
        cleaned = cleaned.slice(1, -1)
      }

      const parts = cleaned.split(',').map(s => s.trim())
      return parts.map(part => {
        if (part.startsWith('0x') || part.startsWith('0X')) {
          return parseInt(part, 16)
        }
        return parseInt(part, 10)
      }).filter(n => !isNaN(n))
    } catch (e) {
      return []
    }
  }

  // 测试USB命令写入
  private async testUSBCommand(cmd: number[]): Promise<void> {
    try {
      const devices = AppStorage.get('devicesList') as any[]
      if (!devices || devices.length === 0) {
        this.testResult = '❌ 错误: 未找到USB设备，请先连接设备'
        return
      }

      const deviceIndex = 0 // 使用第一个设备
      const communication = ConnectDevice.Communication[deviceIndex]

      if (!communication || !communication.Communication) {
        this.testResult = '❌ 错误: USB设备未连接'
        return
      }

      const cmdHex = cmd.map(b => `0x${b.toString(16).padStart(2, '0')}`).join(', ')
      this.testResult = `🔄 正在发送USB命令: [${cmdHex}]...`

      // 发送命令
      await communication.Communication.getDeviceInfo(cmd)

      this.testResult = `✅ USB命令发送成功: [${cmdHex}]\n等待设备响应...`

      // 等待一段时间后检查结果
      setTimeout(() => {
        const deviceInfo = communication.mouseconfig
        if (deviceInfo) {
          this.testResult = `✅ USB命令执行成功\n设备信息已更新\nSN: ${deviceInfo.sn || 'N/A'}\n电量: ${deviceInfo.batteryLevel}%`
        } else {
          this.testResult = `⚠️ USB命令已发送，但未收到响应\n请检查设备连接状态`
        }
      }, 2000)

    } catch (error) {
      this.testResult = `❌ USB命令发送失败: ${error.message || error}`
      console.error('USB命令测试失败:', error)
    }
  }

  // 测试蓝牙命令写入
  private async testBluetoothCommand(cmd: number[]): Promise<void> {
    try {
      const devices = AppStorage.get('devices') as DeviceArrayType_Ble[]
      if (!devices || devices.length === 0) {
        this.testResult = '❌ 错误: 未找到蓝牙设备，请先连接设备'
        return
      }

      const deviceIndex = 0 // 使用第一个设备
      const device = devices[deviceIndex]

      if (!device || !device.BlueTooth_devices) {
        this.testResult = '❌ 错误: 蓝牙设备未连接'
        return
      }

      const cmdHex = cmd.map(b => `0x${b.toString(16).padStart(2, '0')}`).join(', ')
      this.testResult = `🔄 正在发送蓝牙命令: [${cmdHex}]...`

      // 发送命令
      await device.BlueTooth_devices.send(cmd)

      this.testResult = `✅ 蓝牙命令发送成功: [${cmdHex}]\n等待设备响应...`

      // 等待一段时间后检查结果
      setTimeout(() => {
        const deviceInfo = device.mouseconfig
        if (deviceInfo) {
          this.testResult = `✅ 蓝牙命令执行成功\n设备信息已更新\nSN: ${deviceInfo.sn || 'N/A'}\n电量: ${deviceInfo.batteryLevel}%`
        } else {
          this.testResult = `⚠️ 蓝牙命令已发送，但未收到响应\n请检查设备连接状态`
        }
      }, 2000)

    } catch (error) {
      this.testResult = `❌ 蓝牙命令发送失败: ${error.message || error}`
      console.error('蓝牙命令测试失败:', error)
    }
  }

  // 执行测试
  private async executeTest(): Promise<void> {
    const cmd = this.parseCommand(this.commandInput)

    if (cmd.length === 0) {
      this.testResult = '❌ 错误: 命令格式不正确\n支持格式: 0x61 或 0x61,0x62 或 [0x61,0x62]'
      return
    }

    if (this.isUSB) {
      await this.testUSBCommand(cmd)
    } else {
      await this.testBluetoothCommand(cmd)
    }
  }

  build() {
    Column({ space: 20 }) {
      Text('命令写入测试工具')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 10 })

      // 连接方式选择
      Row({ space: 20 }) {
        Button('USB')
          .backgroundColor(this.isUSB ? '#007DFF' : '#F1F3F5')
          .fontColor(this.isUSB ? Color.White : '#000000')
          .onClick(() => {
            this.isUSB = true
            this.testResult = '已切换到USB模式'
          })

        Button('蓝牙')
          .backgroundColor(!this.isUSB ? '#007DFF' : '#F1F3F5')
          .fontColor(!this.isUSB ? Color.White : '#000000')
          .onClick(() => {
            this.isUSB = false
            this.testResult = '已切换到蓝牙模式'
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 20 })

      // 常用命令列表
      Text('常用测试命令:')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)
        .margin({ left: 20, top: 10 })

      List({ space: 10 }) {
        ForEach(this.testCommands, (item, index) => {
          ListItem() {
            Column({ space: 5 }) {
              Row() {
                Text(item.name)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                Blank()
                Text(`[${item.cmd.map(b => `0x${b.toString(16).padStart(2, '0')}`).join(',')}]`)
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .width('100%')

              Text(item.desc)
                .fontSize(12)
                .fontColor('#999999')
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .onClick(() => {
              this.commandInput = item.cmd.map(b => `0x${b.toString(16).padStart(2, '0')}`).join(',')
              this.executeTest()
            })
          }
        })
      }
      .layoutWeight(1)
      .margin({ left: 20, right: 20 })

      // 自定义命令输入
      Column({ space: 10 }) {
        Text('自定义命令:')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)

        TextInput({ placeholder: '输入命令，如: 0x61 或 0x61,0x62' })
          .width('100%')
          .height(40)
          .onChange((value: string) => {
            this.commandInput = value
          })

        Button('发送命令')
          .width('100%')
          .height(45)
          .backgroundColor('#007DFF')
          .fontColor(Color.White)
          .onClick(() => {
            this.executeTest()
          })
      }
      .width('100%')
      .padding(20)

      // 测试结果
      Column({ space: 10 }) {
        Text('测试结果:')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)

        Text(this.testResult)
          .width('100%')
          .padding(15)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .fontSize(14)
          .fontColor('#333333')
      }
      .width('100%')
      .padding(20)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}


