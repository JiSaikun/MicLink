import { AbilityConstant, ConfigurationConstant, UIAbility, Want, WantAgent, wantAgent } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';

// import fs from '@ohos.file.fs';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

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
          bundleName: "com.miclink.myapplication", // 目标应用包名（必填）
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

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
    window.getLastWindow(this.context).then((data: window.Window) => {
      let uiContext = data.getUIContext(); // 获取 UIContext
      AppStorage.setOrCreate('uiContext', uiContext); // 存储到应用全局变量
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
  }
}

function callback(error: BusinessError, data: void) {
  if (error) {
    console.error(`操作开始后台运行失败. code is ${error.code} message is ${error.message}`);
  } else {
    console.info("操作开始后台运行成功");
  }
}