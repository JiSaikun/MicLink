import { webview } from '@kit.ArkWeb';
import { globalShortcutService } from 'utils';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

@Component
export struct Content {
  webviewController: webview.WebviewController = new webview.WebviewController();

  // 正确创建WebDownloadDelegate
  delegate: webview.WebDownloadDelegate = new webview.WebDownloadDelegate();

  @Link web: string
  @State downloadProgress: number = 0
  @State isDownloading: boolean = false
  @State isWebViewReady: boolean = false

  aboutToAppear() {
    // 注册快捷键回调函数
    this.registerShortcutCallbacks();
  }

  // 设置下载委托和监听 - 在Web组件就绪后调用
  private setupDownloadDelegate() {
    if (!this.isWebViewReady) {
      console.error("WebView未就绪，无法设置下载委托");
      return;
    }

    try {
      // 将下载委托设置到WebView控制器
      this.webviewController.setDownloadDelegate(this.delegate);
      console.info("下载委托设置成功");

      // 监听下载开始前的回调
      this.delegate.onBeforeDownload((webDownloadItem: webview.WebDownloadItem) => {
        console.info("准备开始下载");

        // 获取建议的文件名
        const suggestedFileName = webDownloadItem.getSuggestedFileName();
        const url = webDownloadItem.getUrl();

        console.info("下载地址: " + url);
        console.info("建议文件名: " + suggestedFileName);

        // 显示下载确认对话框
        promptAction.showDialog({
          title: '下载文件',
          message: `是否要下载文件：${suggestedFileName || '未知文件'}?`,
          buttons: [
            {
              text: '取消',
              color: '#666666'
            },
            {
              text: '下载',
              color: '#007DFF'
            }
          ]
        }).then((result) => {
          if (result.index === 1) {
            // 用户点击了下载按钮
            this.handleDownload(webDownloadItem, suggestedFileName);
          } else {
            // 用户取消下载
            console.info("用户取消了下载");
            webDownloadItem.cancel(); // 取消下载
          }
        });
      });

      // 监听下载进度更新
      this.delegate.onDownloadUpdated((webDownloadItem: webview.WebDownloadItem) => {
        // 更新下载状态
        this.isDownloading = true;

        // 获取下载进度百分比
        const progress = webDownloadItem.getPercentComplete();
        this.downloadProgress = progress;

        console.info(`下载进度: ${progress}%`);

        // 获取下载速度（字节/秒）
        const speed = webDownloadItem.getCurrentSpeed();
        if (speed > 0) {
          console.info(`下载速度: ${this.formatSpeed(speed)}`);
        }
      });

      // 监听下载完成事件
      this.delegate.onDownloadFinish(() => {
        console.info("下载完成");
        this.isDownloading = false;
        this.downloadProgress = 0;

        promptAction.showToast({
          message: '下载完成',
          duration: 3000
        });
      });

      // 监听下载失败事件
      this.delegate.onDownloadFailed(() => {
        console.error("下载失败");
        this.isDownloading = false;
        this.downloadProgress = 0;

        promptAction.showToast({
          message: '下载失败',
          duration: 3000
        });
      });
    } catch (error) {
      console.error("设置下载委托失败: " + JSON.stringify(error));
    }
  }

  // 处理下载任务
  private handleDownload(webDownloadItem: webview.WebDownloadItem, fileName: string) {
    try {
      // 设置下载路径
      const context = getContext(this) as common.UIAbilityContext;
      const downloadDir = context.filesDir + '/downloads/';

      // 创建文件名（如果为空则使用时间戳）
      const finalFileName = fileName || `download_${new Date().getTime()}.bin`;
      const filePath = downloadDir + finalFileName;

      // 开始下载
      webDownloadItem.start(filePath);
      this.isDownloading = true;

      console.info("开始下载文件到: " + filePath);

      promptAction.showToast({
        message: '开始下载文件',
        duration: 2000
      });
    } catch (error) {
      console.error("处理下载时出错: " + JSON.stringify(error));
      promptAction.showToast({
        message: '下载启动失败',
        duration: 3000
      });
    }
  }

  // 格式化下载速度显示
  private formatSpeed(bytesPerSecond: number): string {
    if (bytesPerSecond === 0) return '0 B/s';

    const k = 1024;
    const sizes = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    const i = Math.floor(Math.log(bytesPerSecond) / Math.log(k));

    return parseFloat((bytesPerSecond / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      // 下载进度显示
      if (this.isDownloading) {
        Text(`下载进度: ${this.downloadProgress}%`)
          .fontSize(14)
          .fontColor(Color.Blue)
          .margin({ bottom: 10 })
      }

      Web({
        src: this.web,
        controller: this.webviewController
      })
        .onPageEnd(() => {
          // Web页面加载完成后设置下载委托
          console.info("Web页面加载完成，设置下载委托");
          this.isWebViewReady = true;
          this.setupDownloadDelegate();
        })
        .onPageBegin(() => {
          // 页面开始加载时重置状态
          this.isWebViewReady = false;
        })
        .flexGrow(1)
        .width('100%')
        .height('100%')
        .domStorageAccess(true)
        // 启用JavaScript和支持下载
        .javaScriptAccess(true)
        .fileAccess(true)
        .onInterceptKeyEvent((event: KeyEvent) => {
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