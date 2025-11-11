import { promptAction, screenshot } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { http } from '@kit.NetworkKit';

@Entry
@Component
struct Index {
  @State message: string = '点击按钮开始截图OCR识别';
  @State permissions: Array<Permissions> = ['ohos.permission.CUSTOM_SCREEN_CAPTURE'];
  @State isLoading: boolean = false;

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
      return ''
    }

  }

  /**
   * 将PixelMap保存为文件
   */
  async savePixelMapToFile(pixelMap: image.PixelMap, filePath: string): Promise<void> {
    return new Promise((resolve, reject) => {
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
    return new Promise((resolve, reject) => {
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
   * 上传文件进行OCR识别
   */
  async uploadFileForOCR(filePath: string, language: string): Promise<void> {
    return new Promise((resolve, reject) => {
      const httpRequest = http.createHttp();

      // 订阅响应头事件
      httpRequest.on('headersReceive', (header: Object) => {
        console.info('OCR API Response Header:', JSON.stringify(header));
      });

      const requestUrl = `http://att.miclink.net/api/ocr?language=${encodeURIComponent(language)}`;

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
        readTimeout: 60000
      };

      httpRequest.request(
        requestUrl,
        requestOptions,
        (err: BusinessError, data: http.HttpResponse) => {
          // 清理资源
          httpRequest.off('headersReceive');
          httpRequest.destroy();

          if (err) {
            reject(new Error(`OCR请求失败: ${JSON.stringify(err)}`));
            return;
          }

          try {
            console.info('OCR响应状态码:', data.responseCode);
            console.info('OCR响应数据:', data.result);

            // 解析响应数据
            // let responseData=null
            // if (typeof data.result === 'string') {
            //   responseData = JSON.parse(data.result);
            // } else {
            //   responseData = data.result;
            // }
            //
            // console.info('OCR识别结果:', JSON.stringify(responseData));
            //
            // // 显示识别结果
            // if (responseData && responseData.data) {
            //   this.message = `识别成功: ${JSON.stringify(responseData.data)}`;
            // } else {
            //   this.message = `识别完成，状态: ${responseData.statusCode || data.responseCode}`;
            // }

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
   * 执行OCR识别流程
   */
  async performOCR() {
    if (this.isLoading) {
      return;
    }

    this.isLoading = true;
    this.message = '正在截图...';

    let tempFilePath: string = '';

    try {
      // 1. 截图并保存为文件
      this.message = '正在截图并保存文件...';
      tempFilePath = await this.captureAndSaveToFile();

      // 2. 上传文件进行OCR识别
      this.message = '正在上传并识别文字...';
      await this.uploadFileForOCR(tempFilePath, "ZH_CN");

    } catch (error) {
      console.error('OCR流程失败:', error);
      this.message = `识别失败: ${error.message || JSON.stringify(error)}`;

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
   * 申请权限（使用您提供的简洁方式）
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
            message: '请授权截图权限',
            duration: 2000
          });
          this.message = '需要截图权限才能使用OCR功能';
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
      }
      .width('100%')
      .height('100%')
      .padding(20)
      .alignItems(HorizontalAlign.Center)
    }
  }
}