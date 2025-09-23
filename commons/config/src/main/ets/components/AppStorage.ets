class AppStorage {
  /**
   * 登录   持久化存储
   */
  static readonly login: boolean = false
  /**
   * 首页上下文信息  Index
   */
  static readonly context: boolean = false
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
  /**
   * 验证码保存,用于登录测试
   */
  static readonly _getCode: boolean = false
  /**
   * 用户注册登录，用户信息数据
   * 初始化 ：用户登录时
   *包含：账号、密码、token等信息
   * 测试密码：123456
   * 数据类型：register_Response---------------features\login\src\main\ets\model
   */
  static readonly userLoginInfo: boolean = false
  /**
   * 鼠标配置相关：用户按键模式详情
   * 初始化 ：获取到鼠标0x61命令，拿到sn数据后调用接口
   * 数据类型：getModelInfoModel---------------commons\config\src\main\ets\components
   */
  static readonly getModelInfo: boolean = false
  /**
   * 点击ai页面是判断是否已经在ai页面了
   * 如果已经在了，不再执行跳转操作
   */
  static readonly currpageIsAI: boolean = false
  /**
   * 语言设置——————多语言
   * 个人中心页面设置
   */
  static readonly languages: boolean = false
  /**
   * 按键方法执行配置
   * 持久化存储
   */
  static readonly KeymethodConfig: boolean = false
}