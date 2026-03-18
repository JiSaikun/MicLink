import { KeyPressType, ConnectDevice } from 'mouse' //语音输入
import { _KeyMethodConfig } from './KeyMethodConfig'
import { getModelInfoModel, keyInfos_childsModel } from 'config'
import { DeviceArrayType_Ble } from 'bluetooth'

export interface KeymethodConfig {
  key: KeyPressType
  currIndex: number
}

class setInterval_curr {
  static setInterval_curr: number = 0
}

export function _change_keyboard_KeyPressType() {

  let KeymethodConfig = AppStorage.get('device_isBle') ?
    (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number].KeymethodConfig :
    ConnectDevice.Communication[AppStorage.get('device_currIndex') as number].KeymethodConfig
  // console.error('77777777777777777777777777777', JSON.stringify(KeymethodConfig))
  let mouse_KeyPressType: KeyPressType = AppStorage.get('mouse_KeyPressType') as KeyPressType //鼠标按键事件监听
  let getModelInfo = AppStorage.get('device_isBle') ?
    (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number].getModelInfo as getModelInfoModel :
    ConnectDevice.Communication[AppStorage.get('device_currIndex') as number].getModelInfo as getModelInfoModel
  let _keyInfos_childsModel: keyInfos_childsModel | null = null
  if (mouse_KeyPressType === 11) { //语音键单击
    console.warn('语音输入+')
    _KeyMethodConfig.voiceInput()
  }
  if (mouse_KeyPressType === 13) { //语音键-长按按下
    //语音输入
    console.warn('语音输入+长按按下')
    // _KeyMethodConfig.voiceInput()
    _KeyMethodConfig.voiceInput_long()
  }
  if (mouse_KeyPressType === 14) { //语音键-长按抬起
    //语音输入
    console.warn('语音输入+长按抬起')
    // _KeyMethodConfig.voiceInput()
    _KeyMethodConfig.endvoiceInput_long()
  }
  if (mouse_KeyPressType === 21) { //搜索键-单击
    //语音助手
    console.warn('语音助手+')
    _KeyMethodConfig.voiceInput(0, true)
  }
  if (mouse_KeyPressType === 23) { //搜索键-长按按下
    //语音助手
    console.warn('语音助手+')
    _KeyMethodConfig.voiceInput_long(0, true)
  }
  if (mouse_KeyPressType === 24) { //搜索键-长按抬起
    //语音助手
    console.warn('语音助手+')
    _KeyMethodConfig.endvoiceInput_long()
  }
  if (mouse_KeyPressType === 31) { //翻译键-单击
    //语音翻译
    console.warn('语音翻译+')
    _KeyMethodConfig.voiceInput(1)
  }
  if (mouse_KeyPressType === 33) { //翻译键-长按按下
    //语音翻译
    console.warn('语音翻译+长按按下')
    _KeyMethodConfig.voiceInput_long(1)
  }
  if (mouse_KeyPressType === 34) { //翻译键-长按抬起
    //语音翻译
    console.warn('语音翻译+长按抬起')
    _KeyMethodConfig.endvoiceInput_long(1)
  }
  if (mouse_KeyPressType === 51) { //AI键-单击
    //AI智能创作
    console.warn('AI智能创作+')
    _KeyMethodConfig.openChatGPT()
  }
  if (mouse_KeyPressType === 53) { //AI键-长按按下
    //AI智能创作
    console.warn('AI智能创作+')
    _KeyMethodConfig.openChatGPT()
  }
  if (mouse_KeyPressType === 54) { //AI键-长按抬起
  }
  if (mouse_KeyPressType === KeyPressType.CUSTOM1_CLICK) { //自定义键1-单击
    for (let item of getModelInfo.keyInfos) {
      if (item.key === "voice_key") {
        _keyInfos_childsModel = item.childs[0]
      }
    }
    // console.error(JSON.stringify(getModelInfo.keyInfos))
    sk((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[0].currIndex].cmd)
  }
  if (mouse_KeyPressType === KeyPressType.CUSTOM1_LONG_PRESS_DOWN) { //自定义键1-长按按下
    for (let item of getModelInfo.keyInfos) {
      if (item.key === "voice_key") {
        _keyInfos_childsModel = item.childs[1]
      }
    }
    // console.error(JSON.stringify(getModelInfo.keyInfos))
    lk_down((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[1].currIndex].cmd)
  }
  if (mouse_KeyPressType === KeyPressType.CUSTOM1_LONG_PRESS_UP) { //自定义键1-长按抬起
    for (let item of getModelInfo.keyInfos) {
      if (item.key === "voice_key") {
        _keyInfos_childsModel = item.childs[1]
      }
    }
    // console.error(JSON.stringify(getModelInfo.keyInfos))
    lk_up((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[1].currIndex].cmd)
  }
  if (mouse_KeyPressType === KeyPressType.CUSTOM2_CLICK) {
    for (let item of getModelInfo.keyInfos) {
      if (item.key === "translate_key") {
        _keyInfos_childsModel = item.childs[0]
      }
    }
    console.error(JSON.stringify(_keyInfos_childsModel))
    console.error('翻译键单击',
      (_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[4].currIndex].cmd + 'KeymethodConfig[4]:' +
      JSON.stringify(KeymethodConfig[4]))
    sk((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[4].currIndex].cmd)
  }
  if (mouse_KeyPressType === KeyPressType.CUSTOM2_LONG_PRESS_DOWN) {
    for (let item of getModelInfo.keyInfos) {
      if (item.key === "translate_key") {
        _keyInfos_childsModel = item.childs[1]
      }
    }
    // console.error(JSON.stringify(getModelInfo.keyInfos))
    lk_down((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[5].currIndex].cmd)
  }
  if (mouse_KeyPressType === KeyPressType.CUSTOM2_LONG_PRESS_UP) {
    for (let item of getModelInfo.keyInfos) {
      if (item.key === "translate_key") {
        _keyInfos_childsModel = item.childs[1]
      }
    }
    // console.error(JSON.stringify(getModelInfo.keyInfos))
    lk_up((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[5].currIndex].cmd)

  }

  if (mouse_KeyPressType === KeyPressType.CUSTOM3_CLICK) {
    for (let item of getModelInfo.keyInfos) {
      if (item.key === "search_key") {
        _keyInfos_childsModel = item.childs[0]
      }
    }
    // console.error(JSON.stringify(getModelInfo.keyInfos))
    sk((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[2].currIndex].cmd)
  }
  if (mouse_KeyPressType === KeyPressType.CUSTOM3_LONG_PRESS_DOWN) {
    for (let item of getModelInfo.keyInfos) {
      if (item.key === "search_key") {
        _keyInfos_childsModel = item.childs[1]
      }
    }
    // console.error(JSON.stringify(getModelInfo.keyInfos))
    lk_down((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[3].currIndex].cmd)
  }
  if (mouse_KeyPressType === KeyPressType.CUSTOM3_LONG_PRESS_UP) {
    for (let item of getModelInfo.keyInfos) {
      if (item.key === "search_key") {
        _keyInfos_childsModel = item.childs[1]
      }
    }
    // console.error(JSON.stringify(getModelInfo.keyInfos))
    lk_up((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[3].currIndex].cmd)
  }

  if (mouse_KeyPressType === 41) {
  }
  if (mouse_KeyPressType === 43) {
  }
  if (mouse_KeyPressType === KeyPressType.WEIBO_COPY_ASSISTANT_CLICK) {
    for (let item of getModelInfo.keyInfos) {
      if (item.key === "M_key") {
        _keyInfos_childsModel = item.childs[0]
      }
    }
    // console.error(JSON.stringify(getModelInfo.keyInfos))
    console.error((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[8].currIndex].cmd)
    sk((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[8].currIndex].cmd)
  }
  if (mouse_KeyPressType === KeyPressType.WEIBO_COPY_ASSISTANT_LONG_PRESS_DOWN) {
    for (let item of getModelInfo.keyInfos) {
      if (item.key === "M_key") {
        _keyInfos_childsModel = item.childs[1]
      }
    }
    // console.error(JSON.stringify(getModelInfo.keyInfos))
    lk_down((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[9].currIndex].cmd)
  }
  if (mouse_KeyPressType === KeyPressType.WEIBO_COPY_ASSISTANT_LONG_PRESS_UP) {
    for (let item of getModelInfo.keyInfos) {
      if (item.key === "M_key") {
        _keyInfos_childsModel = item.childs[1]
      }
    }
    // console.error(JSON.stringify(getModelInfo.keyInfos))
    lk_down((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[9].currIndex].cmd)
  }

  if (mouse_KeyPressType === KeyPressType.WORK_SUMMARY_CLICK) { //工作总结键-单击
    //AI智能创作
    console.warn('AI智能创作+')
    _KeyMethodConfig.openChatGPT()
  }
  if (mouse_KeyPressType === KeyPressType.WORK_SUMMARY_LONG_PRESS_DOWN) { //工作总结键-长按按下
    //AI智能创作
    console.warn('AI智能创作+')
    _KeyMethodConfig.openChatGPT()
  }
  if (mouse_KeyPressType === KeyPressType.TEMPLATE_DOWNLOAD_CLICK) { //模版下载键-单击
    //AI智能创作
    console.warn('AI智能创作+')
    _KeyMethodConfig.openChatGPT()
  }
  if (mouse_KeyPressType === KeyPressType.TEMPLATE_DOWNLOAD_LONG_PRESS_DOWN) { //模版下载键-长按按下
    //AI智能创作
    console.warn('AI智能创作+')
    _KeyMethodConfig.openChatGPT()
  }
  if (mouse_KeyPressType === KeyPressType.MIND_MAP_CLICK) { //思维导图键-单击
    //AI智能创作
    console.warn('AI智能创作+')
    _KeyMethodConfig.openChatGPT()
  }
  if (mouse_KeyPressType === KeyPressType.MIND_MAP_LONG_PRESS_DOWN) { //思维导图键-长按按下
    //AI智能创作
    console.warn('AI智能创作+')
    _KeyMethodConfig.openChatGPT()
  }
  if (mouse_KeyPressType === KeyPressType.READING_COMPREHENSION_CLICK) { //阅读理解键-单击
    //AI智能创作
    console.warn('AI智能创作+')
    _KeyMethodConfig.openChatGPT()
  }
  if (mouse_KeyPressType === KeyPressType.READING_COMPREHENSION_LONG_PRESS_DOWN) { //阅读理解键-长按按下
    //AI智能创作
    console.warn('AI智能创作+')
    _KeyMethodConfig.openChatGPT()
  }
  if (mouse_KeyPressType === KeyPressType.DOCUMENT_CONVERSION_CLICK) { //文档转换键-单击
    //AI智能创作
    console.warn('AI智能创作+')
    _KeyMethodConfig.openChatGPT()
  }
  if (mouse_KeyPressType === KeyPressType.DOCUMENT_CONVERSION_LONG_PRESS_DOWN) { //文档转换键-长按按下
    //AI智能创作
    console.warn('AI智能创作+')
    _KeyMethodConfig.openChatGPT()
  }
  if (mouse_KeyPressType === KeyPressType.WRITING_CLICK) { //写作键-单击
    //AI智能创作
    console.warn('AI智能创作+')
    _KeyMethodConfig.openChatGPT()
  }
  if (mouse_KeyPressType === KeyPressType.WRITING_LONG_PRESS_DOWN) { //写作键-长按按下
    //AI智能创作
    console.warn('AI智能创作+')
    _KeyMethodConfig.openChatGPT()
  }
  if (mouse_KeyPressType === KeyPressType.TABLE_CLICK) { //表格键-单击
    //AI智能创作
    console.warn('AI智能创作+')
    _KeyMethodConfig.openChatGPT()
  }
  if (mouse_KeyPressType === KeyPressType.TABLE_LONG_PRESS_DOWN) { //表格键-长按按下
    //AI智能创作
    console.warn('AI智能创作+')
    _KeyMethodConfig.openChatGPT()
  }
  if (mouse_KeyPressType === KeyPressType.SPEECH_CLICK) { //演讲稿键-单击
    //AI智能创作
    console.warn('AI智能创作+')
    _KeyMethodConfig.openChatGPT()
  }
  if (mouse_KeyPressType === KeyPressType.SPEECH_LONG_PRESS_DOWN) { //演讲稿键-长按按下
    //AI智能创作
    console.warn('AI智能创作+')
    _KeyMethodConfig.openChatGPT()
  }
  if (mouse_KeyPressType === KeyPressType.AI_PAINTING_CLICK) { //AI绘画键-单击
    //AI智能创作
    console.warn('AI智能创作+')
    _KeyMethodConfig.openChatGPT()
  }
  if (mouse_KeyPressType === KeyPressType.AI_PAINTING_LONG_PRESS_DOWN) { //AI绘画键-长按按下
    //AI智能创作
    console.warn('AI智能创作+')
    _KeyMethodConfig.openChatGPT()
  }
  if (mouse_KeyPressType === KeyPressType.CODE_CLICK) { //代码键-单击
    //AI智能创作
    console.warn('AI智能创作+')
    _KeyMethodConfig.openChatGPT()
  }
  if (mouse_KeyPressType === KeyPressType.CODE_LONG_PRESS_DOWN) { //代码键-长按按下
    //AI智能创作
    console.warn('AI智能创作+')
    _KeyMethodConfig.openChatGPT()
  }
  if (mouse_KeyPressType === KeyPressType.PPT_CLICK) { //PPT键-单击
    //AI智能创作
    console.warn('AI智能创作+')
    _KeyMethodConfig.openChatGPT()
  }
  if (mouse_KeyPressType === KeyPressType.PPT_LONG_PRESS_DOWN) { //PPT键-长按按下
    //AI智能创作
    console.warn('AI智能创作+')
    _KeyMethodConfig.openChatGPT()
  }

  AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.DEFAULT)
}

function sk(cmd: string) {
  console.error("命令", cmd)
  switch (cmd) {
    case 'Action_VI': //语音输入
      console.warn('语音输入+')
      _KeyMethodConfig.voiceInput()
      break
    case 'Action_VT':
      //语音翻译
      console.warn('语音翻译+')
      _KeyMethodConfig.voiceInput(1)
      break
    case 'Action_ENTER':
      //回车/发送
      console.warn('回车/发送+')
      _KeyMethodConfig.entry()
      break
    case 'Action_FT':
      //固定文案
      console.warn('固定文案+')
      _KeyMethodConfig.inputFixedText()
      break
    case 'Action_OF':
      //文件
      console.warn('文件+')
      _KeyMethodConfig.openFileWithSystemApp()
      break
    case 'Action_OW':
      //打开网页
      console.warn('打开网页+')
      _KeyMethodConfig.openTheWebpage()
      break
    case 'Action_SK':
      //快捷按键
      console.warn('快捷按键+')
      _KeyMethodConfig.triggerShortcut()
      break
    case 'Action_ST':
      //截图翻译
      console.warn('截图翻译+')
      break
    case 'DEL_OPT':
      //删除
      console.warn('删除+')
      _KeyMethodConfig.delete()
      break
    case 'GO_HOME':
      //回到桌面
      console.warn('回到桌面+')
      _KeyMethodConfig.desktop()
      break
    case 'Action_LockScreen':
      //一键锁屏
      console.warn('一键锁屏+')
      _KeyMethodConfig.lockNow()
      break
    case 'Action_forward':
      //前进
      console.warn('前进+')
      _KeyMethodConfig.forward()
      break
    case 'Action_back':
      //后退
      console.warn('后退+')
      _KeyMethodConfig.back()
      break
    case 'Action_GetWord_Trans':
      //划词翻译
      console.warn('划词翻译+')
      _KeyMethodConfig.word_SelectedTranslation()
      break
    case "Action_DPI":
      //DPI切换
      console.warn('DPI切换+')
      _KeyMethodConfig.DPI_Switch()
      break
    case "Action_OFJ":
      //文件夹
      console.warn('文件夹+')
      _KeyMethodConfig.explorer()
      break
    case "Action_VS":
      //语音助手
      console.warn('语音助手+')
      _KeyMethodConfig.voiceInput(0, true)
      break
    case "Action_NO":
      //无功能
      console.warn('无功能+')
      break
    case "Action_copy":
      //复制
      console.warn('复制+')
      _KeyMethodConfig.copyContent()
      break
    case "Action_paste":
      //粘贴
      console.warn('粘贴+')
      _KeyMethodConfig.pasteTarget()
      break
    case "Action_GPT":
      //AI智能创作
      console.warn('AI智能创作+')
      _KeyMethodConfig.openChatGPT()
      break
  }
}

function lk_down(cmd: string) {
  console.error("命令", cmd)
  switch (cmd) {
    case 'Action_VI':
      //语音输入
      console.warn('语音输入+长按按下')
      // _KeyMethodConfig.voiceInput()
      _KeyMethodConfig.voiceInput_long()
      break
    case "Action_VT":
      //语音翻译
      console.warn('语音翻译+长按按下')
      _KeyMethodConfig.voiceInput_long(1)
      break
    case "Action_VS":
      //语音助手
      console.warn('语音助手+')
      _KeyMethodConfig.voiceInput_long(0, true)
      break
    case "DEL_OPT":
      //删除
      console.warn('删除+')
      if (setInterval_curr.setInterval_curr === 0) {
        setInterval_curr.setInterval_curr = setInterval(() => {
          _KeyMethodConfig.delete()
        }, 100)
      }
      break
    case "Action_GPT":
      _KeyMethodConfig.openChatGPT()
      break
  }
}

function lk_up(cmd: string) {
  console.error("命令", cmd)
  switch (cmd) {
    case 'Action_VI':
      //语音输入
      console.warn('语音输入+长按抬起')
      // _KeyMethodConfig.voiceInput()
      _KeyMethodConfig.endvoiceInput_long()
      break
    case "Action_VT":
      //语音翻译
      console.warn('语音翻译+长按抬起')
      _KeyMethodConfig.endvoiceInput_long(1)
      break
    case "Action_VS":
      //语音助手
      console.warn('语音助手+')
      _KeyMethodConfig.endvoiceInput_long()
      break
    case "DEL_OPT":
      //删除
      console.warn('删除+') //**避免按下可抬起都执行一次
      clearInterval(setInterval_curr.setInterval_curr)
      setInterval_curr.setInterval_curr = 0
      // _KeyMethodConfig.delete()
      break
  }
}