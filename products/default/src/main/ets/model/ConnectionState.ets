/**
 * 设备连接状态
 */
export class ConnectionState {
  /**
   * 连接中
   */
  static readonly STATE_CONNECTING = 1
  /**
   * 已连接
   */
  static readonly STATE_CONNECTED = 2
  /**
   * 断开中
   */
  static readonly STATE_DISCONNECTING = 3
  /**
   * 已断开
   */
  static readonly STATE_DISCONNECTED = 4
  /**
   * 连接中断 -- 连接时，设备id错误，无权限等情况触发
   */
  static readonly STATE_INTERRUPTED = 5
}