import { promptAction, screenshot } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { http } from '@kit.NetworkKit';

interface wordsModel {
  text: string;
  confidence?: number;
}

interface dataModel {
  words?: wordsModel
}

// 定义明确的类型
interface OcrResponseData {
  data?: dataModel
  message: string;
  statusCode: number;
}

@Entry
@Component
struct Index {
  @State message: string = '点击按钮开始截图OCR识别';
  @State permissions: Array<Permissions> = [
    'ohos.permission.CUSTOM_SCREEN_CAPTURE',
    'ohos.permission.INTERNET'
  ];
  @State isLoading: boolean = false;
  @State ocrResult: string = '';

  /**
   * 截图并保存为文件
   */
  async captureAndSaveToFile(): Promise<string> {
    try {
      const captureOption: screenshot.CaptureOption = {
        displayId: 0
      };

      // 截图
      const pixelMap: image.PixelMap = await screenshot.capture(captureOption);
      console.info('截图成功');

      // 创建临时文件路径
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const filesDir: string = context.filesDir;
      const timestamp: number = new Date().getTime();
      const tempFilePath: string = `${filesDir}/ocr_screenshot_${timestamp}.jpg`;

      // 将PixelMap保存为JPEG文件
      await this.savePixelMapToFile(pixelMap, tempFilePath);
      console.info('文件保存成功:', tempFilePath);

      return tempFilePath;
    } catch (error) {
      console.error('截图或保存文件失败:', JSON.stringify(error));
      this.message = '截图失败，请重试';
      return '';
    }
  }

  /**
   * 将PixelMap保存为文件
   */
  async savePixelMapToFile(pixelMap: image.PixelMap, filePath: string): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      const imagePacker: image.ImagePacker = image.createImagePacker();
      const packOptions: image.PackingOption = {
        format: "image/jpeg",
        quality: 85
      };

      imagePacker.packing(pixelMap, packOptions, (err: BusinessError, data: ArrayBuffer) => {
        if (err) {
          reject(err);
          return;
        }

        // 将ArrayBuffer写入文件
        this.writeArrayBufferToFile(data, filePath)
          .then(() => resolve())
          .catch(reject);
      });
    });
  }

  /**
   * 将ArrayBuffer写入文件
   */
  async writeArrayBufferToFile(buffer: ArrayBuffer, filePath: string): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      // 创建文件
      fileIo.open(filePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)
        .then((file: fileIo.File) => {
          // 写入数据
          fileIo.write(file.fd, buffer)
            .then(() => {
              // 关闭文件
              fileIo.close(file.fd);
              resolve();
            })
            .catch((error: BusinessError) => {
              fileIo.close(file.fd);
              reject(error);
            });
        })
        .catch(reject);
    });
  }

  /**
   * 上传文件进行OCR识别 - 添加网络错误处理
   */
  async uploadFileForOCR(filePath: string, language: string): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      const httpRequest = http.createHttp();

      // 订阅响应头事件
      httpRequest.on('headersReceive', (header: object) => {
        console.info('OCR API Response Header:', JSON.stringify(header));
      });

      // 测试网络连接
      const requestUrl = `http://att.miclink.net/api/ocr?language=${encodeURIComponent(language)}`;
      console.info('尝试请求URL:', requestUrl);

      const requestOptions: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'multipart/form-data'
        },
        multiFormDataList: [
          {
            name: "file",
            contentType: 'image/jpeg',
            filePath: filePath,
            remoteFileName: 'ocr_image.jpg'
          }
        ],
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 30000,
        readTimeout: 60000,
        usingProxy: false // 明确不使用代理
      };

      httpRequest.request(
        requestUrl,
        requestOptions,
        (err: BusinessError, data: http.HttpResponse) => {
          // 清理资源
          httpRequest.off('headersReceive');
          httpRequest.destroy();

          if (err) {
            console.error('HTTP请求详细错误:', JSON.stringify(err));

            // 根据错误码提供更具体的错误信息
            let errorMessage = `OCR请求失败: ${err.message}`;
            if (err.code === 2300006) {
              errorMessage = '网络连接失败：无法解析域名，请检查网络连接和URL地址';
            } else if (err.code === 2300008) {
              errorMessage = '网络连接超时，请检查网络状况';
            } else if (err.code === 2300001) {
              errorMessage = '网络不可用，请检查网络连接';
            }

            reject(new Error(errorMessage));
            return;
          }

          try {
            console.info('OCR响应状态码:', data.responseCode);
            console.info('OCR完整响应数据:', JSON.stringify(data));

            // 解析响应数据 - 使用明确的类型
            if (data.result) {
              let responseData: OcrResponseData;
              if (typeof data.result === 'string') {
                responseData = JSON.parse(data.result) as OcrResponseData;
              } else {
                responseData = data.result as OcrResponseData;
              }

              console.info('OCR识别结果:', JSON.stringify(responseData));

              // 显示识别结果
              if (responseData && responseData.data) {
                this.ocrResult = JSON.stringify(responseData.data);
                this.message = `识别成功！状态码: ${data.responseCode}`;
              } else {
                this.message = `请求完成，状态码: ${data.responseCode}`;
              }
            } else {
              this.message = `请求完成，状态码: ${data.responseCode}`;
            }

            resolve();
          } catch (parseError) {
            reject(new Error(`解析OCR响应失败: ${parseError}`));
          }
        }
      );
    });
  }

  /**
   * 删除临时文件
   */
  async deleteTempFile(filePath: string): Promise<void> {
    try {
      await fileIo.unlink(filePath);
      console.info('临时文件已删除:', filePath);
    } catch (error) {
      console.warn('删除临时文件失败:', error);
    }
  }

  /**
   * 测试网络连接
   */
  async testNetworkConnection(): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      const testRequest = http.createHttp();
      const testUrl = 'http://www.baidu.com'; // 使用知名网站测试网络

      testRequest.request(
        testUrl,
        { method: http.RequestMethod.GET, readTimeout: 10000 },
        (err: BusinessError) => {
          testRequest.destroy();
          if (err) {
            reject(new Error('网络连接失败，请检查设备网络设置'));
          } else {
            resolve();
          }
        }
      );
    });
  }

  /**
   * 执行OCR识别流程 - 添加网络检查
   */
  async performOCR(): Promise<void> {
    if (this.isLoading) {
      return;
    }

    this.isLoading = true;
    this.message = '正在检查网络...';
    this.ocrResult = '';

    // 先进行简单的网络检查
    try {
      await this.testNetworkConnection();
    } catch (networkError) {
      this.isLoading = false;
      this.message = (networkError as Error).message;
      promptAction.showToast({
        message: '网络连接失败',
        duration: 3000
      });
      return;
    }

    let tempFilePath: string = '';

    try {
      // 1. 截图并保存为文件
      this.message = '正在截图并保存文件...';
      tempFilePath = await this.captureAndSaveToFile();

      if (!tempFilePath) {
        throw new Error('截图失败');
      }

      // 2. 上传文件进行OCR识别
      this.message = '正在上传并识别文字...';
      await this.uploadFileForOCR(tempFilePath, "ZH_CN");

    } catch (error) {
      console.error('OCR流程失败:', error);
      this.message = (error as Error).message || '识别失败，请重试';

      promptAction.showToast({
        message: 'OCR识别失败',
        duration: 3000
      });
    } finally {
      // 清理临时文件
      if (tempFilePath) {
        await this.deleteTempFile(tempFilePath);
      }
      this.isLoading = false;
    }
  }

  /**
   * 申请权限
   */
  reqPermissionsFromUser(permissions: Array<Permissions>, context: common.UIAbilityContext): void {
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();

    atManager.requestPermissionsFromUser(context, permissions).then((data) => {
      let grantStatus: Array<number> = data.authResults;
      let length: number = grantStatus.length;

      for (let i = 0; i < length; i++) {
        if (grantStatus[i] === 0) {
          // 用户授权，执行OCR识别
          this.performOCR();
        } else {
          // 用户拒绝授权
          promptAction.showToast({
            message: '请授权截图和网络权限',
            duration: 2000
          });
          this.message = '需要截图和网络权限才能使用OCR功能';
          return;
        }
      }
    }).catch((err: BusinessError) => {
      console.error(`权限申请失败: ${err.code}, ${err.message}`);
      promptAction.showToast({
        message: '权限申请失败',
        duration: 2000
      });
    });
  }

  build() {
    Scroll() {
      Column({ space: 20 }) {
        Text('OCR文字识别')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

        Text(this.message)
          .fontSize(16)
          .textAlign(TextAlign.Center)
          .width('90%')

        if (this.ocrResult) {
          Text('识别结果:')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .width('90%')
            .textAlign(TextAlign.Start)

          TextArea({ text: this.ocrResult })
            .width('90%')
            .height(200)
            .fontSize(14)
            .backgroundColor('#F5F5F5')
            .border({ width: 1, color: '#E0E0E0' })
            .padding(10)
        }

        Button(this.isLoading ? '处理中...' : '开始截图OCR识别')
          .width('80%')
          .height(50)
          .backgroundColor(this.isLoading ? '#CCCCCC' : '#007DFF')
          .fontColor(Color.White)
          .enabled(!this.isLoading)
          .onClick(() => {
            const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
            this.reqPermissionsFromUser(this.permissions, context);
          })

        if (this.isLoading) {
          LoadingProgress()
            .width(40)
            .height(40)
        }

        // 网络状态提示
        Text('请确保设备已连接到互联网')
          .fontSize(12)
          .fontColor('#999999')
          .width('90%')
          .textAlign(TextAlign.Center)
          .margin({ top: 20 })
      }
      .width('100%')
      .height('100%')
      .padding(20)
      .alignItems(HorizontalAlign.Center)
    }
  }
}