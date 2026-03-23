import { KeyCode } from '@kit.InputKit'
import { LengthMetrics } from '@kit.ArkUI'
import { Languages } from 'config'
import { ThemeConfig } from 'common'
import { globalShortcutService } from 'utils'

@Builder
export function Shortcut_popBuilder() {
  Shortcut_pop()
}

// 快捷键配置类
class ShortcutConfig {
  modifierKeys: number[] // 使用number类型存储keyCode
  mainKey: string
  keyCode: number
  displayText: string // 用于显示的按键组合文本

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

interface shortcutType {
  keyPreview: string
  pressedKeys: number[]
}

@Component
struct Shortcut_pop {
  @StorageLink("paletteTheme") paletteTheme: string = ThemeConfig.PaletteTheme
  @StorageLink('languages') languages: string = 'ZH_CN'
  // 快捷键组列表
  @State shortcutGroups: ShortcutConfig[] = []
  // 预览按键信息
  @State keyPreview: string = ''
  @State keyPreview_old: string = ''
  // 当前按下的键
  @State currentKeys: CurrentKeyState = {
    modifiers: [],
    mainKey: '',
    keyCode: 0,
    displayText: ''
  }
  // 当前按下的所有键（只记录按下，不处理松开）
  @State pressedKeys: number[] = []
  @State feedback: string = '' // 添加反馈信息
  @Consume('pageInfo') pageInfo: NavPathStack
  @StorageLink("shortcut") shortcut: number = 0 //标记快捷键功能
  @StorageLink("voice_recognition_shortcut") voice_recognition_shortcut: shortcutType = {
    keyPreview: Languages.none[this.languages], //无
    pressedKeys: []
  } //语音识别快捷键
  @StorageLink("voice_translation_shortcut") voice_translation_shortcut: shortcutType = {
    keyPreview: Languages.none[this.languages], //无
    pressedKeys: []
  } //语音翻译快捷键
  @StorageLink("screenshot_recognition_shortcut") screenshot_recognition_shortcut: shortcutType = {
    keyPreview: Languages.none[this.languages], //无
    pressedKeys: []
  } //截图识别快捷键
  @StorageLink("custom_shortcut") custom_shortcut: shortcutType = {
    keyPreview: Languages.none[this.languages], //无
    pressedKeys: []
  } //自定义快捷键

  aboutToAppear(): void {
    switch (this.shortcut) {
      case 1:
        //语音识别
        this.keyPreview_old =
          this.voice_recognition_shortcut.keyPreview ? this.voice_recognition_shortcut.keyPreview :
          Languages.none[this.languages] //无
        break
      case 2:
        //语音翻译
        this.keyPreview_old =
          this.voice_translation_shortcut.keyPreview ? this.voice_translation_shortcut.keyPreview :
          Languages.none[this.languages] //无
        break
      case 3:
        //截图识别
        this.keyPreview_old =
          this.screenshot_recognition_shortcut.keyPreview ? this.screenshot_recognition_shortcut.keyPreview :
          Languages.none[this.languages] //无
        break
      case 4:
        //自定义快捷键
        this.keyPreview_old =
          this.custom_shortcut.keyPreview ? this.custom_shortcut.keyPreview : Languages.none[this.languages] //无
        break
      default:
        this.keyPreview_old = Languages.none[this.languages] //无
    }
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          Row() {
            // Text('按键盘设置快捷键')
            Text(Languages.set_shortcut_by_keyboard[this.languages])
              .fontSize(16)
              .fontWeight(400)
              .fontColor(Color.White)
          }
          .justifyContent(FlexAlign.Center)
          .width('100%')
          .borderRadius({ topLeft: 8, topRight: 8 })
          .padding(10)
          .backgroundColor(this.paletteTheme)

          Text(this.keyPreview ? this.keyPreview : this.keyPreview_old)
            .margin({ top: 50, bottom: 50 })
            .padding(20)
            .fontSize(20)
            .fontWeight(600)
            .fontColor('#31373d')

          // 添加反馈信息显示
          if (this.feedback) {
            Text(this.feedback)
              .fontSize(14)
              .fontColor('#ff0000')
              .margin({ bottom: 10 })
          }

          Flex({ space: { main: LengthMetrics.px(30) }, justifyContent: FlexAlign.Center }) {
            // Text('确定')
            Text(Languages.confirm_btn[this.languages])
              .fontSize(16)
              .fontWeight(400)
              .fontColor(Color.White)
              .padding({
                top: 15,
                bottom: 15,
                left: 35,
                right: 35
              })
              .backgroundColor(this.paletteTheme)
              .borderRadius(5)
              // 在Shortcut_pop的确定按钮点击事件中简化：
              .onClick(() => {
                if (this.keyPreview) {
                  // 检查快捷键是否重复（对于shortcut=1,2,3）
                  if (this.shortcut >= 1 && this.shortcut <= 3) {
                    if (this.isShortcutDuplicate(this.getNormalizedPressedKeys())) {
                      // this.feedback = '该快捷键已被其他功能使用，请重新设置'
                      this.feedback = Languages.shortcut_duplicate_error[this.languages]
                      return
                    }
                  }

                  // 获取标准化后的按键
                  const normalizedKeys = this.getNormalizedPressedKeys()

                  switch (this.shortcut) {
                    case 1:
                      // 语音识别 - 只更新持久化存储
                      this.voice_recognition_shortcut = {
                        pressedKeys: normalizedKeys,
                        keyPreview: this.keyPreview
                      }
                      break
                    case 2:
                      // 语音翻译
                      this.voice_translation_shortcut = {
                        pressedKeys: normalizedKeys,
                        keyPreview: this.keyPreview
                      }
                      break
                    case 3:
                      // 截图识别
                      this.screenshot_recognition_shortcut = {
                        pressedKeys: normalizedKeys,
                        keyPreview: this.keyPreview
                      }
                      break
                    case 4:
                      // 自定义快捷键 - 转换为HID键值数组
                      const hidArray = this.convertToHIDArray(normalizedKeys)
                      this.custom_shortcut = {
                        pressedKeys: hidArray,
                        keyPreview: this.keyPreview
                      }
                      break
                  }
                  // 刷新快捷键配置缓存
                  globalShortcutService.refreshShortcutConfigs()
                  this.feedback = ''
                }
                this.shortcut = 1000
                this.pageInfo.pop()
              })
            // Text('取消')
            Text(Languages.cancel[this.languages])
              .fontSize(16)
              .fontWeight(400)
              .fontColor(Color.White)
              .padding({
                top: 15,
                bottom: 15,
                left: 35,
                right: 35
              })
              .backgroundColor(this.paletteTheme)
              .borderRadius(5)
              .onClick(() => {
                this.shortcut = 1000;
                this.pageInfo.pop()
              })
              .margin({ left: 20 })
          }
          .width('100%')

        }
        .shadow({ radius: 10, color: '#e9e9eb' })
        .width(340)
        .borderRadius(8)
        .backgroundColor(Color.White)
        .zIndex(10)
        .padding({ bottom: 20 })

        Column() {

        }
        .width('100%')
        .height('100%')
        .backgroundColor('#000')
        .opacity(0.2)
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .hideToolBar(true)
    .onKeyEvent((event: KeyEvent) => {
      this.HandleKeyEvent(event)
      console.error(this.keyPreview)
    })
  }

  // 获取标准化的按键数组（将左右修饰键统一）
  private getNormalizedPressedKeys(): number[] {
    return this.pressedKeys.map(keyCode => this.normalizeModifierKey(keyCode))
  }

  // 将左右修饰键统一为标准值
  private normalizeModifierKey(keyCode: number): number {
    switch (keyCode) {
      case KeyCode.KEYCODE_CTRL_LEFT:
      case KeyCode.KEYCODE_CTRL_RIGHT:
        return KeyCode.KEYCODE_CTRL_LEFT // 统一使用左Ctrl作为代表
      case KeyCode.KEYCODE_SHIFT_LEFT:
      case KeyCode.KEYCODE_SHIFT_RIGHT:
        return KeyCode.KEYCODE_SHIFT_LEFT // 统一使用左Shift作为代表
      case KeyCode.KEYCODE_ALT_LEFT:
      case KeyCode.KEYCODE_ALT_RIGHT:
        return KeyCode.KEYCODE_ALT_LEFT // 统一使用左Alt作为代表
      case KeyCode.KEYCODE_META_LEFT:
      case KeyCode.KEYCODE_META_RIGHT:
        return KeyCode.KEYCODE_META_LEFT // 统一使用左Meta作为代表
      default:
        return keyCode
    }
  }

  // 检查快捷键是否重复（针对shortcut=1,2,3）
  private isShortcutDuplicate(pressedKeys: number[]): boolean {
    const otherShortcuts: number[][] = []

    // 收集其他功能的快捷键（也进行标准化处理）
    if (this.shortcut !== 1) {
      otherShortcuts.push(this.voice_recognition_shortcut.pressedKeys.map(keyCode => this.normalizeModifierKey(keyCode)))
    }
    if (this.shortcut !== 2) {
      otherShortcuts.push(this.voice_translation_shortcut.pressedKeys.map(keyCode => this.normalizeModifierKey(keyCode)))
    }
    if (this.shortcut !== 3) {
      otherShortcuts.push(this.screenshot_recognition_shortcut.pressedKeys.map(keyCode => this.normalizeModifierKey(keyCode)))
    }

    // 检查是否有重复
    for (const shortcutKeys of otherShortcuts) {
      if (shortcutKeys.length > 0 && this.ArraysEqual(shortcutKeys, pressedKeys)) {
        return true
      }
    }

    return false
  }

  // 保存快捷键
  private SaveShortcut() {
    if (this.currentKeys.modifiers.length === 0 && !this.currentKeys.mainKey) {
      // this.feedback = '请先按下一些按键再保存'
      this.feedback = Languages.press_keys_before_save[this.languages]
      return
    }

    // 检查是否重复（使用标准化后的按键）
    const normalizedModifiers = this.currentKeys.modifiers.map(keyCode => this.normalizeModifierKey(keyCode))
    const normalizedKeyCode = this.normalizeModifierKey(this.currentKeys.keyCode)

    const isDuplicate = this.shortcutGroups.some(group =>
    group.keyCode === normalizedKeyCode &&
    this.ArraysEqual(group.modifierKeys.map(keyCode => this.normalizeModifierKey(keyCode)), normalizedModifiers)
    )

    if (isDuplicate) {
      // this.feedback = '该按键组合已存在'
      this.feedback = Languages.shortcut_combination_exists[this.languages]
      return
    }

    // 保存新快捷键（使用标准化后的按键）
    this.shortcutGroups.push(new ShortcutConfig(
      normalizedModifiers,
      this.currentKeys.mainKey,
      normalizedKeyCode,
      this.currentKeys.displayText
    ))

    // this.feedback = `按键组合已保存: ${this.currentKeys.displayText}`
    this.feedback = `${Languages.shortcut_saved_prefix[this.languages]}${this.currentKeys.displayText}`
  }

  // 比较两个数组是否相等
  private ArraysEqual(arr1: number[], arr2: number[]): boolean {
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

  // 处理键盘事件 - 只处理按下事件
  private HandleKeyEvent(event: KeyEvent) {
    // 只处理按键按下事件，忽略松开事件
    if (event.type !== KeyType.Down) {
      return
    }

    const keyName = this.GetKeyName(event.keyCode)
    const isModifier = this.IsModifierKey(event.keyCode)

    // 如果是修饰键，且pressedKeys中已有同类键，则跳过
    if (isModifier) {
      const modifierType = this.getModifierType(event.keyCode);
      const hasSameType = this.pressedKeys.some(key => this.getModifierType(key) === modifierType);
      if (hasSameType) {
        return; // 同类修饰键已存在，不处理当前事件
      }
    }

    // 对于自定义快捷键（shortcut=4），限制只能有一个主键和一个辅助键
    if (this.shortcut === 4) {
      this.handleCustomShortcutKey(event, keyName, isModifier)
    } else {
      // 其他快捷键类型的原有逻辑
      this.handleNormalShortcutKey(event, keyName, isModifier)
    }

    // 更新实时按键预览
    this.UpdateKeyPreview()
    this.feedback = '' // 清除之前的反馈信息
  }

  // 获取修饰键的类别（用于区分Alt/Ctrl/Shift/Meta四类）
  private getModifierType(keyCode: number): 'alt' | 'ctrl' | 'shift' | 'meta' | null {
    switch (keyCode) {
      case KeyCode.KEYCODE_ALT_LEFT:
      case KeyCode.KEYCODE_ALT_RIGHT:
        return 'alt';
      case KeyCode.KEYCODE_CTRL_LEFT:
      case KeyCode.KEYCODE_CTRL_RIGHT:
        return 'ctrl';
      case KeyCode.KEYCODE_SHIFT_LEFT:
      case KeyCode.KEYCODE_SHIFT_RIGHT:
        return 'shift';
      case KeyCode.KEYCODE_META_LEFT:
      case KeyCode.KEYCODE_META_RIGHT:
        return 'meta';
      default:
        return null;
    }
  }

  // 处理自定义快捷键按键（限制一个主键一个辅助键）
  private handleCustomShortcutKey(event: KeyEvent, keyName: string, isModifier: boolean) {
    if (isModifier) {
      // 移除所有现有的辅助键（确保只能有一个辅助键）
      this.pressedKeys = this.pressedKeys.filter(keyCode => !this.IsModifierKey(keyCode))
      // 添加新的辅助键
      this.pressedKeys.push(event.keyCode);
    } else {
      // 如果按下的是主键
      // 移除所有非修饰键（主键），但保留现有的辅助键
      this.pressedKeys = this.pressedKeys.filter(keyCode => this.IsModifierKey(keyCode))
      // 添加新的主键
      this.pressedKeys.push(event.keyCode)
    }

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
  }

  // 处理普通快捷键按键（原有逻辑）
  private handleNormalShortcutKey(event: KeyEvent, keyName: string, isModifier: boolean) {
    // 如果是修饰键，先移除pressedKeys中同一类的修饰键（去重）
    if (isModifier) {
      const modifierType = this.getModifierType(event.keyCode);
      if (modifierType) {
        // 过滤掉当前类别下的所有修饰键（左右键都移除）
        this.pressedKeys = this.pressedKeys.filter(key => {
          return this.getModifierType(key) !== modifierType;
        });
      }
    }

    // 记录按下的键（避免重复添加）
    if (!this.pressedKeys.includes(event.keyCode)) {
      this.pressedKeys.push(event.keyCode)
    }

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

    // 检查是否匹配任何已保存的快捷键（使用标准化后的按键进行比较）
    if (!isModifier) {
      this.CheckShortcutMatch(event.keyCode)
    }
  }

  // 转换为HID键值数组 [0x20, keyCode1, keyCode2]
  private convertToHIDArray(pressedKeys: number[]): number[] {
    let keyCode1 = 0x00; // 辅助键位掩码
    let keyCode2 = 0x00; // 主键键值

    // 处理修饰键（辅助键）- 使用标准化后的按键
    const normalizedKeys = pressedKeys.map(keyCode => this.normalizeModifierKey(keyCode))

    normalizedKeys.forEach(keyCode => {
      if (this.IsModifierKey(keyCode)) {
        keyCode1 |= this.getHIDModifierCode(keyCode)
      } else {
        // 处理主键
        keyCode2 = this.getHIDKeyCode(keyCode)
      }
    })

    return [0x20, keyCode1, keyCode2]
  }

  // 获取HID修饰键位掩码
  private getHIDModifierCode(keyCode: number): number {
    // 使用标准化后的按键值
    const normalizedKeyCode = this.normalizeModifierKey(keyCode)

    switch (normalizedKeyCode) {
      case KeyCode.KEYCODE_CTRL_LEFT:
        return 0x01; // Control
      case KeyCode.KEYCODE_SHIFT_LEFT:
        return 0x02; // Shift
      case KeyCode.KEYCODE_ALT_LEFT:
        return 0x04; // Alt
      case KeyCode.KEYCODE_META_LEFT:
        return 0x08; // Command/Meta
      default:
        return 0x00;
    }
  }

  // 获取HID主键键值
  private getHIDKeyCode(keyCode: number): number {
    // 这里需要将KeyCode映射到HID键值
    switch (keyCode) {
      // 字母键
      case KeyCode.KEYCODE_A:
        return 0x04;
      case KeyCode.KEYCODE_B:
        return 0x05;
      case KeyCode.KEYCODE_C:
        return 0x06;
      case KeyCode.KEYCODE_D:
        return 0x07;
      case KeyCode.KEYCODE_E:
        return 0x08;
      case KeyCode.KEYCODE_F:
        return 0x09;
      case KeyCode.KEYCODE_G:
        return 0x0A;
      case KeyCode.KEYCODE_H:
        return 0x0B;
      case KeyCode.KEYCODE_I:
        return 0x0C;
      case KeyCode.KEYCODE_J:
        return 0x0D;
      case KeyCode.KEYCODE_K:
        return 0x0E;
      case KeyCode.KEYCODE_L:
        return 0x0F;
      case KeyCode.KEYCODE_M:
        return 0x10;
      case KeyCode.KEYCODE_N:
        return 0x11;
      case KeyCode.KEYCODE_O:
        return 0x12;
      case KeyCode.KEYCODE_P:
        return 0x13;
      case KeyCode.KEYCODE_Q:
        return 0x14;
      case KeyCode.KEYCODE_R:
        return 0x15;
      case KeyCode.KEYCODE_S:
        return 0x16;
      case KeyCode.KEYCODE_T:
        return 0x17;
      case KeyCode.KEYCODE_U:
        return 0x18;
      case KeyCode.KEYCODE_V:
        return 0x19;
      case KeyCode.KEYCODE_W:
        return 0x1A;
      case KeyCode.KEYCODE_X:
        return 0x1B;
      case KeyCode.KEYCODE_Y:
        return 0x1C;
      case KeyCode.KEYCODE_Z:
        return 0x1D;

    // 数字键
      case KeyCode.KEYCODE_0:
        return 0x27;
      case KeyCode.KEYCODE_1:
        return 0x1E;
      case KeyCode.KEYCODE_2:
        return 0x1F;
      case KeyCode.KEYCODE_3:
        return 0x20;
      case KeyCode.KEYCODE_4:
        return 0x21;
      case KeyCode.KEYCODE_5:
        return 0x22;
      case KeyCode.KEYCODE_6:
        return 0x23;
      case KeyCode.KEYCODE_7:
        return 0x24;
      case KeyCode.KEYCODE_8:
        return 0x25;
      case KeyCode.KEYCODE_9:
        return 0x26;

    // 功能键
      case KeyCode.KEYCODE_F1:
        return 0x3A;
      case KeyCode.KEYCODE_F2:
        return 0x3B;
      case KeyCode.KEYCODE_F3:
        return 0x3C;
      case KeyCode.KEYCODE_F4:
        return 0x3D;
      case KeyCode.KEYCODE_F5:
        return 0x3E;
      case KeyCode.KEYCODE_F6:
        return 0x3F;
      case KeyCode.KEYCODE_F7:
        return 0x40;
      case KeyCode.KEYCODE_F8:
        return 0x41;
      case KeyCode.KEYCODE_F9:
        return 0x42;
      case KeyCode.KEYCODE_F10:
        return 0x43;
      case KeyCode.KEYCODE_F11:
        return 0x44;
      case KeyCode.KEYCODE_F12:
        return 0x45;

    // 其他常用键
      case KeyCode.KEYCODE_ENTER:
        return 0x28;
      case KeyCode.KEYCODE_SPACE:
        return 0x2C;
      case KeyCode.KEYCODE_TAB:
        return 0x2B;
      case KeyCode.KEYCODE_ESCAPE:
        return 0x29;

      default:
        return 0x00; // 未映射的键
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
      keyCode === KeyCode.KEYCODE_ALT_RIGHT ||
      keyCode === KeyCode.KEYCODE_META_LEFT ||
      keyCode === KeyCode.KEYCODE_META_RIGHT
  }

  // 根据keyCode获取键名 - 使用标准KeyCode枚举
  private GetKeyName(keyCode: number): string {
    // 使用标准化后的按键值来获取显示名称
    const normalizedKeyCode = this.normalizeModifierKey(keyCode)

    switch (normalizedKeyCode) {
      // 字母键
      case KeyCode.KEYCODE_A:
        return 'A';
      case KeyCode.KEYCODE_B:
        return 'B';
      case KeyCode.KEYCODE_C:
        return 'C';
      case KeyCode.KEYCODE_D:
        return 'D';
      case KeyCode.KEYCODE_E:
        return 'E';
      case KeyCode.KEYCODE_F:
        return 'F';
      case KeyCode.KEYCODE_G:
        return 'G';
      case KeyCode.KEYCODE_H:
        return 'H';
      case KeyCode.KEYCODE_I:
        return 'I';
      case KeyCode.KEYCODE_J:
        return 'J';
      case KeyCode.KEYCODE_K:
        return 'K';
      case KeyCode.KEYCODE_L:
        return 'L';
      case KeyCode.KEYCODE_M:
        return 'M';
      case KeyCode.KEYCODE_N:
        return 'N';
      case KeyCode.KEYCODE_O:
        return 'O';
      case KeyCode.KEYCODE_P:
        return 'P';
      case KeyCode.KEYCODE_Q:
        return 'Q';
      case KeyCode.KEYCODE_R:
        return 'R';
      case KeyCode.KEYCODE_S:
        return 'S';
      case KeyCode.KEYCODE_T:
        return 'T';
      case KeyCode.KEYCODE_U:
        return 'U';
      case KeyCode.KEYCODE_V:
        return 'V';
      case KeyCode.KEYCODE_W:
        return 'W';
      case KeyCode.KEYCODE_X:
        return 'X';
      case KeyCode.KEYCODE_Y:
        return 'Y';
      case KeyCode.KEYCODE_Z:
        return 'Z';

    // 数字键
      case KeyCode.KEYCODE_0:
        return '0';
      case KeyCode.KEYCODE_1:
        return '1';
      case KeyCode.KEYCODE_2:
        return '2';
      case KeyCode.KEYCODE_3:
        return '3';
      case KeyCode.KEYCODE_4:
        return '4';
      case KeyCode.KEYCODE_5:
        return '5';
      case KeyCode.KEYCODE_6:
        return '6';
      case KeyCode.KEYCODE_7:
        return '7';
      case KeyCode.KEYCODE_8:
        return '8';
      case KeyCode.KEYCODE_9:
        return '9';

    // 功能键
      case KeyCode.KEYCODE_F1:
        return 'F1';
      case KeyCode.KEYCODE_F2:
        return 'F2';
      case KeyCode.KEYCODE_F3:
        return 'F3';
      case KeyCode.KEYCODE_F4:
        return 'F4';
      case KeyCode.KEYCODE_F5:
        return 'F5';
      case KeyCode.KEYCODE_F6:
        return 'F6';
      case KeyCode.KEYCODE_F7:
        return 'F7';
      case KeyCode.KEYCODE_F8:
        return 'F8';
      case KeyCode.KEYCODE_F9:
        return 'F9';
      case KeyCode.KEYCODE_F10:
        return 'F10';
      case KeyCode.KEYCODE_F11:
        return 'F11';
      case KeyCode.KEYCODE_F12:
        return 'F12';

    // 修饰键 - 统一显示，不区分左右
      case KeyCode.KEYCODE_CTRL_LEFT:
        return 'Ctrl';
      case KeyCode.KEYCODE_SHIFT_LEFT:
        return 'Shift';
      case KeyCode.KEYCODE_ALT_LEFT:
        return 'Alt';
      case KeyCode.KEYCODE_META_LEFT:
        return 'Cmd';

    // 特殊键
      case KeyCode.KEYCODE_ENTER:
        return 'Enter';
      case KeyCode.KEYCODE_SPACE:
        return 'Space';
      case KeyCode.KEYCODE_TAB:
        return 'Tab';
      case KeyCode.KEYCODE_BACK:
        return 'Backspace';
      case KeyCode.KEYCODE_CAPS_LOCK:
        return 'Caps';
      case KeyCode.KEYCODE_ESCAPE:
        return 'Escape';
      case KeyCode.KEYCODE_DEL:
        return 'Delete';
      case KeyCode.KEYCODE_MOVE_HOME:
        return 'Home';
      case KeyCode.KEYCODE_MOVE_END:
        return 'End';
      case KeyCode.KEYCODE_PAGE_UP:
        return 'PageUp';
      case KeyCode.KEYCODE_PAGE_DOWN:
        return 'PageDown';
      case KeyCode.KEYCODE_DPAD_UP:
        return '↑';
      case KeyCode.KEYCODE_DPAD_DOWN:
        return '↓';
      case KeyCode.KEYCODE_DPAD_LEFT:
        return '←';
      case KeyCode.KEYCODE_DPAD_RIGHT:
        return '→';
      case KeyCode.KEYCODE_DPAD_CENTER:
        return 'Center';

    // 符号键
      case KeyCode.KEYCODE_COMMA:
        return ',';
      case KeyCode.KEYCODE_PERIOD:
        return '.';
      case KeyCode.KEYCODE_SLASH:
        return '/';
      case KeyCode.KEYCODE_BACKSLASH:
        return '\\';
      case KeyCode.KEYCODE_SEMICOLON:
        return ';';
      case KeyCode.KEYCODE_APOSTROPHE:
        return "'";
      case KeyCode.KEYCODE_LEFT_BRACKET:
        return '[';
      case KeyCode.KEYCODE_RIGHT_BRACKET:
        return ']';
      case KeyCode.KEYCODE_MINUS:
        return '-';
      case KeyCode.KEYCODE_EQUALS:
        return '=';
      case KeyCode.KEYCODE_GRAVE:
        return '`';
      case KeyCode.KEYCODE_AT:
        return '@';
      case KeyCode.KEYCODE_PLUS:
        return '+';
      case KeyCode.KEYCODE_STAR:
        return '*';
      case KeyCode.KEYCODE_POUND:
        return '#';

      default:
        return `Key${keyCode}`;
    }
  }

  // 格式化按键显示
  private FormatKeysDisplay(modifiers: number[], mainKey: string): string {
    if (modifiers.length === 0 && !mainKey) {
      return '';
    }

    const modifierNames = modifiers.map(keyCode => {
      return this.GetKeyName(keyCode)
    }).filter(name => name === 'Ctrl' || name === 'Shift' || name === 'Alt' || name === 'Cmd').join(' + ');

    return modifierNames + (modifierNames && mainKey ? ' + ' : '') + mainKey;
  }

  // 检查快捷键匹配
  private CheckShortcutMatch(pressedKeyCode: number) {
    if (!this.IsModifierKey(pressedKeyCode)) { // 只有非修饰键才触发匹配
      for (const group of this.shortcutGroups) {
        const currentModifiers = this.pressedKeys.filter(keyCode =>
        this.IsModifierKey(keyCode) && keyCode !== pressedKeyCode
        );

        // 使用标准化后的按键进行比较
        const normalizedCurrentModifiers = currentModifiers.map(keyCode => this.normalizeModifierKey(keyCode));
        const normalizedGroupModifiers = group.modifierKeys.map(keyCode => this.normalizeModifierKey(keyCode));
        const normalizedPressedKeyCode = this.normalizeModifierKey(pressedKeyCode);
        const normalizedGroupKeyCode = this.normalizeModifierKey(group.keyCode);

        const modifiersMatch = this.ArraysEqual(normalizedGroupModifiers, normalizedCurrentModifiers);
        const mainKeyMatch = normalizedGroupKeyCode === normalizedPressedKeyCode;

        if (modifiersMatch && mainKeyMatch) {
          // this.feedback = `触发已保存组合: ${group.displayText}`;
          this.feedback = `${Languages.triggered_shortcut_prefix[this.languages]} ${group.displayText}`;
          return;
        }
      }
    }
  }
}
