import { KeyPressType } from 'mouse'
import { LengthMetrics } from "@kit.ArkUI"
import {
  getModelInfoModel,
  keyInfosModel,
  LanguageNames,
  keyInfos_childsModel,
  keyInfos_childs_childsModel
} from 'config' //获取设备按键信息

export interface KeymethodConfig {
  key: KeyPressType
  currIndex: number
}

/**
 * 按键设置
 */
@Component
export struct ConfigPage2 {
  @Watch('Watch_null') @StorageLink('getModelInfo') getModelInfo: getModelInfoModel =
    AppStorage.get('getModelInfo') as getModelInfoModel
  @StorageLink('languages') languages: string = 'ZH_CN'
  @StorageLink('KeymethodConfig') KeymethodConfig: KeymethodConfig[] = []
  @StorageLink("shortcut") shortcut: number = 0 //改变该值弹出对应快捷键悬浮窗口 1：语音识别 2：语音翻译 3:截图识别 4：自定义快捷键
  @Link isShowConfig: boolean

  /**
   * 将子项转换为ArkUI官方SelectOption数组
   * （使用官方类型，避免自定义对象导致的“未声明类型”报错）
   */
  private convertChildsToOptions(childs: keyInfos_childs_childsModel[]): SelectOption[] {
    return childs.map((child, index) => {
      // 多语言适配：优先取当前语言文本，无则按顺序兜底
      const displayText = (child.names as LanguageNames)[this.languages]
      // console.error(displayText)
      // 返回ArkUI官方SelectOption类型的对象（非自定义类型，符合规范）
      return {
        value: displayText     // 选项显示文本
      } as SelectOption; // 显式断言为官方类型，消除“未声明类型”警告
    });
  }

  /**
   * 获取默认选中索引（childs中first=1的项为默认选中）
   */
  private getDefaultSelectedIndex(childs: keyInfos_childs_childsModel[], index1: number, index2: number): number {
    for (let i = 0; i < childs.length; i++) {
      if (childs[i].first === 1) {
        if (!AppStorage.get('KeymethodConfig')) {
          AppStorage.setOrCreate('KeymethodConfig', [
            { key: KeyPressType.VOICE_CLICK, currIndex: 0 }, { key: KeyPressType.VOICE_LONG_PRESS_DOWN, currIndex: 1 },
            { key: KeyPressType.SEARCH_CLICK, currIndex: 0 },
            { key: KeyPressType.SEARCH_LONG_PRESS_DOWN, currIndex: 0 },
            { key: KeyPressType.TRANSLATE_CLICK, currIndex: 0 },
            { key: KeyPressType.TRANSLATE_LONG_PRESS_DOWN, currIndex: 0 },
            { key: KeyPressType.AI_CLICK, currIndex: 0 }, { key: KeyPressType.TRANSLATE_LONG_PRESS_DOWN, currIndex: 0 },
          ])
          // console.log('*/*/*/*/*', JSON.stringify(AppStorage.get('KeymethodConfig')))
          AppStorage.setOrCreate('KeymethodConfig', this.KeymethodConfig)
          return i;
        }
        switch (this.getModelInfo.keyInfos[index1].names['ZH_CN']) {
          case '语音键':
            if (index2) {
              return this.KeymethodConfig[1].currIndex
            } else {
              return this.KeymethodConfig[0].currIndex
            }
          case '搜索键':
            if (index2) {
              return this.KeymethodConfig[3].currIndex
            } else {
              return this.KeymethodConfig[2].currIndex
            }
          case '翻译键':
            if (index2) {
              return this.KeymethodConfig[5].currIndex
            } else {
              return this.KeymethodConfig[4].currIndex
            }
          case 'AI键':
            if (index2) {
              return this.KeymethodConfig[7].currIndex
            } else {
              return this.KeymethodConfig[6].currIndex
            }
        }
      }
    }
    return 0; // 无默认项时选中第一个
  }

  aboutToAppear(): void {
    if (!AppStorage.get('languages')) {
      AppStorage.setOrCreate('languages', 'ZH_CN')
    }
  }

  build() {
    if (this.getModelInfo.keyInfos) {
      Flex({ space: { main: LengthMetrics.px(15) }, direction: FlexDirection.Column }) {
        ForEach(this.getModelInfo.keyInfos, (item: keyInfosModel, index1) => {
          Text((item.names as LanguageNames)[this.languages])//多语言还未添加
            .fontSize(14)
            .lineHeight(14)
            .fontWeight(400)
            .fontColor('#a4aab2')
            .margin(index1 === 0 ? { bottom: 10 } : { bottom: 5, top: 10 })
          // Select()
          ForEach(item.childs, (item: keyInfos_childsModel, index2) => {
            Text((item.names as LanguageNames)[this.languages])
              .fontSize($r('app.float.default_text_font_size_14'))
              .fontWeight(400)
              .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
            Select(this.convertChildsToOptions(item.childs || []))
              .value(((item.childs[this.getDefaultSelectedIndex(item.childs, index1,
                index2)] as keyInfos_childs_childsModel).names as LanguageNames)[this.languages
              ])
              .onSelect((index: number, value) => {
                this.getModelInfo.keyInfos[index1].childs[index2].childs[this.getDefaultSelectedIndex(item.childs || [],
                  index1, index2)].first = 0
                this.getModelInfo.keyInfos[index1].childs[index2].childs[index].first = 1
                // this.KeymethodConfig[index1 * 2+index2].currIndex = index
                console.error('11', this.getModelInfo.keyInfos[index1].names['ZH_CN'], index2, index)
                switch (this.getModelInfo.keyInfos[index1].names['ZH_CN']) {
                  case '语音键':
                    if (index2) {
                      this.KeymethodConfig[1].currIndex = index
                    } else {
                      this.KeymethodConfig[0].currIndex = index
                    }
                    break
                  case '搜索键':
                    if (index2) {
                      this.KeymethodConfig[3].currIndex = index
                    } else {
                      this.KeymethodConfig[2].currIndex = index
                    }
                    break
                  case '翻译键':
                    if (index2) {
                      this.KeymethodConfig[5].currIndex = index
                    } else {
                      this.KeymethodConfig[4].currIndex = index
                    }
                    break
                  case 'AI键':
                    if (index2) {
                      this.KeymethodConfig[7].currIndex = index
                    } else {
                      this.KeymethodConfig[6].currIndex = index
                    }
                    break
                }
                // console.log('*/*/*/*/*', JSON.stringify(AppStorage.get('KeymethodConfig')))
                AppStorage.setOrCreate('KeymethodConfig', this.KeymethodConfig)
                console.log('*/*/*/*/*', JSON.stringify(AppStorage.get('KeymethodConfig')))

                const shortcutKeywords = [
                  '快捷按键', 'Tasten für Verknüpfungen', "كنوپكا", "快捷按鍵", "단축키",
                  "Shortcut key", "زر الاختصار", "Botones de acceso directo", "མྱུར་མཐེབ་",
                  "Tasto di scorciatoia", "Kekunci pintasan", "تېز كۇنۇپكىسى", "Kısayol tuşları",
                  "Tombol pintasan", "Phím tắt", "ᠲᠦᠷᠭᠡᠨ ᠳᠠᠷᠤᠭᠤᠯ", "Boutons de raccourci",
                  "Торчлолын товчлуур", "ปุ่มทางลัด", "ショートカットキー"
                ];
                if (shortcutKeywords.includes(value)) {
                  this.shortcut = 4;
                }

                const fixedText = [
                  "Feste Textverfassung", "تۇراقتى دەلو", "固定文案", "고정 카피라이팅", "Fixed copy", "كتابة نسخة ثابتة",
                  "固定文案", "Redacción fija", "གཏན་འཇགས་ཡིག་ཆ་", "Copywriting fisso", "Fixed copy",
                  "nakapirming copywriting", "Copywriting tetap", "مۇقىم دەپتەردار", "Sabit metin yazarlığı",
                  "Copywriting tetap", "Bản sao cố định", "ᠲᠣᠭᠲᠠᠮᠠᠯ ᠠᠯᠪᠠᠨ ᠪᠢᠴᠢᠭ", "Rédaction fixe", "Тогтмол бичих",
                  "การเขียนคำโฆษณาคงที่", "修正されたコピー"
                ];
                if (fixedText.includes(value)) {
                  AppStorage.setOrCreate('isShowFixedText_pop', true)
                }
                const webUrlToOpen = [
                  "Öffnen Sie die Webseite", "تور جايىلۋ", "打開網頁", "웹 페이지 열기", "Open web page", "فتح صفحة الويب",
                  "打开网页", "Abra la página web", "དྲ་ངོས་ཁ་ཕྱེ་།", "Apri una pagina web", "Open web page",
                  "Magbukas ng web page", "Buka halaman web", "تور بەتنى ئېچىش", "Web sayfasını açın",
                  "Buka halaman web",
                  "mở trang web", "ᠰᠦᠯᠵᠢᠶᠡᠨ\u202fᠦ ᠬᠠᠭᠤᠳᠠᠰᠤ\u202fᠶᠢ ᠨᠡᠭᠡᠭᠡᠬᠦ", "Ouvrir la page Web", "Вэб хуудсыг нээх",
                  "เปิดหน้าเว็บ", "Webページを開く"
                ];
                if (webUrlToOpen.includes(value)) {
                  AppStorage.setOrCreate('isShow_webUrlToOpen_pop', true)
                }

              })
              .selected(this.getDefaultSelectedIndex(item.childs || [], index1, index2))
              .width('100%')
              .font({ size: $r('app.float.default_text_font_size_14'), weight: 400 })
              .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
              .borderRadius(4)
              .border({ width: 1, color: $r('app.string.DEFAULT_BORDER_COLOR') })
              .backgroundColor(Color.White)
          }, (item: keyInfos_childsModel) => item.name)


        }, (item: keyInfosModel) => item.keyName)


      }
      .width('100%')
    }
  }

  Watch_null() {
    if (JSON.stringify(this.getModelInfo.keyInfos)==='[]') {
      this.isShowConfig = false
      // AppStorage.setOrCreate('isShowConfig', false)
    }
  }
}