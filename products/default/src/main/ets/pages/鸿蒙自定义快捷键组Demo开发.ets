// 快捷键配置类
class ShortcutConfig {
  name: string
  modifierKeys: number[]  // 使用number类型存储keyCode
  mainKey: string
  keyCode: number

  constructor(name: string, modifierKeys: number[], mainKey: string, keyCode: number) {
    this.name = name
    this.modifierKeys = modifierKeys
    this.mainKey = mainKey
    this.keyCode = keyCode
  }
}

// 当前按键状态接口
interface CurrentKeyState {
  modifiers: number[]
  mainKey: string
  keyCode: number
}

@Entry
@Component
struct KeyboardShortcutDemo {
  // 快捷键组列表
  @State shortcutGroups: ShortcutConfig[] = []
  // 操作反馈信息
  @State feedback: string = '请设置您的快捷键'
  // 预览按键信息
  @State keyPreview: string = ''
  // 是否正在捕获快捷键
  @State isCapturing: boolean = false
  // 功能名称输入
  @State functionName: string = ''
  // 当前按下的键
  @State currentKeys: CurrentKeyState = { modifiers: [], mainKey: '', keyCode: 0 }
  // 当前按下的所有键（使用数组而不是Set）
  @State pressedKeys: number[] = []
  // 按键记录状态
  @State keyRecordText: string = ''

  build() {
    Column({ space: 20 }) {
      // 标题
      Text('键盘捕获快捷键设置')
        .fontSize(25)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 })

      // 快捷键配置区域
      this.BuildShortcutConfigArea()

      // 快捷键预览
      this.BuildShortcutPreview()

      // 功能按钮区域
      this.BuildActionButtons()

      // 已保存的快捷键组列表
      this.BuildShortcutList()
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .onKeyEvent((event: KeyEvent) => {
      this.HandleKeyEvent(event)
    })
  }

  // 构建快捷键配置区域
  @Builder
  BuildShortcutConfigArea() {
    Column({ space: 15 }) {
      Text('配置新快捷键')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .align(Alignment.Start)
        .width('100%')

      // 功能名称输入
      TextInput({ placeholder: '输入功能名称，如：保存文件', text: this.functionName })
        .width('100%')
        .onChange((value: string) => {
          this.functionName = value
        })

      // 快捷键捕获区域
      Column({ space: 10 }) {
        Text('设置快捷键组合')
          .fontSize(16)
          .align(Alignment.Start)
          .width('100%')

        // 捕获区域
        Row() {
          if (this.isCapturing) {
            Text('正在捕获按键...请按下快捷键组合')
              .fontSize(14)
              .fontColor('#007DFF')
          } else {
            if (this.currentKeys.mainKey) {
              Text('已设置: ' + this.FormatKeysDisplay(this.currentKeys.modifiers, this.currentKeys.mainKey))
                .fontSize(16)
                .fontColor('#007DFF')
            } else {
              Text('点击"开始捕获"按钮后按下快捷键')
                .fontSize(14)
                .fontColor('#666666')
            }
          }
        }
        .width('100%')
        .height(60)
        .justifyContent(FlexAlign.Center)
        .borderRadius(8)
        .backgroundColor(this.isCapturing ? '#E6F0FF' : '#F5F5F5')
        .border({ width: 2, color: this.isCapturing ? '#007DFF' : '#E0E0E0' })

        // 捕获按钮
        Button(this.isCapturing ? '停止捕获' : '开始捕获快捷键')
          .width('100%')
          .backgroundColor(this.isCapturing ? '#FF6B6B' : '#007DFF')
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.ToggleCapture()
          })
          .margin({ top: 10 })

        // 按键记录显示
        Text(this.keyRecordText ? `按键记录: ${this.keyRecordText}` : '')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 5 })
      }
      .width('100%')
      .padding(10)
      .borderRadius(8)
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .padding(15)
    .borderRadius(12)
    .backgroundColor('#FFFFFF')
    .shadow({ radius: 4, color: '#20000000', offsetX: 1, offsetY: 1 })
  }

  // 构建快捷键预览
  @Builder
  BuildShortcutPreview() {
    Column({ space: 10 }) {
      Text('快捷键预览')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .align(Alignment.Start)
        .width('100%')

      Text(this.FormatKeysDisplay(this.currentKeys.modifiers, this.currentKeys.mainKey) || '未设置')
        .fontSize(24)
        .fontColor('#007DFF')
        .margin({ top: 5, bottom: 5 })

      Text(this.feedback)
        .fontSize(14)
        .fontColor('#666666')

      Text(this.keyPreview ? `实时按键: ${this.keyPreview}` : '按下键盘测试已保存的快捷键')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 5 })

      Text(`当前按下键数: ${this.pressedKeys.length}`)
        .fontSize(10)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding(15)
    .borderRadius(12)
    .backgroundColor('#F8F9FA')
  }

  // 构建操作按钮
  @Builder
  BuildActionButtons() {
    Row({ space: 15 }) {
      Button('保存快捷键')
        .backgroundColor('#007DFF')
        .fontColor('#FFFFFF')
        .onClick(() => {
          this.SaveShortcut()
        })
        .flexGrow(1)

      Button('清空当前')
        .backgroundColor('#FFE6E6')
        .fontColor('#FF0000')
        .onClick(() => {
          this.ClearCurrent()
        })
        .flexGrow(1)

      Button('清空所有')
        .backgroundColor('#FFA0A0')
        .fontColor('#FFFFFF')
        .onClick(() => {
          this.ClearAll()
        })
        .flexGrow(1)
    }
    .width('100%')
    .height(50)
  }

  // 构建快捷键列表
  @Builder
  BuildShortcutList() {
    Column({ space: 10 }) {
      Text('已保存的快捷键组')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .align(Alignment.Start)
        .width('100%')
        .margin({ bottom: 10 })

      if (this.shortcutGroups.length > 0) {
        ForEach(this.shortcutGroups, (group: ShortcutConfig, index?: number) => {
          this.BuildShortcutItem(group, index!)
        })
      } else {
        Text('暂无保存的快捷键')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 20 })
      }
    }
    .width('100%')
    .margin({ top: 20 })
  }

  // 构建单个快捷键项
  @Builder
  BuildShortcutItem(group: ShortcutConfig, index: number) {
    Row() {
      Column({ space: 5 }) {
        Text(group.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .align(Alignment.Start)

        Text(this.FormatKeysDisplay(group.modifierKeys, group.mainKey))
          .fontSize(14)
          .fontColor('#007DFF')
      }
      .align(Alignment.Start)
      .flexGrow(1)

      Button('删除')
        .fontSize(12)
        .backgroundColor('#FFE6E6')
        .fontColor('#FF0000')
        .onClick(() => {
          this.RemoveShortcut(index)
        })
    }
    .width('100%')
    .padding(15)
    .borderRadius(8)
    .backgroundColor('#FFFFFF')
    .margin({ bottom: 10 })
    .shadow({ radius: 2, color: '#10000000', offsetX: 1, offsetY: 1 })
  }

  // 切换捕获状态
  private ToggleCapture() {
    if (this.isCapturing) {
      this.isCapturing = false
      this.feedback = '已停止捕获'
      this.pressedKeys = []
      this.keyRecordText = ''
    } else {
      this.isCapturing = true
      this.currentKeys = { modifiers: [], mainKey: '', keyCode: 0 }
      this.pressedKeys = []
      this.keyRecordText = '开始记录按键...'
      this.feedback = '请按下您想要的快捷键组合（例如：Ctrl+S）'
    }
  }

  // 保存快捷键
  private SaveShortcut() {
    if (!this.functionName.trim()) {
      this.feedback = '请输入功能名称'
      return
    }

    if (this.currentKeys.modifiers.length === 0 || !this.currentKeys.mainKey) {
      this.feedback = '请先设置完整的快捷键组合（修饰键+主键）'
      return
    }

    // 检查是否重复
    const isDuplicate = this.shortcutGroups.some(group =>
    group.keyCode === this.currentKeys.keyCode &&
    this.ArraysEqual(group.modifierKeys, this.currentKeys.modifiers)
    )

    if (isDuplicate) {
      this.feedback = '该快捷键已存在，请使用不同的组合'
      return
    }

    // 保存新快捷键
    this.shortcutGroups.push(new ShortcutConfig(
      this.functionName,
      [...this.currentKeys.modifiers],
      this.currentKeys.mainKey,
      this.currentKeys.keyCode
    ))

    this.feedback = `快捷键 "${this.functionName}" 已保存`
    this.ResetCurrentConfig()
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

  // 清空当前配置
  private ClearCurrent() {
    this.ResetCurrentConfig()
    this.feedback = '当前配置已清空'
  }

  // 清空所有快捷键
  private ClearAll() {
    this.shortcutGroups = []
    this.ResetCurrentConfig()
    this.feedback = '所有快捷键已清空'
  }

  // 删除单个快捷键
  private RemoveShortcut(index: number) {
    const newGroups = [...this.shortcutGroups]
    newGroups.splice(index, 1)
    this.shortcutGroups = newGroups
    this.feedback = '快捷键已删除'
  }

  // 重置当前配置
  private ResetCurrentConfig() {
    this.functionName = ''
    this.currentKeys = { modifiers: [], mainKey: '', keyCode: 0 }
    this.isCapturing = false
    this.pressedKeys = []
    this.keyRecordText = ''
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

  // 处理键盘事件
  private HandleKeyEvent(event: KeyEvent) {
    const keyName = this.GetKeyName(event.keyCode)
    const isModifier = this.IsModifierKey(event.keyCode)

    // 更新按键记录
    this.keyRecordText = `按键事件: ${event.type === KeyType.Down ? '按下' : '释放'} ${keyName} (${event.keyCode})`

    if (event.type === KeyType.Down) {
      // 记录按下的键（避免重复添加）
      if (!this.pressedKeys.includes(event.keyCode)) {
        this.pressedKeys.push(event.keyCode)
      }

      // 更新实时按键预览
      this.UpdateKeyPreview()

      if (this.isCapturing) {
        if (!isModifier) {
          // 按下非修饰键，完成捕获
          const modifiers = this.pressedKeys.filter(keyCode =>
          this.IsModifierKey(keyCode) && keyCode !== event.keyCode
          )

          this.currentKeys = {
            modifiers: modifiers,
            mainKey: keyName,
            keyCode: event.keyCode
          }
          this.isCapturing = false
          this.feedback = `快捷键已设置为: ${this.FormatKeysDisplay(modifiers, keyName)}`
          this.keyRecordText = `捕获完成: ${this.FormatKeysDisplay(modifiers, keyName)}`
        } else {
          this.keyRecordText = `按下修饰键: ${keyName}，请继续按下主键`
        }
      } else {
        // 检查是否匹配任何已保存的快捷键
        this.CheckShortcutMatch(event.keyCode)
      }
    } else if (event.type === KeyType.Up) {
      // 移除释放的键
      const index = this.pressedKeys.indexOf(event.keyCode)
      if (index >= 0) {
        this.pressedKeys.splice(index, 1)
      }
      this.UpdateKeyPreview()
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
    return keyCode === 1001 || keyCode === 1002 || keyCode === 1003 // Ctrl, Shift, Alt
  }

  // 根据keyCode获取键名
  private GetKeyName(keyCode: number): string {
    // 功能键
    if (keyCode >= 2000 && keyCode <= 2012) {
      return `F${keyCode - 1999}`
    }
    // 字母键
    else if (keyCode >= 65 && keyCode <= 90) {
      return String.fromCharCode(keyCode)
    }
    // 数字键
    else if (keyCode >= 48 && keyCode <= 57) {
      return String.fromCharCode(keyCode)
    }
    // 特殊键
    else {
      switch (keyCode) {
        case 1001: return 'Ctrl'
        case 1002: return 'Shift'
        case 1003: return 'Alt'
        case 1004: return 'Enter'
        case 1005: return 'Space'
        case 1006: return 'Tab'
        case 1007: return 'Backspace'
        case 1008: return 'Escape'
        default: return `Key${keyCode}`
      }
    }
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
          this.feedback = `快捷键触发: ${group.name}`
          return
        }
      }
    }
  }
}