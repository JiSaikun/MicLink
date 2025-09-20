import { webview } from '@kit.ArkWeb';
import { getModelInfoModel } from 'config'

@Builder
function AiPageBuilder() {
  AiPage()
}

@Component
struct AiPage {
  webviewController: webview.WebviewController = new webview.WebviewController();
  @State getModelInfo: getModelInfoModel = AppStorage.get('getModelInfo') as getModelInfoModel

  build() {
    NavDestination() {
      Flex() {
        Web({ src: 'this.getModelInfo.chatChromeUrl', controller: this.webviewController })
          .flexGrow(1)
          .height('100%')
          .flexShrink(1)
        // .key(this.web) // 添加key属性，确保值变化时重新创建组件
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Red)
      .padding({ top: 66 })
    }.hideToolBar(true)
    .hideTitleBar(true)
  }
}