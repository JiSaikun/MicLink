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
  // 缓存快捷键配置，避免每次按键都读取存储
  private cachedShortcutConfigs: Map<number, number[]> | null = null
  private lastConfigUpdateTime: number = 0
  private readonly CONFIG_CACHE_DURATION = 5000 // 5秒缓存

  static getInstance(): GlobalShortcutService {
    if (!GlobalShortcutService.instance) {
      GlobalShortcutService.instance = new GlobalShortcutService()
    }
    return GlobalShortcutService.instance
  }

  // 获取当前快捷键配置（使用缓存优化性能）
  private getShortcutConfigs(): Map<number, number[]> {
    const now = Date.now()

    // 检查缓存是否有效
    if (this.cachedShortcutConfigs && (now - this.lastConfigUpdateTime) < this.CONFIG_CACHE_DURATION) {
      return this.cachedShortcutConfigs
    }

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

    // 更新缓存
    this.cachedShortcutConfigs = configs
    this.lastConfigUpdateTime = now

    return configs
  }

  // 注册快捷键触发回调
  registerCallback(shortcutType: number, callback: () => void) {
    this.shortcutCallbacks.set(shortcutType, callback)
  }

  // 刷新快捷键配置缓存（当配置变更时调用）
  refreshShortcutConfigs() {
    this.cachedShortcutConfigs = null
    this.lastConfigUpdateTime = 0
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

    // 使用缓存的配置，避免每次读取存储
    const shortcutConfigs = this.getShortcutConfigs()

    // 检查所有已配置的快捷键
    for (const entry of shortcutConfigs.entries()) {
      const shortcutType: number = entry[0]
      const shortcutKeys: number[] = entry[1]
      if (shortcutKeys.length > 0 && this.arraysEqual(shortcutKeys, currentKeys)) {
        this.triggerShortcut(shortcutType)
        // 匹配成功后清空当前按键状态，避免连续触发
        this.currentPressedKeys = []
        return true // 找到匹配时立即返回
      }
    }
    return false
  }

  // 触发快捷键
  private triggerShortcut(shortcutType: number) {
    console.log(`触发全局快捷键: 类型${shortcutType}`)

    // 异步执行，避免阻塞UI线程
    setTimeout(() => {
      // 显示弹窗提示（移到异步执行）
      this.showShortcutPrompt(shortcutType)

      // 执行注册的回调函数
      const callback = this.shortcutCallbacks.get(shortcutType)
      if (callback) {
        try {
          callback()
        } catch (error) {
          console.error(`快捷键回调执行失败 (${shortcutType}):`, error)
        }
      }
    }, 0)
  }

  // 显示快捷键提示弹窗
  private showShortcutPrompt(shortcutType: number) {
    // 执行快捷键对应的操作
    switch (shortcutType) {
      case 1:
        try {
          _KeyMethodConfig.voiceInput()
          GlobalShortcutService.flax = true
        } catch (error) {
          console.error('语音识别快捷键执行失败:', error)
        }
        break
      case 2:
        try {
          _KeyMethodConfig.voiceInput(1)
          GlobalShortcutService.flax = true
        } catch (error) {
          console.error('语音翻译快捷键执行失败:', error)
        }
        break
      case 3:
        GlobalShortcutService.flax = true
        break
    }

    // 注释掉耗时的Toast显示，避免阻塞UI
    // try {
    //   prompt.showToast({
    //     message: this.getShortcutMessage(shortcutType),
    //     duration: 2000
    //   })
    // } catch (error) {
    //   console.error('显示提示失败:', error)
    // }
  }

  // 获取快捷键提示消息
  private getShortcutMessage(shortcutType: number): string {
    switch (shortcutType) {
      case 1:
        return '触发语音识别快捷键'
      case 2:
        return '触发语音翻译快捷键'
      case 3:
        return '触发截图识别快捷键'
      default:
        return '触发快捷键'
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