import { KeyPressType } from 'mouse' //语音输入
import { _KeyMethodConfig } from './KeyMethodConfig'
import { fileGuard } from '@kit.EnterpriseDataGuardKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { OpenFileWithSystemApp } from 'api';

export interface KeymethodConfig {
  key: KeyPressType
  currIndex: number
}

export function _change_mouse_KeyPressType() {
  // console.log('77777777777777777777777777777', AppStorage.get('mouse_KeyPressType'))
  let KeymethodConfig = AppStorage.get('KeymethodConfig') as KeymethodConfig []
  let mouse_KeyPressType: KeyPressType = AppStorage.get('mouse_KeyPressType') as KeyPressType //鼠标按键事件监听
  if (mouse_KeyPressType === 11) {
    switch (KeymethodConfig[0].currIndex) {
      case 0:
        //语音输入
        console.warn('语音输入+')
        _KeyMethodConfig.voiceInput()
        break
      case 1:
        //语音翻译
        console.warn('语音翻译+')
        _KeyMethodConfig.voiceInput(1)
        break
      case 2:
        //回车/发送
        console.warn('回车/发送+')
        _KeyMethodConfig.entry()
        break
      case 3:
        //固定文案
        console.warn('固定文案+')
        break
      case 4:
        //文件
        console.warn('文件+')
        OpenFileWithSystemApp.openFileWithSystemApp()
        // let guard: fileGuard.FileGuard = new fileGuard.FileGuard();
        // let path: string =
        //   'file://docs/storage/Users/currentUser/Desktop/%E6%96%B0%E5%BB%BA%20DWG%20%E6%96%87%E4%BB%B6.dwg';
        // guard.openFile(path, (err: BusinessError, fd: number) => {
        //   if (err) {
        //     console.error(`Failed to open file. Code: ${err.code}, message: ${err.message}.`);
        //     return;
        //   }
        //   console.info(`Succeeded in opening file. path: ${path}, fd: ${fd}.`);
        // });
        break
      case 5:
        //打开网页
        console.warn('打开网页+')
        _KeyMethodConfig.openTheWebpage()
        break
      case 6:
        //快捷按键
        console.warn('快捷按键+')
        break
      case 7:
        //截图翻译
        console.warn('截图翻译+')
        break
      case 8:
        //删除
        console.warn('删除+')
        _KeyMethodConfig.delete()
        break
      case 9:
        //回到桌面
        console.warn('回到桌面+')
        _KeyMethodConfig.desktop()
        break
      case 10:
        //一键锁屏
        console.warn('一键锁屏+')
        _KeyMethodConfig.lockNow()
        break
      case 11:
        //前进
        console.warn('前进+')
        _KeyMethodConfig.forward()
        break
      case 12:
        //后退
        console.warn('后退+')
        _KeyMethodConfig.back()
        break
      case 13:
        //划词翻译
        console.warn('划词翻译+')
        _KeyMethodConfig.word_SelectedTranslation()
        break
      case 14:
        //DPI切换
        console.warn('DPI切换+')
        _KeyMethodConfig.DPI_Switch()
        break
    }
  }
  if (mouse_KeyPressType === 13) {
    switch (KeymethodConfig[1].currIndex) {
      case 0:
        //语音输入
        console.warn('语音输入+长按按下')
        // _KeyMethodConfig.voiceInput()
        _KeyMethodConfig.voiceInput_long()
        break
      case 1:
        //语音翻译
        console.warn('语音翻译+长按按下')
        _KeyMethodConfig.voiceInput_long(1)
        break
      case 2:
        //语音助手
        console.warn('语音助手+')
        break
      case 3:
        //删除
        console.warn('删除+')
        _KeyMethodConfig.delete()
        break
    }
  }
  if (mouse_KeyPressType === 14) {
    switch (KeymethodConfig[1].currIndex) {
      case 0:
        //语音输入
        console.warn('语音输入+长按抬起')
        // _KeyMethodConfig.voiceInput()
        _KeyMethodConfig.endvoiceInput_long()
        break
      case 1:
        //语音翻译
        console.warn('语音翻译+长按抬起')
        _KeyMethodConfig.endvoiceInput_long(1)
        break
      case 2:
        //语音助手
        console.warn('语音助手+')
        break
      case 3:
        //删除
        console.warn('删除+') //**避免按下可抬起都执行一次
        // _KeyMethodConfig.delete()
        break
    }
  }
  if (mouse_KeyPressType === 21) {
    switch (KeymethodConfig[2].currIndex) {
      case 0:
        //回车/发送
        console.warn('回车/发送+')
        _KeyMethodConfig.entry()
        break
      case 1:
        //文件
        console.warn('文件+')
        break
      case 2:
        //文件夹
        console.warn('文件夹+')
        _KeyMethodConfig.explorer()
        break
      case 3:
        //打开网页
        console.warn('打开网页+')
        _KeyMethodConfig.openTheWebpage()
        break
      case 4:
        //快捷按键
        console.warn('快捷按键+')
        break

      case 5:
        //截图翻译
        console.warn('截图翻译+')
        break
      case 6:
        //语音输入
        console.warn('语音输入+')
        _KeyMethodConfig.voiceInput()
        break
      case 7:
        //回到桌面
        console.warn('回到桌面+')
        _KeyMethodConfig.desktop()
        break
      case 8:
        //删除
        console.warn('删除+')
        _KeyMethodConfig.delete()
        break
      case 9:
        //DPI切换
        console.warn('DPI切换+')
        _KeyMethodConfig.DPI_Switch()
        break
      case 10:
        //前进
        console.warn('前进+')
        _KeyMethodConfig.forward()
        break
      case 11:
        //后退
        console.warn('后退+')
        _KeyMethodConfig.back()
        break
      case 12:
        //划词翻译
        console.warn('划词翻译+')
        _KeyMethodConfig.word_SelectedTranslation()
        break
    }
  }
  if (mouse_KeyPressType === 23) {
    switch (KeymethodConfig[3].currIndex) {
      case 0:
        //语音助手
        console.warn('语音助手+')
        break
      case 1:
        //语音翻译
        console.warn('语音翻译+长按按下')
        _KeyMethodConfig.voiceInput_long(1)
        break
      case 2:
        //语音输入
        console.warn('语音输入+长按按下')
        _KeyMethodConfig.voiceInput_long()
        break
      case 3:
        //删除
        console.warn('删除+')
        _KeyMethodConfig.delete()
        break
    }
  }
  if (mouse_KeyPressType === 24) {
    switch (KeymethodConfig[3].currIndex) {
      case 0:
        //语音助手
        console.warn('语音助手+')
        break
      case 1:
        //语音翻译
        console.warn('语音翻译+长按抬起')
        _KeyMethodConfig.endvoiceInput_long(1)
        break
      case 2:
        //语音输入
        console.warn('语音输入+长按抬起')
        // _KeyMethodConfig.voiceInput()
        _KeyMethodConfig.endvoiceInput_long()
        break
      case 3:
        //删除
        console.warn('删除+') //**避免按下可抬起都执行一次
        // _KeyMethodConfig.delete()
        break
    }
  }
  if (mouse_KeyPressType === 31) {
    switch (KeymethodConfig[4].currIndex) {
      case 0:
        //截图翻译
        console.warn('截图翻译+')
        break
      case 1:
        //回车/发送
        console.warn('回车/发送+')
        _KeyMethodConfig.entry()
        break
      case 2:
        //语音输入
        console.warn('语音输入+')
        _KeyMethodConfig.voiceInput()
        break
      case 3:
        //语音翻译
        console.warn('语音翻译+')
        _KeyMethodConfig.voiceInput(1)
        break
      case 4:
        //语音助手
        console.warn('语音助手+')
        break
      case 5:
        //DPI切换
        console.warn('DPI切换+')
        _KeyMethodConfig.DPI_Switch()
        break
      case 6:
        //回到桌面
        console.warn('回到桌面+')
        _KeyMethodConfig.desktop()
        break
      case 7:
        //打开网页
        console.warn('打开网页+')
        _KeyMethodConfig.openTheWebpage()
        break
      case 8:
        //文件夹
        console.warn('文件夹+')
        _KeyMethodConfig.explorer()
        break
      case 9:
        //文件
        console.warn('文件+')
        break
      case 10:
        //固定文案
        console.warn('固定文案+')
        break
      case 11:
        //划词翻译
        console.warn('划词翻译+')
        _KeyMethodConfig.word_SelectedTranslation()
        break
    }

  }
  if (mouse_KeyPressType === 33) {
    switch (KeymethodConfig[5].currIndex) {
      case 0:
        //删除
        console.warn('删除+')
        _KeyMethodConfig.delete()
        break
      case 1:
        //语音翻译
        console.warn('语音翻译+')
        _KeyMethodConfig.voiceInput_long(1)
        break
      case 2:
        //语音助手
        console.warn('语音助手+')
        break
    }
  }
  if (mouse_KeyPressType === 34) {
    switch (KeymethodConfig[5].currIndex) {
      case 0:
        //删除
        console.warn('删除+')
        _KeyMethodConfig.delete()
        break
      case 1:
        //语音翻译
        console.warn('语音翻译+长按抬起')
        _KeyMethodConfig.endvoiceInput_long(1)
        break
      case 2:
        //语音助手
        console.warn('语音助手+')
        break
    }
  }
  if (mouse_KeyPressType === 41) {
  }
  if (mouse_KeyPressType === 43) {
  }
  if (mouse_KeyPressType === 51) {
    switch (KeymethodConfig[6].currIndex) {
      case 0:
        //无功能
        console.warn('无功能+')
        break
      case 1:
        //ChatGPT
        console.warn('ChatGPT+')
        _KeyMethodConfig.openChatGPT()
        break
      case 2:
        //划词翻译
        console.warn('划词翻译+')
        _KeyMethodConfig.word_SelectedTranslation()
        break
    }
  }
  if (mouse_KeyPressType === 53) {
    _KeyMethodConfig.openChatGPT()
  }
  AppStorage.setOrCreate('mouse_KeyPressType', KeyPressType.DEFAULT)
}