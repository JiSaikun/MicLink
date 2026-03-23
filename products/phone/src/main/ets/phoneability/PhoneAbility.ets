import { AbilityConstant, UIAbility, Want, WantAgent, wantAgent } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Notification } from 'config';
import { setupNetworkStatusListener } from 'common';
import { WXApi, WXEventHandler } from 'api';

// import fs from '@ohos.file.fs';

const DOMAIN = 0x0000;

export default class PhoneAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    Notification.init()
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    this.handleWeChatCallIfNeed(want) //微信支付
    // if (want.uri) {
    //   const fileUri = want.uri; // 获取文件URI
    //   try {
    //     const file = fs.openSync(fileUri, fs.OpenMode.READ_WRITE); // 打开文件
    //     // 后续处理（如读取内容、渲染界面等）
    //   } catch (error) {
    //     console.error(`File open failed: ${error.message}`);
    //   }
    // }

  }

  onNewWant(want: Want, _launchParam: AbilityConstant.LaunchParam): void {
    this.handleWeChatCallIfNeed(want)
  }

  private handleWeChatCallIfNeed(want: Want) {
    WXApi.handleWant(want, WXEventHandler)
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    setupNetworkStatusListener() //监听网络变化

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
    if (!AppStorage.get('Backgrounding')) {
      return
    }
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      // 点击通知后，将要执行的动作列表
      wants: [
        {
          bundleName: "com.miclink.HOS.MicLink", // 目标应用包名（必填）
          abilityName: "PhoneAbility"// 目标Ability名称（必填）
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
}

function callback(error: BusinessError, data: void) {
  if (error) {
    console.error(`操作开始后台运行失败. code is ${error.code} message is ${error.message}`);
  } else {
    console.info("操作开始后台运行成功");
  }
}