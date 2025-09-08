import { usbManager } from '@kit.BasicServicesKit';
import {ConnectionState}from './ConnectionState'
/**
 * Usb设备实体
 */
export class UsbDevice {
  /**
   * 设备 ID
   */
  deviceId: string
  /**
   * 设备名称
   */
  deviceName: string
  /**
   * 制造商
   */
  manufacturerName: string
  /**
   * pid
   */
  pid: number
  /**
   * vid
   */
  vid: number
  /**
   * usbManager.USBDevice
   */
  usbDevice: usbManager.USBDevice
  /**
   * 设备当前连接状态
   */
  connectionState: number = ConnectionState.STATE_DISCONNECTED
  /**
   * Device连接成功时间戳
   */
  connectTime: number = -1

  /**
   * 构造函数
   * @param deviceId
   * @param deviceName
   * @param manufacturerName
   * @param pid
   * @param vid
   * @param usbDevice
   */
  constructor(
    deviceId: string,
    deviceName: string,
    manufacturerName: string,
    pid: number,
    vid: number,
    usbDevice: usbManager.USBDevice,
  ) {
    this.deviceId = deviceId
    this.deviceName = deviceName
    this.manufacturerName = manufacturerName
    this.pid = pid
    this.vid = vid
    this.usbDevice = usbDevice
  }
  
}