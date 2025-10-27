import { LeftBar, Topbar, Content, paramModel } from 'common'
import { webview } from '@kit.ArkWeb';
import { ConnectDevice, DeviceArrayType } from 'mouse'
import { globalShortcutService } from 'utils';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { Want } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { getModelInfoModel } from 'config';

// PersistentStorage.persistProp("login", false)

@Builder
function AiPageBuilder() {
  AiPage()
}

@Component
struct AiPage {
  @State getModelInfo: getModelInfoModel =
    (ConnectDevice.Communication[AppStorage.get('device_currIndex') as number] as DeviceArrayType).getModelInfo as getModelInfoModel
  @StorageLink("login") login: boolean = true
  @Watch('executeJSFunction')@StorageLink("chatIeUrl") chatIeUrl: string = 'ai'
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


  aboutToAppear(): void {
    if (!this.login) {
      this.pageInfo.pushPath({ 'name': 'login' })
    }
    console.error(this.chatIeUrl)
    // this.pageInfo.getParamByName('aipage')
    // 注册快捷键回调函数
    this.registerShortcutCallbacks();
  }

  aboutToDisappear(): void {
    AppStorage.setOrCreate('currpageIsAI', true)
  }


  // 执行JavaScript函数
  private executeJSFunction(): void {
    if (!this.isWebViewReady) {
      console.error("WebView未就绪，无法执行JS");
      return;
    }

    if (!this.chatIeUrl) {
      console.warn("chatIeUrl为空，无法执行JS函数");
      return;
    }

    try {
      // 构建JS代码字符串
      const jsCode = `handlHelperInput('${this.chatIeUrl}')`;

      console.error("执行JS代码: " + jsCode);

      this.webviewController.runJavaScript(jsCode).then((result: string) => {
        console.error("JS执行成功，返回值: " + result);
      }).catch((error: Error) => {
        console.error("JS执行失败: " + error.message);
      });
    } catch (error) {
      console.error("执行JS函数时出错: " + JSON.stringify(error));
    }
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
    const protocolIndex = url.indexOf('://');
    if (protocolIndex === -1) {
      return false;
    }

    const hostPart = url.substring(protocolIndex + 3);
    if (!hostPart || hostPart.length === 0) {
      return false;
    }

    if (hostPart.indexOf('/') === 0) {
      return false;
    }

    return true;
  }

  // 使用系统浏览器打开下载链接
  private openDownloadLinkInBrowser(downloadUrl: string, fileName: string) {
    try {
      console.info("使用系统浏览器打开下载链接: " + downloadUrl);

      const context = getContext(this) as common.UIAbilityContext;

      const want: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: downloadUrl
      };

      context.startAbility(want).then(() => {
        console.info("成功启动系统浏览器处理下载");
        promptAction.showToast({
          message: '正在通过系统浏览器下载',
          duration: 2000
        });
      }).catch(() => {
        console.error("启动系统浏览器失败: ");
        this.fallbackToInAppDownload(downloadUrl, fileName);
      });

    } catch (error) {
      console.error("打开系统浏览器失败: " + JSON.stringify(error));
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
      const context = getContext(this) as common.UIAbilityContext;
      const downloadDir = context.filesDir + '/downloads/';

      this.ensureDirectoryExists(downloadDir);

      const finalFileName = fileName || `download_${new Date().getTime()}.bin`;
      const filePath = downloadDir + finalFileName;

      this.currentDownloadPath = filePath;

      webDownloadItem.start(filePath);
      this.isDownloading = true;

      console.info("开始应用内下载文件到: " + filePath);

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
    this.delegate.onDownloadUpdated((webDownloadItem: webview.WebDownloadItem) => {
      this.isDownloading = true;
      const progress = webDownloadItem.getPercentComplete();
      this.downloadProgress = progress;
      console.info(`下载进度: ${progress}%`);

      const speed = webDownloadItem.getCurrentSpeed();
      if (speed > 0) {
        console.info(`下载速度: ${this.formatSpeed(speed)}`);
      }
    });

    this.delegate.onDownloadFinish(() => {
      console.info("下载完成");
      this.isDownloading = false;
      this.downloadProgress = 0;

      this.showDownloadCompleteDialog();

      promptAction.showToast({
        message: '下载完成',
        duration: 3000
      });
    });

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
    if (bytesPerSecond === 0) {
      return '0 B/s';
    }

    const k = 1024;
    const sizes = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    const i = Math.floor(Math.log(bytesPerSecond) / Math.log(k));

    return parseFloat((bytesPerSecond / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  // 注册快捷键回调函数
  private registerShortcutCallbacks() {
    globalShortcutService.registerCallback(1, () => {
      console.log('执行语音识别功能')
    })

    globalShortcutService.registerCallback(2, () => {
      console.log('执行语音翻译功能')
    })

    globalShortcutService.registerCallback(3, () => {
      console.log('执行截图识别功能')
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
                // 下载进度显示
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
                  src: (ConnectDevice.Communication[AppStorage.get('device_currIndex') as number] as DeviceArrayType).getModelInfo?.chatChromeUrl as string,
                  controller: this.webviewController
                })
                  .onPageEnd(() => {
                    console.info("Web页面加载完成，设置下载委托");
                    this.isWebViewReady = true;
                    this.setupDownloadDelegate();

                    // 页面加载完成后执行JS函数
                    this.executeJSFunction();
                  })
                  .onPageBegin(() => {
                    this.isWebViewReady = false;
                  })
                  .flexGrow(1)
                  .height('100%')
                  .flexShrink(1)
                  .domStorageAccess(true)
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