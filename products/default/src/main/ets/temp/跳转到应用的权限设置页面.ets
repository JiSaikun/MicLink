import { common } from "@kit.AbilityKit"

/**
 * 检索信息中系统设置界面的标准跳转参数为：
 * bundleName: "com.huawei.hmos.settings",
 * abilityName: "com.huawei.hmos.settings.MainAbility", // 需完整Ability名称
 * uri: "application_info_entry" // 关键参数，指定跳转目标
 */
export function sheZhi() {
  let context = getContext() as common.UIAbilityContext
  context.startAbility({
    bundleName: "com.huawei.hmos.settings",//被拉起方的应用包名。
      abilityName: "com.huawei.hmos.settings.MainAbility", //abilityName 必须完整匹配
    uri: 'application_info_entry', //决定具体子页面，不可省略
    parameters: {
      pushParams: context.abilityInfo.bundleName//应用包名
    }
  })
}