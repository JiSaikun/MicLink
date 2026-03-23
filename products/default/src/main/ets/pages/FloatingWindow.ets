// 悬浮窗UI组件中的点击事件处理
import { AbilityConstant, common, UIAbility, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { CursorController } from '@kit.ArkUI';
import { pointer } from '@kit.InputKit';

@Entry
@Component
struct FloatingWindow {
  cursorCustom: CursorController = this.getUIContext().getCursorController();

  build() {
    Flex() {
      Image($r('app.media.MicLink'))
        .width('100%')
    }
    .padding(15)
    .borderRadius('50%')
    .width('100%')
    .height('100%')
    .onHover((flag) => {
      if (flag) {
        this.cursorCustom.setCursor(pointer.PointerStyle.HAND_POINTING);
      } else {
        console.info("restoreDefault");
        this.cursorCustom.restoreDefault();
      }
    })
    .onClick(() => {
      const abilityContext = AppStorage.get('context') as common.UIAbilityContext; // 获取AbilityContext
      const want: Want = {
        bundleName: "com.miclink.HOS.MicLink",
        abilityName: "EntryAbility"
      };

      // 1. 尝试唤醒主应用
      abilityContext.startAbility(want).then(() => {
        console.info('Succeeded in starting ability.');
      }).catch((err: BusinessError) => {
        console.error(`Failed to start ability. Code:${err.code}, message:${err.message}`);
      });
    })
  }
}

