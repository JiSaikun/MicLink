import { common } from "@kit.AbilityKit";
import bundleManager from '@ohos.bundle.bundleManager';
import { updateManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from "@kit.ArkUI";
import { Languages } from "config";

export class AppUtil {
  private static context: common.UIAbilityContext; //common.UIAbilityContext，上下文

  /**
   * 初始化方法,缓存全局变量，在UIAbility的onCreate方法中初始化该方法。
   * @param windowStage 窗口管理器
   */
  static init(context: common.UIAbilityContext) {
    AppUtil.context = context;
  }

  /**
   * 获取当前应用的BundleInfo
   */
  static getBundleInfoSync(): bundleManager.BundleInfo {
    const bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION |
    bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_ABILITY |
    bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_EXTENSION_ABILITY |
    bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_HAP_MODULE |
    bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_METADATA |
    bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION |
    bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_SIGNATURE_INFO |
    bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_ROUTER_MAP |
    bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_MENU |
    bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_SKILL |
    bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_DISABLE;
    return bundleManager.getBundleInfoForSelfSync(bundleFlags);
  }

  /**
   * 获取应用版本号。
   */
  static getVersionCode(): number {
    return AppUtil.getBundleInfoSync().versionCode;
  }

  /**
   * 获取应用版本名。
   */
  static getVersionName(): string {
    return AppUtil.getBundleInfoSync().versionName;
  }

  /**
   * 检测应用新版本
   */
  static checkAppUpdate() {
    try {
      updateManager.checkAppUpdate(AppUtil.context)
        .then((checkResult: updateManager.CheckUpdateResult) => {
          hilog.info(0, 'TAG', "Succeeded in checking Result updateAvailable:" + checkResult.updateAvailable);
          if (checkResult.updateAvailable === updateManager.UpdateAvailableCode.LATER_VERSION_NOT_EXIST) {
            promptAction.showToast({ message: Languages.alreadyLatestVersion[AppStorage.get('languages')as string] });
            return
          } else if (checkResult.updateAvailable === updateManager.UpdateAvailableCode.LATER_VERSION_EXIST) {
            AppUtil.showUpdateDialog()
          }
        }).catch((error: BusinessError) => {
        hilog.error(0, 'TAG', `checkAppUpdate onError.code is ${error.code}, message is ${error.message}`);
      });
    } catch (error) {
      hilog.error(0, 'TAG', `checkAppUpdate onError.code is ${error.code}, message is ${error.message}`);
    }
  }

  /**
   * 检测应用新版本
   */
  static showUpdateDialog() {
    try {
      updateManager.showUpdateDialog(AppUtil.context)
        .then((resultCode: updateManager.ShowUpdateResultCode) => {
          hilog.info(0, 'TAG', "Succeeded in showing UpdateDialog resultCode:" + resultCode);
        })
        .catch((error: BusinessError) => {
          hilog.error(0, 'TAG', `showUpdateDialog onError.code is ${error.code}, message is ${error.message}`);
        });
    } catch (error) {
      hilog.error(0, 'TAG', `showUpdateDialog onError.code is ${error.code}, message is ${error.message}`);
    }
  }
}