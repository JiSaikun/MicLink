// import { abilityAccessCtrl, bundleManager, common } from '@kit.AbilityKit';
// import { BusinessError } from '@kit.BasicServicesKit';
//
// export class PermissionManager {
//   private static instance: PermissionManager;
//
//   public static getInstance(): PermissionManager {
//     if (!PermissionManager.instance) {
//       PermissionManager.instance = new PermissionManager();
//     }
//     return PermissionManager.instance;
//   }
//
//   /**
//    * 检查权限状态
//    */
//   async checkPermission(permission: string): Promise<abilityAccessCtrl.GrantStatus> {
//     let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
//     let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;
//
//     try {
//       // 获取应用程序的accessTokenID
//       let tokenId: number = await this.getAccessTokenId();
//       // 校验应用是否被授予权限
//       grantStatus = await atManager.checkAccessToken(tokenId, permission);
//     } catch (error) {
//       const err: BusinessError = error as BusinessError;
//       console.error(`Failed to check permission, code: ${err.code}, message: ${err.message}`);
//     }
//
//     return grantStatus;
//   }
//
//   /**
//    * 获取访问令牌ID
//    */
//   private async getAccessTokenId(): Promise<number> {
//     try {
//       let bundleInfo: bundleManager.BundleInfo = await bundleManager.getBundleInfoForSelf(
//         bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
//       );
//       let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
//       return appInfo.accessTokenId;
//     } catch (error) {
//       const err: BusinessError = error as BusinessError;
//       console.error(`Failed to get access token ID, code: ${err.code}, message: ${err.message}`);
//       throw err;
//     }
//   }
//
//   /**
//    * 向用户申请权限
//    */
//   async requestPermissions(
//     context: common.UIAbilityContext,
//     permissions: Array<string>
//   ): Promise<abilityAccessCtrl.PermissionRequestResult> {
//     let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
//
//     try {
//       const result = await atManager.requestPermissionsFromUser(context, permissions);
//       return result;
//     } catch (error) {
//       const err: BusinessError = error as BusinessError;
//       console.error(`Failed to request permissions, code: ${err.code}, message: ${err.message}`);
//       throw err;
//     }
//   }
//
//   /**
//    * 检查所有权限是否都已授权
//    */
//   async checkAllPermissionsGranted(permissions: Array<string>): Promise<boolean> {
//     for (const permission of permissions) {
//       const status = await this.checkPermission(permission);
//       if (status !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
//         return false;
//       }
//     }
//     return true;
//   }
// }