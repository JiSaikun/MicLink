import { LeftBar, Topbar, Content, paramModel } from 'common'
import { webview } from '@kit.ArkWeb';
import { ConnectDevice, DeviceArrayType } from 'mouse'
import { globalShortcutService } from 'utils';
import { promptAction } from '@kit.ArkUI';
import { common, OpenLinkOptions } from '@kit.AbilityKit';
import { Want } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { getModelInfoModel } from 'config';
import { DeviceArrayType_Ble } from 'bluetooth';
import { picker } from '@kit.CoreFileKit';
import { fileUri } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

// PersistentStorage.persistProp("login", false)

@Builder
function AiPageBuilder() {
  AiPage()
}

@Component
struct AiPage {
  @State getModelInfo: getModelInfoModel = AppStorage.get('getModelInfo') as getModelInfoModel
  @StorageLink("login") login: boolean = true
  @Watch('executeJSFunction') @StorageLink("chatIeUrl") chatIeUrl: string = 'ai'
  @Consume('pageInfo') pageInfo: NavPathStack
  @State web: string = ''
  @State currentIndex: number = 10000000
  @State bottomCurrIndex: number = 10000
  @State extend: boolean = false //状态栏延申
  @State width_length: number = 88 //左侧选项卡样式宽度
  webviewController: webview.WebviewController = new webview.WebviewController();
  @State dirUri: string = ''
  // 下载相关属性和委托
  delegate: webview.WebDownloadDelegate = new webview.WebDownloadDelegate();
  @State isWebViewReady: boolean = false
  @State downloadProgress: number = 0
  @State isDownloading: boolean = false
  @State currentDownloadPath: string = ''
  @State currentDownloadUrl: string = ''
  @State currentFileName: string = ''
  @State currentDownloadDirUri: string = '' // 保存下载目录URI

  aboutToAppear(): void {
    if (!this.login) {
      this.pageInfo.pushPath({ 'name': 'login' })
    }
    if (AppStorage.get('device_isBle')) {
      this.getModelInfo =
        (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number ||
          0].getModelInfo as getModelInfoModel
    } else {
      this.getModelInfo =
        (ConnectDevice.Communication[AppStorage.get('device_currIndex') as number] as DeviceArrayType).getModelInfo as getModelInfoModel
    }
    console.error(this.chatIeUrl)

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

  // 设置下载委托和监听 - 使用DOWNLOAD模式
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

        // 直接使用DOWNLOAD模式处理下载
        this.handleDownloadWithDOWNLOADMode(webDownloadItem, suggestedFileName, url);

        return true; // 表示已处理下载请求
      });

    } catch (error) {
      console.error("设置下载委托失败: " + JSON.stringify(error));
    }
  }

  // 使用DOWNLOAD模式处理下载
  private handleDownloadWithDOWNLOADMode(webDownloadItem: webview.WebDownloadItem, fileName: string,
    downloadUrl: string) {
    try {
      const context = getContext(this) as common.UIAbilityContext;

      // 创建文件选择器实例
      const documentViewPicker = new picker.DocumentViewPicker(context);
      const documentSaveOptions = new picker.DocumentSaveOptions();

      // 配置为DOWNLOAD模式
      documentSaveOptions.pickerMode = picker.DocumentPickerMode.DOWNLOAD;

      // 设置文件名
      const finalFileName = fileName || this.extractFileNameFromUrl(downloadUrl);
      documentSaveOptions.newFileNames = [finalFileName];

      this.currentFileName = finalFileName;
      this.currentDownloadUrl = downloadUrl;

      console.info("准备下载文件: " + finalFileName);

      // 显示下载开始提示
      promptAction.showToast({
        message: '开始下载文件',
        duration: 2000
      });

      // 调用save接口获取DOWNLOAD目录
      documentViewPicker.save(documentSaveOptions).then((documentSaveResult: Array<string>) => {
        if (documentSaveResult.length > 0) {
          const dirUri = documentSaveResult[0];
          console.info('DOWNLOAD目录URI: ' + dirUri);

          // 保存下载目录URI，用于后续打开文件夹
          this.currentDownloadDirUri = dirUri;

          // 构建完整的文件路径
          const filePath = new fileUri.FileUri(dirUri + '/' + finalFileName).path;

          // 保存当前下载路径用于显示
          this.currentDownloadPath = filePath;

          console.info("WebView下载路径: " + filePath);

          // 设置下载状态
          this.isDownloading = true;
          this.downloadProgress = 0;

          // 设置下载监听器
          this.setupDownloadListeners();

          // 让WebView开始下载到指定路径
          webDownloadItem.start(filePath);

          console.info("WebView下载已启动");
        }
      }).catch((err: BusinessError) => {
        console.error(`DOWNLOAD模式失败, code is ${err.code}, message is ${err.message}`);
        promptAction.showToast({
          message: '下载启动失败',
          duration: 3000
        });
      });

    } catch (error) {
      console.error("处理下载时出错: " + JSON.stringify(error));
      promptAction.showToast({
        message: '下载处理异常',
        duration: 3000
      });
    }
  }

  // 设置下载监听器
  private setupDownloadListeners() {
    // 监听下载进度更新
    this.delegate.onDownloadUpdated((webDownloadItem: webview.WebDownloadItem) => {
      this.isDownloading = true;
      const progress = webDownloadItem.getPercentComplete();
      this.downloadProgress = progress;
      console.info(`下载进度: ${progress}%`);
    });

    // 监听下载完成事件
    this.delegate.onDownloadFinish(() => {
      console.info("下载完成");
      this.isDownloading = false;
      this.downloadProgress = 100;

      // 验证下载的文件
      this.verifyDownloadedFile();

      // 显示选择对话框，让用户决定是否打开文件夹
      this.showDownloadCompleteDialogWithChoice();

      // promptAction.showToast({
      //   message: '下载完成',
      //   duration: 2000
      // });
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

  // 验证下载的文件
  private verifyDownloadedFile() {
    if (!this.currentDownloadPath) {
      console.error("没有下载路径信息");
      return;
    }

    try {
      const stat = fileIo.statSync(this.currentDownloadPath);
      console.info(`文件大小: ${stat.size} 字节`);

      if (stat.size === 0) {
        console.error("下载的文件大小为0，文件可能已损坏");
        promptAction.showToast({
          message: '下载的文件为空或已损坏',
          duration: 3000
        });

        // 删除空文件
        try {
          fileIo.unlinkSync(this.currentDownloadPath);
          console.info("已删除空文件");
        } catch (deleteError) {
          console.error("删除空文件失败: " + JSON.stringify(deleteError));
        }
      } else {
        console.info("文件下载成功，大小正常");

        // 尝试读取文件头信息来验证文件类型
        this.checkFileHeader();
      }
    } catch (error) {
      console.error("文件验证失败: " + JSON.stringify(error));
      promptAction.showToast({
        message: '文件验证失败',
        duration: 3000
      });
    }
  }

  // 检查文件头信息
  private checkFileHeader() {
    if (!this.currentDownloadPath) {
      return;
    }

    try {
      const file = fileIo.openSync(this.currentDownloadPath, fileIo.OpenMode.READ_ONLY);
      const buffer = new ArrayBuffer(8); // 读取前8个字节
      const bytesRead = fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file);

      if (bytesRead > 0) {
        const uint8Array = new Uint8Array(buffer);
        console.info("文件头(十六进制): " + Array.from(uint8Array).map(b => b.toString(16).padStart(2, '0')).join(' '));

        // 常见文件类型的魔数检查
        if (this.isZipFile(uint8Array)) {
          console.info("检测到ZIP文件格式");
        } else if (this.isPngFile(uint8Array)) {
          console.info("检测到PNG文件格式");
        } else if (this.isJpegFile(uint8Array)) {
          console.info("检测到JPEG文件格式");
        } else {
          console.info("未知文件格式");
        }
      }
    } catch (error) {
      console.error("检查文件头失败: " + JSON.stringify(error));
    }
  }

  // 检查ZIP文件格式 (PK开头)
  private isZipFile(header: Uint8Array): boolean {
    return header.length >= 4 &&
      header[0] === 0x50 && header[1] === 0x4B &&
      header[2] === 0x03 && header[3] === 0x04;
  }

  // 检查PNG文件格式
  private isPngFile(header: Uint8Array): boolean {
    return header.length >= 8 &&
      header[0] === 0x89 && header[1] === 0x50 &&
      header[2] === 0x4E && header[3] === 0x47 &&
      header[4] === 0x0D && header[5] === 0x0A &&
      header[6] === 0x1A && header[7] === 0x0A;
  }

  // 检查JPEG文件格式
  private isJpegFile(header: Uint8Array): boolean {
    return header.length >= 3 &&
      header[0] === 0xFF && header[1] === 0xD8 && header[2] === 0xFF;
  }

  // 从URL中提取文件名
  private extractFileNameFromUrl(url: string): string {
    try {
      let fileName = `download_${new Date().getTime()}`;

      // 查找最后一个斜杠
      const lastSlashIndex = url.lastIndexOf('/');
      if (lastSlashIndex !== -1 && lastSlashIndex < url.length - 1) {
        const lastPart = url.substring(lastSlashIndex + 1);

        // 检查是否有查询参数
        const queryIndex = lastPart.indexOf('?');
        if (queryIndex !== -1) {
          fileName = lastPart.substring(0, queryIndex);
        } else {
          fileName = lastPart;
        }

        // 如果文件名仍然为空或太短，使用默认名称
        if (!fileName || fileName.length < 3) {
          fileName = `download_${new Date().getTime()}.bin`;
        }
      }

      // 确保文件名有扩展名
      if (!fileName.includes('.')) {
        fileName += this.guessFileExtension(url);
      }

      return fileName;
    } catch (error) {
      return `download_${new Date().getTime()}.bin`;
    }
  }

  // 根据URL猜测文件扩展名
  private guessFileExtension(url: string): string {
    if (url.includes('.jpg') || url.includes('.jpeg')) {
      return '.jpg';
    } else if (url.includes('.png')) {
      return '.png';
    } else if (url.includes('.pdf')) {
      return '.pdf';
    } else if (url.includes('.mp4')) {
      return '.mp4';
    } else if (url.includes('.mp3')) {
      return '.mp3';
    } else if (url.includes('.zip')) {
      return '.zip';
    } else if (url.includes('.rar')) {
      return '.rar';
    } else if (url.includes('.7z')) {
      return '.7z';
    } else if (url.includes('.doc') || url.includes('.docx')) {
      return '.docx';
    } else if (url.includes('.xls') || url.includes('.xlsx')) {
      return '.xlsx';
    } else {
      return '.bin';
    }
  }

  // 显示下载完成对话框，让用户选择是否打开文件夹
  private showDownloadCompleteDialogWithChoice() {
    if (!this.currentDownloadPath) {
      return;
    }

    const fileName: string = this.getFileNameFromPath(this.currentDownloadPath);

    promptAction.showDialog({
      title: '下载完成',
      message: `文件 "${fileName}" 已下载完成！\n\n是否要打开下载文件夹？`,
      buttons: [
        {
          text: '打开文件夹',
          color: '#007DFF'
        },
        {
          text: '仅查看',
          color: '#999999'
        }
      ]
    }).then((result) => {
      if (result.index === 0) {
        // 用户点击了"打开文件夹"
        this.openDownloadDirectory();
      } else {
        // 用户点击了"仅查看"，只显示成功消息
        promptAction.showToast({
          message: '文件已保存到下载目录',
          duration: 2000
        });
      }
      this.clearDownloadState();
    });
  }

  // 打开下载目录
  private openDownloadDirectory(): void {
    if (!this.currentDownloadDirUri) {
      console.error("没有下载目录信息");
      promptAction.showToast({
        message: '无法打开下载目录',
        duration: 3000
      });
      return;
    }

    try {
      const context = getContext(this) as common.UIAbilityContext;
      const TAG: string = '[OpenDownloadDirectory]';
      const DOMAIN_NUMBER: number = 0xFF00;

      let openLinkOptions: OpenLinkOptions = {
        parameters: {
          'fileUri': this.currentDownloadDirUri
        }
      };

      console.info(`尝试打开目录: ${this.currentDownloadDirUri}`);

      context.openLink('filemanager://openDirectory', openLinkOptions)
        .then(() => {
          console.info('打开下载目录成功');
          hilog.info(DOMAIN_NUMBER, TAG, 'open download directory success.');
        })
        .catch((err: BusinessError) => {
          console.error(`打开下载目录失败. Code is ${err.code}, message is ${err.message}`);
          hilog.error(DOMAIN_NUMBER, TAG,
            `open download directory failed. Code is ${err.code}, message is ${err.message}`);

          // 如果打开失败，尝试使用默认方式
          this.fallbackOpenDirectory();
        });
    } catch (paramError) {
      const error = paramError as BusinessError;
      console.error(`打开下载目录参数错误. Code is ${error.code}, message is ${error.message}`);
      const TAG: string = '[OpenDownloadDirectory]';
      const DOMAIN_NUMBER: number = 0xFF00;
      hilog.error(DOMAIN_NUMBER, TAG,
        `Failed to open download directory. Code is ${error.code}, message is ${error.message}`);

      // 如果参数错误，尝试使用默认方式
      this.fallbackOpenDirectory();
    }
  }

  // 回退方式打开目录
  private fallbackOpenDirectory(): void {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const TAG: string = '[FallbackOpenDirectory]';
      const DOMAIN_NUMBER: number = 0xFF00;

      // 尝试使用简单的文件管理器URI
      const link: string = 'filemanager://';
      let openLinkOptions: OpenLinkOptions = {};

      context.openLink(link, openLinkOptions)
        .then(() => {
          console.info('成功打开文件管理器');
          hilog.info(DOMAIN_NUMBER, TAG, 'open file manager success.');
        })
        .catch((err: BusinessError) => {
          console.error(`打开文件管理器失败. Code is ${err.code}, message is ${err.message}`);
          hilog.error(DOMAIN_NUMBER, TAG, `open file manager failed. Code is ${err.code}, message is ${err.message}`);
        });
    } catch (error) {
      console.error('回退方式打开目录失败: ' + JSON.stringify(error));
    }
  }

  // 清理下载状态
  private clearDownloadState(): void {
    this.currentDownloadPath = '';
    this.currentDownloadUrl = '';
    this.currentFileName = '';
    this.currentDownloadDirUri = '';
  }

  // 从路径中提取文件名
  private getFileNameFromPath(filePath: string): string {
    const segments: string[] = filePath.split('/');
    return segments[segments.length - 1] || '未知文件';
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
              Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.Center
              }) {
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

                    Text(`文件: ${this.currentFileName}`)
                      .fontSize(12)
                      .fontColor(Color.Gray)
                      .margin({ top: 5 })
                  }
                  .width('100%')
                  .padding(10)
                  .backgroundColor('#F5F5F5')
                  .borderRadius(8)
                  .margin({ bottom: 10 })
                }

                Web({
                  src: AppStorage.get('device_isBle') ? this.getModelInfo.chatChromeUrl :
                    (ConnectDevice.Communication[AppStorage.get('device_currIndex') as number] as DeviceArrayType).getModelInfo?.chatChromeUrl as string,
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