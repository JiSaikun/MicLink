import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import notification from '@ohos.notification';

const TAG: string = '[Notification]';
const DOMAIN_NUMBER: number = 0xFF00;

export class Notification {
  static state:boolean=false
  static async init(): Promise<boolean> {
    try {
      let context = AppStorage.get('context') as common.UIAbilityContext;

      // Check if notifications are enabled
      const isEnabled = await notificationManager.isNotificationEnabled();
      hilog.info(DOMAIN_NUMBER, TAG, "isNotificationEnabled success, data: " + JSON.stringify(isEnabled));

      // If already enabled, return true
      if (isEnabled) {
        // // addSlot回调
        // let addSlotCallBack = (err: BusinessError): void => {
        //   if (err) {
        //     hilog.error(DOMAIN_NUMBER, TAG, `创建指定类型的通知渠道失败:addSlot failed, code is ${err.code}, message is ${err.message}`);
        //   } else {
        //     hilog.info(DOMAIN_NUMBER, TAG, `创建指定类型的通知渠道成功:addSlot success`);
        //     // getSlot回调
        // let getSlotCallback = (err: BusinessError, data: notificationManager.NotificationSlot): void => {
        //   if (err) {
        //     hilog.error(DOMAIN_NUMBER, TAG, `Failed to get slot. Code is ${err.code}, message is ${err.message}`);
        //   } else {
        //     hilog.info(DOMAIN_NUMBER, TAG, `Succeeded in getting slot.`);
        //     if (data != null) {
        //       hilog.info(DOMAIN_NUMBER, TAG, `slot enable status is ${JSON.stringify(data.enabled)}`);
        //       hilog.info(DOMAIN_NUMBER, TAG, `vibrationEnabled status is ${JSON.stringify(data.vibrationEnabled)}`);
        //       hilog.info(DOMAIN_NUMBER, TAG, `lightEnabled status is ${JSON.stringify(data.lightEnabled)}`);
        //     }
        //   }
        // }
        // let slotType: notificationManager.SlotType = notificationManager.SlotType.SERVICE_INFORMATION;
        // notificationManager.getSlot(slotType, getSlotCallback);
        //   }
        // }
        // // notificationManager.addSlot(notificationManager.SlotType.SERVICE_INFORMATION, addSlotCallBack);
        return true;
      }

      // If not enabled, request to enable them
      try {
        await notificationManager.requestEnableNotification(context);
        hilog.info(DOMAIN_NUMBER, TAG, `[ANS] requestEnableNotification success`);
        return true;
      } catch (err) {
        const businessErr = err as BusinessError;
        if (businessErr.code === 1600004) {
          hilog.error(DOMAIN_NUMBER, TAG, `[ANS]请求启用通知被拒绝, code is ${businessErr.code}, message is ${businessErr.message}`);
          // removeSlot回调
          let removeSlotCallback = (err: BusinessError): void => {
            if (err) {
              hilog.error(DOMAIN_NUMBER, TAG, `删除指定类型的通知渠道失败：removeSlot failed, code is ${JSON.stringify(err.code)}, message is ${JSON.stringify(err.message)}`);
            } else {
              hilog.info(DOMAIN_NUMBER, TAG, "删除指定类型的通知渠道成功： removeSlot success");
            }
          }
          let slotType: notificationManager.SlotType = notificationManager.SlotType.SERVICE_INFORMATION;
          notificationManager.removeSlot(slotType, removeSlotCallback);
        } else {
          hilog.error(DOMAIN_NUMBER, TAG,
            `[ANS] requestEnableNotification failed, code is ${businessErr.code}, message is ${businessErr.message}`);
        }
        return false;
      }
    } catch (err) {
      const businessErr = err as BusinessError;
      hilog.error(DOMAIN_NUMBER, TAG, `isNotificationEnabled fail, code is ${businessErr.code}, message is ${businessErr.message}`);
      return false;
    }
  }
  static async setOrCreate(title:string='',text:string='',additionalText=''){
    let notificationRequest: notificationManager.NotificationRequest = {
      id: 1,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT, // 普通文本类型通知
        normal: {
          title: title,
          text: text,
          additionalText: additionalText,
        }
      },notificationSlotType:notificationManager.SlotType.SERVICE_INFORMATION,
      sound:''
    };
    notificationManager.publish(notificationRequest, (err: BusinessError) => {
      if (err) {
        hilog.error(DOMAIN_NUMBER, TAG, `Failed to publish notification. Code is ${err.code}, message is ${err.message}`);
        return;
      }
      hilog.info(DOMAIN_NUMBER, TAG, 'Succeeded in publishing notification.');
    });
  }
  static async clear(){
    // 当拉起应用到前台，查看消息后，调用该接口取消通知。
    notificationManager.cancel(1, (err: BusinessError) => {
      if (err) {
        hilog.error(DOMAIN_NUMBER, TAG, `Failed to cancel notification. Code is ${err.code}, message is ${err.message}`);
        return;
      }
      hilog.info(DOMAIN_NUMBER, TAG, 'Succeeded in canceling notification.');
    });
  }
}