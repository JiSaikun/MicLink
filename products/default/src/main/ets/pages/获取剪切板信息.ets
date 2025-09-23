import { pasteboard } from '@kit.BasicServicesKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct ClipboardDemo {
  @State message: string = 'Hello World';
  @State clipboardContent: string = '';

  build() {
    Column() {
      Text(this.message)
        .fontSize(20)
        .margin(10)

      // 写入文本到剪贴板
      Button('复制文本到剪贴板')
        .onClick(() => {
          this.writeToClipboard();
        })
        .margin(10)

      // 从剪贴板读取文本
      Button('从剪贴板读取文本')
        .onClick(() => {
          this.readFromClipboard();
        })
        .margin(10)

      // 显示剪贴板内容
      Text('剪贴板内容: ' + this.clipboardContent)
        .fontSize(16)
        .margin(10)
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }

  // 写入文本到剪贴板
  private writeToClipboard() {
    try {
      // 创建包含纯文本的PasteData对象
      const textToCopy = '这是要复制的示例文本';
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, textToCopy);

      // 获取系统剪贴板
      const systemPasteboard = pasteboard.getSystemPasteboard();

      // 将数据写入剪贴板
      systemPasteboard.setData(pasteData)
        .then(() => {
          console.info('文本已成功复制到剪贴板');
          this.clipboardContent = '已复制: ' + textToCopy;
        })
        .catch((err: BusinessError) => {
          console.error('复制失败: ' + err.message);
          this.clipboardContent = '复制失败';
        });
    } catch (error) {
      console.error('复制操作异常: ' + error.message);
    }
  }

  // 从剪贴板读取文本
  private readFromClipboard() {
    try {
      // 获取系统剪贴板
      const systemPasteboard = pasteboard.getSystemPasteboard();

      // 从剪贴板读取数据
      systemPasteboard.getData()
        .then((pasteData: pasteboard.PasteData) => {
          if (pasteData) {
            // 获取纯文本内容
            const text = pasteData.getPrimaryText();
            if (text) {
              console.info('从剪贴板读取的文本: ' + text);
              this.clipboardContent = text;
            } else {
              console.info('剪贴板中没有文本内容');
              this.clipboardContent = '剪贴板中没有文本内容';
            }
          } else {
            console.info('剪贴板为空');
            this.clipboardContent = '剪贴板为空';
          }
        })
        .catch((err: BusinessError) => {
          console.error('读取剪贴板失败: ' + err.message);
          this.clipboardContent = '读取失败';
        });
    } catch (error) {
      console.error('读取操作异常: ' + error.message);
    }
  }
}