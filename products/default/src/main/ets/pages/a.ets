import { KeyCode } from '@kit.InputKit'

// 快捷键配置类
class ShortcutConfig {
  modifierKeys: number[]  // 使用number类型存储keyCode
  mainKey: string
  keyCode: number
  displayText: string  // 用于显示的按键组合文本

  constructor(modifierKeys: number[], mainKey: string, keyCode: number, displayText: string) {
    this.modifierKeys = modifierKeys
    this.mainKey = mainKey
    this.keyCode = keyCode
    this.displayText = displayText
  }
}

// 当前按键状态接口
interface CurrentKeyState {
  modifiers: number[]
  mainKey: string
  keyCode: number
  displayText: string
}

@Entry
@Component
struct KeyboardShortcutDemo {
  // 快捷键组列表
  @State shortcutGroups: ShortcutConfig[] = []
  // 预览按键信息
  @State keyPreview: string = ''

  // 当前按下的键
  @State currentKeys: CurrentKeyState = { modifiers: [], mainKey: '', keyCode: 0, displayText: '' }
  // 当前按下的所有键（只记录按下，不处理松开）
  @State pressedKeys: number[] = []

  build() {
    Column({ space: 20 }) {
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .onKeyEvent((event: KeyEvent) => {
      this.HandleKeyEvent(event)
      console.error(this.keyPreview,this.shortcutGroups.length)
      console.error(JSON.stringify(this.pressedKeys),this.shortcutGroups.length)
    })
  }

  // 保存快捷键
  private SaveShortcut() {
    if (this.currentKeys.modifiers.length === 0 && !this.currentKeys.mainKey) {
      // this.feedback = '请先按下一些按键再保存'
      return
    }

    // 检查是否重复
    const isDuplicate = this.shortcutGroups.some(group =>
    group.keyCode === this.currentKeys.keyCode &&
    this.ArraysEqual(group.modifierKeys, this.currentKeys.modifiers)
    )

    // if (isDuplicate) {
    //   this.feedback = '该按键组合已存在'
    //   return
    // }

    // 保存新快捷键
    this.shortcutGroups.push(new ShortcutConfig(
      [...this.currentKeys.modifiers],
      this.currentKeys.mainKey,
      this.currentKeys.keyCode,
      this.currentKeys.displayText
    ))

    // this.feedback = `按键组合已保存: ${this.currentKeys.displayText}`
  }

  // 比较两个数组是否相等
  private ArraysEqual(arr1: number[], arr2: number[]): boolean {
    if (arr1.length !== arr2.length) return false
    const sorted1 = [...arr1].sort()
    const sorted2 = [...arr2].sort()
    for (let i = 0; i < sorted1.length; i++) {
      if (sorted1[i] !== sorted2[i]) return false
    }
    return true
  }


  // 处理键盘事件 - 只处理按下事件
  private HandleKeyEvent(event: KeyEvent) {
    // 只处理按键按下事件，忽略松开事件
    if (event.type !== KeyType.Down) {
      return
    }

    const keyName = this.GetKeyName(event.keyCode)
    const isModifier = this.IsModifierKey(event.keyCode)


    // 记录按下的键（避免重复添加）
    if (!this.pressedKeys.includes(event.keyCode)) {
      this.pressedKeys.push(event.keyCode)
    }

    // 更新实时按键预览
    this.UpdateKeyPreview()

    // 更新当前按键组合
    const modifiers = this.pressedKeys.filter(keyCode => this.IsModifierKey(keyCode))
    const mainKey = isModifier ? '' : keyName
    const mainKeyCode = isModifier ? 0 : event.keyCode

    this.currentKeys = {
      modifiers: modifiers,
      mainKey: mainKey,
      keyCode: mainKeyCode,
      displayText: this.FormatKeysDisplay(modifiers, mainKey)
    }

    // this.feedback = `检测到按键: ${keyName}`

    // 检查是否匹配任何已保存的快捷键
    if (!isModifier) {
      this.CheckShortcutMatch(event.keyCode)
    }
  }

  // 更新按键预览
  private UpdateKeyPreview() {
    const modifiers = this.pressedKeys
      .filter(keyCode => this.IsModifierKey(keyCode))
      .map(keyCode => this.GetKeyName(keyCode))

    const mainKeys = this.pressedKeys
      .filter(keyCode => !this.IsModifierKey(keyCode))
      .map(keyCode => this.GetKeyName(keyCode))

    this.keyPreview = modifiers.join(' + ') +
      (modifiers.length > 0 && mainKeys.length > 0 ? ' + ' : '') +
    mainKeys.join(' + ')
  }

  // 检查是否为修饰键
  private IsModifierKey(keyCode: number): boolean {
    return keyCode === KeyCode.KEYCODE_CTRL_LEFT ||
      keyCode === KeyCode.KEYCODE_CTRL_RIGHT ||
      keyCode === KeyCode.KEYCODE_SHIFT_LEFT ||
      keyCode === KeyCode.KEYCODE_SHIFT_RIGHT ||
      keyCode === KeyCode.KEYCODE_ALT_LEFT ||
      keyCode === KeyCode.KEYCODE_ALT_RIGHT
  }

  // 根据keyCode获取键名 - 使用标准KeyCode枚举
  private GetKeyName(keyCode: number): string {
    switch (keyCode) {
      // 字母键
      case KeyCode.KEYCODE_A: return 'A'
      case KeyCode.KEYCODE_B: return 'B'
      case KeyCode.KEYCODE_C: return 'C'
      case KeyCode.KEYCODE_D: return 'D'
      case KeyCode.KEYCODE_E: return 'E'
      case KeyCode.KEYCODE_F: return 'F'
      case KeyCode.KEYCODE_G: return 'G'
      case KeyCode.KEYCODE_H: return 'H'
      case KeyCode.KEYCODE_I: return 'I'
      case KeyCode.KEYCODE_J: return 'J'
      case KeyCode.KEYCODE_K: return 'K'
      case KeyCode.KEYCODE_L: return 'L'
      case KeyCode.KEYCODE_M: return 'M'
      case KeyCode.KEYCODE_N: return 'N'
      case KeyCode.KEYCODE_O: return 'O'
      case KeyCode.KEYCODE_P: return 'P'
      case KeyCode.KEYCODE_Q: return 'Q'
      case KeyCode.KEYCODE_R: return 'R'
      case KeyCode.KEYCODE_S: return 'S'
      case KeyCode.KEYCODE_T: return 'T'
      case KeyCode.KEYCODE_U: return 'U'
      case KeyCode.KEYCODE_V: return 'V'
      case KeyCode.KEYCODE_W: return 'W'
      case KeyCode.KEYCODE_X: return 'X'
      case KeyCode.KEYCODE_Y: return 'Y'
      case KeyCode.KEYCODE_Z: return 'Z'

    // 数字键
      case KeyCode.KEYCODE_0: return '0'
      case KeyCode.KEYCODE_1: return '1'
      case KeyCode.KEYCODE_2: return '2'
      case KeyCode.KEYCODE_3: return '3'
      case KeyCode.KEYCODE_4: return '4'
      case KeyCode.KEYCODE_5: return '5'
      case KeyCode.KEYCODE_6: return '6'
      case KeyCode.KEYCODE_7: return '7'
      case KeyCode.KEYCODE_8: return '8'
      case KeyCode.KEYCODE_9: return '9'

    // 功能键
      case KeyCode.KEYCODE_F1: return 'F1'
      case KeyCode.KEYCODE_F2: return 'F2'
      case KeyCode.KEYCODE_F3: return 'F3'
      case KeyCode.KEYCODE_F4: return 'F4'
      case KeyCode.KEYCODE_F5: return 'F5'
      case KeyCode.KEYCODE_F6: return 'F6'
      case KeyCode.KEYCODE_F7: return 'F7'
      case KeyCode.KEYCODE_F8: return 'F8'
      case KeyCode.KEYCODE_F9: return 'F9'
      case KeyCode.KEYCODE_F10: return 'F10'
      case KeyCode.KEYCODE_F11: return 'F11'
      case KeyCode.KEYCODE_F12: return 'F12'

    // 修饰键
      case KeyCode.KEYCODE_CTRL_LEFT:
      case KeyCode.KEYCODE_CTRL_RIGHT: return 'Ctrl'
      case KeyCode.KEYCODE_SHIFT_LEFT:
      case KeyCode.KEYCODE_SHIFT_RIGHT: return 'Shift'
      case KeyCode.KEYCODE_ALT_LEFT:
      case KeyCode.KEYCODE_ALT_RIGHT: return 'Alt'

    // 特殊键
      case KeyCode.KEYCODE_ENTER: return 'Enter'
      case KeyCode.KEYCODE_SPACE: return 'Space'
      case KeyCode.KEYCODE_TAB: return 'Tab'
      case KeyCode.KEYCODE_BACK: return 'Backspace'
      case KeyCode.KEYCODE_CAPS_LOCK: return 'Caps'
      case KeyCode.KEYCODE_META_LEFT: return 'Meta'
      case KeyCode.KEYCODE_ESCAPE: return 'Escape'
      case KeyCode.KEYCODE_DEL: return 'Delete'
      case KeyCode.KEYCODE_MOVE_HOME: return 'Home'
      case KeyCode.KEYCODE_MOVE_END: return 'End'
      case KeyCode.KEYCODE_PAGE_UP: return 'PageUp'
      case KeyCode.KEYCODE_PAGE_DOWN: return 'PageDown'
      case KeyCode.KEYCODE_DPAD_UP: return '↑'
      case KeyCode.KEYCODE_DPAD_DOWN: return '↓'
      case KeyCode.KEYCODE_DPAD_LEFT: return '←'
      case KeyCode.KEYCODE_DPAD_RIGHT: return '→'
      case KeyCode.KEYCODE_DPAD_CENTER: return 'Center'

    // 符号键
      case KeyCode.KEYCODE_COMMA: return ','
      case KeyCode.KEYCODE_PERIOD: return '.'
      case KeyCode.KEYCODE_SLASH: return '/'
      case KeyCode.KEYCODE_BACKSLASH: return '\\'
      case KeyCode.KEYCODE_SEMICOLON: return ';'
      case KeyCode.KEYCODE_APOSTROPHE: return "'"
      case KeyCode.KEYCODE_LEFT_BRACKET: return '['
      case KeyCode.KEYCODE_RIGHT_BRACKET: return ']'
      case KeyCode.KEYCODE_MINUS: return '-'
      case KeyCode.KEYCODE_EQUALS: return '='
      case KeyCode.KEYCODE_GRAVE: return '`'
      case KeyCode.KEYCODE_AT: return '@'
      case KeyCode.KEYCODE_PLUS: return '+'
      case KeyCode.KEYCODE_STAR: return '*'
      case KeyCode.KEYCODE_POUND: return '#'

      default: return `Key${keyCode}`
    }
  }

  // 格式化按键显示
  private FormatKeysDisplay(modifiers: number[], mainKey: string): string {
    if (modifiers.length === 0 && !mainKey) {
      return ''
    }

    const modifierNames = modifiers.map(keyCode => {
      return this.GetKeyName(keyCode)
    }).filter(name => name === 'Ctrl' || name === 'Shift' || name === 'Alt').join(' + ')

    return modifierNames + (modifierNames && mainKey ? ' + ' : '') + mainKey
  }

  // 检查快捷键匹配
  private CheckShortcutMatch(pressedKeyCode: number) {
    if (!this.IsModifierKey(pressedKeyCode)) { // 只有非修饰键才触发匹配
      for (const group of this.shortcutGroups) {
        const currentModifiers = this.pressedKeys.filter(keyCode =>
        this.IsModifierKey(keyCode) && keyCode !== pressedKeyCode
        )

        const modifiersMatch = this.ArraysEqual(group.modifierKeys, currentModifiers)
        const mainKeyMatch = group.keyCode === pressedKeyCode

        if (modifiersMatch && mainKeyMatch) {
          // this.feedback = `触发已保存组合: ${group.displayText}`
          return
        }
      }
    }
  }
}