// xxx.ets
import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';

// =============== 第一步：定义数据传输接口 ===============
interface RecordData {
  state: number;
  language: string;
}

// =============== 第二步：创建代理类 ===============
class WebProxy {
  // 存储WebComponent的引用
  private component: WebComponent;

  constructor(component: WebComponent) {
    this.component = component;
  }

  // =============== 关键方法：供前端调用 ===============
  // 方法名必须与javaScriptProxy中注册的一致
  // 参数类型使用定义好的接口
  webRecord(data: RecordData): void {
    console.info(`WebProxy收到数据: ${JSON.stringify(data)}`);

    // 添加数据验证
    if (typeof data.state !== 'number') {
      console.error('webRecord: state 必须是数字类型');
      return;
    }

    if (typeof data.language !== 'string') {
      console.error('webRecord: language 必须是字符串类型');
      return;
    }

    // 将接收到的对象数据转发给WebComponent
    this.component.onWebRecord(data.state, data.language);
  }

  // =============== 测试方法 ===============
  test(): string {
    return 'ArkTS: 连接测试成功 ' + new Date().toLocaleTimeString();
  }

  // 可以添加更多方法...
  getStatus(): string {
    return 'WebProxy运行正常';
  }
}

// =============== 第三步：主组件定义 ===============
@Entry
@Component
struct WebComponent {
  // Web组件控制器
  controller: webview.WebviewController = new webview.WebviewController();

  // =============== 组件的状态变量 ===============
  @State FLAX: boolean = false;
  @State currentState: number = 0;
  @State currentLanguage: string = '未设置';
  @State lastUpdateTime: string = '';

  // 代理对象实例
  private webProxy: WebProxy = new WebProxy(this);

  // =============== 业务处理方法 ===============
  // 注意：这个方法名与WebProxy中调用的要一致
  onWebRecord(state: number, language: string): void {
    // 更新状态
    this.FLAX = !this.FLAX;
    this.currentState = state;
    this.currentLanguage = language;
    this.lastUpdateTime = new Date().toLocaleTimeString();

    // 输出日志
    console.info(`onWebRecord被调用: state=${state}, language=${language}`);
    console.info(`FLAX状态切换为: ${this.FLAX}`);

    // 这里可以添加更多业务逻辑，如：
    // - 保存到本地存储
    // - 触发其他组件更新
    // - 发送网络请求等
  }

  // =============== 组件生命周期 ===============
  aboutToAppear() {
    console.info('WebComponent已加载');
  }

  // =============== UI构建 ===============
  build() {
    Column({ space: 10 }) {
      // =============== 标题区域 ===============
      Text('ArkTS Web通信演示')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 10 })
        .fontColor('#183153')

      // =============== 状态显示卡片 ===============
      Column({ space: 8 }) {
        // FLAX状态（带视觉反馈）
        Row() {
          Text('FLAX状态: ')
            .fontSize(16)
            .fontColor('#666')
          Text(this.FLAX ? 'TRUE' : 'FALSE')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.FLAX ? '#007DFF' : '#FF0000')
        }
        .width('90%')
        .justifyContent(FlexAlign.SpaceBetween)

        // 接收到的状态值
        Row() {
          Text('状态值(State): ')
            .fontSize(16)
            .fontColor('#666')
          Text(this.currentState.toString())
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#007DFF')
        }
        .width('90%')
        .justifyContent(FlexAlign.SpaceBetween)

        // 接收到的语言
        Row() {
          Text('语言(Language): ')
            .fontSize(16)
            .fontColor('#666')
          Text(this.currentLanguage)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#007DFF')
        }
        .width('90%')
        .justifyContent(FlexAlign.SpaceBetween)

        // 最后更新时间
        Row() {
          Text('最后更新: ')
            .fontSize(14)
            .fontColor('#999')
          Text(this.lastUpdateTime)
            .fontSize(14)
            .fontColor('#999')
        }
        .width('90%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ top: 5 })
      }
      .width('90%')
      .padding(15)
      .backgroundColor('#F5F5F5')
      .borderRadius(12)
      .margin({ bottom: 15 })

      // =============== 操作按钮区域 ===============
      Row({ space: 10 }) {
        Button('测试连接')
          .fontSize(14)
          .backgroundColor('#007DFF')
          .onClick(() => {
            try {
              const result = this.webProxy.test();
              console.info('测试连接结果:', result);
            } catch (error) {
              console.error('测试连接失败:', error);
            }
          })

        Button('重置状态')
          .fontSize(14)
          .backgroundColor('#888')
          .onClick(() => {
            this.FLAX = false;
            this.currentState = 0;
            this.currentLanguage = '已重置';
            this.lastUpdateTime = new Date().toLocaleTimeString();
          })
      }
      .margin({ bottom: 15 })

      // =============== Web组件区域 ===============
      Text('内嵌Web页面:')
        .fontSize(16)
        .fontColor('#333')
        .margin({ left: 20, bottom: 5 })

      Web({
        // 请修改为你的前端页面地址
        src: $rawfile('microphone.html'),
        controller: this.controller
      })
        .javaScriptProxy({
          // 关键配置：注册代理对象
          object: this.webProxy,           // 要暴露的对象
          name: "hostInstance",           // 前端通过window.hostInstance访问
          methodList: ["webRecord", "test", "getStatus"], // 暴露的方法列表
          controller: this.controller
        })
        .width('95%')
        .height(300)
        .margin({ bottom: 20 })
        .border({ width: 1, color: '#E0E0E0' })
        .borderRadius(8)

      // =============== 调试信息 ===============
      Text('调试信息:')
        .fontSize(14)
        .fontColor('#666')
        .margin({ left: 20, bottom: 5 })

      Text('前端通过 window.hostInstance.webRecord({state: 值, language: "语言"}) 调用')
        .fontSize(12)
        .fontColor('#888')
        .width('90%')
        .textAlign(TextAlign.Start)
        .margin({ bottom: 10 })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#FFFFFF')
  }
}