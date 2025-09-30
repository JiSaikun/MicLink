class AppStorage {
  /**
   * 登录   持久化存储
   * 数据类型：Boolean
   */
  static readonly login: boolean = false
  /**
   * 首页上下文信息  Index
   * 数据类型：common.UIAbilityContext
   * 首页初始化
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
   * 持久化存储
   */
  static readonly getModelInfo: boolean = false
  /**
   * 点击ai页面是判断是否已经在ai页面了
   * 如果已经在了，不再执行跳转操作
   * 数据类型：Boolean
   */
  static readonly currpageIsAI: boolean = false
  /**
   * 语言设置——————多语言
   * 个人中心页面设置——————暂未初始化
   * 持久化储存
   * 数据类型：string
   */
  static readonly languages: boolean = false
  /**
   * 按键方法执行配置
   * 持久化存储——————
   * 初始化在设备详细设置页面——————ConfigPage2
   * 数据类型：KeymethodConfig
   */
  static readonly KeymethodConfig: boolean = false
  /**
   * 路由栈储存，方便在非页面的方法中调用路由栈对象
   * 持久化储存
   * 初始化：Index
   */
  static readonly pageInfo: boolean = false
  /**
   * 切换DPI，记录当前挡位，以及挡位个数
   * 数据类型：number
   */
  static readonly DPI_currInfo: boolean = false
  /**
   * 是否开启低电量提醒
   * 持久化存储
   * 数据类型：Boolean
   */
  static readonly lowPowerAlertEnabled: boolean = false
  /**
   * 语音输入文本记录
   * 初始化 ：语音输入弹窗
   */
  static readonly voiceInputText: boolean = false
  /**
   * 语音输入是否正在采集语音
   * 初始化 ：语音输入弹窗
   */
  static readonly voiceInputState: boolean = false
  /**
   * 语音翻译是否正在采集语音
   * 初始化 ：语音翻译弹窗
   */
  static readonly voiceTranslationState: boolean = false
  /**
   * 翻译原语言
   * 持久化储存
   * 初始化 ：语音翻译弹窗
   */
  static readonly from_languages: boolean = false
  /**
   * 翻译目标语言
   * 持久化储存
   * 初始化 ：语音翻译弹窗
   */
  static readonly to_languages: boolean = false
}