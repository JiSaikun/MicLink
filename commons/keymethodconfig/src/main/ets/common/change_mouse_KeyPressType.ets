import { KeyPressType, ConnectDevice } from 'mouse' //语音输入
import { _KeyMethodConfig } from './KeyMethodConfig'
import { OpenFileWithSystemApp } from 'api';
import { getModelInfoModel, keyInfos_childsModel } from 'config'
import { DeviceArrayType_Ble } from 'bluetooth';

export interface KeymethodConfig {
  key: KeyPressType
  currIndex: number
}

class setInterval_curr {
  static setInterval_curr: number = 0
}

export function _change_mouse_KeyPressType() {
  let KeymethodConfig = AppStorage.get('device_isBle') ?
    (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number].KeymethodConfig :
    ConnectDevice.Communication[AppStorage.get('device_currIndex') as number].KeymethodConfig
  // console.error('77777777777777777777777777777', JSON.stringify(KeymethodConfig))
  let mouse_KeyPressType: KeyPressType = AppStorage.get('mouse_KeyPressType') as KeyPressType //鼠标按键事件监听
  let getModelInfo = AppStorage.get('device_isBle') ?
    (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number].getModelInfo as getModelInfoModel :
    ConnectDevice.Communication[AppStorage.get('device_currIndex') as number].getModelInfo as getModelInfoModel
  let _keyInfos_childsModel: keyInfos_childsModel | null = null
  if (mouse_KeyPressType === 11) {
    for (let item of getModelInfo.keyInfos) {
      if (item.key === "voice_key") {
        _keyInfos_childsModel = item.childs[0]
      }
    }
    // console.error(JSON.stringify(getModelInfo.keyInfos))
    sk((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[0].currIndex].cmd)
  }
  if (mouse_KeyPressType === 13) {
    for (let item of getModelInfo.keyInfos) {
      if (item.key === "voice_key") {
        _keyInfos_childsModel = item.childs[1]
      }
    }
    // console.error(JSON.stringify(getModelInfo.keyInfos))
    lk_down((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[1].currIndex].cmd)
  }
  if (mouse_KeyPressType === 14) {
    for (let item of getModelInfo.keyInfos) {
      if (item.key === "voice_key") {
        _keyInfos_childsModel = item.childs[1]
      }
    }
    // console.error(JSON.stringify(getModelInfo.keyInfos))
    lk_up((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[1].currIndex].cmd)
  }
  if (mouse_KeyPressType === 21) {
    for (let item of getModelInfo.keyInfos) {
      if (item.key === "search_key") {
        _keyInfos_childsModel = item.childs[0]
      }
    }
    // console.error(JSON.stringify(getModelInfo.keyInfos))
    sk((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[2].currIndex].cmd)
  }
  if (mouse_KeyPressType === 23) {
    for (let item of getModelInfo.keyInfos) {
      if (item.key === "search_key") {
        _keyInfos_childsModel = item.childs[1]
      }
    }
    // console.error(JSON.stringify(getModelInfo.keyInfos))
    lk_down((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[3].currIndex].cmd)
  }
  if (mouse_KeyPressType === 24) {
    for (let item of getModelInfo.keyInfos) {
      if (item.key === "search_key") {
        _keyInfos_childsModel = item.childs[1]
      }
    }
    // console.error(JSON.stringify(getModelInfo.keyInfos))
    lk_up((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[3].currIndex].cmd)
  }
  if (mouse_KeyPressType === 31) {
    for (let item of getModelInfo.keyInfos) {
      if (item.key === "translate_key") {
        _keyInfos_childsModel = item.childs[0]
      }
    }
    console.error(JSON.stringify(_keyInfos_childsModel))
    console.error('翻译件单击',
      (_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[4].currIndex].cmd + 'KeymethodConfig[4]:' +
      JSON.stringify(KeymethodConfig[4]))
    sk((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[4].currIndex].cmd)
  }
  if (mouse_KeyPressType === 33) {
    for (let item of getModelInfo.keyInfos) {
      if (item.key === "translate_key") {
        _keyInfos_childsModel = item.childs[1]
      }
    }
    // console.error(JSON.stringify(getModelInfo.keyInfos))
    lk_down((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[5].currIndex].cmd)
  }
  if (mouse_KeyPressType === 34) {
    for (let item of getModelInfo.keyInfos) {
      if (item.key === "translate_key") {
        _keyInfos_childsModel = item.childs[1]
      }
    }
    // console.error(JSON.stringify(getModelInfo.keyInfos))
    lk_up((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[5].currIndex].cmd)

  }
  if (mouse_KeyPressType === 41) {
  }
  if (mouse_KeyPressType === 43) {
  }
  if (mouse_KeyPressType === 51) {
    for (let item of getModelInfo.keyInfos) {
      if (item.key === "AI_key") {
        _keyInfos_childsModel = item.childs[0]
      }
    }
    // console.error(JSON.stringify(getModelInfo.keyInfos))
    console.error((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[6].currIndex].cmd)
    sk((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[6].currIndex].cmd)
  }
  if (mouse_KeyPressType === 53) {
    for (let item of getModelInfo.keyInfos) {
      if (item.key === "AI_key") {
        _keyInfos_childsModel = item.childs[1]
      }
    }
    // console.error(JSON.stringify(getModelInfo.keyInfos))
    lk_down((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[7].currIndex].cmd)
  }
  if (mouse_KeyPressType === 54) {
    for (let item of getModelInfo.keyInfos) {
      if (item.key === "AI_key") {
        _keyInfos_childsModel = item.childs[1]
      }
    }
    // console.error(JSON.stringify(getModelInfo.keyInfos))
    lk_down((_keyInfos_childsModel as keyInfos_childsModel).childs[KeymethodConfig[7].currIndex].cmd)
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
      // 先清除可能存在的旧定时器，防止多个定时器同时运行
      clearInterval(setInterval_curr.setInterval_curr)
      setInterval_curr.setInterval_curr = setInterval(() => {
        _KeyMethodConfig.delete()
      }, 100)
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