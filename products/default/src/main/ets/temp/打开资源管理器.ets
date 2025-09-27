import { common, OpenLinkOptions } from '@kit.AbilityKit'; // 导入AbilityKit中的常用功能和打开链接选项
import { hilog } from '@kit.PerformanceAnalysisKit'; // 导入性能分析工具包中的日志功能
import { BusinessError } from '@kit.BasicServicesKit'; // 导入基础服务包中的业务错误类型

const TAG: string = '[UIAbilityComponentsOpenLink]'; // 定义日志标签
const DOMAIN_NUMBER: number = 0xFF00; // 定义日志域编号

@Entry
  // 标记为入口组件
@Component
  // 标记为自定义组件
struct Index { // 定义名为Index的结构体组件
  @State message: string = '拉起文件管理'; // 使用@State装饰器定义响应式消息文本

  build() { // 构建UI布局
    Row() { // 行布局
      Column() { // 列布局
        Button(this.message) // 按钮组件，显示消息文本
          .width('100%') // 宽度100%
          .fontWeight(FontWeight.Bold) // 字体加粗
          .onClick(() => { // 点击事件处理
            let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext; // 获取当前UIAbility上下文
            let link: string = 'filemanager://openDirectory'; // 定义要打开的链接，这里是文件管理的URI
            let openLinkOptions: OpenLinkOptions = {
              // 配置打开链接的选项
              parameters: {
                // 参数设置
                'fileUri': '' // 文件URI参数，这里为空
              }
            };
            try { // 异常处理
              context.openLink(link, openLinkOptions) // 调用打开链接方法
                .then(() => { // 成功回调
                  hilog.info(DOMAIN_NUMBER, TAG, 'open link success.'); // 记录成功日志
                }).catch((err: BusinessError) => { // 失败回调
                hilog.error(DOMAIN_NUMBER, TAG,
                  `open link failed. Code is ${err.code}, message is ${err.message}`); // 记录错误日志
              });
            } catch (paramError) { // 捕获参数错误
              hilog.error(DOMAIN_NUMBER, TAG,
                `Failed to start link. Code is ${paramError.code}, message is ${paramError.message}`); // 记录参数错误日志
            }
          })
      }
      .padding({ left: 16, right: 16 }) // 设置左右内边距
      .width('100%') // 宽度100%
    }
    .height('100%') // 高度100%
  }
}