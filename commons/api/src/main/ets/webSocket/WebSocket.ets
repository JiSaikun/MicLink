import { webSocket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';



export class WebSocket {
  public isConnected: boolean = false;
  // 创建 WebSocket 实例
  private ws: webSocket.WebSocket | null = null;
  private serverUrl: string = "ws://asr.miclink.net/ws";

  constructor(serverUrl: string) {
    this.serverUrl = serverUrl;
  }

  public connect(): void {
    console.log('*************************进入webSocket连接************************', typeof this.ws)
    // 如果已有连接，先关闭
    if (this.ws) {
      this.disconnect();
    }


    // 创建新的WebSocket实例
    this.ws = webSocket.createWebSocket();

    // 监听连接打开事件
    this.ws.on('open', (err: BusinessError, value: Object) => {
      if (!err) {
        this.isConnected = true;
        const msg: string = "连接已打开，可以开始通信";
        console.log("连接已打开，状态:" + JSON.stringify(value));
      } else {
        const msg: string = "连接失败: " + err.message;
        console.error("连接错误:" + JSON.stringify(err));
      }
    });

    // 监听消息接收事件
    this.ws.on('message', (err: BusinessError, value: string | ArrayBuffer) => {
      if (!err) {
        let message: string;
        if (typeof value === 'string') {
          message = value;
        } else {
          // 使用鸿蒙平台支持的方式处理ArrayBuffer
          message = this.arrayBufferToString(value);
        }
        console.log("收到消息，内容:" + message);
      } else {
        const msg: string = "接收消息错误: " + err.message;
        console.error("消息错误:" + JSON.stringify(err));
      }
    });

    // 监听连接关闭事件
    this.ws.on('close', (err: BusinessError, value: webSocket.CloseResult) => {
      this.isConnected = false;
      const msg: string = `连接已关闭，状态码: ${value.code}, 原因: ${value.reason}`;
      console.log(msg);
    });

    // 监听错误事件
    this.ws.on('error', (err: BusinessError) => {
      const msg: string = "发生错误: " + err.message;
      console.error(msg);
    });

    // 发起连接
    console.warn('正在连接到服务器...')
    const connectingMsg: string = "正在连接到服务器...";
    this.ws.connect(this.serverUrl, (err: BusinessError, value: boolean) => {
      if (!err) {
        console.warn("连接成功");
      } else {
        const msg: string = "连接失败。错误信息:" + err.message;
        console.error(msg);
      }
    });
  }

  // 断开WebSocket连接
  public disconnect(): void {
    if (this.ws) {
      this.ws.close({
        code: 1000,
        reason: "客户端主动关闭"
      }, (err: BusinessError, value: boolean) => {
        if (!err) {
          console.log("连接已成功关闭");
        } else {
          console.error("关闭连接失败。错误信息: " + JSON.stringify(err));
        }
      });
      this.ws = null;
      this.isConnected = false;
    }
  }

  // 发送消息
  public sendMessage(inputMessage: string): boolean {
    if (!this.isConnected || !this.ws) {
      const msg: string = "未连接到服务器，无法发送消息";
      console.error(msg)
      return false;
    }

    if (!inputMessage.trim()) {
      const msg: string = "消息不能为空";
      console.error(msg)
      return false;
    }

    // 发送消息到服务器
    this.ws.send(JSON.stringify(inputMessage), (err: BusinessError, value: boolean) => {
      if (err) {
        const msg: string = "消息发送失败: " + err.message;
        console.error(msg);
      } else {
        const msg: string = "消息发送成功~~~";
        console.error(msg)
      }
    });

    return true;
  }

  // 添加arrayBufferToString方法，用于将ArrayBuffer转换为字符串
  private arrayBufferToString(buffer: ArrayBuffer): string {
    const uint8Array: Uint8Array = new Uint8Array(buffer);
    let result: string = "";

    for (let i = 0; i < uint8Array.length; i++) {
      result += String.fromCharCode(uint8Array[i]);
    }

    return result;
  }

}
