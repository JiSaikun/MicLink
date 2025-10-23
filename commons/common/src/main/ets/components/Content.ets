import { webview } from '@kit.ArkWeb';
import { globalShortcutService } from 'utils';

@Component
export struct Content {
  webviewController: webview.WebviewController = new webview.WebviewController();
  delegate: webview.WebDownloadDelegate = new webview.WebDownloadDelegate();
  @Link web: string
  build() {
    Flex() {
      Web({ src: this.web, controller: this.webviewController })
        .flexGrow(1)
        .height('100%')
        .flexShrink(1)
        .domStorageAccess(true)
      // .key(this.web) // 添加key属性，确保值变化时重新创建组件
        .onInterceptKeyEvent((event: KeyEvent) => {
          // console.warn(JSON.stringify(event))
          // 将按键事件传递给全局监听服务

          // if (event.keyCode === KeyCode.KEYCODE_S && event.metaKey === 1) {
          //   console.log("Ctrl+S 被按下");
          //   // this.handleGlobalShortcut();
          //   return true;
          // }
          globalShortcutService.handleGlobalKeyEvent(event)
          return false;
        })


    }
    .width('100%')
    .height('100%')
    .padding({ top: 66 })
  }
  // 注册快捷键回调函数
  private registerShortcutCallbacks() {
    globalShortcutService.registerCallback(1, () => {
      console.log('执行语音识别功能')
      // 这里可以调用您的语音识别方法
      // this.startVoiceRecognition()
    })

    globalShortcutService.registerCallback(2, () => {
      console.log('执行语音翻译功能')
      // 这里可以调用您的语音翻译方法
      // this.startVoiceTranslation()
    })

    globalShortcutService.registerCallback(3, () => {
      console.log('执行截图识别功能')
      // 这里可以调用您的截图识别方法
      // this.startScreenshotRecognition()
    })
  }
}
