import { promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { cameraPicker } from '@kit.CameraKit';
import { camera } from '@kit.CameraKit';
import { fileIo } from '@kit.CoreFileKit';
import { http } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
import { UserLoginInfo } from '../model/UserLoginInfo';

/**
 * 调用相机拍照
 */
export async function takePhoto(): Promise<string> {
  const context = AppStorage.get('context') as common.UIAbilityContext;
  if (!context) {
    throw new Error('未获取到上下文');
  }

  try {
    // 配置相机选择器
    let pickerProfile: cameraPicker.PickerProfile = {
      cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK, // 使用后置摄像头
      // 可选：设置保存路径到沙箱
      // saveUri: `${context.cacheDir}/photo_${Date.now()}.jpg`
    };

    // 拉起相机拍照
    let pickerResult: cameraPicker.PickerResult = await cameraPicker.pick(
      context,
      [cameraPicker.PickerMediaType.PHOTO], // 只拍照，不录像
      pickerProfile
    );

    console.info("相机拍照结果:" + JSON.stringify(pickerResult));

    // 检查拍照结果
    if (pickerResult.resultCode === 0 && pickerResult.resultUri) {
      let imgUri = pickerResult.resultUri;
      console.info('拍照成功，图片URI:', imgUri);
      return imgUri;
    } else {
      if (pickerResult.resultCode === -1) {
        promptAction.showToast({
          message: '拍照失败，请重试',
          duration: 1000
        });
      } else {
        // 用户取消拍照
        console.info('用户取消拍照');
      }
      return '';
    }
  } catch (err) {
    console.error('调用相机失败:', JSON.stringify(err));
    promptAction.showToast({
      message: '调用相机失败',
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

          // 这里可以添加对服务器响应的具体处理逻辑
          // 根据实际API响应结构调整判断条件

          promptAction.showToast({
            message: '头像上传成功',
            duration: 2000
          });
          resolve();
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
 * 拍照处理（仅本地更新，不上传）
 */
export async function updateAvatarLocal(): Promise<boolean> {
  try {
    const uri = await takePhoto();
    if (uri) {
      let userLoginInfo = AppStorage.get('userLoginInfo') as UserLoginInfo;
      userLoginInfo.avatar = uri;
      AppStorage.setOrCreate('userLoginInfo', userLoginInfo);
      return true;
    }
    return false;
  } catch (error) {
    console.error('拍照错误:', error);
    promptAction.showToast({
      message: '头像更新失败',
      duration: 2000
    });
    return false;
  }
}

/**
 * 完整的头像更新流程（拍照+上传）
 */
export async function UpdateAvatar_Camera(): Promise<boolean> {
  try {
    const uri = await takePhoto();
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
        message: '请先设置头像',
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