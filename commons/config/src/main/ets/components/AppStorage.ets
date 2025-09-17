class AppStorage {
  /**
   * 登录   持久化存储
   */
  static readonly login: boolean = false
  /**
   * 鼠标信息
   * 数据类型：DeviceInfo
   * 根据鼠标0x69命令实时变化
   * 根据鼠标0x61命令初始化
   */
  static readonly mouseconfig: boolean = false
  /**
   * 鼠标 1b数据 webSocket对话转换  语音转文字
   * 初始化 in AudioWebSocketHandler
   * 调用;
   */
  static readonly audioToText_res: boolean = false
  /**
   * 鼠标按键事件监听
   * 根据鼠标响应数据随时改变
   */
  static readonly mouse_KeyPressType: boolean = false
}