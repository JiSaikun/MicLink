import { promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { http } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct UserAvatar {
  @State imageUri: string = '';
  @State isUploading: boolean = false;
  @State uploadMessage: string = '请选择头像';
  @State token: string = 'your_token_here'; // 需要从用户登录信息中获取

  /**
   * 从相册选择图片
   */
  async fileSelect(): Promise<string> {
    let photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    photoSelectOptions.maxSelectNumber = 1;

    let photoPicker = new photoAccessHelper.PhotoViewPicker();
    try {
      let photoSelectResult = await photoPicker.select(photoSelectOptions);
      if (photoSelectResult && photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
        let imgUri = photoSelectResult.photoUris[0];
        if (imgUri.indexOf('media/Photo') < 0) {
          promptAction.showToast({
            message: '请选择图片进行上传',
            duration: 1000
          });
          return '';
        }
        return imgUri;
      } else {
        promptAction.showToast({
          message: '未选择图片',
          duration: 1000
        });
        return '';
      }
    } catch (err) {
      console.error('选择图片失败:', JSON.stringify(err));
      promptAction.showToast({
        message: '选择图片失败',
        duration: 1000
      });
      return '';
    }
  }

  /**
   * 选择图片处理
   */
  async selectImage() {
    try {
      const uri = await this.fileSelect();
      if (uri) {
        this.imageUri = uri;
        this.uploadMessage = '图片已选择，点击上传';
      }
    } catch (error) {
      console.error('选择图片错误:', error);
    }
  }

  /**
   * 保存图片到沙箱
   */
  async savePhotoToSandbox(fileUri: string): Promise<string> {
    const context = getContext(this) as common.UIAbilityContext;
    // 获取应用的沙箱路径
    let cacheDir = context.cacheDir;
    // 获取文件名
    let imgName = fileUri.split('/').pop() || `avatar_${new Date().getTime()}.jpg`;
    // 图片保存到沙箱中的目标路径
    let dstPath = `${cacheDir}/${imgName}`;

    try {
      // 打开源文件
      let srcFile = await fileIo.open(fileUri, fileIo.OpenMode.READ_ONLY);

      // 创建目标文件
      let dstFile = await fileIo.open(dstPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);

      // 复制文件
      await fileIo.copyFile(srcFile.fd, dstFile.fd);

      // 关闭文件
      await fileIo.close(srcFile.fd);
      await fileIo.close(dstFile.fd);

      console.log('图片已保存到沙箱:', dstPath);
      return dstPath;
    } catch (error) {
      console.error('保存图片到沙箱失败:', JSON.stringify(error));
      throw new Error('保存图片失败');
    }
  }

  /**
   * 上传头像到服务器
   */
  async uploadAvatar(filePath: string): Promise<void> {
    return new Promise((resolve, reject) => {
      const httpRequest = http.createHttp();

      // 订阅响应头事件
      httpRequest.on('headersReceive', (header: Object) => {
        console.info('头像上传响应头:', JSON.stringify(header));
      });

      // 构建请求URL，包含token参数
      const requestUrl = `http://att.miclink.net/api/updateAvatar?token=${encodeURIComponent(this.token)}`;

      const requestOptions: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'multipart/form-data'
        },
        multiFormDataList: [
          {
            name: "avatar",
            contentType: 'image/jpeg',
            filePath: filePath,
            remoteFileName: 'user_avatar.jpg'
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
            reject(new Error(`上传失败: ${JSON.stringify(err)}`));
            return;
          }

          try {
            console.info('上传响应状态码:', data.responseCode);
            console.info('上传响应数据:', data.result);

            // 解析响应数据
            // let responseData: any;
            // if (typeof data.result === 'string') {
            //   responseData = JSON.parse(data.result);
            // } else {
            //   responseData = data.result;
            // }
            //
            // console.info('头像上传结果:', JSON.stringify(responseData));

            // // 处理响应
            // if (data.responseCode === 200 && responseData) {
            //   if (responseData.statusCode === 200) {
            //     resolve();
            //   } else {
            //     reject(new Error(responseData.message || '上传失败'));
            //   }
            // } else {
            //   reject(new Error(`服务器错误: ${data.responseCode}`));
            // }
          } catch (parseError) {
            reject(new Error(`解析响应失败: ${parseError}`));
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
   * 执行头像上传流程
   */
  async performUpload() {
    if (this.isUploading || !this.imageUri) {
      return;
    }

    this.isUploading = true;
    this.uploadMessage = '正在处理图片...';

    let tempFilePath: string = '';

    try {
      // 1. 将图片保存到沙箱
      this.uploadMessage = '正在准备图片...';
      tempFilePath = await this.savePhotoToSandbox(this.imageUri);

      // 2. 上传头像
      this.uploadMessage = '正在上传头像...';
      await this.uploadAvatar(tempFilePath);

      // 3. 上传成功
      this.uploadMessage = '头像上传成功！';
      promptAction.showToast({
        message: '头像更新成功',
        duration: 2000
      });

    } catch (error) {
      console.error('头像上传流程失败:', error);
      this.uploadMessage = `上传失败: ${error.message || JSON.stringify(error)}`;

      promptAction.showToast({
        message: '头像上传失败',
        duration: 3000
      });
    } finally {
      // 清理临时文件
      if (tempFilePath) {
        await this.deleteTempFile(tempFilePath);
      }
      this.isUploading = false;
    }
  }

  build() {
    Column({ space: 20 }) {
      Text('更新头像')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 })

      // 头像预览
      Image(this.imageUri ? this.imageUri : $r('app.media.startIcon'))
        .width(120)
        .height(120)
        .borderRadius(60)
        .objectFit(ImageFit.Cover)
        .backgroundColor('#F0F0F0')
        .onClick(() => this.selectImage())

      Text('点击头像选择图片')
        .fontSize(14)
        .fontColor('#666')

      // 状态信息
      Text(this.uploadMessage)
        .fontSize(16)
        .textAlign(TextAlign.Center)
        .width('90%')
        .margin({ top: 10 })

      // 上传按钮
      Button(this.isUploading ? '上传中...' : '上传头像')
        .width('80%')
        .height(50)
        .backgroundColor(this.isUploading || !this.imageUri ? '#CCCCCC' : '#007DFF')
        .fontColor(Color.White)
        .enabled(!this.isUploading && !!this.imageUri)
        .onClick(() => {
          this.performUpload();
        })
        .margin({ top: 20 })

      // 加载指示器
      if (this.isUploading) {
        LoadingProgress()
          .width(40)
          .height(40)
          .margin({ top: 10 })
      }
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Start)
  }
}