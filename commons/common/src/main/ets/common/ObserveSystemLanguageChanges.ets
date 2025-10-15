/**
 *获取以及监听系统语言的改变
 */
import { i18n } from "@kit.LocalizationKit";
import { BusinessError, commonEventManager } from "@kit.BasicServicesKit";

export function observeSystemLanguageChanges() {
  // 获取系统语言
  let systemLanguage: string = i18n.System.getSystemLanguage();
  console.log('系统语言：', systemLanguage)
  switch (systemLanguage) {
    case 'zh-Hans':
      AppStorage.setOrCreate('languages', 'ZH_CN')
      break
    case 'zh-Hant':
      AppStorage.setOrCreate('languages', 'ZH_TW')
      break
    default:
      AppStorage.setOrCreate('languages', 'EN_US')
  }
  // 创建订阅者
  let subscriber: commonEventManager.CommonEventSubscriber;
  let subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
    events: [commonEventManager.Support.COMMON_EVENT_LOCALE_CHANGED]
  };
  commonEventManager.createSubscriber(subscribeInfo)
    .then((sub: commonEventManager.CommonEventSubscriber) => {
      subscriber = sub;
      // 订阅语言变更事件
      commonEventManager.subscribe(subscriber, (err: BusinessError) => {
        if (err) {
          console.error(`订阅失败，错误码: ${err.code}, 信息: ${err.message}`);
          return;
        }
        console.info("系统语言/区域已变化"); // 此处更新UI或重载资源
        // 获取系统语言
        let systemLanguage: string = i18n.System.getSystemLanguage();
        console.log('系统语言：', systemLanguage)
        switch (systemLanguage) {
          case 'zh-Hans':
            AppStorage.setOrCreate('languages', 'ZH_CN')
            break
          case 'zh-Hant':
            AppStorage.setOrCreate('languages', 'ZH_TW')
            break
          default:
            AppStorage.setOrCreate('languages', 'EN_US')
        }
      });
    })
    .catch((err: BusinessError) => {
    });
}