import { LeftBar, Topbar, Content, paramModel } from 'common'
import { webview } from '@kit.ArkWeb';
import { getModelInfoModel } from 'config'
import { globalShortcutService } from 'utils';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { Want } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';

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

  // 添加下载相关属性和委托
  delegate: webview.WebDownloadDelegate = new webview.WebDownloadDelegate();
  @State isWebViewReady: boolean = false
  @State downloadProgress: number = 0
  @State isDownloading: boolean = false
  @State currentDownloadPath: string = ''

  @State getModelInfo: getModelInfoModel = AppStorage.get('getModelInfo') as getModelInfoModel

  aboutToAppear(): void {
    if (!this.login) {
      this.pageInfo.pushPath({ 'name': 'login' })
    }
    // 注册快捷键回调函数
    this.registerShortcutCallbacks();
  }

  aboutToDisappear(): void {
    AppStorage.setOrCreate('currpageIsAI', true)
  }

  // 设置下载委托和监听
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
        console.info("监听到下载请求");

        // 获取下载信息
        const suggestedFileName = webDownloadItem.getSuggestedFileName();
        const url = webDownloadItem.getUrl();

        console.info("下载地址: " + url);
        console.info("建议文件名: " + suggestedFileName);

        // 首先尝试通过浏览器下载
        this.tryBrowserDownload(webDownloadItem, url, suggestedFileName);

        return true; // 表示已处理下载请求
      });

    } catch (error) {
      console.error("设置下载委托失败: " + JSON.stringify(error));
    }
  }

  // 尝试通过浏览器下载
  private tryBrowserDownload(webDownloadItem: webview.WebDownloadItem, downloadUrl: string, fileName: string) {
    // 验证URL是否有效
    if (!this.isValidDownloadUrl(downloadUrl)) {
      console.info("检测到无效下载链接，切换到应用内下载");
      this.startInAppDownload(webDownloadItem, fileName);
      return;
    }

    // 取消WebView内部的下载处理
    webDownloadItem.cancel();

    // 通过系统浏览器打开下载链接
    this.openDownloadLinkInBrowser(downloadUrl, fileName);
  }

  // 验证下载链接是否有效
  private isValidDownloadUrl(url: string): boolean {
    if (!url) {
      return false;
    }

    // 检查是否为HTTP/HTTPS协议
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return false;
    }

    // 简单验证URL格式
    // 检查是否有有效的主机名部分（在 :// 之后至少有一个字符）
    const protocolIndex = url.indexOf('://');
    if (protocolIndex === -1) {
      return false;
    }

    const hostPart = url.substring(protocolIndex + 3); // +3 跳过 "://"
    if (!hostPart || hostPart.length === 0) {
      return false;
    }

    // 检查主机名部分是否包含至少一个点或有效字符
    if (hostPart.indexOf('/') === 0) {
      return false; // 直接以斜杠开头，缺少主机名
    }

    return true;
  }

  // 使用系统浏览器打开下载链接
  private openDownloadLinkInBrowser(downloadUrl: string, fileName: string) {
    try {
      console.info("使用系统浏览器打开下载链接: " + downloadUrl);

      const context = getContext(this) as common.UIAbilityContext;

      // 创建Want对象，使用系统浏览器打开链接
      const want: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: downloadUrl
      };

      // 使用startAbility打开链接
      context.startAbility(want).then(() => {
        console.info("成功启动系统浏览器处理下载");
        promptAction.showToast({
          message: '正在通过系统浏览器下载',
          duration: 2000
        });
      }).catch(() => {
        console.error("启动系统浏览器失败: ");
        // 浏览器下载失败，回退到应用内下载
        this.fallbackToInAppDownload(downloadUrl, fileName);
      });

    } catch (error) {
      console.error("打开系统浏览器失败: " + JSON.stringify(error));
      // 浏览器下载失败，回退到应用内下载
      this.fallbackToInAppDownload(downloadUrl, fileName);
    }
  }

  // 回退到应用内下载
  private fallbackToInAppDownload(downloadUrl: string, fileName: string) {
    console.info("浏览器下载失败，回退到应用内下载");

    promptAction.showToast({
      message: '浏览器下载失败，请在WebView中重新点击下载链接',
      duration: 3000
    });
  }

  // 启动应用内下载
  private startInAppDownload(webDownloadItem: webview.WebDownloadItem, fileName: string) {
    try {
      // 设置下载路径
      const context = getContext(this) as common.UIAbilityContext;
      const downloadDir = context.filesDir + '/downloads/';

      // 确保下载目录存在
      this.ensureDirectoryExists(downloadDir);

      // 创建文件名（如果为空则使用时间戳）
      const finalFileName = fileName || `download_${new Date().getTime()}.bin`;
      const filePath = downloadDir + finalFileName;

      // 记录当前下载路径
      this.currentDownloadPath = filePath;

      // 开始下载
      webDownloadItem.start(filePath);
      this.isDownloading = true;

      console.info("开始应用内下载文件到: " + filePath);

      // 设置下载进度和状态监听
      this.setupDownloadListeners();

      promptAction.showToast({
        message: '开始下载文件',
        duration: 2000
      });
    } catch (error) {
      console.error("处理应用内下载时出错: " + JSON.stringify(error));
      promptAction.showToast({
        message: '下载启动失败',
        duration: 3000
      });
    }
  }

  // 设置下载监听器
  private setupDownloadListeners() {
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

      // 显示下载完成提示和文件位置
      this.showDownloadCompleteDialog();

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
  }

  // 确保目录存在
  private ensureDirectoryExists(dirPath: string) {
    try {
      // 检查目录是否存在，如果不存在则创建
      if (!fileIo.accessSync(dirPath)) {
        fileIo.mkdirSync(dirPath, true);
        console.info("创建下载目录: " + dirPath);
      }
    } catch (error) {
      console.error("创建目录失败: " + JSON.stringify(error));
    }
  }

  // 显示下载完成对话框
  private showDownloadCompleteDialog() {
    if (!this.currentDownloadPath) {
      return;
    }

    // 从完整路径中提取文件名
    const fileName = this.getFileNameFromPath(this.currentDownloadPath);

    promptAction.showDialog({
      title: '下载完成',
      message: `文件 "${fileName}" 已下载完成！\n\n保存位置：\n${this.currentDownloadPath}\n\n您可以在设备的"文件管理"应用中查看下载的文件。`,
      buttons: [
        {
          text: '知道了',
          color: '#007DFF'
        }
      ]
    }).then(() => {
      // 清空当前下载路径
      this.currentDownloadPath = '';
    });
  }

  // 从路径中提取文件名
  private getFileNameFromPath(filePath: string): string {
    const segments = filePath.split('/');
    return segments[segments.length - 1] || '未知文件';
  }

  // 格式化下载速度显示
  private formatSpeed(bytesPerSecond: number): string {
    if (bytesPerSecond === 0) return '0 B/s';

    const k = 1024;
    const sizes = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    const i = Math.floor(Math.log(bytesPerSecond) / Math.log(k));

    return parseFloat((bytesPerSecond / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
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

  build() {
    Column() {
      NavDestination() {
        Stack() {
          Row() {
            LeftBar({
              currentIndex: this.currentIndex,
              web: this.web,
              bottomCurrIndex: this.bottomCurrIndex,
              extend: this.extend,
              width_length: this.width_length
            })
            Stack() {
              Topbar()
                .zIndex(100)
              Flex() {
                // 下载进度显示（仅应用内下载时显示）
                if (this.isDownloading) {
                  Column() {
                    Text('正在下载文件...')
                      .fontSize(16)
                      .fontColor(Color.Black)
                      .margin({ bottom: 5 })

                    Text(`下载进度: ${this.downloadProgress}%`)
                      .fontSize(14)
                      .fontColor(Color.Blue)

                    Progress({ value: this.downloadProgress, total: 100 })
                      .width('80%')
                      .height(8)
                      .color(Color.Blue)
                      .backgroundColor('#EEEEEE')
                  }
                  .width('100%')
                  .padding(10)
                  .backgroundColor('#F5F5F5')
                  .borderRadius(8)
                  .margin({ bottom: 10 })
                }

                Web({
                  src: this.getModelInfo.chatChromeUrl,
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
                  .height('100%')
                  .flexShrink(1)
                  .domStorageAccess(true)
                  .javaScriptAccess(true) // 启用JavaScript
                  .fileAccess(true) // 启用文件访问
                  .onInterceptKeyEvent((event: KeyEvent) => {
                    // 将按键事件传递给全局监听服务
                    globalShortcutService.handleGlobalKeyEvent(event)
                    return false;
                  })
              }
              .width('100%')
              .height('100%')
              .padding({ top: 66 })
            }
            .align(Alignment.TopStart)
            .height('100%')
            .layoutWeight(1)
          }
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