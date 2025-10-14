import { common, Want } from "@kit.AbilityKit";
import { OpenFileWithSystemApp } from "api";
import { tableDataModel } from 'command_ai'
import { hilog } from "@kit.PerformanceAnalysisKit";
import { BusinessError, pasteboard } from "@kit.BasicServicesKit";
import { Communication } from "mouse";

@Entry
@Component
export struct Overlay {
  @Watch('changeText') @StorageLink('voiceInputText') voiceInputText: string = ''
  @StorageLink('voiceInputState') voiceInputState: boolean = true
  @StorageLink('table_data') table_data: tableDataModel[] = []
  @StorageLink('isAI_assistant') isAI_assistant: boolean = false //是不是语音助手

  changeText() {
    if (this.isAI_assistant && this.voiceInputText) {
      let maxIndex: number = -1;

      // 模糊匹配：忽略大小写、空格等差异
      const normalizedInput = this.voiceInputText.trim().toLowerCase().replace(/\s+/g, '');

      this.table_data.forEach((item, index) => {
        const normalizedVoice = item.voice.trim().toLowerCase().replace(/\s+/g, '');

        // 使用 includes 或完全匹配
        if (normalizedVoice === normalizedInput ||
        normalizedInput.includes(normalizedVoice) ||
        normalizedVoice.includes(normalizedInput)) {
          maxIndex = index;
          return; // 找到第一个匹配项就返回
        }
      });

      console.log('语音输入:', this.voiceInputText);
      console.log('匹配到的索引:', maxIndex);

      if (maxIndex !== -1) {
        const matchedItem = this.table_data[maxIndex];
        console.log('匹配到的指令:', JSON.stringify(matchedItem));

        switch (matchedItem.category) {
          case '文件':
            this.openFileWithSystemApp(matchedItem.execute);
            return;
          case '网址':
            this.openTheWebpageDirect(matchedItem.execute); // 直接打开网址
            return;
          case '生成文本':
            this.inputFixedText(matchedItem.execute);
            return;
        }
      } else {
        console.log('未找到匹配指令，执行默认搜索');
        // 没有匹配的指令，执行默认的网页搜索
        this.openWebpageForSearch(this.voiceInputText);
      }
    }
  }

  openTheWebpageDirect(execute: string) {
    // 明确context的类型
    const context: common.UIAbilityContext = AppStorage.get('context') as common.UIAbilityContext;
    // 明确storedUrl为string类型（可能为null/undefined）
    const storedUrl: string | null | undefined = execute;
    const defaultUrl: string = 'https://www.baidu.com/';

    // 网址校验函数（适配ArkTS，不依赖URL对象）
    const isValidUrl = (url: string): boolean => {
      // 基础正则：检查http/https开头及基本域名格式
      const urlRegex: RegExp = /^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,6})([\/\w.-]*)*\/?$/i;
      return urlRegex.test(url);
    };

    // 确定最终URL（严格类型判断）
    let finalUrl: string = defaultUrl;
    if (typeof storedUrl === 'string' && storedUrl.trim() !== '' && isValidUrl(storedUrl)) {
      finalUrl = storedUrl;
    }

    const want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: finalUrl
    }

    context.startAbility(want);
  }

  inputFixedText(execute: string) {
    try {
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, execute);
      let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard(); //获取系统剪贴板对象。
      // systemPasteboard.setAppShareOptions(pasteboard.ShareOption.INAPP);
      systemPasteboard.setData(pasteData)
        .then(() => {
          // console.info('文本已复制到剪贴板: ' + audioToText_res);
          Communication.getDeviceInfo([0x20, 0x01, 0x19]) //Ctrl+V
          setTimeout(() =>
          systemPasteboard.clearData() //清空剪贴板
            , 2000)
        })
        .catch((err: BusinessError) => {
          console.error('复制失败: ' + err.message);
        });
    } catch (error) {
      console.error('复制操作异常: ' + error.message);
    }

  }

  async openFileWithSystemApp(execute: string) {

    try {
      // 步骤2: 准备文件信息
      // this.selectedFileName = this.getFileNameFromUri(selectedFileUri);
      const mimeType: string =
        OpenFileWithSystemApp.getMimeType(OpenFileWithSystemApp.getFileNameFromUri(execute));

      // 步骤3: 构建Want意图，告诉系统"我要查看这个文件"
      const want: Want = {
        action: 'ohos.want.action.view', // 标准的查看动作
        uri: execute, // 使用选择的文件URI，而不是硬编码的路径
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

  openWebpageForSearch(text: string) {
    const context: common.UIAbilityContext = AppStorage.get('context') as common.UIAbilityContext;
    const encodedKeyword = encodeURIComponent(text);
    let uri: string = ''
    switch (AppStorage.get('EnhancedBrowserSearch') as number) {
      case 0: //百度
        uri = `https://www.baidu.com/s?wd=${encodedKeyword}`
        break
      case 1: //谷歌
        uri = `https://www.google.com/search?q=${encodedKeyword}`
        break
      // case 2: //必应
      //   uri = `https://www.bing.com/search?q=${encodedKeyword}`
      //   break
      // case 3: //搜狗
      //   uri = `https://www.sogou.com/web?query=${encodedKeyword}`
      //   break

    }
    let want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: uri,
      // parameters: {
      //   'ohos.ability.params.showDefaultPicker': true
      // }
    };
    context.startAbility(want)
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