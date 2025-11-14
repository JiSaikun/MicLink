import { Float_Window } from 'float_window'
import { ConnectDevice, translate_Response, Communication, _translate, translate_Params } from "mouse"
import { getModelInfoModel, languagesModel } from 'config'
import { promptAction } from '@kit.ArkUI'
import { pasteboard } from '@kit.BasicServicesKit'; //复制
import { BusinessError } from '@kit.BasicServicesKit';
import { globalShortcutService } from 'utils';
import { DeviceArrayType_Ble } from 'bluetooth';

/**
 * 语音翻译悬浮窗
 */
@Entry
@Component
struct VoiceTranslation {
  @State getModelInfo: getModelInfoModel = AppStorage.get('getModelInfo') as getModelInfoModel
  @StorageLink('voiceTranslationText') voiceTranslationText: translate_Response = {
    transText: '',
    text: ''
  }
  @StorageLink('voiceTranslationState') voiceTranslationState: boolean = true
  @StorageLink('voiceOrText') voiceOrText: boolean = true //语音翻译为true,文本翻译为false
  @Watch('changeLanguages') @StorageLink('from_languages') from_languages: string = 'ZH_CN' //翻译源语言
  @Watch('changeLanguages') @StorageLink('to_languages') to_languages: string = 'EN_US' //翻译目标语言
  @Watch('changeLanguages') @StorageLink('wordScan_from_languages') wordScan_from_languages: string = 'ZH_CN' //翻译源语言
  @Watch('changeLanguages') @StorageLink('wordScan_to_languages') wordScan_to_languages: string = 'EN_US' //翻译目标语言

  // 防抖定时器，避免频繁触发翻译请求
  private translateDebounceTimer: number | null = null
  // 1. 初始化滚动控制器
  private scroller_to: Scroller = new Scroller();
  private scroller_from: Scroller = new Scroller();

  changeLanguages() {
    // 清除之前的定时器
    if (this.translateDebounceTimer) {
      clearTimeout(this.translateDebounceTimer);
    }

    // 检查是否有翻译文本
    if (!this.voiceTranslationText.text || this.voiceTranslationText.text.trim() === '') {
      return; // 没有文本时不触发翻译
    }

    // 防抖处理，避免频繁请求（500ms延迟）
    this.translateDebounceTimer = setTimeout(() => {
      let params: translate_Params = {
        appkey: this.getModelInfo.appkey, //获取用户按键模式详情中得到
        from: this.voiceOrText ? AppStorage.get('from_languages') as string :
          AppStorage.get('wordScan_from_languages') as string, //源语言___后面配置
        productCode: AppStorage.get('device_isBle') ?
        (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
          0].BlueTooth_devices.deviceInfo.productType.toString() :
        ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||
          0].Communication.deviceInfo.productType.toString(), //产品编码
        sno: AppStorage.get('device_isBle') ?
        (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
          0].BlueTooth_devices.deviceInfo.sn : ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||
          0].Communication.deviceInfo.sn, //设备号
        text: this.voiceTranslationText.text, //翻译内容
        to: this.voiceOrText ? AppStorage.get('to_languages') as string :
          AppStorage.get('wordScan_to_languages') as string //翻译语言___后面配置
      }

      _translate(params).then((res) => {
        console.warn(JSON.stringify(res.data))
        if (res.data) {
          console.log('翻译请求成功————翻译结果：' + res.data?.transText)
          let data: translate_Response = {
            transText: res.data?.transText as string,
            text: res.data?.text as string,
          }
          AppStorage.setOrCreate('voiceTranslationText', data)
        } else {
          promptAction.showToast({ message: '无法翻译到对应目标语言1111' });
        }
      }).catch((error: BusinessError) => {
        console.error('翻译请求失败:', error);
        promptAction.showToast({ message: '翻译请求失败，请检查网络连接' });
      })
    }, 500);
  }

  aboutToAppear(): void {
    if (AppStorage.get('device_isBle')) {
      this.getModelInfo =
        (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
          0].getModelInfo as getModelInfoModel
    } else {
      this.getModelInfo =
        ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].getModelInfo as getModelInfoModel
    }
  }

  build() {
    Flex({ direction: FlexDirection.Column }) {
      Flex({ justifyContent: FlexAlign.SpaceBetween }) {
        Image($r('app.media.MicLink'))
          .width(48)
        Stack() {
          Image($r("app.media.float_window_deafult"))
            .width(100)
            .height(100)
          if (this.voiceOrText) {
            Image($r(`${this.voiceTranslationState ? 'app.media.textTranslation' : 'app.media.unTextTranslation'}`))
              .width(32)
              .height(32)
          } else {
            Image($r("app.media.textTranslation"))
              .objectFit(ImageFit.Contain)
              .width(32)
              .height(32)
          }

        }
        .width(100)

        Image($r('app.media.Frame_12'))
          .width(50)
          .height(50)
          .onClick(() => {
            Float_Window.destroyWindow(Float_Window.window_VoiceTranslation)
            Float_Window.showVoiceTranslation = false
            this.voiceTranslationText = {
              transText: '',
              text: ''
            }
            if (AppStorage.get('device_isBle')) {
              if ((AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
                0].BlueTooth_devices.audioDataState) {
                (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
                  0].BlueTooth_devices.send([0x63]);
                (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
                  0].BlueTooth_devices.audioDataState =
                  !(AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
                    0].BlueTooth_devices.audioDataState
              }
            } else {
              if (ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||
                0].Communication.audioDataState) {
                ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||
                  0].Communication.getDeviceInfo([0x63])
                ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||
                  0].Communication.audioDataState =
                  !ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||
                    0].Communication.audioDataState
              }
            }

          })
      }
      .width('100%')

      Column() {
        if (this.voiceTranslationState && this.voiceOrText) {
          TextArea({ text: '请讲话' })
            .width('100%')
            .textAlign(TextAlign.Start)
            .padding({ left: 0, top: 0, right: 0 })
            .borderRadius(0)
            .fontColor('#a4aab2')
            .fontWeight(400)
            .fontSize(14)
            .backgroundColor('#f8f8f8')
            .focusable(false)
        }
        List({ scroller: this.scroller_from }) {
          ListItem() {
            TextArea({ text: $$this.voiceTranslationText.text })
              .width('100%')
              .textAlign(TextAlign.Start)
              .padding({ left: 0, top: 0, right: 0 })
              .borderRadius(0)
              .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
              .fontWeight(400)
              .fontSize(14)
              .backgroundColor('#f8f8f8')
            // .focusable(false)
          }
        }
        .padding({
          left: 12,
          top: 12,
          right: 24,
          bottom: 12
        })
        .width('100%')
        .layoutWeight(1)
        .align(Alignment.TopStart)

        Column() {
          List({ scroller: this.scroller_to }) {
            ListItem() {
              TextArea({ text: this.voiceTranslationText.transText })
                .width('100%')
                .textAlign(TextAlign.Start)
                .padding({ left: 0, top: 0, right: 0 })
                .borderRadius(0)
                .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
                .fontWeight(400)
                .fontSize(14)
                .backgroundColor(Color.White)
                .focusable(false)
            }
          }
          .layoutWeight(1)
          .align(Alignment.TopStart)

          Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
            Select(this.convert_ttsLanguagesToOptions())
              .value(this.getDefaultSelectedIndex_fromText(this.getModelInfo.transLanguages[this.getDefaultSelectedIndex_from(this.voiceOrText ?
              this.from_languages : this.wordScan_from_languages)]))
              .onSelect((index: number) => {
                if (this.voiceOrText) {
                  this.from_languages = this.getModelInfo.transLanguages[index].code
                } else {
                  this.wordScan_from_languages = this.getModelInfo.transLanguages[index].code
                }
              })
              .selected(this.getDefaultSelectedIndex_from(this.voiceOrText ? this.from_languages :
              this.wordScan_from_languages))
              .width('100%')
              .font({ size: 12, weight: 400 })
              .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
              .borderRadius(4)
              .border({ width: 1, color: $r('app.string.DEFAULT_BORDER_COLOR') })
              .backgroundColor(Color.White)
              .width(150)
            Text('至')
              .fontSize(12)
              .fontWeight(400)
              .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
              .padding({ left: 20, right: 20 })
            Select(this.convert_ttsLanguagesToOptions())
              .value(this.getDefaultSelectedIndex_fromText(this.getModelInfo.transLanguages[this.getDefaultSelectedIndex_from(this.voiceOrText ?
              this.to_languages : this.wordScan_to_languages)]))
              .onSelect((index: number) => {
                if (this.voiceOrText) {
                  this.to_languages = this.getModelInfo.transLanguages[index].code
                } else {
                  this.wordScan_to_languages = this.getModelInfo.transLanguages[index].code
                }
              })
              .selected(this.getDefaultSelectedIndex_from(this.voiceOrText ? this.to_languages :
              this.wordScan_to_languages))
              .width('100%')
              .font({ size: 12, weight: 400 })
              .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
              .borderRadius(4)
              .border({ width: 1, color: $r('app.string.DEFAULT_BORDER_COLOR') })
              .backgroundColor(Color.White)
              .width(150)
            Blank()
            Image($r('app.media.Frame_1984'))
              .width(25)
              .height(25)
              .padding(4)
              .onClick(() => {
                try {
                  const pasteData =
                    pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.voiceTranslationText.transText);
                  let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard(); //获取系统剪贴板对象。
                  // systemPasteboard.setAppShareOptions(pasteboard.ShareOption.INAPP);
                  systemPasteboard.setData(pasteData)
                    .then(() => {
                      console.error('文本已复制到剪贴板: ' + this.voiceTranslationText.transText);
                      promptAction.showToast({ message: '复制成功' });
                    })
                    .catch((err: BusinessError) => {
                      console.error('复制失败: ' + err.message);
                    });
                } catch (error) {
                  console.error('复制操作异常: ' + error.message);
                }
              })
          }
          .width('100%')
        }
        .padding(12)
        .borderRadius(8)
        .backgroundColor(Color.White)
        .width('100%')
        .height('50%')
        .align(Alignment.TopStart)
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .padding(24)
    .height('100%')
    .backgroundColor('#f8f8f8')
    .onKeyEvent((event: KeyEvent) => {
      // 异步处理按键事件，避免阻塞UI渲染
      setTimeout(() => {
        try {
          globalShortcutService.handleGlobalKeyEvent(event)
        } catch (error) {
          console.error('按键事件处理失败:', error)
        }
      }, 0)
    })
  }

  // 语言映射缓存，避免每次渲染都重新计算
  private languageFieldMap: Map<string, string> = new Map();

  convert_ttsLanguagesToOptions(): SelectOption[] {
    const currentLang = AppStorage.get('languages') as string;

    // 检查缓存是否有效
    if (this.languageFieldMap.size === 0 || !this.languageFieldMap.has('currentLang') ||
        this.languageFieldMap.get('currentLang') !== currentLang) {
      // 清空旧缓存
      this.languageFieldMap.clear();
      this.languageFieldMap.set('currentLang', currentLang);
    }

    return this.getModelInfo.transLanguages.map((item) => {
      // 使用缓存获取语言字段
      const cacheKey = `${item.code}_${currentLang}`;
      let languageField = this.languageFieldMap.get(cacheKey);

      if (!languageField) {
        // 高效的语言字段获取，使用Map替代switch
        const langMap = new Map([
          ['FIL_PH', item.nameFil_ph],
          ['ES_ES', item.nameEs_es],
          ['JA_JP', item.nameJp],
          ['ZH_TW', item.nameTw],
          ['UYGUR', item.nameUygur],
          ['MO_MO', item.nameMo_mo],
          ['RU_RU', item.nameRu_ru],
          ['IT_IT', item.nameIt_it],
          ['ZH_TI', item.nameZh_ti],
          ['EN_US', item.nameEn],
          ['MAY_MAY', item.nameMay_may],
          ['AR_SA', item.nameAr_sa],
          ['DE_DE', item.nameDe_de],
          ['KO_KR', item.nameKo_kr],
          ['ID_ID', item.nameId_id],
          ['TR_TR', item.nameTr_tr],
          ['KA_KA', item.nameKa_ka],
          ['FR_FR', item.nameFr_fr],
          ['MN_MN', item.nameMn_mn],
          ['TH_TH', item.nameTh_th],
          ['VI_VN', item.nameVi_vn]
        ]);

        languageField = langMap.get(currentLang) || item.name; // 默认中文简体
        this.languageFieldMap.set(cacheKey, languageField);
      }

      return { value: languageField } as SelectOption;
    });
  }

  /**
   * 获取默认选中索引（childs中first=1的项为默认选中）
   */
  /**
   * 获取默认选中索引（childs中first=1的项为默认选中）
   */
  private getDefaultSelectedIndex_from(from_languages: string):
    number {
    const index = this.getModelInfo.transLanguages.findIndex((item) => {
      return item.code === from_languages;
    });
    return index !== -1 ? index : 0; // 找到返回索引，否则返回0
  }

  private getDefaultSelectedIndex_fromText(item: languagesModel): string {
    const currentLang = AppStorage.get('languages') as string;

    // 使用Map提升性能，避免长switch语句
    const langMap = new Map([
      ['FIL_PH', item.nameFil_ph],
      ['ES_ES', item.nameEs_es],
      ['JA_JP', item.nameJp],
      ['ZH_TW', item.nameTw],
      ['UYGUR', item.nameUygur],
      ['MO_MO', item.nameMo_mo],
      ['RU_RU', item.nameRu_ru],
      ['IT_IT', item.nameIt_it],
      ['ZH_TI', item.nameZh_ti],
      ['EN_US', item.nameEn],
      ['MAY_MAY', item.nameMay_may],
      ['AR_SA', item.nameAr_sa],
      ['DE_DE', item.nameDe_de],
      ['KO_KR', item.nameKo_kr],
      ['ID_ID', item.nameId_id],
      ['TR_TR', item.nameTr_tr],
      ['KA_KA', item.nameKa_ka],
      ['FR_FR', item.nameFr_fr],
      ['MN_MN', item.nameMn_mn],
      ['TH_TH', item.nameTh_th],
      ['VI_VN', item.nameVi_vn]
    ]);

    return langMap.get(currentLang) || item.name; // 默认中文简体
  }

  @Watch('change_flax_yuyinfanyi_chachaobudaoyuyan') @StorageLink('flax_yuyinfanyi_chachaobudaoyuyan') flax_yuyinfanyi_chachaobudaoyuyan: boolean =
    true //语音翻译为true,文本翻译为false

  change_flax_yuyinfanyi_chachaobudaoyuyan() {
    promptAction.showToast({ message: '无法翻译到对应目标语言', backgroundColor: Color.Red, duration: 3000 });
  }

  @Watch('change_flax_huacifanyi') @StorageLink('flax_huacifanyi') flax_huacifanyi: boolean =
    true //语音翻译为true,文本翻译为false

  change_flax_huacifanyi() {
    promptAction.showToast({ message: '未识别到选中划词', backgroundColor: Color.Red });
  }

  // 页面销毁时清理资源
  onDestroy(): void {
    if (this.translateDebounceTimer) {
      clearTimeout(this.translateDebounceTimer);
      this.translateDebounceTimer = null;
    }
  }
}