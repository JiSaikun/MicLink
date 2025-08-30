/*
通过使用UIContext中获取到的PromptAction对象来实现自定义弹窗工具类的封装
* 弹窗提供方通过promptAction对象封装弹窗工具类
 */
import { ComponentContent, promptAction } from '@kit.ArkUI';
/*
导出枚举类型：PopViewShowType---指定打开的弹窗的名称
 */
export enum PopViewShowType {
  OPEN
}
/*
@PopViewModel:弹窗页面数据模型
* ComponentContent表示组件内容的实体封装，其对象支持在非UI组件中创建与传递，便于开发者对弹窗类组件进行解耦封装。
 */
interface PopViewModel {
  com: ComponentContent<object>;
  popType: PopViewShowType;
}
/*
* 自定义弹窗类
*
通过openCustomDialog创建打开弹窗的showDialog函数
*
 */
export class PopViewUtils {
  private static popShare: PopViewUtils;
  private infoList: PopViewModel[] = new Array<PopViewModel>();
  static shareInstance(): PopViewUtils {
    if (!PopViewUtils.popShare) {
      PopViewUtils.popShare = new PopViewUtils();
    }
    return PopViewUtils.popShare;
  }

  /*
通过openCustomDialog创建打开弹窗的showDialog函数
   */
  static showDialog<T extends object>(type: PopViewShowType, contentView: WrappedBuilder<[T]>, args: T,
    options?: promptAction.BaseDialogOptions):void {
    let uiContext = AppStorage.get<UIContext>('uiContext');
    if (uiContext) {
      // 获取提示操作对象
      let prompt = uiContext.getPromptAction();
      // 创建组件内容对象
      let componentContent = new ComponentContent(uiContext, contentView, args);
      // 设置对话框的对齐方式，使用传入的alignment或默认底部对齐
      let customOptions: promptAction.BaseDialogOptions = {
        alignment: options?.alignment || DialogAlignment.Bottom
      };
      // 使用openCustomDialog方法打开自定义对话框
      prompt.openCustomDialog(componentContent, customOptions);
      // 获取弹窗工具类的信息列表实例
      let infoList = PopViewUtils.shareInstance().infoList;
      // 创建一个新的弹窗数据模型
      let info: PopViewModel = {
        com: componentContent,
        popType: type
      };
      // 将新的弹窗数据模型添加到信息列表的第一个位置
      infoList[0] = info;
    }
  }

/*
通过closeCustomDialog创建关闭弹窗的closeDialog函数
 */
  static closeDialog(type: PopViewShowType): void {
    let uiContext = AppStorage.get<UIContext>('uiContext');
    if (uiContext) {
      // The promptAction object was obtained.
      let prompt = uiContext.getPromptAction();
      let sameTypeList = PopViewUtils.shareInstance().infoList.filter((model) => {
        return model.popType === type;
      })
      let info = sameTypeList[sameTypeList.length - 1];
      if (info && info.com) {
        PopViewUtils.shareInstance().infoList = PopViewUtils.shareInstance().infoList.filter((model) => {
          return model.com !== info.com;
        })
        // Close pop-ups using closeCustomDialog.
        prompt.closeCustomDialog(info.com);
      }
    }
  }

  /*
  封装对外的打开和关闭弹窗接口函数
   */
  static showPopView<T extends object>(contentView: WrappedBuilder<[T]>, args: T,
    options?: promptAction.BaseDialogOptions):void {
    PopViewUtils.showDialog(PopViewShowType.OPEN, contentView, args, options);
  }

  static closePopView():void {
    PopViewUtils.closeDialog(PopViewShowType.OPEN);
  }

}

// [End Step1]