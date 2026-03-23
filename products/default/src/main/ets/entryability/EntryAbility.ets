import { AbilityConstant, ConfigurationConstant, UIAbility, Want, WantAgent, wantAgent, common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BusinessError, commonEventManager, emitter } from '@kit.BasicServicesKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { AppUtil, holdStatusBar, loadStatusBar, setupNetworkStatusListener } from 'common';
import { statusBarManager } from '@kit.DeskTopExtensionKit';
import { DeviceArrayType_Ble } from 'bluetooth';
import { bundleManager } from '@kit.AbilityKit';

// import fs from '@ohos.file.fs';

const DOMAIN = 0x0000;
let global_context: common.UIAbilityContext;
let myWindowStage: window.WindowStage | undefined = undefined;
let isAuto: boolean = false;
let isFirst: boolean = true;
let isLoadContent: boolean = false;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    global_context = this.context;
    bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_SIGNATURE_INFO)
      .then((RES) => {
        console.log('软件信息获取:', JSON.stringify(RES.signatureInfo.appId))
      })
    //判断是否开机自启
    if (want.parameters?.['ohos.aafwk.param.callerNativeName'] === '_foundation') { // 开机自启
      isAuto = true;
    }
    //加载系统托盘
    loadStatusBar(this.context).then(() => {
      //注册状态栏图标左键点击事件
      statusBarManager.on("statusBarIconClick", onStatusBarIconClick);
      setTimeout(() => {
        //维系系统托盘
        holdStatusBar(this.context).then(() => {
          // if(isAuto){ //若开机自启，则隐藏到托盘hideAbility，并且不loadContent，不显示主界面【代码在onWindowStageCreate】
          //   this.context.hideAbility().then(() => {
          //     hilog.info(0x0000, 'testTag', `hideAbility success`);
          //   }).catch((err: BusinessError) => {
          //     hilog.error(0x0000, 'testTag', `hideAbility fail, code is ${err.code}, message is ${err.message}`);
          //   });
          // }
        });
      }, 500);
    });
    hilog.info(0x0000, 'testTag', '%{public}s', 'EntryAbility onCreate');


    setupNetworkStatusListener() //监听网络变化

    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    AppUtil.init(this.context)
    // if (want.uri) { //申请允许其他应用的文件导入到本应用中。
    //   const fileUri = want.uri; // 获取文件URI
    //   console.warn('获取文件URI:'+fileUri)
    //   try {
    //     // const file = fs.openSync(fileUri, fs.OpenMode.READ_WRITE); // 打开文件
    //     // 后续处理（如读取内容、渲染界面等）
    //   } catch (error) {
    //     console.error(`File open failed: ${error.message}`);
    //   }
    // }

    /**
     * 申请长时任务
     */
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      // 点击通知后，将要执行的动作列表
      wants: [
        {
          bundleName: "com.miclink.HOS.MicLink", // 目标应用包名（必填）
          abilityName: "EntryAbility"// 目标Ability名称（必填）
        }
      ],
      // 点击通知后，动作类型
      actionType: wantAgent.OperationType.START_ABILITY, // 明确操作类型为启动Ability
      // 使用者自定义的一个私有值
      requestCode: 0,
      // 点击通知后，动作执行属性
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };

    try {
      // 通过wantAgent模块下getWantAgent方法获取WantAgent对象
      // 在元服务中，请使用wantAgent.getWantAgent(wantAgentInfo).then((wantAgentObj: object) => {替换下面一行代码
      wantAgent.getWantAgent(wantAgentInfo).then((wantAgentObj: WantAgent) => {
        try {
          backgroundTaskManager.startBackgroundRunning(this.context,
            backgroundTaskManager.BackgroundMode.BLUETOOTH_INTERACTION, wantAgentObj, callback)
        } catch (error) {
          console.error(`执行startBackgroundRunning失败. code is ${(error as BusinessError).code} message is ${(error as BusinessError).message}`);
        }
      });
    } catch (error) {
      console.error(`执行getWandAgent失败. code is ${(error as BusinessError).code} message is ${(error as BusinessError).message}`);
    }


  }

  /*
   * 在onCreate()中注册了状态栏图标左键点击事件后，onPrepareToTerminate()中调用hideAbility并且在该回调中
   * 返回true阻拦此次关闭，可实现关闭应用之后，点击托盘，再显示应用界面到前台的效果。
   * ！！！注意：此做法会引入一个问题，即该回调返回true会导致用户点击Dock栏/托盘右键退出应用时，出现BackgroundAbility销毁，
   * 但是EntryAbility不销毁的情况，因此需要在合适时机主动调用terminateSelf接口关闭EntryAbility.
   * ！！！解决方法：在BackgroundAbility的onPrepareToTerminate()中发布公共事件，告知EntryAblity，
   * BackgroundAbility要销毁了，EntryAbility调用this.context.terminateSelf()主动销毁自己，相关代码本demo写在onWindowStageCreate中
   */
  onPrepareToTerminate(): boolean {
    hilog.info(0x0000, 'testTag', '%{public}s', 'EntryAbility onPrepareToTerminate');

    // 隐藏应用
    this.context.hideAbility().then(() => {
      hilog.info(0, 'testTag', 'entry hideAbility success');
    }).catch((err: BusinessError) => {
      hilog.error(0, 'testTag', `hideAbility fail, err: ${JSON.stringify(err)}`);
    });
    return true;
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    window.getLastWindow(this.context).then((data: window.Window) => {
      let uiContext = data.getUIContext(); // 获取 UIContext
      AppStorage.setOrCreate('uiContext', uiContext); // 存储到应用全局变量
    });

    // 用于保存创建成功的订阅者对象，后续使用其完成订阅及退订的动作
    let subscriber: commonEventManager.CommonEventSubscriber | null = null;
    // 订阅者信息，其中的event字段需要替换为实际的事件名称。
    let subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: ['com.miclink.HOS.MicLink.BackgroundAbility_onPrepareToTerminate_event'], // 订阅BackgroundAbility onPrepareToTerminate公共事件
    };
    // 创建订阅者回调
    commonEventManager.createSubscriber(subscribeInfo,
      (err: BusinessError, data: commonEventManager.CommonEventSubscriber) => {
        if (err) {
          hilog.error(0, 'testTag', `Failed to create subscriber. Code is ${err.code}, message is ${err.message}`);
          return;
        }
        hilog.info(0, 'testTag', 'Succeeded in creating subscriber.');
        subscriber = data;
        // 订阅公共事件回调
        if (subscriber !== null) {
          commonEventManager.subscribe(subscriber, (err: BusinessError, data: commonEventManager.CommonEventData) => {
            if (err) {
              hilog.error(0, 'testTag',
                `Failed to subscribe common event. Code is ${err.code}, message is ${err.message}`);
              return;
            }
            // 清理蓝牙资源
            const currentDevices = AppStorage.get('devices') as DeviceArrayType_Ble[] || [];
            currentDevices.forEach(async (device: DeviceArrayType_Ble) => {
              try {
                if (device && device.BlueTooth_devices) {
                  hilog.info(0, 'testTag', `清理蓝牙设备资源: ${device.BlueTooth_devices.device_address}`);
                  await device.BlueTooth_devices.closeconnectDevice();
                }
              } catch (error) {
                hilog.error(0, 'testTag', `清理蓝牙设备资源失败: ${JSON.stringify(error)}`);
              }
            });

            statusBarManager.removeFromStatusBar(this.context); //移除托盘
            setTimeout(() => {
              this.context.terminateSelf(); //订阅BackgroundAbility onPrepareToTerminate公共事件后，主动关闭EntryAbility
            }, 200)
          })
        } else {
          hilog.error(0, 'testTag', `Need create subscriber`);
        }
      })
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'testTag', '%{public}s', 'EntryAbility onWindowStageCreate');

    myWindowStage = windowStage;
    // if(!isAuto){ //非开机自启，才loadContent，显示主界面，否则不loadContent
    isLoadContent = true;
    // }
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'EntryAbility onForeground');
    // if ( isAuto && !isFirst && !isLoadContent ){ //若开机自启，首次onForeground不需要loadContent；非首次onForeground且没有loadContent，则点击图标时loadContent
    //   myWindowStage?.loadContent('pages/Index', (err) => {
    //     if (err.code) {
    //       hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
    //       return;
    //     }
    //     hilog.info(0x0000, 'testTag', 'onForeground Succeeded in loading the content.');
    //   });
    //   isLoadContent = true;
    // }
    isFirst = false;
  }


  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}

function callback(error: BusinessError, data: void) {
  if (error) {
    console.error(`操作开始后台运行失败. code is ${error.code} message is ${error.message}`);
  } else {
    console.info("操作开始后台运行成功");
  }
}

export function myShowUiAbility() {
  // if( isAuto && !isLoadContent){ //若开机自启且没有loadContent，则点击托盘时loadContent
  //   myWindowStage?.loadContent('pages/Index', (err) => {
  //     if (err.code) {
  //       hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
  //       return;
  //     }
  //     hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
  //   });
  //   isLoadContent = true;
  // }
  if (global_context) {
    global_context.showAbility().then(() => {
      hilog.info(0x0000, 'testTag', 'Succeeded in myShowUiAbility.');
    }).catch((err: Error) => {
      hilog.error(0x0000, 'testTag', 'Failed to load myShowUiAbility. Cause: %{public}s', JSON.stringify(err) ?? '');
    });
  }
}

export const onStatusBarIconClick = (eventData: emitter.EventData) => {
  console.log("testTag 走进回调")
  // 自定义图标点击业务
  let data = eventData.data;
  if (data) {
    switch (data['iconClickType']) {
      case 'leftClick':
        myShowUiAbility(); //点击托盘图标，showAbility
        break;
      default:
        break;
    }
  }
}
