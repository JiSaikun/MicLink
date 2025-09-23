import { LeftBar, Topbar, Content, paramModel } from 'common'
import { webview } from '@kit.ArkWeb';
import { getModelInfoModel } from 'config'

// PersistentStorage.persistProp("login", false)

@Builder
function AiPageBuilder() {
  AiPage()
}

@Component
struct AiPage {
  @StorageLink("login") login: boolean = true
  @Consume('pageInfo') pageInfo: NavPathStack
  @State web: string = ''
  @State currentIndex: number = 10000000
  @State bottomCurrIndex: number = 10000
  @State extend: boolean = false //状态栏延申
  @State width_length: number = 88 //左侧选项卡样式宽度
  webviewController: webview.WebviewController = new webview.WebviewController();
  @State getModelInfo: getModelInfoModel = AppStorage.get('getModelInfo') as getModelInfoModel

  aboutToAppear(): void {
    if (!this.login) {
      this.pageInfo.pushPath({ 'name': 'login' })
    }
    // console.log('=================================进入测试机')
    // console.log('+',JSON.stringify(this.pageInfo.getParamByName("indexPage")))
    // console.log(JSON.stringify(this.pageInfo.getParamByName("indexPage")[0]))
  }

  aboutToDisappear(): void {
    AppStorage.setOrCreate('currpageIsAI', true)
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
              Flex() {
                Web({ src: this.getModelInfo.chatChromeUrl, controller: this.webviewController })
                  .flexGrow(1)
                  .height('100%')
                  .flexShrink(1)
                  .domStorageAccess(true)
                // .key(this.web) // 添加key属性，确保值变化时重新创建组件
              }
              .width('100%')
              .height('100%')
              .padding({ top: 66 })
            }
            // .border({width:1})
            .align(Alignment.TopStart)
            .height('100%')
            .layoutWeight(1)
          }
          // .backgroundColor(Color.Blue)
          .width('100%')
          .height('100%')

        }
        .width('100%')
        .height('100%')

      }
      .hideToolBar(true)
      .hideTitleBar(true)

    }

  }
}