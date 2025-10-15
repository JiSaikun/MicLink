import { common, Want } from "@kit.AbilityKit";
import { OpenFileWithSystemApp } from "api";
import { tableDataModel } from 'command_ai';
import { hilog } from "@kit.PerformanceAnalysisKit";
import { BusinessError, pasteboard } from "@kit.BasicServicesKit";
import { Communication } from "mouse";

// 定义匹配结果接口
interface MatchResult {
  index: number;
  similarity: number;
  item: tableDataModel;
}
@Entry
@Component
export struct Overlay {
  @Watch('changeText') @StorageLink('voiceInputText') voiceInputText: string = ''
  @StorageLink('voiceInputState') voiceInputState: boolean = true
  @StorageLink('table_data') table_data: tableDataModel[] = []
  @StorageLink('isAI_assistant') isAI_assistant: boolean = false //是不是语音助手

  // 计算字符串相似度的方法
  private calculateSimilarity(str1: string, str2: string): number {
    if (!str1 || !str2) return 0;

    const s1 = str1.trim().toLowerCase();
    const s2 = str2.trim().toLowerCase();

    // 完全匹配
    if (s1 === s2) return 1;

    // 包含关系
    if (s1.includes(s2) || s2.includes(s1)) return 0.8;

    // 计算编辑距离相似度
    const longer = s1.length > s2.length ? s1 : s2;
    const shorter = s1.length > s2.length ? s2 : s1;

    if (longer.length === 0) return 1.0;

    const editDistance = this.calculateEditDistance(longer, shorter);
    return (longer.length - editDistance) / longer.length;
  }

  // 计算编辑距离（Levenshtein距离）
  private calculateEditDistance(s1: string, s2: string): number {
    const len1 = s1.length;
    const len2 = s2.length;

    // 创建二维数组
    const matrix: number[][] = [];
    for (let i = 0; i <= len1; i++) {
      matrix[i] = [];
      for (let j = 0; j <= len2; j++) {
        if (i === 0) {
          matrix[i][j] = j;
        } else if (j === 0) {
          matrix[i][j] = i;
        } else {
          matrix[i][j] = 0;
        }
      }
    }

    // 填充矩阵
    for (let i = 1; i <= len1; i++) {
      for (let j = 1; j <= len2; j++) {
        const cost = s1[i - 1] === s2[j - 1] ? 0 : 1;
        matrix[i][j] = Math.min(
          matrix[i - 1][j] + 1,     // 删除
          matrix[i][j - 1] + 1,     // 插入
          matrix[i - 1][j - 1] + cost // 替换
        );
      }
    }

    return matrix[len1][len2];
  }

  // 查找相似度最高的指令
  private findBestMatch(inputText: string): MatchResult | null {
    if (!inputText || this.table_data.length === 0) {
      return null;
    }

    let bestMatch: MatchResult | null = null;
    const SIMILARITY_THRESHOLD = 0.3; // 相似度阈值，可以根据需要调整

    console.log('=== 开始语音指令匹配 ===');
    console.log('输入文本:', inputText);
    console.log('可用指令数量:', this.table_data.length);

    this.table_data.forEach((item: tableDataModel, index: number) => {
      const similarity = this.calculateSimilarity(item.voice, inputText);
      console.log(`指令 "${item.voice}" 相似度: ${similarity.toFixed(3)}`);

      if (similarity >= SIMILARITY_THRESHOLD) {
        if (!bestMatch || similarity > bestMatch.similarity) {
          bestMatch = {
            index: index,
            similarity: similarity,
            item: item
          };
        }
      }
    });

    return bestMatch;
  }

  changeText() {
    if (this.isAI_assistant && this.voiceInputText) {
      console.log('=== 语音指令处理开始 ===');
      console.log('语音输入:', this.voiceInputText);

      // 查找相似度最高的指令
      const bestMatch = this.findBestMatch(this.voiceInputText);

      // 安全地处理匹配结果
      if (bestMatch) {
        console.log(`最佳匹配: 索引 ${bestMatch.index}, 相似度 ${bestMatch.similarity.toFixed(3)}, 指令 "${bestMatch.item.voice}"`);

        if (bestMatch.similarity >= 0.5) { // 使用更高的阈值来执行操作
          console.log('执行匹配指令:', JSON.stringify(bestMatch.item));

          switch (bestMatch.item.category) {
            case '文件':
              this.openFileWithSystemApp(bestMatch.item.execute);
              break;
            case '网址':
              this.openTheWebpageDirect(bestMatch.item.execute);
              break;
            case '生成文本':
              this.inputFixedText(bestMatch.item.execute);
              break;
            default:
              console.log('未知指令类别:', bestMatch.item.category);
            // 默认执行网页搜索
              this.openWebpageForSearch(this.voiceInputText);
          }
        } else {
          console.log('未找到高相似度指令，执行默认搜索');
          // 没有匹配的指令，执行默认的网页搜索
          this.openWebpageForSearch(this.voiceInputText);
        }
      } else {
        console.log('未找到任何匹配指令，执行默认搜索');
        // 没有匹配的指令，执行默认的网页搜索
        this.openWebpageForSearch(this.voiceInputText);
      }
    }
  }

  // 直接打开网址
  private openTheWebpageDirect(url: string) {
    if (!url) {
      console.log('网址为空');
      return;
    }

    const context: common.UIAbilityContext = AppStorage.get('context') as common.UIAbilityContext;

    // 网址校验函数
    const isValidUrl = (url: string): boolean => {
      try {
        // 简单的网址格式检查
        const urlRegex: RegExp = /^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,6})([\/\w.-]*)*\/?$/i;
        return urlRegex.test(url);
      } catch {
        return false;
      }
    };

    // 确保网址有协议前缀
    let finalUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      finalUrl = 'https://' + url;
    }

    if (!isValidUrl(finalUrl)) {
      console.log('无效的网址:', finalUrl);
      return;
    }

    const want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: finalUrl
    };

    context.startAbility(want).then(() => {
      console.log('成功打开网址:', finalUrl);
    }).catch((err: BusinessError) => {
      console.error('打开网址失败:', err.message);
    });
  }

  // 为搜索词打开网页
  private openWebpageForSearch(searchText: string) {
    const context: common.UIAbilityContext = AppStorage.get('context') as common.UIAbilityContext;
    const encodedKeyword = encodeURIComponent(searchText);
    let uri: string = '';

    // 获取搜索配置，默认为百度
    const searchConfig = AppStorage.get('EnhancedBrowserSearch') as number || 0;

    switch (searchConfig) {
      case 0: //百度
        uri = `https://www.baidu.com/s?wd=${encodedKeyword}`;
        break;
      case 1: //谷歌
        uri = `https://www.google.com/search?q=${encodedKeyword}`;
        break;
      default:
        uri = `https://www.baidu.com/s?wd=${encodedKeyword}`;
    }

    const want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: uri,
    };

    context.startAbility(want).then(() => {
      console.log('成功打开搜索页面:', uri);
    }).catch((err: BusinessError) => {
      console.error('打开搜索页面失败:', err.message);
    });
  }

  inputFixedText(execute: string) {
    try {
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, execute);
      let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      systemPasteboard.setData(pasteData)
        .then(() => {
          console.info('文本已复制到剪贴板: ' + execute);
          Communication.getDeviceInfo([0x20, 0x01, 0x19]) //Ctrl+V
          setTimeout(() =>
          systemPasteboard.clearData()
            , 2000)
        })
        .catch((err: BusinessError) => {
          console.error('复制失败: ' + err.message);
        });
    } catch (error) {
      const businessError = error as BusinessError;
      console.error('复制操作异常: ' + businessError.message);
    }
  }

  async openFileWithSystemApp(execute: string) {
    try {
      const mimeType: string =
        OpenFileWithSystemApp.getMimeType(OpenFileWithSystemApp.getFileNameFromUri(execute));

      const want: Want = {
        action: 'ohos.want.action.view',
        uri: execute,
        type: mimeType
      };

      await OpenFileWithSystemApp.context.startAbility(want);
      hilog.info(0x0000, 'FileOpener', 'System app launch request sent.');

    } catch (error) {
      const err: BusinessError = error as BusinessError;
      hilog.error(0x0000, 'FileOpener', 'Failed to open file: code=%{public}d, message=%{public}s', err.code,
        err.message);

      switch (err.code) {
        case 13900002:
          console.error('文件可能已被移动或删除，或应用无权限访问。')
          break;
        case 202:
          console.error('未找到可以打开此文件类型的应用。')
          break;
        default:
          console.error(`打开文件失败: ${err.message}`)
      }
    } finally {
      OpenFileWithSystemApp.isProcessing = false;
    }
  }

  build() {
    Flex({ direction: FlexDirection.Column }) {
      Flex() {
        Stack() {
          Image($r("app.media.float_window_deafult"))
            .width(100)
            .height(100)
          if (this.isAI_assistant) {
            Image($r(`${this.voiceInputState ? 'app.media.AI_assistant' : 'app.media.unAI_assistant'}`))
              .width(32)
              .height(32)
          } else {
            Image($r(`${this.voiceInputState ? 'app.media.voiceing_icon' : 'app.media.voice_icon'}`))
              .width(32)
              .height(32)
          }
        }
        .margin({ right: 24 })
        .width(100)

        Scroll() {
          Text(this.voiceInputText)
            .textAlign(TextAlign.Start)
            .padding({ right: 8, left: 8 })
            .fontSize(14)
            .fontWeight(400)
            .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
            .width('100%')
        }
        .align(Alignment.TopStart)
        .height('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .padding(24)
      .borderRadius(16)
      .backgroundColor(Color.White)
    }
  }
}