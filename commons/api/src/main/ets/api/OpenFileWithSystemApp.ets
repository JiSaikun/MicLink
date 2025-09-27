/**
 * 拉起资源管理器，让用户选择打开的文件，并通过系统应用打开
 */
// 1. 导入必要的模块
import { common } from '@kit.AbilityKit';
import { Want } from '@kit.AbilityKit';
import { picker } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';


export class OpenFileWithSystemApp {
  // 获取Ability上下文
  static context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  static isProcessing: boolean = false; //防止多次点击

  // // 从文件URI中提取文件名（用于显示）
  static getFileNameFromUri(uriString: string): string {
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
  static getMimeType(filename: string): string {
    const extension: string = filename.split('.').pop()?.toLowerCase() || '';
    return MIME_TYPE_MAP[extension] || 'application/octet-stream'; // 使用通用的二进制流类型作为默认值
  }

  // 核心方法：选择文件并用系统应用打开
  static async openFileWithSystemApp(): Promise<void> {
    // 防止重复点击
    if (OpenFileWithSystemApp.isProcessing) {
      return;
    }

    OpenFileWithSystemApp.isProcessing = true;
    try {
      // 步骤1: 创建文件选择器实例并选择文件（取消注释这部分）
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(OpenFileWithSystemApp.context);
      const fileList: Array<string> = await documentPicker.select();

      if (!fileList || fileList.length === 0) {
        OpenFileWithSystemApp.isProcessing = false;
        return;
      }


      const selectedFileUri: string = fileList[0];
      // const selectedFileUri: string = 'file://docs/storage/Users/currentUser/Desktop/aa.txt';
      hilog.info(0x0000, 'FileOpener', 'File selected: %{public}s', selectedFileUri);

      // 步骤2: 准备文件信息
      // this.selectedFileName = this.getFileNameFromUri(selectedFileUri);
      const mimeType: string =
        OpenFileWithSystemApp.getMimeType(OpenFileWithSystemApp.getFileNameFromUri(selectedFileUri));

      // 步骤3: 构建Want意图，告诉系统"我要查看这个文件"
      const want: Want = {
        action: 'ohos.want.action.view', // 标准的查看动作
        uri: selectedFileUri, // 使用选择的文件URI，而不是硬编码的路径
        type: mimeType // 提供MIME类型有助于系统选择更合适的应用
      };

      // 步骤4: 启动系统能力
      await OpenFileWithSystemApp.context.startAbility(want);
      hilog.info(0x0000, 'FileOpener', 'System app launch request sent.');

    } catch (error) {
      // 步骤5: 详细的错误处理
      const err: BusinessError = error as BusinessError;
      hilog.error(0x0000, 'FileOpener', 'Failed to open file: code=%{public}d, message=%{public}s', err.code,
        err.message);

      // 根据错误码提供用户友好的提示
      switch (err.code) {
        case 13900002: // 文件不存在或无权限
          console.error('文件可能已被移动或删除，或应用无权限访问。')
          break;
        case 202: // 能力未找到
          console.error('未找到可以打开此文件类型的应用。')
          break;
        default:
          console.error(`打开文件失败: ${err.message}`)
      }
    } finally {
      OpenFileWithSystemApp.isProcessing = false;
    }
  }
}

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