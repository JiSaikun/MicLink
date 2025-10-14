// GlobalShortcutService.ets
import { KeyCode } from '@kit.InputKit'
import { _KeyMethodConfig } from 'keymethodconfig'
import { prompt } from '@kit.ArkUI'

// 定义 shortcutType 接口
interface ShortcutType {
  keyPreview: string
  pressedKeys: number[]
}

class GlobalShortcutService {
  private static instance: GlobalShortcutService
  private static flax: boolean=false
  private currentPressedKeys: number[] = []
  private shortcutCallbacks: Map<number, () => void> = new Map()

  static getInstance(): GlobalShortcutService {
    if (!GlobalShortcutService.instance) {
      GlobalShortcutService.instance = new GlobalShortcutService()
    }
    return GlobalShortcutService.instance
  }

  // 获取当前快捷键配置（每次从持久化存储读取）
  private getShortcutConfigs(): Map<number, number[]> {
    const configs = new Map<number, number[]>()

    try {
      // 语音识别快捷键 - 使用明确的类型
      const voiceRecognition = AppStorage.get<ShortcutType>('voice_recognition_shortcut')
      if (voiceRecognition && voiceRecognition.pressedKeys.length > 0) {
        configs.set(1, voiceRecognition.pressedKeys)
      }

      // 语音翻译快捷键 - 使用明确的类型
      const voiceTranslation = AppStorage.get<ShortcutType>('voice_translation_shortcut')
      if (voiceTranslation && voiceTranslation.pressedKeys.length > 0) {
        configs.set(2, voiceTranslation.pressedKeys)
      }

      // 截图识别快捷键 - 使用明确的类型
      const screenshotRecognition = AppStorage.get<ShortcutType>('screenshot_recognition_shortcut')
      if (screenshotRecognition && screenshotRecognition.pressedKeys.length > 0) {
        configs.set(3, screenshotRecognition.pressedKeys)
      }
    } catch (error) {
      console.error('读取快捷键配置失败:', error)
    }

    return configs
  }

  // 注册快捷键触发回调
  registerCallback(shortcutType: number, callback: () => void) {
    this.shortcutCallbacks.set(shortcutType, callback)
  }

  // 处理全局按键事件
  handleGlobalKeyEvent(event: KeyEvent):boolean {
    if (event.type === KeyType.Down) {
      // 标准化按键并记录
      const normalizedKey = this.normalizeModifierKey(event.keyCode)
      if (!this.currentPressedKeys.includes(normalizedKey)) {
        this.currentPressedKeys.push(normalizedKey)
      }
    } else if (event.type === KeyType.Up) {
      // 移除松开的键
      const normalizedKey = this.normalizeModifierKey(event.keyCode)
      this.currentPressedKeys = this.currentPressedKeys.filter(
        key => key !== normalizedKey
      )
    }

    // 检查是否匹配任何快捷键
   return this.checkShortcutMatch()
  }

  // 检查快捷键匹配
  private checkShortcutMatch() :boolean{
    if (this.currentPressedKeys.length === 0) {
      return false
    }

    // 对当前按下的键进行标准化和排序（确保比较的一致性）
    const currentKeys = [...this.currentPressedKeys].sort()

    // 每次检查时都从持久化存储读取最新配置
    const shortcutConfigs = this.getShortcutConfigs()

    // 检查所有已配置的快捷键
    shortcutConfigs.forEach((shortcutKeys: number[], shortcutType: number) => {
      if (shortcutKeys.length > 0 && this.arraysEqual(shortcutKeys, currentKeys)) {
        this.triggerShortcut(shortcutType)
        // 匹配成功后清空当前按键状态，避免连续触发
        this.currentPressedKeys = []
        return
      }
    })
    return GlobalShortcutService.flax
  }

  // 触发快捷键
  private triggerShortcut(shortcutType: number) {
    console.log(`触发全局快捷键: 类型${shortcutType}`)

    // 显示弹窗提示
    this.showShortcutPrompt(shortcutType)

    // 执行注册的回调函数
    const callback = this.shortcutCallbacks.get(shortcutType)
    if (callback) {
      callback()
    }
  }

  // 显示快捷键提示弹窗
  private showShortcutPrompt(shortcutType: number) {
    let message = ''
    switch (shortcutType) {
      case 1:
        message = '触发语音识别快捷键'
        _KeyMethodConfig.voiceInput()
        GlobalShortcutService.flax=true
        break
      case 2:
        message = '触发语音翻译快捷键'
        _KeyMethodConfig.voiceInput(1)
        GlobalShortcutService.flax=true
        break
      case 3:
        message = '触发截图识别快捷键'
        GlobalShortcutService.flax=true
        break
    }

    try {
      prompt.showToast({
        message: message,
        duration: 2000
      })
    } catch (error) {
      console.error('显示提示失败:', error)
    }
  }

  // 标准化修饰键（与Shortcut_pop中的方法保持一致）
  private normalizeModifierKey(keyCode: number): number {
    switch (keyCode) {
      case KeyCode.KEYCODE_CTRL_LEFT:
      case KeyCode.KEYCODE_CTRL_RIGHT:
        return KeyCode.KEYCODE_CTRL_LEFT
      case KeyCode.KEYCODE_SHIFT_LEFT:
      case KeyCode.KEYCODE_SHIFT_RIGHT:
        return KeyCode.KEYCODE_SHIFT_LEFT
      case KeyCode.KEYCODE_ALT_LEFT:
      case KeyCode.KEYCODE_ALT_RIGHT:
        return KeyCode.KEYCODE_ALT_LEFT
      case KeyCode.KEYCODE_META_LEFT:
      case KeyCode.KEYCODE_META_RIGHT:
        return KeyCode.KEYCODE_META_LEFT
      default:
        return keyCode
    }
  }

  // 比较数组是否相等
  private arraysEqual(arr1: number[], arr2: number[]): boolean {
    if (arr1.length !== arr2.length) {
      return false
    }

    const sorted1 = [...arr1].sort()
    const sorted2 = [...arr2].sort()

    for (let i = 0; i < sorted1.length; i++) {
      if (sorted1[i] !== sorted2[i]) {
        return false
      }
    }
    return true
  }

  // 清空当前按键状态（可选，用于重置）
  clearCurrentKeys() {
    this.currentPressedKeys = []
  }
}

export const globalShortcutService = GlobalShortcutService.getInstance()