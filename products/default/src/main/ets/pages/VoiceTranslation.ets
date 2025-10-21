import { Float_Window } from 'float_window'
import { ConnectDevice,translate_Response, Communication, _translate, translate_Params } from "mouse"
import { getModelInfoModel, languagesModel } from 'config'
import { promptAction } from '@kit.ArkUI'
import { pasteboard } from '@kit.BasicServicesKit'; //复制
import { BusinessError } from '@kit.BasicServicesKit';
import { globalShortcutService } from 'utils';

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
  // 1. 初始化滚动控制器
  private scroller_to: Scroller = new Scroller();
  private scroller_from: Scroller = new Scroller();
  changeLanguages() {
    let params: translate_Params = {
      appkey: (AppStorage.get('getModelInfo') as getModelInfoModel).appkey, //获取用户按键模式详情中得到
      from: this.voiceOrText ? AppStorage.get('from_languages') as string :
        AppStorage.get('wordScan_from_languages') as string, //源语言___后面配置
      productCode: ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.deviceInfo.productType.toString(), //产品编码
      sno: ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.deviceInfo.sn, //设备号
      text: this.voiceTranslationText.text, //翻译内容
      to: this.voiceOrText ? AppStorage.get('to_languages') as string :
        AppStorage.get('wordScan_to_languages') as string //翻译语言___后面配置
    }
    _translate(params).then((res) => {
      if (res.data) {
        console.log('翻译请求成功————翻译结果：' + res.data?.transText)
        let data: translate_Response = {
          transText: res.data?.transText as string,
          text: res.data?.text as string,
        }
        AppStorage.setOrCreate('voiceTranslationText', data)
      } else {
        promptAction.showToast({ message: '无法翻译到对应目标语言' });
      }
    })

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
            if (ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.audioDataState) {
              ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.getDeviceInfo([0x63])
              ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.audioDataState = !ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.audioDataState
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
              .value(this.getDefaultSelectedIndex_fromText(this.getModelInfo.ttsLanguages[this.getDefaultSelectedIndex_from(this.voiceOrText ?
              this.from_languages : this.wordScan_from_languages)]))
              .onSelect((index: number) => {
                if (this.voiceOrText) {
                  this.from_languages = this.getModelInfo.ttsLanguages[index].code
                } else {
                  this.wordScan_from_languages = this.getModelInfo.ttsLanguages[index].code
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
              .value(this.getDefaultSelectedIndex_fromText(this.getModelInfo.ttsLanguages[this.getDefaultSelectedIndex_from(this.voiceOrText ?
              this.to_languages : this.wordScan_to_languages)]))
              .onSelect((index: number) => {
                if (this.voiceOrText) {
                  this.to_languages = this.getModelInfo.ttsLanguages[index].code
                } else {
                  this.wordScan_to_languages = this.getModelInfo.ttsLanguages[index].code
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
                  const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.voiceTranslationText.transText);
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
      // console.error('err：',JSON.stringify(event))
      // 将按键事件传递给全局监听服务
      globalShortcutService.handleGlobalKeyEvent(event)
    })
  }

  convert_ttsLanguagesToOptions(): SelectOption[] {
    return ((this.getModelInfo.ttsLanguages).map((item, index) => {
      // 多语言适配：优先取当前语言文本，无则按顺序兜底
      let languageField: string = item.name; // 默认使用中文简体

      switch (AppStorage.get('languages') as string) {
        case "FIL_PH":
          languageField = item.nameFil_ph;
          break;
        case "ES_ES":
          languageField = item.nameEs_es;
          break;
        case "JA_JP":
          languageField = item.nameJp;
          break;
        case "ZH_TW":
          languageField = item.nameTw;
          break;
        case "UYGUR":
          languageField = item.nameUygur;
          break;
        case "MO_MO":
          languageField = item.nameMo_mo;
          break;
        case "RU_RU":
          languageField = item.nameRu_ru;
          break;
        case "IT_IT":
          languageField = item.nameIt_it;
          break;
        case "ZH_TI":
          languageField = item.nameZh_ti;
          break;
        case "EN_US":
          languageField = item.nameEn;
          break;
        case "MAY_MAY":
          languageField = item.nameMay_may;
          break;
        case "AR_SA":
          languageField = item.nameAr_sa;
          break;
        case "DE_DE":
          languageField = item.nameDe_de;
          break;
        case "KO_KR":
          languageField = item.nameKo_kr;
          break;
        case "ID_ID":
          languageField = item.nameId_id;
          break;
        case "TR_TR":
          languageField = item.nameTr_tr;
          break;
        case "KA_KA":
          languageField = item.nameKa_ka;
          break;
        case "FR_FR":
          languageField = item.nameFr_fr;
          break;
        case "MN_MN":
          languageField = item.nameMn_mn;
          break;
        case "TH_TH":
          languageField = item.nameTh_th;
          break;
        case "VI_VN":
          languageField = item.nameVi_vn;
          break;
        // 默认使用中文简体
        default:
          languageField = item.name;
          break;
      }

      // 使用方括号表示法动态访问属性
      return {
        value: languageField // 正确的属性访问方式
      } as SelectOption;
    }));
  }

  /**
   * 获取默认选中索引（childs中first=1的项为默认选中）
   */
  /**
   * 获取默认选中索引（childs中first=1的项为默认选中）
   */
  private getDefaultSelectedIndex_from(from_languages: string):
    number {
    const index = this.getModelInfo.ttsLanguages.findIndex((item) => {
      return item.code === from_languages;
    });
    return index !== -1 ? index : 0; // 找到返回索引，否则返回0
  }

  private getDefaultSelectedIndex_fromText(item: languagesModel): string {
    switch (AppStorage.get('languages') as string) {
      case "FIL_PH":
        return item.nameFil_ph;
      case "ES_ES":
        return item.nameEs_es;
      case "JA_JP":
        return item.nameJp;
      case "ZH_TW":
        return item.nameTw;
      case "UYGUR":
        return item.nameUygur;
      case "MO_MO":
        return item.nameMo_mo;
      case "RU_RU":
        return item.nameRu_ru;
      case "IT_IT":
        return item.nameIt_it;
      case "ZH_TI":
        return item.nameZh_ti;
      case "EN_US":
        return item.nameEn;
      case "MAY_MAY":
        return item.nameMay_may;
      case "AR_SA":
        return item.nameAr_sa;
      case "DE_DE":
        return item.nameDe_de;
      case "KO_KR":
        return item.nameKo_kr;
      case "ID_ID":
        return item.nameId_id;
      case "TR_TR":
        return item.nameTr_tr;
      case "KA_KA":
        return item.nameKa_ka;
      case "FR_FR":
        return item.nameFr_fr;
      case "MN_MN":
        return item.nameMn_mn;
      case "TH_TH":
        return item.nameTh_th;
      case "VI_VN":
        return item.nameVi_vn;
      default:
        return item.name;
    }
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
}