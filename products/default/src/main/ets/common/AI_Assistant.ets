/**
 * 语音助手语音处理逻辑
 */
import { tableDataModel } from 'command_ai'
import { common, OpenLinkOptions, Want } from '@kit.AbilityKit';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Communication } from 'mouse';
import { OpenFileWithSystemApp } from 'api';

export class AI_Assistant {
  // 相似度阈值常量
  private readonly SIMILARITY_THRESHOLD: number = 0.6;
  private readonly table_data: tableDataModel[] = AppStorage.get('table_data') as tableDataModel[]
  private readonly HIGH_CONFIDENCE_THRESHOLD: number = 0.8;
  private readonly isAI_assistant: boolean = AppStorage.get('table_data') as boolean;
  private readonly voiceInputText: string = AppStorage.get('voiceInputText') as string;

  changeText(): void {
    if (this.isAI_assistant && this.voiceInputText) {
      console.log('=== 语音指令处理开始 ===');
      console.log('语音输入:', this.voiceInputText);

      const bestMatch = this.findBestMatch(this.voiceInputText);

      if (bestMatch) {
        console.log(`最佳匹配: 索引 ${bestMatch.index}, 相似度 ${bestMatch.similarity.toFixed(3)}, 指令 "${bestMatch.item.voice}"`);

        // 根据置信度决定是否执行
        if (bestMatch.similarity >= this.HIGH_CONFIDENCE_THRESHOLD) {
          console.log('高置信度匹配，执行指令:', JSON.stringify(bestMatch.item));
          this.executeCommand(bestMatch.item);
        } else {
          console.log('中等置信度匹配，可能需要用户确认');
          this.executeCommand(bestMatch.item);
        }
      } else {
        console.log('未找到匹配指令，执行默认搜索');
        this.openWebpageForSearch(this.voiceInputText);
      }
    }
  }

  /**
   * 文本预处理
   */
  private preprocessText(text: string): string {
    if (!text) {
      return '';
    }
    return text.replace(/[^\u4e00-\u9fa5a-zA-Z0-9]/g, '').trim();
  }

  /**
   * 简单拼音转换
   */
  private toPinyin(text: string): string {
    // 基础实现，实际项目中应使用拼音库
    return text;
  }

  /**
   * 计算字符串相似度
   */
  private calculateSimilarity(str1: string, str2: string): number {
    if (!str1 || !str2) {
      return 0;
    }

    const processedA = this.preprocessText(str1);
    const processedB = this.preprocessText(str2);

    // 完全匹配
    if (processedA === processedB) {
      return 1.0;
    }

    // 包含关系
    if (processedA.includes(processedB) || processedB.includes(processedA)) {
      return 0.8;
    }

    // 计算字符编辑距离相似度
    const longer = processedA.length > processedB.length ? processedA : processedB;
    const shorter = processedA.length > processedB.length ? processedB : processedA;

    if (longer.length === 0) {
      return 1.0;
    }

    const charEditDistance = this.calculateEditDistance(processedA, processedB);
    const charMaxLength = Math.max(processedA.length, processedB.length);
    const charSimilarity = charMaxLength === 0 ? 1.0 : 1.0 - (charEditDistance / charMaxLength);

    // 计算拼音相似度
    const pinyinA = this.toPinyin(processedA);
    const pinyinB = this.toPinyin(processedB);
    let pinyinSimilarity = 0.0;

    if (pinyinA && pinyinB && pinyinA.length > 0 && pinyinB.length > 0) {
      const pinyinEditDistance = this.calculateEditDistance(pinyinA, pinyinB);
      const pinyinMaxLength = Math.max(pinyinA.length, pinyinB.length);
      pinyinSimilarity = 1.0 - (pinyinEditDistance / pinyinMaxLength);
    } else if (!pinyinA && !pinyinB) {
      pinyinSimilarity = 1.0;
    }

    // 加权计算最终相似度
    return (charSimilarity * 0.7) + (pinyinSimilarity * 0.3);
  }

  /**
   * 计算编辑距离 - 修复解构赋值错误
   */
  private calculateEditDistance(s1: string, s2: string): number {
    const len1 = s1.length;
    const len2 = s2.length;

    // 使用二维数组，避免解构赋值
    let prevRow: number[] = [];
    let currRow: number[] = [];

    // 初始化prevRow
    for (let j = 0; j <= len2; j++) {
      prevRow[j] = j;
    }

    for (let i = 1; i <= len1; i++) {
      currRow = [];
      currRow[0] = i;

      for (let j = 1; j <= len2; j++) {
        const cost = s1[i - 1] === s2[j - 1] ? 0 : 1;
        currRow[j] = Math.min(
          prevRow[j] + 1, // 删除
          currRow[j - 1] + 1, // 插入
          prevRow[j - 1] + cost // 替换
        );
      }

      // 不使用解构赋值，改用临时变量
      const tempRow = prevRow;
      prevRow = currRow;
      currRow = tempRow;
    }

    return prevRow[len2];
  }

  /**
   * 查找最佳匹配
   */
  private findBestMatch(inputText: string): MatchResult | null {
    if (!inputText || this.table_data.length === 0) {
      return null;
    }

    let bestMatch: MatchResult | null = null;
    const validMatches: MatchResult[] = [];

    console.log('=== 开始语音指令匹配 ===');
    console.log('输入文本:', inputText);
    console.log('可用指令数量:', this.table_data.length);

    // 收集所有超过阈值的匹配项
    this.table_data.forEach((item: tableDataModel, index: number) => {
      const similarity = this.calculateSimilarity(item.voice, inputText);
      console.log(`指令 "${item.voice}" 相似度: ${similarity.toFixed(3)}`);

      if (similarity >= this.SIMILARITY_THRESHOLD) {
        validMatches.push({
          index: index,
          similarity: similarity,
          item: item
        });
      }
    });

    // 按相似度排序，选择最佳匹配
    if (validMatches.length > 0) {
      validMatches.sort((a: MatchResult, b: MatchResult) => b.similarity - a.similarity);
      bestMatch = validMatches[0];
      console.log(`找到 ${validMatches.length} 个匹配指令，最佳匹配: "${bestMatch.item.voice}"`);
    }

    return bestMatch;
  }

  /**
   * 执行指令
   */
  private executeCommand(item: tableDataModel): void {
    try {
      switch (item.category) {
        case CommandCategory.FILE:
          this.openFileWithSystemApp(item.execute);
          break;
        case CommandCategory.WEBSITE:
          this.openTheWebpageDirect(item.execute);
          break;
        case CommandCategory.EDIT:
          this.inputFixedText(item.execute);
          break;
        case CommandCategory.FOLDER:
          console.log('打开文件夹功能待实现:', item.execute);
          this.explorer(item.execute);
          break;
        case CommandCategory.APP:
          console.log('打开应用功能待实现:', item.execute);
          break;
        default:
          console.log('未知指令类别，执行默认搜索:', item.category);
          this.openWebpageForSearch(item.voice);
      }
    } catch (error) { // 修复错误1：明确指定error类型
      console.error('执行指令失败:', error.message);
      this.openWebpageForSearch(item.voice);
    }
  }

  explorer(execute: string) {
    const TAG: string = '[UIAbilityComponentsOpenLink]'; // 定义日志标签
    const DOMAIN_NUMBER: number = 0xFF00; // 定义日志域编号
    let context: common.UIAbilityContext = AppStorage.get('context') as common.UIAbilityContext; // 获取当前UIAbility上下文
    let link: string = 'filemanager://openDirectory'; // 定义要打开的链接，这里是文件管理的URI
    let openLinkOptions: OpenLinkOptions = {
      // 配置打开链接的选项
      parameters: {
        // 参数设置
        'fileUri': execute // 文件URI参数，这里为空
        // 'fileUri': 'file://docs/storage/Users/currentUser/Desktop/%E6%96%B0%E5%BB%BA%20DWG%20%E6%96%87%E4%BB%B6.dwg' // 文件URI参数，这里为空
        // 'fileUri': 'file://docs/storage/Users/currentUser/Documents/test.txt' // 文件URI参数，这里为空
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
  }

  /**
   * 打开网页
   */
  openTheWebpageDirect(execute: string): void {
    const context: common.UIAbilityContext = AppStorage.get('context') as common.UIAbilityContext;
    const defaultUrl: string = 'https://www.baidu.com/';

    const ensureUrlProtocol = (url: string): string => {
      if (!url) {
        return defaultUrl;
      }
      const trimmedUrl = url.trim();
      if (!trimmedUrl.startsWith('http://') && !trimmedUrl.startsWith('https://')) {
        return 'https://' + trimmedUrl;
      }
      return trimmedUrl;
    };

    const isValidUrl = (url: string): boolean => {
      try {
        const urlRegex =  /^(https?:\/\/)?[\w.-]+\.[a-z]{2,}.*$/i;
        return urlRegex.test(url);
      } catch (error) { // 修复错误1：明确指定error类型
        return false;
      }
    };

    let finalUrl = defaultUrl;
    if (typeof execute === 'string' && execute.trim() !== '') {
      const processedUrl = ensureUrlProtocol(execute);
      if (isValidUrl(processedUrl)) {
        finalUrl = processedUrl;
      }
    }

    console.log('打开网址:', finalUrl);
    const want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: finalUrl
    };

    context.startAbility(want).catch((err: BusinessError) => {
      console.error('打开网页失败:', err.message);
    });
  }

  /**
   * 输入固定文本
   */
  inputFixedText(execute: string): void {
    try {
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, execute);
      const systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();

      systemPasteboard.setData(pasteData)
        .then(() => {
          console.info('文本已复制到剪贴板:', execute);
          Communication.getDeviceInfo([0x20, 0x01, 0x19]);

          setTimeout(() => {
            systemPasteboard.clearData().catch((err: BusinessError) => {
              console.error('清空剪贴板失败:', err.message);
            });
          }, 2000);
        })
        .catch((err: BusinessError) => {
          console.error('复制失败:', err.message);
        });
    } catch (error) { // 修复错误1：明确指定error类型
      console.error('复制操作异常:', error.message);
    }
  }

  /**
   * 打开文件
   */
  async openFileWithSystemApp(execute: string): Promise<void> {
    try {
      const mimeType: string = OpenFileWithSystemApp.getMimeType(OpenFileWithSystemApp.getFileNameFromUri(execute));
      const want: Want = {
        action: 'ohos.want.action.view',
        uri: execute,
        type: mimeType
      };
      await OpenFileWithSystemApp.context.startAbility(want);
      hilog.info(0x0000, 'FileOpener', 'System app launch request sent.');
    } catch (error) { // 修复错误1：明确指定error类型
      const err: BusinessError = error as BusinessError;
      hilog.error(0x0000, 'FileOpener', 'Failed to open file: code=%{public}d, message=%{public}s', err.code,
        err.message);
    } finally {
      OpenFileWithSystemApp.isProcessing = false;
    }
  }

  /**
   * 网页搜索 - 修复数组类型错误
   */
  openWebpageForSearch(text: string): void {
    const context: common.UIAbilityContext = AppStorage.get('context') as common.UIAbilityContext;
    const encodedKeyword = encodeURIComponent(text);
    let uri: string = '';

    const searchEngine = AppStorage.get('EnhancedBrowserSearch') as number || 0;

    // 修复错误3、4、5：明确指定数组类型
    const searchEngines: SearchEngineConfig[] = [
      { name: '百度', url: `https://www.baidu.com/s?wd=${encodedKeyword}` } as SearchEngineConfig,
      { name: '谷歌', url: `https://www.google.com/search?q=${encodedKeyword}` } as SearchEngineConfig
    ];

    if (searchEngine >= 0 && searchEngine < searchEngines.length) {
      uri = searchEngines[searchEngine].url;
      console.log(`使用${searchEngines[searchEngine].name}搜索: ${text}`);
    } else {
      uri = searchEngines[0].url;
      console.log(`使用默认搜索引擎搜索: ${text}`);
    }

    const want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: uri
    };

    context.startAbility(want).catch((err: BusinessError) => {
      console.error('搜索失败:', err.message);
    });
  }
}

// 定义匹配结果接口
interface MatchResult {
  index: number;
  similarity: number;
  item: tableDataModel;
}

// 指令类型枚举
enum CommandCategory {
  WEBSITE = '网址',
  EDIT = '生成文本',
  FILE = '文件',
  FOLDER = '文件夹',
  APP = '应用',
  OTHER = '其他'
}

// 定义搜索引擎配置接口
interface SearchEngineConfig {
  name: string;
  url: string;
}