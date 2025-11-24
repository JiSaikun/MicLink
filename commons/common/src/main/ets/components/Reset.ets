import { Communication, ConnectDevice } from 'mouse'

export function Reset() {
  // (AppStorage.get('pageInfo') as NavPathStack).clear()
  for (let item of ConnectDevice.Communication) {
    item.Communication.deviceInfo.sn = ''
    item.getModelInfo = null
    item.KeymethodConfig = []
    item.DPI_currInfo = null
    AppStorage.setOrCreate("KeymethodConfig", null) //按键设置方法执行记录
    AppStorage.setOrCreate("devicesList", []) //按键设置方法执行记录
    AppStorage.setOrCreate("mouseconfig", null) //鼠标实时数据
    AppStorage.setOrCreate("getModelInfo", {
      id: 0,
      productId: 0,
      productModelId: 0,
      type: '',
      name: null,
      memberId: null,
      sno: '',
      first: '',
      lastUpdatedDate: 0,
      keyInfos: [],
      appkey: '',
      languages: [],
      transLanguages: [],
      ttsLanguages: [],
      regionregion: '',
      cmds: [],
      xfocr: null,
      images: [],
      functions: [],
      lives: '',
      chatIeUrl: '',
      chatChromeUrl: '',
      pLevel: ''
    }) //获取用户按键模式详情
    // AppStorage.setOrCreate("languages", 'ZH_CN') //用户语言
    AppStorage.setOrCreate("speech_Recognition_languages", 'ZH_CN') //语音识别语言
    // AppStorage.setOrCreate("from_languages", 'ZH_CN') //语音翻译源语言
    // AppStorage.setOrCreate("to_languages", 'EN_US') //语音翻译目标语言
    // AppStorage.setOrCreate("wordScan_from_languages", 'ZH_CN') //划词翻译源语言
    // AppStorage.setOrCreate("wordScan_to_languages", 'EN_US') //划词翻译目标语言
    // AppStorage.setOrCreate("screenshotOCR_from_languages", 'ZH_CN') //截图识别/翻译源语言
    // AppStorage.setOrCreate("screenshotOCR_to_languages", 'EN_US') //截图识别/翻译目标语言
    // AppStorage.setOrCreate("isPunctuationRecognition", true) //语音识别是否带标点
    // AppStorage.setOrCreate("isEnableLongVoiceRecog", true) //是否开启长语音识别
    // AppStorage.setOrCreate("isWordScan_Translation", true) //是否开启划词翻译功能
    // AppStorage.setOrCreate("isOCR_Translate_Toggle", true) //是否开启截图识别/翻译
    AppStorage.setOrCreate("devices", []) //是否开启语音翻译弹窗自动关闭
  }
}