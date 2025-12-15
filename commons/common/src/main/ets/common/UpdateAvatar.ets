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
export async function fileSelect(): Promise<string> {
  let photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
  photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
  photoSelectOptions.maxSelectNumber = 1; // 最多选择1个文件
  // photoSelectOptions.isPhotoTakingSupported = false; // 隐藏拍照功能

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
 * 保存图片到沙箱
 */
async function savePhotoToSandbox(fileUri: string): Promise<string> {
  const context = AppStorage.get('context') as common.UIAbilityContext;
  if (!context) {
    throw new Error('未获取到上下文');
  }

  // 获取应用的沙箱路径
  let cacheDir = context.cacheDir;
  // 生成唯一文件名
  let imgName = `avatar_${Date.now()}.jpg`;
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
export async function uploadAvatar(filePath: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const httpRequest = http.createHttp();

    // 订阅响应头事件
    httpRequest.on('headersReceive', (header: Object) => {
      console.info('头像上传响应头:', JSON.stringify(header));
    });

    const userLoginInfo = AppStorage.get('userLoginInfo') as UserLoginInfo;
    if (!userLoginInfo?.token) {
      reject(new Error('用户未登录'));
      return;
    }

    const requestUrl = `http://att.miclink.net/api/updateAvatar?token=${encodeURIComponent(userLoginInfo.token)}`;

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
          remoteFileName: `avatar_${Date.now()}.jpg`
        }
      ],
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: 30000,
      readTimeout: 60000
    };

    httpRequest.request(
      requestUrl,
      requestOptions,
      async (err: BusinessError, data: http.HttpResponse) => {
        // 清理资源
        httpRequest.off('headersReceive');
        httpRequest.destroy();

        // 无论上传成功与否，都删除临时文件
        try {
          await deleteTempFile(filePath);
        } catch (deleteError) {
          console.warn('删除临时文件失败:', deleteError);
        }

        if (err) {
          reject(new Error(`上传失败: ${JSON.stringify(err)}`));
          return;
        }

        try {
          console.info('上传响应状态码:', data.responseCode);
          console.info('上传响应数据:', data.result);

          // // 解析响应数据
          // let responseData: any;
          // if (typeof data.result === 'string') {
          //   responseData = JSON.parse(data.result);
          // } else {
          //   responseData = data.result;
          // }

          // console.info('头像上传结果:', JSON.stringify(responseData));
          //
          // // 根据实际API响应结构调整这里的判断条件
          // if (data.responseCode === 200 && responseData) {
          //   // 假设成功返回 statusCode 为 200
          //   if (responseData.statusCode === 200) {
          //     // 如果服务器返回新的头像URL，更新本地存储
          //     if (responseData.data?.avatarUrl) {
          //       let userInfo = AppStorage.get('userLoginInfo') as UserLoginInfo;
          //       userInfo.avatar = responseData.data.avatarUrl;
          //       AppStorage.setOrCreate('userLoginInfo', userInfo);
          //     }
          //
          //     promptAction.showToast({
          //       message: '头像上传成功',
          //       duration: 2000
          //     });
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

/**
 * 选择图片处理（仅本地更新，不上传）
 */
export async function updateAvatarLocal(): Promise<boolean> {
  try {
    const uri = await fileSelect();
    if (uri) {
      let userLoginInfo = AppStorage.get('userLoginInfo') as UserLoginInfo;
      userLoginInfo.avatar = uri;
      AppStorage.setOrCreate('userLoginInfo', userLoginInfo);
      return true;
    }
    return false;
  } catch (error) {
    console.error('选择图片错误:', error);
    promptAction.showToast({
      message: '头像更新失败',
      duration: 2000
    });
    return false;
  }
}

/**
 * 完整的头像更新流程（选择+上传）
 */
export async function updateAvatar(): Promise<boolean> {
  try {
    const uri = await fileSelect();
    if (!uri) {
      return false;
    }

    // 先更新本地显示
    let userLoginInfo = AppStorage.get('userLoginInfo') as UserLoginInfo;
    userLoginInfo.avatar = uri;
    AppStorage.setOrCreate('userLoginInfo', userLoginInfo);

    // 保存到沙箱并上传
    const sandboxPath = await savePhotoToSandbox(uri);
    await uploadAvatar(sandboxPath);

    return true;
  } catch (error) {
    console.error('完整头像更新流程错误:', error);

    let errorMessage = '头像更新失败';
    if (error instanceof Error) {
      errorMessage = error.message;
    }

    promptAction.showToast({
      message: errorMessage,
      duration: 3000
    });

    return false;
  }
}

/**
 * 仅上传已选择的头像（用于重新上传等场景）
 */
export async function uploadExistingAvatar(): Promise<boolean> {
  try {
    const userLoginInfo = AppStorage.get('userLoginInfo') as UserLoginInfo;
    if (!userLoginInfo?.avatar) {
      promptAction.showToast({
        message: '请先选择头像',
        duration: 2000
      });
      return false;
    }

    const sandboxPath = await savePhotoToSandbox(userLoginInfo.avatar);
    await uploadAvatar(sandboxPath);
    return true;
  } catch (error) {
    console.error('上传现有头像错误:', error);

    let errorMessage = '头像上传失败';
    if (error instanceof Error) {
      errorMessage = error.message;
    }

    promptAction.showToast({
      message: errorMessage,
      duration: 3000
    });

    return false;
  }
}

/**
 * 检查用户登录状态
 */
function checkUserLogin(): boolean {
  const userLoginInfo = AppStorage.get('userLoginInfo') as UserLoginInfo;
  return !!(userLoginInfo && userLoginInfo.token);
}

/**
 * 获取当前用户头像
 */
export function getCurrentAvatar(): string {
  const userLoginInfo = AppStorage.get('userLoginInfo') as UserLoginInfo;
  return userLoginInfo?.avatar || '';
}