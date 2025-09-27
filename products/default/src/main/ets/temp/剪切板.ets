import { pasteboard } from '@kit.BasicServicesKit';
import { BusinessError } from '@kit.BasicServicesKit';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
@Entry
@Component
struct ClipboardDemo {
  @State inputText: string = ''; // 输入框文本
  @State outputText: string = ''; // 输出框文本
  @State clipboardStatus: string = '就绪';

  build() {
    Column() {
      // 标题
      Text('复制粘贴演示')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin(20)

      // 输入区域
      Text('输入文本:')
        .fontSize(16)
        .margin(10)
        .width('90%')
        .textAlign(TextAlign.Start)

      TextInput({ text: this.inputText, placeholder: '请输入要复制的文本' })
        .width('90%')
        .height(60)
        .border({ width: 1, color: Color.Gray })
        .padding(10)
        .onChange((value: string) => {
          this.inputText = value;
        })

      // 复制按钮
      Button('复制文本')
        .width('90%')
        .height(50)
        .margin(10)
        .onClick(() => {
          this.copyToClipboard();
        })

      // 输出区域
      Text('粘贴结果:')
        .fontSize(16)
        .margin(10)
        .width('90%')
        .textAlign(TextAlign.Start)

      TextInput({ text: this.outputText, placeholder: '粘贴的内容将显示在这里' })
        .width('90%')
        .height(60)
        .border({ width: 1, color: Color.Gray })
        .padding(10)
        .onChange((value: string) => {
          this.outputText = value;
        })

      // 粘贴按钮
      Button('粘贴文本')
        .width('90%')
        .height(50)
        .margin(10)
        .onClick(() => {
          this.pasteFromClipboard();
        })

      // 状态显示
      Text('状态: ' + this.clipboardStatus)
        .fontSize(14)
        .fontColor(Color.Gray)
        .margin(10)

      // 清空按钮
      Button('清空所有')
        .width('90%')
        .height(50)
        .margin(10)
        .onClick(() => {
          this.clearAll();
        })
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .justifyContent(FlexAlign.Center)
  }

  // 复制文本到剪贴板
  private copyToClipboard() {
    if (!this.inputText.trim()) {
      this.clipboardStatus = '请输入要复制的文本';
      return;
    }

    try {
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.inputText);
      const systemPasteboard = pasteboard.getSystemPasteboard();

      systemPasteboard.setData(pasteData)
        .then(() => {
          console.info('文本已复制到剪贴板: ' + this.inputText);
          this.clipboardStatus = '复制成功';
        })
        .catch((err: BusinessError) => {
          console.error('复制失败: ' + err.message);
          this.clipboardStatus = '复制失败: ' + err.message;
        });
    } catch (error) {
      console.error('复制操作异常: ' + error.message);
      this.clipboardStatus = '复制异常';
    }
  }

  // 从剪贴板粘贴文本
  private pasteFromClipboard() {
    try {
      const systemPasteboard = pasteboard.getSystemPasteboard();
      let atManager = abilityAccessCtrl.createAtManager();
      try {
        // 向用户申请读取剪贴板的权限
        atManager.requestPermissionsFromUser(AppStorage.get('context'), ['ohos.permission.READ_PASTEBOARD'])
          .then((data) => {
            console.info("权限申请结果: " + JSON.stringify(data));
          })
          .catch((err: BusinessError) => {
            console.error("权限申请失败: " + err.message);
          });
      } catch (err) {
        console.error(`权限申请捕获异常: ${err.code}, ${err.message}`);
      }
      systemPasteboard.getData()
        .then((pasteData: pasteboard.PasteData) => {
          console.log('***************************************'+JSON.stringify(pasteData))
          if (pasteData) {
            const text = pasteData.getPrimaryText();
            console.log('$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'+text)
            if (text) {
              this.outputText = text;
              console.info('粘贴成功: ' + text);
              this.clipboardStatus = '粘贴成功';
            } else {
              this.clipboardStatus = '剪贴板中没有文本内容';
            }
          } else {
            this.clipboardStatus = '剪贴板为空';
          }
        })
        .catch((err: BusinessError) => {
          console.error('粘贴失败: ' + err.message);
          this.clipboardStatus = '粘贴失败: ' + err.message;
        });
    } catch (error) {
      console.error('粘贴操作异常: ' + error.message);
      this.clipboardStatus = '粘贴异常';
    }
  }

  // 清空所有内容
  private clearAll() {
    this.inputText = '';
    this.outputText = '';
    this.clipboardStatus = '已清空';

    // 可选：清空剪贴板
    const systemPasteboard = pasteboard.getSystemPasteboard();
    systemPasteboard.clearData()
      .then(() => {
        console.info('剪贴板已清空');
      })
      .catch((err: BusinessError) => {
        console.error('清空剪贴板失败: ' + err.message);
      });
  }
}