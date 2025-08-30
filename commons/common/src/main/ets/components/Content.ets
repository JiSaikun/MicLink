import { webview } from '@kit.ArkWeb';
@Component
export struct Content {
  webviewController: webview.WebviewController = new webview.WebviewController();
   @Watch('Waf') @Link web: string
  Waf(){
    console.log(this.web)
  }
  build() {
    Flex(){
      Web({ src: this.web, controller: this.webviewController })
        .flexShrink(1)
        .key(this.web) // 添加key属性，确保值变化时重新创建组件
    }
    .width('100%')
    .height('100%')
    .padding(66)
  }
}
