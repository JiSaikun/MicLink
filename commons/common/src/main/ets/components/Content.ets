import { webview } from '@kit.ArkWeb';

@Component
export struct Content {
  webviewController: webview.WebviewController = new webview.WebviewController();
  @Link web: string

  build() {
    Flex() {
      Web({ src: this.web, controller: this.webviewController })
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
}
