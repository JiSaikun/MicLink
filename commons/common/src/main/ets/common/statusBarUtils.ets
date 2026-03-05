import { common, contextConstant, StartOptions, Want } from "@kit.AbilityKit";
import { statusBarManager } from "@kit.DeskTopExtensionKit";
import { image } from "@kit.ImageKit";
import { hilog } from "@kit.PerformanceAnalysisKit";

/**
 * @description 获取图片
 * @param { string } name
 * @param { any } context
 * @return { void }
 */
const getPixelMap = async (name: string, context: common.UIAbilityContext) => {
  // 获取resourceManager资源管理器
  const resourceMgr = context.resourceManager;
  // 获取rawfile文件夹下icon.png的ArrayBuffer
  const fileData = resourceMgr.getRawFileContentSync(name);
  // 获取图片的ArrayBuffer
  const buffer = fileData.buffer;
  // 创建imageSource
  const imageSource = image.createImageSource(buffer);
  // 创建PixelMap
  let pixMap = await imageSource.createPixelMap();
  return Promise.resolve(pixMap);
}

/**
 * @description 加载状态栏
 * @param { any } context
 * @return { void }
 */
export const loadStatusBar = async (context: common.UIAbilityContext): Promise<void> => {

  // 设置系统托盘图标信息
  let icon: statusBarManager.StatusBarIcon = {
    white: await getPixelMap("startBarIcon.png", context),
    black: await getPixelMap("startBarIcon.png", context),
  };

  //构建添加到状态栏的图标详细信息
  const operation: statusBarManager.QuickOperation = {
    //abilityName: "MyStatusBarViewAbility", // 指定创建的StatusBarViewExtensionAbility
    abilityName: "", //此处为空，是由于点击左键无须弹出页面，想要直接showability
    title: "backgroundWindowShow", // 左键弹窗标题
    height: 30, // 左键弹窗高度
    moduleName: 'entry' // 可缺省,但不建议，缺省后hover托盘时不会显示abilityName
  }

  //构建右键菜单项内容
  let subMenus: Array<statusBarManager.StatusBarSubMenuItem> = [];
  let subMenuItemAction: statusBarManager.StatusBarMenuAction = {
    abilityName: "EntryAbility",
    moduleName: "entry",
    menuCode: "sub1",
    notifyOnly: true
  }
  let subMenu: statusBarManager.StatusBarSubMenuItem = {
    subTitle: "子菜单项",
    menuAction: subMenuItemAction
  }
  subMenus.push(subMenu);

  let statusBarMenuItems: Array<statusBarManager.StatusBarMenuItem> = [];
  // let menuItem: statusBarManager.StatusBarMenuItem = {
  //   title: "一级菜单项",
  //   // 一级menuAction和subMenu两项不可都缺省
  //   subMenu: subMenus
  // };
  // statusBarMenuItems.push(menuItem);

  let statusBarGroupMenus: Array<statusBarManager.StatusBarGroupMenu> = [];
  statusBarGroupMenus.push(statusBarMenuItems);

  //构建状态栏信息
  const statusBarItem: statusBarManager.StatusBarItem = {
    icons: icon, // 指定图标
    quickOperation: operation, // 指定启动参数
    statusBarGroupMenu: statusBarGroupMenus, //可选，右键菜单项
    hoverTips:"MicLink"
  }
  try {
    statusBarManager.addToStatusBar(context, statusBarItem); // 调用 addToStatusBar 设置系统托盘
    hilog.info(0, 'testTag', 'addToStatusBar success');
    Promise.resolve();
  } catch (error) {
    hilog.error(0, 'testTag', `addToStatusBar failed. error code: ${error.code}, error message: ${error.message}`);
  }

}

/**
 * @description 维持后台状态栏
 * @param { any } context
 * @return { void }
 */
export const holdStatusBar = (context: common.UIAbilityContext | common.UIExtensionContext): Promise<void> => {
  return new Promise((resolve, reject) => {
    let want: Want = {
      bundleName: 'com.miclink.myapplication', // 指定当前应用名
      abilityName: 'BackGroundAbility' // 指定应用的Ability
    };
    let options: StartOptions = {
      processMode: contextConstant.ProcessMode.NEW_PROCESS_ATTACH_TO_STATUS_BAR_ITEM, // 创建一个新进程，在该进程上启动Ability，并绑定该进程到状态栏图标上
      startupVisibility: contextConstant.StartupVisibility.STARTUP_HIDE // 目标Ability启动后，进入隐藏状态。不会调用Ability的onForeground生命周期
    }
    context.startAbility(want, options, (err: BusinessError) => {
      if (err.code) {
        hilog.error(0, 'testTag', `startError:: ${JSON.stringify(err)}}`)
        reject();
      } else {
        hilog.info(0, 'testTag', `startAbility Success`);
        resolve();
      }
    })

  })
}