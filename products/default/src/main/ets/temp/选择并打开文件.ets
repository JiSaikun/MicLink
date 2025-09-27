// 1. 导入必要的模块
import { common } from '@kit.AbilityKit';
import { Want } from '@kit.AbilityKit';
import { picker } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 2. 定义常见的MIME类型映射
const MIME_TYPE_MAP: Record<string, string> = {
  'pdf': 'application/pdf',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'txt': 'text/plain',
  'doc': 'application/msword',
  'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'xls': 'application/vnd.ms-excel',
  'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'ppt': 'application/vnd.ms-powerpoint',
  'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'mp3': 'audio/mpeg',
  'mp4': 'video/mp4',
  'dwg': 'application/acad',
  'dwt': 'application/acad',
  'dxf': 'application/dxf',
  // 图像格式
  'gif': 'image/gif',
  'bmp': 'image/bmp',
  'webp': 'image/webp',
  'svg': 'image/svg+xml',
  'ico': 'image/x-icon',
  // 音频格式
  'wav': 'audio/wav',
  'ogg': 'audio/ogg',
  'aac': 'audio/aac',
  'flac': 'audio/flac',
  'wma': 'audio/x-ms-wma',
  // 视频格式
  'avi': 'video/x-msvideo',
  'mov': 'video/quicktime',
  'wmv': 'video/x-ms-wmv',
  'flv': 'video/x-flv',
  'mkv': 'video/x-matroska',
  // 压缩文件
  'zip': 'application/zip',
  'rar': 'application/vnd.rar',
  '7z': 'application/x-7z-compressed',
  'tar': 'application/x-tar',
  'gz': 'application/gzip',
  // 编程文件
  'html': 'text/html',
  'htm': 'text/html',
  'css': 'text/css',
  'js': 'text/javascript',
  'json': 'application/json',
  'xml': 'application/xml',
  'php': 'application/x-httpd-php',
  'py': 'text/x-python',
  'java': 'text/x-java-source',
  'cpp': 'text/x-c++src',
  'c': 'text/x-csrc',
  'h': 'text/x-chdr',
  'cs': 'text/x-csharp',
  // 其他文档
  'rtf': 'application/rtf',
  'odt': 'application/vnd.oasis.opendocument.text',
  'ods': 'application/vnd.oasis.opendocument.spreadsheet',
  'odp': 'application/vnd.oasis.opendocument.presentation',
  'epub': 'application/epub+zip',
  // 系统文件
  'exe': 'application/x-msdownload',
  'msi': 'application/x-msdownload',
  'apk': 'application/vnd.android.package-archive',
  'deb': 'application/x-debian-package',
  'rpm': 'application/x-rpm',
  // 字体文件
  'ttf': 'font/ttf',
  'otf': 'font/otf',
  'woff': 'font/woff',
  'woff2': 'font/woff2',
  // 数据文件
  'csv': 'text/csv',
  'tsv': 'text/tab-separated-values',
  'sql': 'application/sql',
  'db': 'application/vnd.sqlite3',
  // 3D文件
  'stl': 'model/stl',
  'obj': 'model/obj',
  'fbx': 'application/octet-stream',
  'blend': 'application/x-blender',
  // 配置文件
  'ini': 'text/plain',
  'cfg': 'text/plain',
  'conf': 'text/plain',
  'yaml': 'application/x-yaml',
  'yml': 'application/x-yaml',
  'toml': 'application/toml',
  // 日志文件
  'log': 'text/plain'
};

@Entry
@Component
struct SystemFileOpener {
  // 获取Ability上下文
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  // 状态变量，用于UI控制和信息提示
  @State message: string = '准备就绪，请选择文件';
  @State isProcessing: boolean = false;
  @State selectedFileName: string = '';

  // 从文件URI中提取文件名（用于显示）
  private getFileNameFromUri(uriString: string): string {
    try {
      const segments: string[] = uriString.split('/');
      const fileNameWithEncoding: string = segments[segments.length - 1];
      // 对URL编码的文件名进行解码
      return decodeURIComponent(fileNameWithEncoding);
    } catch (error) {
      hilog.error(0x0000, 'FileOpener', 'Failed to parse filename from URI');
      return '未知文件';
    }
  }

  // 根据文件后缀名获取对应的MIME类型
  private getMimeType(filename: string): string {
    const extension: string = filename.split('.').pop()?.toLowerCase() || '';
    return MIME_TYPE_MAP[extension] || 'application/octet-stream'; // 使用通用的二进制流类型作为默认值
  }

  // 核心方法：选择文件并用系统应用打开
  private async openFileWithSystemApp(): Promise<void> {
    // 防止重复点击
    if (this.isProcessing) {
      return;
    }

    this.isProcessing = true;
    this.message = '正在选择文件...';

    try {
      // 步骤1: 创建文件选择器实例并选择文件（取消注释这部分）
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(this.context);
      const fileList: Array<string> = await documentPicker.select();

      if (!fileList || fileList.length === 0) {
        this.message = '未选择文件';
        this.isProcessing = false;
        return;
      }

      const selectedFileUri: string = fileList[0];
      hilog.info(0x0000, 'FileOpener', 'File selected: %{public}s', selectedFileUri);

      // 步骤2: 准备文件信息
      this.selectedFileName = this.getFileNameFromUri(selectedFileUri);
      const mimeType: string = this.getMimeType(this.selectedFileName);
      this.message = `正在尝试打开: ${this.selectedFileName}`;

      // 步骤3: 构建Want意图，告诉系统"我要查看这个文件"
      const want: Want = {
        action: 'ohos.want.action.view', // 标准的查看动作
        uri: selectedFileUri, // 使用选择的文件URI，而不是硬编码的路径
        type: mimeType // 提供MIME类型有助于系统选择更合适的应用
      };

      // 步骤4: 启动系统能力
      await this.context.startAbility(want);
      this.message = `已请求系统打开文件`;
      hilog.info(0x0000, 'FileOpener', 'System app launch request sent.');

    } catch (error) {
      // 步骤5: 详细的错误处理
      const err: BusinessError = error as BusinessError;
      hilog.error(0x0000, 'FileOpener', 'Failed to open file: code=%{public}d, message=%{public}s', err.code,
        err.message);

      // 根据错误码提供用户友好的提示
      switch (err.code) {
        case 13900002: // 文件不存在或无权限
          this.message = '文件可能已被移动或删除，或应用无权限访问。';
          break;
        case 202: // 能力未找到
          this.message = '未找到可以打开此文件类型的应用。';
          break;
        default:
          this.message = `打开文件失败: ${err.message}`;
      }
    } finally {
      this.isProcessing = false;
    }
  }

  build() {
    Column({ space: 20 }) {
      Text(this.message)
        .fontSize(18)
        .textAlign(TextAlign.Center)
        .margin({ top: 40, bottom: 20 })
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      if (this.selectedFileName) {
        Text(`已选文件: ${this.selectedFileName}`)
          .fontSize(14)
          .fontColor(Color.Blue)
          .margin({ bottom: 10 })
      }

      Button(this.isProcessing ? '处理中...' : '选择文件并用系统应用打开')
        .width('90%')
        .height(50)
        .fontSize(16)
        .fontColor(Color.White)
        .backgroundColor(this.isProcessing ? '#CCC' : '#007DFF')
        .borderRadius(8)
        .enabled(!this.isProcessing)
        .onClick(() => {
          this.openFileWithSystemApp();
        })

      // 添加说明文本
      Text('支持的文件类型')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 30, bottom: 10 })

      Text('文档: PDF, DOC, DOCX, XLS, XLSX, PPT, PPTX, TXT, RTF\n' +
        '图像: JPG, PNG, GIF, BMP, WEBP, SVG, ICO\n' +
        '音频: MP3, WAV, OGG, AAC, FLAC\n' +
        '视频: MP4, AVI, MOV, WMV, FLV, MKV\n' +
        '压缩: ZIP, RAR, 7Z, TAR, GZ\n' +
        '设计: DWG, DWT, DXF, STL, OBJ\n' +
        '编程: HTML, CSS, JS, JSON, XML, PY, JAVA等')
        .fontSize(12)
        .fontColor('#666')
        .textAlign(TextAlign.Start)
        .lineHeight(18)
        .width('90%')

    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#F5F5F5')
  }
}

// // 1. 导入必要的模块（请根据您的SDK版本确认模块路径）
// import { common } from '@kit.AbilityKit';
// import { Want } from '@kit.AbilityKit';
// import { picker } from '@kit.CoreFileKit';
// import { BusinessError } from '@kit.BasicServicesKit';
// import { hilog } from '@kit.PerformanceAnalysisKit';
//
// // 2. 定义常见的MIME类型映射，用于告知系统文件类型
// const MIME_TYPE_MAP: Record<string, string> = {
//   'pdf': 'application/pdf',
//   'jpg': 'image/jpeg',
//   'jpeg': 'image/jpeg',
//   'png': 'image/png',
//   'txt': 'text/plain',
//   'doc': 'application/msword',
//   'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
//   'xls': 'application/vnd.ms-excel',
//   'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
//   'ppt': 'application/vnd.ms-powerpoint',
//   'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
//   'mp3': 'audio/mpeg',
//   'mp4': 'video/mp4',
//   'dwg': 'application/acad', // AutoCAD文件
//   // 可继续添加其他类型
// };
//
// @Entry
// @Component
// struct SystemFileOpener {
//   // 获取Ability上下文
//   private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
//   // 状态变量，用于UI控制和信息提示
//   @State message: string = '准备就绪，请选择文件';
//   @State isProcessing: boolean = false;
//   @State selectedFileName: string = '';
//
//   // 从文件URI中提取文件名（用于显示）
//   private getFileNameFromUri(uriString: string): string {
//     try {
//       const segments: string[] = uriString.split('/');
//       const fileNameWithEncoding: string = segments[segments.length - 1];
//       // 对URL编码的文件名进行解码
//       return decodeURIComponent(fileNameWithEncoding);
//     } catch (error) {
//       hilog.error(0x0000, 'FileOpener', 'Failed to parse filename from URI');
//       return '未知文件';
//     }
//   }
//
//   // 根据文件后缀名获取对应的MIME类型
//   private getMimeType(filename: string): string {
//     const extension: string = filename.split('.').pop()?.toLowerCase() || '';
//     return MIME_TYPE_MAP[extension] || '*/*'; // 未知类型使用通配符
//   }
//
//   // 核心方法：选择文件并用系统应用打开
//   private async openFileWithSystemApp(): Promise<void> {
//     // 防止重复点击
//     if (this.isProcessing) {
//       return;
//     }
//
//     this.isProcessing = true;
//     this.message = '正在选择文件...';
//
//     try {
//       // 步骤1: 创建文件选择器实例并选择文件:cite[7]
//       const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(this.context);
//       const fileList: Array<string> = await documentPicker.select();
//
//       if (!fileList || fileList.length === 0) {
//         this.message = '未选择文件';
//         this.isProcessing = false;
//         return;
//       }
//
//       const selectedFileUri: string = fileList[0];
//       hilog.info(0x0000, 'FileOpener', 'File selected: %{public}s', selectedFileUri);
//
//       // 步骤2: 准备文件信息
//       this.selectedFileName = this.getFileNameFromUri(selectedFileUri);
//       const mimeType: string = this.getMimeType(this.selectedFileName);
//       this.message = `正在尝试打开: ${this.selectedFileName}`;
//
//       // 步骤3: 构建Want意图，告诉系统"我要查看这个文件":cite[4]
//       const want: Want = {
//         action: 'ohos.want.action.view', // 标准的查看动作
//         uri: selectedFileUri,
//         type: mimeType // 提供MIME类型有助于系统选择更合适的应用
//       };
//
//       // 步骤4: 启动系统能力
//       await this.context.startAbility(want);
//       this.message = `已请求系统打开文件`;
//       hilog.info(0x0000, 'FileOpener', 'System app launch request sent.');
//
//     } catch (error) {
//       // 步骤5: 详细的错误处理
//       const err: BusinessError = error as BusinessError;
//       hilog.error(0x0000, 'FileOpener', 'Failed to open file: code=%{public}d, message=%{public}s', err.code,
//         err.message);
//
//       // 根据错误码提供用户友好的提示
//       switch (err.code) {
//         case 13900002: // 文件不存在或无权限
//           this.message = '文件可能已被移动或删除，或应用无权限访问。';
//           break;
//         case 202: // 能力未找到
//           this.message = '未找到可以打开此文件类型的应用。';
//           break;
//         default:
//           this.message = `打开文件失败: ${err.message}`;
//       }
//     } finally {
//       this.isProcessing = false;
//     }
//   }
//
//   build() {
//     Column({ space: 20 }) {
//       Text(this.message)
//         .fontSize(18)
//         .textAlign(TextAlign.Center)
//         .margin({ top: 40, bottom: 20 })
//         .maxLines(2)
//         .textOverflow({ overflow: TextOverflow.Ellipsis })
//
//       if (this.selectedFileName) {
//         Text(`已选文件: ${this.selectedFileName}`)
//           .fontSize(14)
//           .fontColor(Color.Blue)
//           .margin({ bottom: 10 })
//       }
//
//       Button(this.isProcessing ? '处理中...' : '选择文件并用系统应用打开')
//         .width('90%')
//         .height(50)
//         .fontSize(16)
//         .fontColor(Color.White)
//         .backgroundColor(this.isProcessing ? '#CCC' : '#007DFF')
//         .borderRadius(8)
//         .enabled(!this.isProcessing)
//         .onClick(() => {
//           this.openFileWithSystemApp();
//         })
//
//     }
//     .width('100%')
//     .height('100%')
//     .padding(20)
//     .backgroundColor('#F5F5F5')
//   }
// }