import { DeviceArrayType_Ble } from 'bluetooth'
import { Communication, ConnectDevice } from 'mouse'

export async function Reset() {
  // (AppStorage.get('pageInfo') as NavPathStack).clear()
  if (ConnectDevice.Communication.length) {
    for (let item of ConnectDevice.Communication) {
      item.Communication.deviceInfo.sn = ''
      item.getModelInfo = null
      item.KeymethodConfig = []
      item.DPI_currInfo = null
    }
  }
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
  ConnectDevice.connectDevice().then(() => {
    // for (let item of ConnectDevice.Communication) {
    //   item.Communication.changPhysicalKeyboardExistState(true)
    // }
  })

  if (AppStorage.get('devices')&&(AppStorage.get('devices') as DeviceArrayType_Ble[]).length) {
    // 获取当前的蓝牙设备列表并关闭所有连接
    const currentDevices = AppStorage.get('devices') as DeviceArrayType_Ble[] || []
    console.info('Reset: 开始关闭蓝牙设备连接，当前设备数量:', currentDevices.length)
    for (let device of currentDevices) {
      try {
        console.info('Reset: 关闭蓝牙设备连接:', device.name)
        await device.BlueTooth_devices.closeconnectDevice()
      } catch (error) {
        console.error('Reset: 关闭蓝牙设备连接失败:', error)
      }
    }
  }
  // 清空蓝牙设备列表，创建全新的空数组确保引用改变
  const emptyDevices: DeviceArrayType_Ble[] = []
  AppStorage.setOrCreate("devices", emptyDevices)
  console.info('Reset: 蓝牙设备列表已清空')

  // 强制触发设备列表更新，确保UI同步
  setTimeout(() => {
    // 再次确认清空，使用新的空数组实例
    const newEmptyDevices: DeviceArrayType_Ble[] = []
    AppStorage.setOrCreate('devices', newEmptyDevices)
    console.info('Reset: 二次确认蓝牙设备列表清空')
  }, 10)

}