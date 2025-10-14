import { LeftBar, Topbar, Content, paramModel } from 'common'
import { FixedText_pop, WebUrlToOpen_pop } from 'utils'
import Content_Ai from 'command_ai/src/main/ets/components/Command_Ai'
import { DeviceSettings } from '../components/DeviceSettings'
import { CreateNewInstruction_pop } from 'command_ai'

@Builder
function IndexPageBuilder() {
  IndexPage()
}

PersistentStorage.persistProp("voice_recognition_shortcut", { keyPreview: '', pressedKeys: [] }) //语音识别快捷键
PersistentStorage.persistProp("voice_translation_shortcut", { keyPreview: '', pressedKeys: [] }) //语音翻译快捷键
PersistentStorage.persistProp("screenshot_recognition_shortcut", { keyPreview: '', pressedKeys: [] }) //截图识别快捷键
PersistentStorage.persistProp("custom_shortcut", { keyPreview: '', pressedKeys: [] }) //自定义快捷键

@Component
struct IndexPage {
  @StorageLink("login") login: boolean = true
  @Watch('shortcut_change') @StorageLink("shortcut") shortcut: number =
    0 //改变该值弹出对应快捷键悬浮窗口 1：语音识别 2：语音翻译 3:截图识别 4：自定义快捷键
  @Consume('pageInfo') pageInfo: NavPathStack
  @State web: string = 'https://asrai.miclink.net/'
  @State currentIndex: number = 0
  @State bottomCurrIndex: number = 10000
  @State extend: boolean = true //状态栏延申
  @State width_length: number = 248 //左侧选项卡样式宽度
  @State isShow_CreateNewInstruction_pop: boolean = false //AI指令创建弹窗
  @State isShow_EditInstruction_pop: boolean = false //AI指令编辑弹窗
  @State EditInstruction_pop_currIndex: number = 0 //AI指令编辑弹窗定位索引
  @State shortcut_pop: boolean = false //快捷键弹窗
  @StorageLink("isShowFixedText_pop") isShowFixedText_pop: boolean = false //控制打开固定文本悬浮窗
  @StorageLink("isShow_webUrlToOpen_pop") isShow_webUrlToOpen_pop: boolean = false //快捷键弹窗

  shortcut_change() {
    this.shortcut_pop = !this.shortcut_pop
    if (this.shortcut_pop) {
      // Shortcut_pop()
      this.pageInfo.pushPath({ 'name': 'shortcut_pop' })
    }
  }

  aboutToAppear(): void {
    if (!this.login) {
      this.pageInfo.pushPath({ 'name': 'login' })
    }
    // console.log('=================================进入测试机')
    // console.log('+',JSON.stringify(this.pageInfo.getParamByName("indexPage")))
    this.web = (this.pageInfo.getParamByName("indexPage")[0] as paramModel).web
    this.currentIndex = (this.pageInfo.getParamByName("indexPage")[0] as paramModel).currentIndex
    this.bottomCurrIndex = (this.pageInfo.getParamByName("indexPage")[0] as paramModel).bottomCurrIndex
    this.extend = (this.pageInfo.getParamByName("indexPage")[0] as paramModel).extend
    this.width_length = (this.pageInfo.getParamByName("indexPage")[0] as paramModel).width_length
    // console.log(JSON.stringify(this.pageInfo.getParamByName("indexPage")[0]))
  }

  build() {
    Column() {
      NavDestination() {
        Stack() {
          Row() {
            LeftBar({
              currentIndex: this.currentIndex,
              web: this.web,
              bottomCurrIndex: this.bottomCurrIndex,
              extend: this.extend
            ,
              width_length: this.width_length
            })
            Stack() {
              Topbar()
                .zIndex(100)
              if (this.web) {
                if (this.web === 'Command_Ai') {
                  Content_Ai({
                    isShow_CreateNewInstruction_pop: this.isShow_CreateNewInstruction_pop,
                    isShow_EditInstruction_pop: this.isShow_EditInstruction_pop,
                    EditInstruction_pop_currIndex: this.EditInstruction_pop_currIndex
                  }) //AI--指令
                } else if (this.web === 'DeviceSettings') {
                  /*
                    设备设置
                   */
                  DeviceSettings()
                } else {
                  Content({ web: this.web })
                }
              }
            }
            // .border({width:1})
            .align(Alignment.TopStart)
            .height('100%')
            .layoutWeight(1)
          }
          // .backgroundColor(Color.Blue)
          .width('100%')
          .height('100%')

          if (this.isShow_CreateNewInstruction_pop) {
            CreateNewInstruction_pop({
              isShow_CreateNewInstruction_pop: this.isShow_CreateNewInstruction_pop,
              isShow_EditInstruction_pop: this.isShow_EditInstruction_pop
            })
          }
          if (this.isShow_EditInstruction_pop) {
            CreateNewInstruction_pop({
              isShow_CreateNewInstruction_pop: this.isShow_CreateNewInstruction_pop,
              isShow_EditInstruction_pop: this.isShow_EditInstruction_pop,
              isParam: true,
              currIndexParam: this.EditInstruction_pop_currIndex
            })
          }
          if (this.isShowFixedText_pop) {
            FixedText_pop({ isShowFixedText_pop: this.isShowFixedText_pop })
          }
          if (this.isShow_webUrlToOpen_pop) {
            WebUrlToOpen_pop({ isShow_webUrlToOpen_pop: this.isShow_webUrlToOpen_pop })
          }

        }
        .width('100%')
        .height('100%')

      }
      .hideToolBar(true)
      .hideTitleBar(true)

    }

  }
}