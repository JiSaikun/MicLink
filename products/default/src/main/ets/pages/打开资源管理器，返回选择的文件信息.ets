import { picker } from '@kit.CoreFileKit'; // 导入文件选择器模块，用于调用系统文件选择器
import { fileIo as fs } from '@kit.CoreFileKit'; // 导入文件IO模块，用于文件操作
import { common } from '@kit.AbilityKit'; // 导入Ability常用功能
import { BusinessError } from '@kit.BasicServicesKit'; // 导入业务错误类型
import { promptAction } from '@kit.ArkUI'; // 导入UI提示操作模块

@Entry // 标记为应用入口组件
@Component // 标记为自定义组件
struct FilePickerExample {
  // 获取当前UIAbility上下文
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  @State selectedFileUris: Array<string> = []; // 存储用户选择的文件URI列表
  @State fileName: string = ''; // 存储文件名
  @State fileSize: string = ''; // 存储文件大小（格式化后的字符串）
  @State fileUrl: string = ''; // 存储文件的完整URI/URL地址
  @State isLoading: boolean = false; // 加载状态标志，防止重复点击

  // 选择文件方法 - 异步函数
  async selectFile() {
    this.isLoading = true; // 开始加载，禁用按钮
    try {
      // 创建文档选择选项
      const documentSelectOptions = new picker.DocumentSelectOptions();
      documentSelectOptions.maxSelectNumber = 1; // 设置最大选择文件数为1
      // 设置文件后缀过滤器，只允许选择特定类型的文件
      documentSelectOptions.fileSuffixFilters = ['.pdf', '.txt', '.doc', '.docx', '.jpg', '.png'];

      // 创建文档视图选择器实例
      const documentViewPicker = new picker.DocumentViewPicker(this.context);
      // 调用选择方法并等待结果
      const result = await documentViewPicker.select(documentSelectOptions);

      // 检查结果是否有效且有文件被选中
      if (result && result.length > 0) {
        this.selectedFileUris = result; // 保存选中的文件URI
        this.fileUrl = result[0]; // 保存文件的完整URI/URL地址

        // 从URI中提取文件名（取路径的最后一部分）
        this.fileName = result[0].split('/').pop() || '未知文件';

        // 获取文件大小信息
        let file = fs.openSync(result[0], fs.OpenMode.READ_ONLY); // 以只读方式打开文件
        const stat = fs.statSync(file.fd); // 获取文件状态信息
        this.fileSize = this.formatFileSize(stat.size); // 格式化文件大小
        fs.closeSync(file); // 关闭文件

        // 显示成功提示
        promptAction.showToast({ message: '文件选择成功', duration: 2000 });
      }
    } catch (err) {
      // 捕获并处理错误
      console.error('Failed to select file. Cause: ' + (err as BusinessError).message);
      promptAction.showToast({ message: '文件选择失败', duration: 2000 });
    } finally {
      this.isLoading = false; // 无论成功或失败，都结束加载状态
    }
  }

  // 格式化文件大小 - 将字节数转换为更易读的格式
  private formatFileSize(bytes: number): string {
    if (bytes < 1024) {
      return bytes + ' B';
    } else if (bytes < 1024 * 1024) {
      return (bytes / 1024).toFixed(2) + ' KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
    } else {
      return (bytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB';
    }
  }

  // 复制文件URL到剪贴板
  private copyFileUrl() {
    // 在实际应用中，这里可以使用系统剪贴板API
    console.info('文件URL: ' + this.fileUrl);
    promptAction.showToast({ message: '文件URL已复制到控制台', duration: 2000 });
  }

  // 构建UI布局
  build() {
    Column() { // 垂直布局
      Button('选择文件') // 文件选择按钮
        .onClick(() => { // 点击事件处理
          this.selectFile();
        })
        .width('80%') // 宽度设置为父容器的80%
        .height(40) // 固定高度
        .margin(20) // 外边距
        .enabled(!this.isLoading) // 根据加载状态启用/禁用按钮

      // 条件渲染：当有文件被选中时显示文件信息
      if (this.selectedFileUris.length > 0) {
        Column() {
          Text(`文件名: ${this.fileName}`) // 显示文件名
            .fontSize(16)
            .margin(5)
          Text(`文件大小: ${this.fileSize}`) // 显示文件大小
            .fontSize(16)
            .margin(5)
          Text('文件URI:') // 显示文件URI标签
            .fontSize(16)
            .margin({ top: 10, bottom: 5 })
          Text(this.fileUrl) // 显示完整的文件URI
            .fontSize(14)
            .textOverflow({ overflow: TextOverflow.Ellipsis }) // 超出部分显示省略号
            .maxLines(2) // 最多显示2行
            .margin(5)
          Button('复制文件URI') // 复制URI按钮
            .onClick(() => {
              this.copyFileUrl();
            })
            .width('60%')
            .height(35)
            .margin(10)
        }
        .width('90%')
        .padding(10)
        .backgroundColor(Color.White) // 设置背景色
        .borderRadius(8) // 圆角边框
        .shadow({ radius: 4, color: Color.Gray, offsetX: 2, offsetY: 2 }) // 添加阴影效果
      }
    }
    .width('100%') // 宽度100%
    .height('100%') // 高度100%
    .justifyContent(FlexAlign.Center) // 垂直居中
    .alignItems(HorizontalAlign.Center) // 水平居中
    .backgroundColor('#ccc') // 设置背景色
  }
}