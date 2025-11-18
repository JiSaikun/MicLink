import { promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { http } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
import { UserLoginInfo } from '../model/UserLoginInfo';

export interface register_Response {
  unionid: string;
  channel: string;
  lastLoginDate: number | null;
  type: string;
  mac: string | null;
  platform: string | null;
  lastLoginIp: string | null;
  password: string;
  now: number;
  registrationId: string | null;
  id: number;
  lastUpdatedBy: string | null;
  address: string | null;
  chatExpiredTime: number;
  openid: string | null;
  totalTime: number;
  sex: string;
  artExpiredTime: number;
  avatar: string | null;
  appleId: string | null;
  version: number;
  expiredTime: number;
  token: string;
  lastUpdatedDate: number | null;
  createdDate: number;
  createdBy: string | null;
  name: string;
  account: string;
  status: number;
}

/**
 * 从相册选择图片
 */
async function fileSelect(): Promise<string> {
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
export async function updateAvatar() {
  try {
    const uri = await fileSelect();
    if (uri) {
      let userLoginInfo = AppStorage.get('userLoginInfo') as UserLoginInfo
      userLoginInfo.avatar = uri
      AppStorage.setOrCreate('userLoginInfo', userLoginInfo)
    }
  } catch (error) {
    console.error('选择图片错误:', error);
  }
}

/**
 * 保存图片到沙箱
 */
async function savePhotoToSandbox(fileUri: string): Promise<string> {
  const context = AppStorage.get('context') as common.UIAbilityContext;
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
    await uploadAvatar(dstPath);

    return dstPath;
  } catch (error) {
    console.error('保存图片到沙箱失败:', JSON.stringify(error));
    throw new Error('保存图片失败');
  }
}

/**
 * 上传头像到服务器
 */
async function uploadAvatar(filePath: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const httpRequest = http.createHttp();

    // 订阅响应头事件
    httpRequest.on('headersReceive', (header: Object) => {
      console.info('头像上传响应头:', JSON.stringify(header));
    });

    // 构建请求URL，包含token参数
    const requestUrl =
      `http://att.miclink.net/api/updateAvatar?token=${encodeURIComponent((AppStorage.get('userLoginInfo') as UserLoginInfo).token)}`;

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
async function deleteTempFile(filePath: string): Promise<void> {
  try {
    await fileIo.unlink(filePath);
    console.info('临时文件已删除:', filePath);
  } catch (error) {
    console.warn('删除临时文件失败:', error);
  }
}

