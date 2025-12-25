import { fileIo as fs } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common, OpenLinkOptions } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"
import { TopTitle } from "../common/TopTitle"
import { picker } from '@kit.CoreFileKit';
import { fileUri } from '@kit.CoreFileKit';

@Builder
export function FileManagementBuilder() {
  FileManagement()
}

// 文件信息接口
interface FileInfo {
  name: string;
  path: string;
  isDirectory: boolean;
  size: number;
  lastModified: number;
  extension: string;
}

// 文件统计信息接口
interface FileStats {
  total: number;
  folders: number;
  files: number;
  totalSize: number;
}

// 对话框结果接口
interface DialogResult {
  index: number;
}

@Component
struct FileManagement {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @Consume('pageInfo') pageInfo: NavPathStack
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State fileList: FileInfo[] = [];
  @State filteredFileList: FileInfo[] = [];
  @State isLoading: boolean = true;
  @State currentDirectory: string = '';
  @State currentDirectoryUri: string = '';
  @State errorMessage: string = '';
  // 添加AppStorage链接
  @StorageLink('downloadDirectoryUri') downloadDirectoryUri: string = '';
  @State selectedFilter: string = 'all'; // 'all', 'files', 'folders'
  @State searchKeyword: string = '';
  @State showFileStats: boolean = false;
  @State stats: FileStats = {
    total: 0,
    folders: 0,
    files: 0,
    totalSize: 0
  };

  aboutToAppear() {
    console.info('FileManagement组件已加载');

    // 优先使用AppStorage中保存的下载目录
    if (this.downloadDirectoryUri && this.downloadDirectoryUri !== '') {
      console.info('使用AppStorage中的下载目录URI: ' + this.downloadDirectoryUri);
      this.useDownloadDirectoryUri(this.downloadDirectoryUri);
    } else {
      console.info('AppStorage中没有下载目录，尝试获取系统下载目录');
      this.getSystemDownloadDirectory();
    }
  }

  // 使用下载目录URI
  private useDownloadDirectoryUri(dirUri: string): void {
    try {
      console.info('使用下载目录URI: ' + dirUri);

      this.currentDirectoryUri = dirUri;

      try {
        // 将URI转换为文件路径
        const filePath = new fileUri.FileUri(dirUri).path;
        console.info('下载目录路径: ' + filePath);
        this.currentDirectory = filePath;

        // 列出目录中的文件
        this.listFilesInDirectory();
      } catch (uriError) {
        console.error('URI转换为路径失败: ' + JSON.stringify(uriError));

        // 如果URI转换失败，尝试直接使用URI作为路径
        if (dirUri.startsWith('file://')) {
          // 尝试去掉file://前缀
          const path = dirUri.substring(7);
          console.info('尝试使用去掉file://前缀的路径: ' + path);
          this.currentDirectory = path;
          this.listFilesInDirectory();
        } else {
          this.errorMessage = '无法处理下载目录URI';
          this.isLoading = false;
        }
      }
    } catch (error) {
      console.error('处理下载目录URI时出错: ' + JSON.stringify(error));
      this.errorMessage = '处理下载目录失败';
      this.isLoading = false;
    }
  }

  // 获取系统下载目录 - 模仿Tab_ai组件的方式
  private getSystemDownloadDirectory(): void {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      console.info('开始获取系统下载目录，使用DocumentViewPicker方式');

      // 使用DocumentViewPicker获取系统下载目录（与Tab_ai组件相同的方式）
      const documentViewPicker = new picker.DocumentViewPicker(context);
      const documentSaveOptions = new picker.DocumentSaveOptions();

      // 配置为DOWNLOAD模式 - 与Tab_ai组件相同
      documentSaveOptions.pickerMode = picker.DocumentPickerMode.DOWNLOAD;

      // 设置一个临时文件名，仅用于获取目录
      documentSaveOptions.newFileNames = ['temp_file_for_directory_access.txt'];

      console.info('调用DocumentViewPicker.save()获取下载目录...');

      documentViewPicker.save(documentSaveOptions).then((documentSaveResult: Array<string>) => {
        if (documentSaveResult.length > 0) {
          const fullUri = documentSaveResult[0];
          console.info('获取到系统下载目录URI: ' + fullUri);

          // 提取目录部分（去掉文件名）
          const lastSlashIndex = fullUri.lastIndexOf('/');
          if (lastSlashIndex !== -1) {
            // 获取目录URI（去掉文件名）
            const dirUri = fullUri.substring(0, lastSlashIndex);

            // 保存到AppStorage
            AppStorage.Set<string>('downloadDirectoryUri', dirUri);
            console.info('已将下载目录URI保存到AppStorage: ' + dirUri);

            this.currentDirectoryUri = dirUri;

            // 将URI转换为文件路径
            try {
              const filePath = new fileUri.FileUri(dirUri).path;
              console.info('系统下载目录路径: ' + filePath);
              this.currentDirectory = filePath;

              // 列出目录中的文件
              this.listFilesInDirectory();
            } catch (uriError) {
              console.error('URI转换为路径失败: ' + JSON.stringify(uriError));
              this.errorMessage = '无法转换目录路径';
              this.isLoading = false;
            }
          } else {
            console.error('URI格式不正确: ' + fullUri);
            this.errorMessage = '获取的目录URI格式不正确';
            this.isLoading = false;
          }
        } else {
          console.error('未获取到下载目录');
          this.errorMessage = '无法获取系统下载目录';
          this.isLoading = false;
        }
      }).catch((err: BusinessError) => {
        console.error(`获取系统下载目录失败. code is ${err.code}, message is ${err.message}`);
        this.errorMessage = `获取下载目录失败: ${err.message}`;
        this.isLoading = false;

        // 如果获取失败，回退到备用方法
        this.fallbackToAppDownloadDirectory(context);
      });

    } catch (error) {
      const err = error as BusinessError;
      console.error('获取系统下载目录异常: ' + JSON.stringify(err));
      this.errorMessage = '获取下载目录异常';
      this.isLoading = false;
    }
  }

  // 回退到应用下载目录
  private fallbackToAppDownloadDirectory(context: common.UIAbilityContext): void {
    console.info('回退到应用下载目录...');

    try {
      // 使用应用的filesDir作为基础路径
      const appFilesDir = context.filesDir;
      const downloadDir = appFilesDir + '/Download';

      console.info('应用下载目录: ' + downloadDir);

      this.currentDirectory = downloadDir;

      // 确保目录存在
      this.ensureDirectoryExists(downloadDir);

      // 列出目录中的文件
      this.listFilesInDirectory();

    } catch (error) {
      const err = error as BusinessError;
      console.error('回退目录失败: ' + JSON.stringify(err));
      this.errorMessage = '无法访问任何下载目录';
      this.isLoading = false;
    }
  }

  // 确保目录存在
  private ensureDirectoryExists(dirPath: string): void {
    try {
      // 检查目录是否存在
      const exists = fs.accessSync(dirPath);
      if (!exists) {
        console.info('目录不存在，正在创建: ' + dirPath);
        fs.mkdirSync(dirPath, true);
        console.info('目录创建成功: ' + dirPath);
      } else {
        console.info('目录已存在: ' + dirPath);
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error('检查/创建目录失败: ' + JSON.stringify(err));

      try {
        // 尝试创建目录
        fs.mkdirSync(dirPath, true);
        console.info('目录创建成功: ' + dirPath);
      } catch (mkdirError) {
        console.error('目录创建失败: ' + JSON.stringify(mkdirError));
      }
    }
  }

  // 列出目录中的文件 - 修改为时间逆序
  private listFilesInDirectory(): void {
    console.info('开始列出目录文件: ' + this.currentDirectory);

    if (!this.currentDirectory) {
      this.errorMessage = '目录路径为空';
      this.isLoading = false;
      return;
    }

    this.isLoading = true;

    try {
      // 验证目录是否存在
      try {
        if (!fs.accessSync(this.currentDirectory)) {
          console.info('目录不存在，尝试创建');
          this.ensureDirectoryExists(this.currentDirectory);
        }
      } catch (accessError) {
        console.error('访问目录失败: ' + JSON.stringify(accessError));
        this.errorMessage = '无法访问目录';
        this.isLoading = false;
        return;
      }

      // 获取文件列表
      let files: string[] = [];
      try {
        files = fs.listFileSync(this.currentDirectory, {
          recursion: false,
          listNum: 0
        });
        console.info(`找到 ${files.length} 个文件/目录`);
      } catch (listError) {
        console.error('列出文件失败: ' + JSON.stringify(listError));

        // 尝试检查目录状态
        try {
          const dirStat = fs.statSync(this.currentDirectory);
          if (dirStat.isDirectory()) {
            console.info('目录存在但没有文件或无法列出');
            files = [];
          }
        } catch (statError) {
          console.error('检查目录状态失败: ' + JSON.stringify(statError));
        }
      }

      // 处理每个文件/目录，收集到临时数组
      const tempFileList: FileInfo[] = [];
      files.forEach((fileName: string) => {
        try {
          const filePath = this.currentDirectory + '/' + fileName;
          const stat = fs.statSync(filePath);

          const fileInfo: FileInfo = {
            name: fileName,
            path: filePath,
            isDirectory: stat.isDirectory(),
            size: stat.size,
            lastModified: stat.mtime,
            extension: this.getFileExtension(fileName)
          };

          tempFileList.push(fileInfo);
        } catch (statError) {
          console.error(`获取文件信息失败 ${fileName}: ` + JSON.stringify(statError));
        }
      });

      // 对文件列表进行排序：目录在前，文件在后，每个类别内按时间逆序排序
      tempFileList.sort((a: FileInfo, b: FileInfo) => {
        // 首先按类型排序：目录在前，文件在后
        if (a.isDirectory && !b.isDirectory) {
          return -1;
        } else if (!a.isDirectory && b.isDirectory) {
          return 1;
        } else {
          // 类型相同，按时间逆序排序（最新的在前面）
          return b.lastModified - a.lastModified;
        }
      });

      // 赋值给状态变量
      this.fileList = tempFileList;
      this.updateFilteredFileList();

      // 更新统计信息
      this.updateStats();

      // 如果没有文件，添加提示信息
      if (this.fileList.length === 0) {
        this.fileList.push({
          name: '暂无文件',
          path: '',
          isDirectory: false,
          size: 0,
          lastModified: 0,
          extension: ''
        });
      }

      this.errorMessage = '';

    } catch (error) {
      const err = error as BusinessError;
      console.error('列出文件失败: ' + JSON.stringify(err));
      this.errorMessage = '无法列出文件，错误码: ' + err.code;

      // 添加错误提示
      this.fileList = [{
        name: '无法访问目录',
        path: '',
        isDirectory: false,
        size: 0,
        lastModified: 0,
        extension: ''
      }];
    } finally {
      this.isLoading = false;
    }
  }

  // 更新统计信息
  private updateStats(): void {
    const validItems = this.fileList.filter((item: FileInfo) => item.path);
    const folders = validItems.filter((item: FileInfo) => item.isDirectory).length;
    const files = validItems.filter((item: FileInfo) => !item.isDirectory).length;
    const totalSize = validItems.reduce((sum: number, item: FileInfo) => sum + item.size, 0);

    this.stats = {
      total: validItems.length,
      folders,
      files,
      totalSize
    };
  }

  // 更新过滤后的文件列表
  private updateFilteredFileList(): void {
    // 过滤掉占位符项
    let filteredList = this.fileList.filter((item: FileInfo) => item.path !== '');

    // 根据筛选器过滤
    if (this.selectedFilter === 'files') {
      filteredList = filteredList.filter((item: FileInfo) => !item.isDirectory);
    } else if (this.selectedFilter === 'folders') {
      filteredList = filteredList.filter((item: FileInfo) => item.isDirectory);
    }

    // 根据搜索关键词过滤
    if (this.searchKeyword.trim() !== '') {
      const keyword = this.searchKeyword.toLowerCase();
      filteredList = filteredList.filter((item: FileInfo) =>
      item.name.toLowerCase().includes(keyword)
      );
    }

    this.filteredFileList = filteredList;
  }

  // 当筛选条件变化时更新过滤列表
  private onFilterChanged(): void {
    this.updateFilteredFileList();
  }

  // 获取文件扩展名
  private getFileExtension(filename: string): string {
    const dotIndex = filename.lastIndexOf('.');
    if (dotIndex > 0 && dotIndex < filename.length - 1) {
      return filename.substring(dotIndex + 1).toLowerCase();
    }
    return '';
  }

  // 格式化文件大小
  private formatFileSize(bytes: number): string {
    if (bytes === 0) {
      return '0 B';
    }

    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));

    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  // 格式化时间 - 修复版本，确保正确处理时间戳
  private formatTime(timestamp: number): string {
    if (timestamp === 0) {
      return '-';
    }

    // 确保时间戳是数字
    let timeValue = timestamp;

    // 如果时间戳是秒而不是毫秒，转换为毫秒
    if (timeValue > 0 && timeValue < 10000000000) {
      // 时间戳小于10000000000（秒级时间戳），假设为秒，转换为毫秒
      timeValue = timeValue * 1000;
    }

    try {
      const date = new Date(timeValue);

      // 验证日期是否有效
      if (isNaN(date.getTime())) {
        console.error(`无效的日期: ${timeValue}`);
        return '-';
      }

      const now = new Date();
      const diffMs = now.getTime() - date.getTime();
      const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

      if (diffDays === 0) {
        // 今天
        return date.getHours().toString().padStart(2, '0') + ':' +
        date.getMinutes().toString().padStart(2, '0');
      } else if (diffDays === 1) {
        // 昨天
        return '昨天';
      } else if (diffDays < 7) {
        // 一周内
        return diffDays + '天前';
      } else {
        // 更早
        return date.getFullYear() + '-' +
        (date.getMonth() + 1).toString().padStart(2, '0') + '-' +
        date.getDate().toString().padStart(2, '0');
      }
    } catch (error) {
      console.error('格式化时间错误: ' + JSON.stringify(error));
      return '-';
    }
  }

  // 获取文件图标
  private getFileIcon(fileInfo: FileInfo): string {
    if (fileInfo.isDirectory) {
      return '📁';
    }

    const ext = fileInfo.extension;
    const iconMap: Record<string, string> = {
      'txt': '📄',
      'pdf': '📕',
      'doc': '📘',
      'docx': '📘',
      'xls': '📗',
      'xlsx': '📗',
      'ppt': '📙',
      'pptx': '📙',
      'jpg': '🖼️',
      'jpeg': '🖼️',
      'png': '🖼️',
      'gif': '🖼️',
      'mp3': '🎵',
      'wav': '🎵',
      'mp4': '🎬',
      'avi': '🎬',
      'mov': '🎬',
      'zip': '📦',
      'rar': '📦',
      '7z': '📦',
      'apk': '📱',
      'html': '🌐',
      'htm': '🌐',
      'exe': '⚙️',
      'msi': '⚙️',
      'dmg': '🍎',
      'iso': '💿',
      'json': '{}',
      'xml': '</>',
      'js': '📜',
      'ts': '📜',
      'css': '🎨',
      'scss': '🎨',
      'less': '🎨',
      'py': '🐍',
      'java': '☕',
      'c': '🔧',
      'cpp': '🔧',
      'h': '🔧',
      'hpp': '🔧',
      'swift': '🐦',
      'go': '🚀',
      'php': '🐘',
      'rb': '💎',
      'sh': '💻',
      'bat': '💻',
      'ps1': '💻',
      'md': '📝',
      'log': '📋'
    };

    return iconMap[ext] || '📄';
  }

  // 获取文件类型描述
  private getFileTypeDescription(fileInfo: FileInfo): string {
    if (fileInfo.isDirectory) {
      return '文件夹';
    }

    const ext = fileInfo.extension;
    const typeMap: Record<string, string> = {
      'txt': '文本文档',
      'pdf': 'PDF文档',
      'doc': 'Word文档',
      'docx': 'Word文档',
      'xls': 'Excel表格',
      'xlsx': 'Excel表格',
      'ppt': 'PowerPoint演示',
      'pptx': 'PowerPoint演示',
      'jpg': 'JPEG图片',
      'jpeg': 'JPEG图片',
      'png': 'PNG图片',
      'gif': 'GIF图片',
      'mp3': '音频文件',
      'wav': '音频文件',
      'mp4': '视频文件',
      'avi': '视频文件',
      'mov': '视频文件',
      'zip': '压缩文件',
      'rar': '压缩文件',
      '7z': '压缩文件',
      'apk': '安卓应用',
      'html': '网页文件',
      'htm': '网页文件'
    };

    return typeMap[ext] || `${ext.toUpperCase()}文件`;
  }

  // 文件点击处理
  private onFileClick(fileInfo: FileInfo): void {
    if (!fileInfo.path || fileInfo.name === '暂无文件' || fileInfo.name === '无法访问目录') {
      return;
    }

    if (fileInfo.isDirectory) {
      // 如果是目录，进入目录
      this.currentDirectory = fileInfo.path;
      this.listFilesInDirectory();
    } else {
      // 如果是文件，显示操作对话框
      this.showFileActionDialog(fileInfo);
    }
  }

  // 显示文件操作对话框
  private showFileActionDialog(fileInfo: FileInfo): void {
    promptAction.showDialog({
      title: `文件: ${fileInfo.name}`,
      message: '请选择操作',
      buttons: [
        {
          text: '打开所在文件夹',
          color: '#007DFF'
        },
        {
          text: '查看文件信息',
          color: '#666666'
        },
        {
          text: '取消',
          color: '#999999'
        }
      ]
    }).then((result: DialogResult) => {
      if (result.index === 0) {
        // 打开所在文件夹
        this.openFileDirectory(fileInfo);
      } else if (result.index === 1) {
        // 显示文件信息
        this.showFileInfo(fileInfo);
      }
    });
  }

  // 打开文件所在目录
  private openFileDirectory(fileInfo: FileInfo): void {
    const filePath = fileInfo.path;
    const dirPath = filePath.substring(0, filePath.lastIndexOf('/'));

    promptAction.showDialog({
      title: '前往文件夹',
      message: `是否前往文件 "${fileInfo.name}" 所在的文件夹？`,
      buttons: [
        {
          text: '前往',
          color: '#007DFF'
        },
        {
          text: '取消',
          color: '#999999'
        }
      ]
    }).then((result: DialogResult) => {
      if (result.index === 0) {
        this.openDirectoryWithFileManager(dirPath);
      }
    });
  }

  // 使用文件管理器打开目录 - 修复版本
  private openDirectoryWithFileManager(dirPath: string): void {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const TAG: string = '[OpenDirectory]';
      const DOMAIN_NUMBER: number = 0xFF00;

      // 尝试不同的URI格式
      let dirUri: string;

      // 方法1：尝试使用当前目录的URI
      if (this.currentDirectoryUri && this.currentDirectory === dirPath) {
        dirUri = this.currentDirectoryUri;
        console.info('方法1：使用当前目录URI: ' + dirUri);
      }
      // 方法2：尝试从AppStorage获取下载目录URI
      else if (this.downloadDirectoryUri) {
        // 检查下载目录是否与目标目录匹配
        try {
          const downloadDirPath = new fileUri.FileUri(this.downloadDirectoryUri).path;
          if (downloadDirPath === dirPath) {
            dirUri = this.downloadDirectoryUri;
            console.info('方法2：使用下载目录URI: ' + dirUri);
          } else {
            // 方法3：尝试构建file:// URI
            dirUri = 'file://' + dirPath;
            console.info('方法3：构建file:// URI: ' + dirUri);
          }
        } catch (error) {
          dirUri = 'file://' + dirPath;
          console.info('方法4：构建file:// URI（备用）: ' + dirUri);
        }
      }
      // 方法4：默认使用file://前缀
      else {
        dirUri = 'file://' + dirPath;
        console.info('方法5：默认构建file:// URI: ' + dirUri);
      }

      console.info(`尝试打开目录: ${dirUri}`);

      let openLinkOptions: OpenLinkOptions = {
        parameters: {
          'fileUri': dirUri
        }
      };

      context.openLink('filemanager://openDirectory', openLinkOptions)
        .then(() => {
          console.info('打开目录成功');
          promptAction.showToast({
            message: '已打开文件管理器',
            duration: 2000
          });
          hilog.info(DOMAIN_NUMBER, TAG, 'open directory success.');
        })
        .catch((err: BusinessError) => {
          console.error(`打开目录失败. Code is ${err.code}, message is ${err.message}`);

          // 尝试使用备用方案：直接调用文件管理器
          this.fallbackOpenDirectory(context);

          hilog.error(DOMAIN_NUMBER, TAG,
            `open directory failed. Code is ${err.code}, message is ${err.message}`);
        });
    } catch (error) {
      const err = error as BusinessError;
      console.error(`打开目录参数错误. Code is ${err.code}, message is ${err.message}`);

      // 尝试使用备用方案
      try {
        const context = getContext(this) as common.UIAbilityContext;
        this.fallbackOpenDirectory(context);
      } catch (fallbackError) {
        promptAction.showToast({
          message: '无法打开文件管理器',
          duration: 3000
        });
      }
    }
  }

  // 回退方式打开目录 - 增强版本
  private fallbackOpenDirectory(context: common.UIAbilityContext): void {
    console.info('尝试回退方式打开目录');

    try {
      // 尝试1：直接打开文件管理器
      const link1: string = 'filemanager://';
      let openLinkOptions1: OpenLinkOptions = {};

      console.info('尝试1：直接打开文件管理器');

      context.openLink(link1, openLinkOptions1)
        .then(() => {
          console.info('成功打开文件管理器');
          promptAction.showToast({
            message: '已打开文件管理器',
            duration: 2000
          });
        })
        .catch((err: BusinessError) => {
          console.error(`尝试1失败. Code is ${err.code}, message is ${err.message}`);

          // 尝试2：使用更通用的URI
          console.info('尝试2：使用更通用的文件管理器URI');
          const link2: string = 'filemanager://browse';

          context.openLink(link2, openLinkOptions1)
            .then(() => {
              console.info('成功打开文件管理器（方式2）');
              promptAction.showToast({
                message: '已打开文件管理器',
                duration: 2000
              });
            })
            .catch((err2: BusinessError) => {
              console.error(`尝试2失败. Code is ${err2.code}, message is ${err2.message}`);
              promptAction.showToast({
                message: '设备不支持直接打开文件夹',
                duration: 3000
              });
            });
        });
    } catch (error) {
      console.error('回退方式打开目录失败: ' + JSON.stringify(error));
      promptAction.showToast({
        message: '打开文件夹失败',
        duration: 3000
      });
    }
  }

  // 显示文件信息
  private showFileInfo(fileInfo: FileInfo): void {
    const sizeStr = this.formatFileSize(fileInfo.size);
    const timeStr = this.formatTime(fileInfo.lastModified);
    const typeStr = this.getFileTypeDescription(fileInfo);

    promptAction.showDialog({
      title: '文件信息',
      message: `名称: ${fileInfo.name}\n\n` +
        `类型: ${typeStr}\n` +
        `大小: ${sizeStr}\n` +
        `修改时间: ${timeStr}\n` +
        `路径: ${fileInfo.path}`,
      buttons: [
        {
          text: '确定',
          color: '#007DFF'
        }
      ]
    }).then((result: DialogResult) => {
      console.info('用户查看了文件信息');
    });
  }

  // 返回上一级目录
  private goBack(): void {
    if (this.currentDirectory === '') {
      return;
    }

    const lastSlashIndex = this.currentDirectory.lastIndexOf('/');
    if (lastSlashIndex > 0) {
      const parentDir = this.currentDirectory.substring(0, lastSlashIndex);
      this.currentDirectory = parentDir;
      this.listFilesInDirectory();
    }
  }

  // 刷新当前目录
  private refresh(): void {
    this.listFilesInDirectory();
  }

  // 获取当前路径的显示名称
  private getCurrentPathDisplay(): string {
    if (!this.currentDirectory) {
      return '未知目录';
    }

    const parts = this.currentDirectory.split('/');
    if (parts.length <= 1) {
      return '/';
    }

    // 取最后两级目录
    const displayParts = parts.slice(-2);
    return '.../' + displayParts.join('/');
  }

  // 添加一个方法：切换到Tab_ai的下载目录
  private switchToTabAIDownloadDirectory(): void {
    if (this.downloadDirectoryUri && this.downloadDirectoryUri !== '') {
      console.info('切换到Tab_ai下载目录');
      this.useDownloadDirectoryUri(this.downloadDirectoryUri);

      promptAction.showToast({
        message: '已切换到下载目录',
        duration: 2000
      });
    } else {
      console.info('没有找到Tab_ai的下载目录');
      promptAction.showToast({
        message: '没有可用的下载目录',
        duration: 2000
      });
    }
  }

  build() {
    NavDestination() {
      TopTitle({ title: Languages.fileManagement[this.languages], isback: false })
        .margin({ left: 16, right: 16, bottom: 12 })
      Column() {
        // // 顶部标题栏
        // Row() {
        //   Text('📁 文件管理器')
        //     .fontSize(24)
        //     .fontWeight(FontWeight.Bold)
        //     .fontColor('#FFFFFF')
        //     .margin({ left: 20 })
        //     .flexGrow(1)
        //
        //   // 统计信息按钮
        //   Button(this.showFileStats ? '📊' : '📈')
        //     .width(50)
        //     .height(50)
        //     .fontSize(18)
        //     .backgroundColor(Color.Transparent)
        //     .onClick(() => {
        //       this.showFileStats = !this.showFileStats;
        //     })
        // }
        // .width('100%')
        // .height(70)
        // .backgroundColor('#007DFF')
        // .padding({ top: 10, bottom: 10 })

        // // 目录信息栏
        // Column() {
        //   Row() {
        //     // 返回按钮
        //     if (this.currentDirectory.includes('/')) {
        //       Button('⬅️')
        //         .width(50)
        //         .height(50)
        //         .fontSize(18)
        //         .backgroundColor('#E6F7FF')
        //         .borderRadius(25)
        //         .onClick(() => {
        //           this.goBack();
        //         })
        //     } else {
        //       Blank()
        //         .width(50)
        //         .height(50)
        //     }
        //
        //     // 当前路径显示
        //     Column() {
        //       Text('当前路径')
        //         .fontSize(12)
        //         .fontColor('#666666')
        //         .margin({ bottom: 2 })
        //
        //       Text(this.getCurrentPathDisplay())
        //         .fontSize(14)
        //         .fontColor('#333333')
        //         .maxLines(1)
        //         .textOverflow({ overflow: TextOverflow.Ellipsis })
        //     }
        //     .margin({ left: 12 })
        //     .flexGrow(1)
        //
        //     // 刷新按钮
        //     Button('🔄')
        //       .width(50)
        //       .height(50)
        //       .fontSize(18)
        //       .backgroundColor('#E6F7FF')
        //       .borderRadius(25)
        //       .onClick(() => {
        //         this.refresh();
        //       })
        //   }
        //   .width('100%')
        //   .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        // }
        // .backgroundColor('#F8F9FA')
        // .borderRadius(12)
        // .margin({ top: 16, left: 16, right: 16 })

        // 统计信息面板
        if (this.showFileStats) {
          Column() {
            Row() {
              Column() {
                Text(this.stats.total.toString())
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#007DFF')

                Text('总项目')
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .flexGrow(1)
              .alignItems(HorizontalAlign.Center)

              Column() {
                Text(this.stats.folders.toString())
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#52C41A')

                Text('文件夹')
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .flexGrow(1)
              .alignItems(HorizontalAlign.Center)

              Column() {
                Text(this.stats.files.toString())
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FF6B6B')

                Text('文件')
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .flexGrow(1)
              .alignItems(HorizontalAlign.Center)

              Column() {
                Text(this.formatFileSize(this.stats.totalSize))
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#8A2BE2')
                  .maxLines(1)

                Text('总大小')
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .flexGrow(1)
              .alignItems(HorizontalAlign.Center)
            }
            .width('100%')
            .padding({ top: 16, bottom: 16 })
          }
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .shadow({
            radius: 4,
            color: '#000000',
            offsetX: 0,
            offsetY: 2
          })
          .margin({ top: 12, left: 16, right: 16 })
        }

        // 搜索和筛选栏
        Column() {
          // 搜索框
          Row() {
            TextInput({ placeholder: '🔍 搜索文件或文件夹...', text: this.searchKeyword })
              .width('100%')
              .height(45)
              .fontSize(14)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .padding({ left: 16, right: 16 })
              .onChange((value: string) => {
                this.searchKeyword = value;
                this.onFilterChanged();
              })
          }
          .width('100%')
          .margin({ bottom: 12 })

          // 筛选按钮组
          Row() {
            Button('全部')
              .width('30%')
              .height(36)
              .fontSize(14)
              .backgroundColor(this.selectedFilter === 'all' ? '#007DFF' : '#F0F0F0')
              .fontColor(this.selectedFilter === 'all' ? '#FFFFFF' : '#666666')
              .borderRadius(6)
              .onClick(() => {
                this.selectedFilter = 'all';
                this.onFilterChanged();
              })

            Button('文件夹')
              .width('30%')
              .height(36)
              .fontSize(14)
              .backgroundColor(this.selectedFilter === 'folders' ? '#007DFF' : '#F0F0F0')
              .fontColor(this.selectedFilter === 'folders' ? '#FFFFFF' : '#666666')
              .borderRadius(6)
              .margin({ left: 8 })
              .onClick(() => {
                this.selectedFilter = 'folders';
                this.onFilterChanged();
              })

            Button('文件')
              .width('30%')
              .height(36)
              .fontSize(14)
              .backgroundColor(this.selectedFilter === 'files' ? '#007DFF' : '#F0F0F0')
              .fontColor(this.selectedFilter === 'files' ? '#FFFFFF' : '#666666')
              .borderRadius(6)
              .margin({ left: 8 })
              .onClick(() => {
                this.selectedFilter = 'files';
                this.onFilterChanged();
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .backgroundColor('#F8F9FA')
        .borderRadius(12)
        .padding({
          top: 16,
          bottom: 16,
          left: 16,
          right: 16
        })
        .margin({ top: 12, left: 16, right: 16 })

        // 错误信息显示
        if (this.errorMessage) {
          Row() {
            Text('⚠️ ' + this.errorMessage)
              .fontSize(14)
              .fontColor(Color.Red)
              .padding(12)
          }
          .width('90%')
          .backgroundColor('#FFF0F0')
          .borderRadius(8)
          .margin({ top: 12 })
          .justifyContent(FlexAlign.Center)
        }

        // 文件列表区域
        Column() {
          // 列表标题
          Row() {
            Text('📂 文件列表')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .margin({ left: 16 })

            // 切换到Tab_ai下载目录的按钮
            Button('📥 下载目录')
              .height(32)
              .fontSize(12)
              .backgroundColor('#007DFF')
              .fontColor('#FFFFFF')
              .borderRadius(16)
              .margin({ right: 16 })
              .onClick(() => {
                this.switchToTabAIDownloadDirectory();
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ top: 16, bottom: 12 })

          // 文件列表
          if (this.isLoading) {
            Column() {
              LoadingProgress()
                .color('#007DFF')
                .width(60)
                .height(60)
                .margin({ bottom: 16 })

              Text('正在加载文件列表...')
                .fontSize(16)
                .fontColor('#666666')
            }
            .width('100%')
            .height(200)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else {
            // 使用过滤后的文件列表
            if (this.filteredFileList.length === 0) {
              Column() {
                Text('📭')
                  .fontSize(48)
                  .margin({ bottom: 16 })

                Text('未找到匹配的文件')
                  .fontSize(16)
                  .fontColor('#999999')

                if (this.searchKeyword.trim() !== '') {
                  Text('请尝试其他搜索关键词')
                    .fontSize(14)
                    .fontColor('#999999')
                    .margin({ top: 8 })
                }
              }
              .width('100%')
              .height(200)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
            } else {
              List({ space: 0 }) {
                ForEach(this.filteredFileList, (item: FileInfo) => {
                  ListItem() {
                    Row() {
                      // 文件图标区域
                      Column() {
                        Text(this.getFileIcon(item))
                          .fontSize(32)
                          .width(50)
                          .height(50)
                          .backgroundColor(item.isDirectory ? '#E6F7FF' : '#F0F0F0')
                          .borderRadius(10)
                          .textAlign(TextAlign.Center)
                      }
                      .margin({ right: 16 })

                      // 文件信息区域
                      Column() {
                        Text(item.name)
                          .fontSize(16)
                          .fontColor(item.path ? Color.Black : '#999999')
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .margin({ bottom: 4 })

                        if (item.path) {
                          Row() {
                            if (item.isDirectory) {
                              Text('📁 文件夹')
                                .fontSize(12)
                                .fontColor('#52C41A')
                                .backgroundColor('#F6FFED')
                                .padding({
                                  left: 6,
                                  right: 6,
                                  top: 2,
                                  bottom: 2
                                })
                                .borderRadius(4)
                            } else {
                              Text('📄 ' + this.getFileTypeDescription(item))
                                .fontSize(12)
                                .fontColor('#666666')
                                .margin({ right: 8 })
                            }
                          }
                          .width('100%')
                          .margin({ bottom: 4 })

                          Row() {
                            if (!item.isDirectory) {
                              Text(this.formatFileSize(item.size))
                                .fontSize(12)
                                .fontColor('#8A2BE2')
                                .margin({ right: 8 })
                            }

                            Text('🕒 ' + this.formatTime(item.lastModified))
                              .fontSize(12)
                              .fontColor('#999999')
                          }
                          .width('100%')
                        }
                      }
                      .flexGrow(1)

                      // 操作指示器
                      if (item.path) {
                        if (item.isDirectory) {
                          Text('➡️')
                            .fontSize(16)
                            .fontColor('#999999')
                            .margin({ left: 8 })
                        } else {
                          Text('⋮')
                            .fontSize(20)
                            .fontColor('#999999')
                            .margin({ left: 8 })
                        }
                      }
                    }
                    .width('100%')
                    .padding({
                      top: 12,
                      bottom: 12,
                      left: 16,
                      right: 16
                    })
                  }
                  .onClick(() => {
                    this.onFileClick(item);
                  })
                  .border({ width: { bottom: 1 }, color: '#EEEEEE' })
                }, (item: FileInfo) => JSON.stringify(item))
              }
              .width('100%')
              .flexGrow(1)
            }
          }
        }
        .layoutWeight(1)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .margin({
          top: 12,
          left: 16,
          right: 16,
          bottom: 12
        })

        // 底部操作栏
        Row() {
          Column() {
            Text('📁 文件管理器 v1.0')
              .fontSize(12)
              .fontColor('#666666')

            if (this.downloadDirectoryUri && this.downloadDirectoryUri !== '') {
              Text('✅ 已连接到MicLink下载目录')
                .fontSize(11)
                .fontColor('#52C41A')
                .margin({ top: 2 })
            }
          }
          .flexGrow(1)

          Text(`${this.filteredFileList.length} 个项目`)
            .fontSize(12)
            .fontColor('#666666')
        }
        .width('100%')
        .padding({
          top: 12,
          bottom: 12,
          left: 20,
          right: 20
        })
        .backgroundColor('#F8F9FA')
        .border({ width: { top: 1 }, color: '#EEEEEE' })
      }
      .layoutWeight(1)
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}