// xxx.ets
import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct WebComponent {
  controller: webview.WebviewController = new webview.WebviewController();
  ports: webview.WebMessagePort[] = [];
  @State sendFromEts: string = '输入框输入的内容';
  @State receivedFromHtml: string = '展示来自前端的消息：';

  build() {
    Column() {
      Column({ space: 20 }) {
        // 展示接收到的来自HTML的内容
        Text(this.receivedFromHtml)
        // 输入框的内容发送到HTML
        TextInput({ placeholder: '内容发送到HTML' })
          .onChange((value: string) => {
            this.sendFromEts = value;
          })

        // 该内容可以放在onPageEnd生命周期中调用。
        Button('建立消息端口')
          .onClick(() => {
            // 1、创建两个消息端口。
            this.ports = this.controller.createWebMessagePorts();
            console.error(this.ports.length.toString())
            // 2、在应用侧的消息端口(如端口1)上注册回调事件。
            this.ports[1].onMessageEvent((result: webview.WebMessage) => { //ports[1]为应用端的通信端口，接收web端的信息和向web端发送信息都是通过这个端口
              // ports[0]为Web端的通信端口，接收应用端的信息和向应用端发送信息都是通过这个端口
              console.warn('端口0发来信息\T'+result.toString())
              this.receivedFromHtml = result.toString();
            })
            // 3、将另一个消息端口(如端口0)发送到HTML侧，由HTML侧保存并使用。
            this.controller.postMessage('__init_port__', [this.ports[0]], '*');
          })

        // 4、使用应用侧的端口给另一个已经发送到html的端口发送消息。
        Button('发送数据给HTML')
          .onClick(() => {
            if (this.ports && this.ports[1]) {
              this.ports[1].postMessageEvent(this.sendFromEts);
            } else {
              AlertDialog.show({
                message: '还没建立消息端口中'
              });
            }
          })
      }
      .borderWidth(2)


      Web({
        src: 'https://asrai.miclink.net/?sno=123&productCode=999999&config=configMiclink_B_1755079145452#/aiOffice',
        controller: this.controller
      })
    }
  }
}