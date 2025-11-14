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

  // 处理全局按键事件（优化版本，避免阻塞）
  handleGlobalKeyEvent(event: KeyEvent): boolean {
    try {
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

      // 异步检查快捷键匹配，避免阻塞输入线程
      Promise.resolve().then(() => {
        try {
          this.checkShortcutMatchAsync()
        } catch (error) {
          console.error('异步快捷键检查失败:', error)
        }
      })

      // 立即返回，避免阻塞输入事件
      return false
    } catch (error) {
      console.error('按键事件处理异常:', error)
      return false
    }
  }

  // 异步检查快捷键匹配（避免阻塞输入线程）
  private async checkShortcutMatchAsync(): Promise<void> {
    if (this.currentPressedKeys.length === 0) {
      return
    }

    try {
      // 对当前按下的键进行标准化和排序（确保比较的一致性）
      const currentKeys = [...this.currentPressedKeys].sort()

      // 使用缓存的配置，避免每次读取存储
      const shortcutConfigs = this.getShortcutConfigs()

      // 检查所有已配置的快捷键
      for (const entry of shortcutConfigs.entries()) {
        const shortcutType: number = entry[0]
        const shortcutKeys: number[] = entry[1]
        if (shortcutKeys.length > 0 && this.arraysEqual(shortcutKeys, currentKeys)) {
          // 匹配成功后清空当前按键状态，避免连续触发
          this.currentPressedKeys = []

          // 异步触发快捷键，避免阻塞
          setTimeout(() => {
            try {
              this.triggerShortcut(shortcutType)
            } catch (error) {
              console.error('快捷键触发失败:', error)
            }
          }, 10) // 小延迟确保输入事件处理完成

          return // 找到匹配时退出
        }
      }
    } catch (error) {
      console.error('快捷键匹配检查失败:', error)
    }
  }

  // 保留原同步方法以向后兼容（已废弃，建议使用异步版本）
  private checkShortcutMatch(): boolean {
    console.warn('checkShortcutMatch() 方法已废弃，请使用异步版本')
    return false
  }

  // 触发快捷键（完全异步处理）
  private triggerShortcut(shortcutType: number) {
    console.log(`触发全局快捷键: 类型${shortcutType}`)

    // 使用Promise链式异步执行，避免阻塞UI线程
    Promise.resolve<void>(undefined).then((): Promise<void> | void => {
      try {
        // 优先执行回调函数，确保功能正常
        const callback = this.shortcutCallbacks.get(shortcutType)
        if (callback) {
          return Promise.resolve<void>(undefined).then((): void => {
            callback()
          })
        }
        return Promise.resolve<void>(undefined)
      } catch (error) {
        console.error(`快捷键回调执行失败 (${shortcutType}):`)
        return Promise.resolve<void>(undefined)
      }
    }).then((): Promise<void> => {
      // 延迟显示提示，避免影响主要功能
      return new Promise<void>((resolve: () => void) => {
        setTimeout(() => {
          try {
            this.showShortcutPrompt(shortcutType)
          } catch (error) {
            console.error('显示快捷键提示失败:', error)
          }
          resolve()
        }, 100) // 100ms延迟，确保主要功能完成
      })
    }).catch(() => {
      console.error(`快捷键触发过程异常 (${shortcutType}):`, )
    })
  }

  // 显示快捷键提示弹窗（优化版本）
  private showShortcutPrompt(shortcutType: number) {
    try {
      GlobalShortcutService.flax = true

      // 异步执行快捷键操作，避免阻塞
      setTimeout(() => {
        try {
          switch (shortcutType) {
            case 1:
              _KeyMethodConfig.voiceInput()
              break
            case 2:
              _KeyMethodConfig.voiceInput(1)
              break
            case 3:
              // 截图识别快捷键处理
              break
          }
        } catch (error) {
          console.error(`快捷键操作执行失败 (${shortcutType}):`, error)
        }
      }, 50) // 50ms延迟，确保UI响应完成

    } catch (error) {
      console.error('快捷键提示处理失败:', error)
    }
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