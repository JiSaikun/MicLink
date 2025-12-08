import { Float_Window } from 'float_window'
import { ConnectDevice, translate_Response, Communication, _translate, translate_Params } from "mouse"
import { getModelInfoModel, Languages, languagesModel } from 'config'
import { CursorController, promptAction } from '@kit.ArkUI'
import { pasteboard } from '@kit.BasicServicesKit'; //复制
import { BusinessError } from '@kit.BasicServicesKit';
import { globalShortcutService } from 'utils';
import { DeviceArrayType_Ble } from 'bluetooth';
import { pointer } from '@kit.InputKit';

/**
 * 语音翻译悬浮窗
 */
@Entry
@Component
struct VoiceTranslation {
  @State getModelInfo: getModelInfoModel = AppStorage.get('getModelInfo') as getModelInfoModel
  @Watch('updata') @StorageLink('voiceTranslationText') voiceTranslationText: translate_Response = {
    transText: '',
    text: ''
  }
  @StorageLink('voiceTranslationState') voiceTranslationState: boolean = true
  @StorageLink('voiceOrText') voiceOrText: boolean = true //语音翻译为true,文本翻译为false
  @StorageLink('languages') languages: string = 'ZH_CN'
  @Watch('changeLanguages') @StorageLink('from_languages') from_languages: string = 'ZH_CN' //翻译源语言
  @Watch('changeLanguages') @StorageLink('to_languages') to_languages: string = 'EN_US' //翻译目标语言
  @Watch('changeLanguages') @StorageLink('wordScan_from_languages') wordScan_from_languages: string = 'ZH_CN' //翻译源语言
  @Watch('changeLanguages') @StorageLink('wordScan_to_languages') wordScan_to_languages: string = 'EN_US' //翻译目标语言
  @StorageLink('changeText') changeText: boolean = false //语音翻译为true,文本翻译为false
  // 初始化控制标志，避免启动时的@Watch触发
  private isInitialized: boolean = false
  // 防抖定时器，避免频繁触发翻译请求
  private translateDebounceTimer: number | null = null
  // 1. 初始化滚动控制器
  private scroller_to: Scroller = new Scroller();
  private scroller_from: Scroller = new Scroller();
  cursorCustom: CursorController = this.getUIContext().getCursorController();

  updata() {
    if (this.changeText) {
      this.changeLanguages()
    }
  }

  private initializeDeviceInfo(): void {
    try {
      const deviceIndex = (AppStorage.get('device_currIndex') as number) || 0;
      if (AppStorage.get('device_isBle')) {
        const devices = AppStorage.get('devices') as DeviceArrayType_Ble[];
        if (devices && Array.isArray(devices) && deviceIndex >= 0 && deviceIndex < devices.length &&
        devices[deviceIndex]) {
          this.getModelInfo = devices[deviceIndex].getModelInfo as getModelInfoModel;
        } else {
          console.warn('initializeDeviceInfo: invalid BLE device access',
            { deviceIndex, devicesLength: devices?.length });
        }
      } else {
        if (ConnectDevice.Communication && deviceIndex >= 0 && deviceIndex < ConnectDevice.Communication.length &&
        ConnectDevice.Communication[deviceIndex]) {
          this.getModelInfo = ConnectDevice.Communication[deviceIndex].getModelInfo as getModelInfoModel;
        } else {
          console.warn('initializeDeviceInfo: invalid USB device access',
            { deviceIndex, communicationLength: ConnectDevice.Communication?.length });
        }
      }
    } catch (error) {
      console.error('Failed to initialize device info:', error);
    }

    // 设备信息更新后，刷新语言选项缓存
    this.invalidateLanguageCache();
  }

  changeLanguages() {
    // 在初始化完成前跳过@Watch触发，避免阻塞UI加载
    if (!this.isInitialized) {
      console.log('Skipping changeLanguages during initialization')
      return
    }

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
      // 安全检查：确保getModelInfo存在
      if (!this.getModelInfo?.appkey) {
        console.error('changeLanguages: getModelInfo or appkey is missing');
        return;
      }

      const deviceIndex = (AppStorage.get('device_currIndex') as number) || 0;
      let productCode = '';
      let sno = '';

      try {
        if (AppStorage.get('device_isBle')) {
          const devices = AppStorage.get('devices') as DeviceArrayType_Ble[];
          if (devices && Array.isArray(devices) && deviceIndex >= 0 && deviceIndex < devices.length &&
            devices[deviceIndex]?.BlueTooth_devices?.deviceInfo) {
            productCode = devices[deviceIndex].BlueTooth_devices.deviceInfo.productType.toString();
            sno = devices[deviceIndex].BlueTooth_devices.deviceInfo.sn;
          } else {
            console.error('changeLanguages: invalid BLE device access');
            return;
          }
        } else {
          if (ConnectDevice.Communication && deviceIndex >= 0 && deviceIndex < ConnectDevice.Communication.length &&
            ConnectDevice.Communication[deviceIndex]?.Communication?.deviceInfo) {
            productCode = ConnectDevice.Communication[deviceIndex].Communication.deviceInfo.productType.toString();
            sno = ConnectDevice.Communication[deviceIndex].Communication.deviceInfo.sn;
          } else {
            console.error('changeLanguages: invalid USB device access');
            return;
          }
        }
      } catch (error) {
        console.error('changeLanguages: failed to get device info', error);
        return;
      }

      let params: translate_Params = {
        appkey: this.getModelInfo.appkey, //获取用户按键模式详情中得到
        from: this.voiceOrText ? AppStorage.get('from_languages') as string :
          AppStorage.get('wordScan_from_languages') as string, //源语言___后面配置
        productCode: productCode, //产品编码
        sno: sno, //设备号
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
        // promptAction.showToast({ message: '翻译请求失败，请检查网络连接' });
      })
    }, 500);
  }

  aboutToAppear(): void {
    // 使用Promise异步初始化，避免阻塞主线程
    this.asyncInitialize();
  }

  // 异步初始化方法
  private async asyncInitialize(): Promise<void> {
    try {
      // 短暂延迟，让UI先渲染完成
      await new Promise<void>((resolve) => setTimeout(resolve, 50));

      // 在后台线程中初始化设备信息
      this.initializeDeviceInfo();

      // 标记初始化完成，允许@Watch触发器工作
      this.isInitialized = true;
    } catch (error) {
      console.error('VoiceTranslation initialization failed:', error);
      // 即使初始化失败，也标记为完成以避免无限等待
      this.isInitialized = true;
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
          .onHover((flag) => {
            if (flag) {
              this.cursorCustom.setCursor(pointer.PointerStyle.HAND_POINTING);
            } else {
              console.info("restoreDefault");
              this.cursorCustom.restoreDefault();
            }
          })
          .onClick(() => {
            Float_Window.destroyWindow(Float_Window.window_VoiceTranslation)
            Float_Window.showVoiceTranslation = false
            this.voiceTranslationText = {
              transText: '',
              text: ''
            }
            const deviceIndex = (AppStorage.get('device_currIndex') as number) || 0;
            if (AppStorage.get('device_isBle')) {
              const devices = AppStorage.get('devices') as DeviceArrayType_Ble[];
              if (devices && Array.isArray(devices) && deviceIndex >= 0 && deviceIndex < devices.length &&
                devices[deviceIndex]?.BlueTooth_devices) {
                if (devices[deviceIndex].BlueTooth_devices.audioDataState) {
                  devices[deviceIndex].BlueTooth_devices.send([0x63]);
                  devices[deviceIndex].BlueTooth_devices.audioDataState =
                    !devices[deviceIndex].BlueTooth_devices.audioDataState;
                }
              }
            } else {
              if (ConnectDevice.Communication && deviceIndex >= 0 && deviceIndex < ConnectDevice.Communication.length &&
                ConnectDevice.Communication[deviceIndex]?.Communication) {
                if (ConnectDevice.Communication[deviceIndex].Communication.audioDataState) {
                  ConnectDevice.Communication[deviceIndex].Communication.getDeviceInfo([0x63]);
                  ConnectDevice.Communication[deviceIndex].Communication.audioDataState =
                    !ConnectDevice.Communication[deviceIndex].Communication.audioDataState;
                }
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
              .value(this.getDefaultSelectedIndex_fromText(this.getModelInfo?.transLanguages?.[this.getDefaultSelectedIndex_from(this.voiceOrText ?
              this.from_languages : this.wordScan_from_languages)]))
              .onSelect((index: number) => {
                // 安全检查：确保getModelInfo和transLanguages存在且索引有效
                if (!this.getModelInfo?.transLanguages || index < 0 ||
                  index >= this.getModelInfo.transLanguages.length) {
                  console.error('onSelect: invalid language access',
                    { index, length: this.getModelInfo?.transLanguages?.length });
                  return;
                }
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
              .onHover((flag) => {
                if (flag) {
                  this.cursorCustom.setCursor(pointer.PointerStyle.HAND_POINTING);
                } else {
                  console.info("restoreDefault");
                  this.cursorCustom.restoreDefault();
                }
              })
            Text('至')
              .fontSize(12)
              .fontWeight(400)
              .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
              .padding({ left: 20, right: 20 })
            Select(this.convert_ttsLanguagesToOptions())
              .value(this.getDefaultSelectedIndex_fromText(this.getModelInfo?.transLanguages?.[this.getDefaultSelectedIndex_from(this.voiceOrText ?
              this.to_languages : this.wordScan_to_languages)]))
              .onSelect((index: number) => {
                // 安全检查：确保getModelInfo和transLanguages存在且索引有效
                if (!this.getModelInfo?.transLanguages || index < 0 ||
                  index >= this.getModelInfo.transLanguages.length) {
                  console.error('onSelect: invalid language access',
                    { index, length: this.getModelInfo?.transLanguages?.length });
                  return;
                }
                if (this.voiceOrText) {
                  this.to_languages = this.getModelInfo.transLanguages[index].code
                } else {
                  this.wordScan_to_languages = this.getModelInfo.transLanguages[index].code
                }
              })
              .selected(this.getDefaultSelectedIndex_from(this.voiceOrText ? this.to_languages :
              this.wordScan_to_languages))
              .onHover((flag) => {
                if (flag) {
                  this.cursorCustom.setCursor(pointer.PointerStyle.HAND_POINTING);
                } else {
                  console.info("restoreDefault");
                  this.cursorCustom.restoreDefault();
                }
              })
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
              .onHover((flag) => {
                if (flag) {
                  this.cursorCustom.setCursor(pointer.PointerStyle.HAND_POINTING);
                } else {
                  console.info("restoreDefault");
                  this.cursorCustom.restoreDefault();
                }
              })
              .onClick(() => {
                try {
                  const pasteData =
                    pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.voiceTranslationText.transText);
                  let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard(); //获取系统剪贴板对象。
                  // systemPasteboard.setAppShareOptions(pasteboard.ShareOption.INAPP);
                  systemPasteboard.setData(pasteData)
                    .then(() => {
                      console.error('文本已复制到剪贴板: ' + this.voiceTranslationText.transText);
                      promptAction.showToast({ message:`${Languages.copySuccess[this.languages]}` });
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
      // 优化输入事件处理，完全异步且带超时保护
      const handleKeyEvent = async () => {
        try {
          // 添加超时保护，防止输入处理无限阻塞
          const timeoutPromise = new Promise<never>((_, reject) => {
            setTimeout(() => reject(new Error('输入事件处理超时')), 1000)
          })

          const processPromise = Promise.resolve().then(() => {
            return globalShortcutService.handleGlobalKeyEvent(event)
          })

          await Promise.race([processPromise, timeoutPromise])
        } catch (error) {
          console.error('按键事件处理失败或超时:', error)
        }
      }

      // 异步执行，不阻塞输入线程
      handleKeyEvent()
    })
  }

  // 语言选项缓存，避免每次渲染都重新计算
  private languageOptionsCache: SelectOption[] | null = null;
  private lastLanguageCache: string = '';
  private languageFieldMap: Map<string, string> = new Map();

  convert_ttsLanguagesToOptions(): SelectOption[] {
    const currentLang = AppStorage.get('languages') as string;

    // 安全检查：确保getModelInfo和transLanguages存在
    if (!this.getModelInfo?.transLanguages || this.getModelInfo.transLanguages.length === 0) {
      console.warn('convert_ttsLanguagesToOptions: transLanguages is empty or undefined');
      return [{ value: '加载中...' }];
    }

    // 检查缓存是否仍然有效
    if (this.languageOptionsCache && this.lastLanguageCache === currentLang &&
        this.languageOptionsCache.length === this.getModelInfo.transLanguages.length) {
      return this.languageOptionsCache;
    }

    // 更新缓存标识
    this.lastLanguageCache = currentLang;

    // 异步计算语言选项，避免阻塞主线程
    this.updateLanguageOptionsCache(currentLang);

    // 如果缓存还没有准备好，返回临时的默认选项
    if (!this.languageOptionsCache) {
      return [{ value: '加载中...' }];
    }

    return this.languageOptionsCache;
  }

  // 强制刷新语言选项缓存（当设备信息更新时调用）
  private invalidateLanguageCache(): void {
    this.languageOptionsCache = null;
    this.lastLanguageCache = '';
  }

  // 异步更新语言选项缓存
  private updateLanguageOptionsCache(currentLang: string): void {
    if (this.languageOptionsCache && this.lastLanguageCache === currentLang) {
      return; // 缓存已是最新的
    }

    try {
      // 检查语言字段缓存是否需要更新
      if (this.languageFieldMap.size === 0 || !this.languageFieldMap.has('currentLang') ||
        this.languageFieldMap.get('currentLang') !== currentLang) {
        // 清空旧缓存
        this.languageFieldMap.clear();
        this.languageFieldMap.set('currentLang', currentLang);
      }

      // 计算语言选项
      this.languageOptionsCache = this.getModelInfo!.transLanguages.map((item) => {
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
    } catch (error) {
      console.error('updateLanguageOptionsCache error:', error);
      this.languageOptionsCache = [{ value: '错误' }];
    }
  }

  /**
   * 获取默认选中索引（childs中first=1的项为默认选中）
   */
  /**
   * 获取默认选中索引（childs中first=1的项为默认选中）
   */
  private getDefaultSelectedIndex_from(from_languages: string): number {
    // 添加数组空值检查
    if (!this.getModelInfo?.transLanguages || this.getModelInfo.transLanguages.length === 0) {
      console.error('getDefaultSelectedIndex_from: transLanguages is empty or undefined');
      return 0;
    }

    const index = this.getModelInfo.transLanguages.findIndex((item) => {
      return item.code === from_languages;
    });
    return index !== -1 ? index : 0; // 找到返回索引，否则返回0
  }

  private getDefaultSelectedIndex_fromText(item: languagesModel | undefined): string {
    // 添加空值检查，防止崩溃
    if (!item) {
      console.error('getDefaultSelectedIndex_fromText: item is undefined');
      return '';
    }

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
    promptAction.showToast({ message: '无法翻译到对应目标语言', backgroundColor: Color.Red, duration: 1000 });
  }

  @Watch('change_flax_huacifanyi') @StorageLink('flax_huacifanyi') flax_huacifanyi: boolean =
    true //语音翻译为true,文本翻译为false

  change_flax_huacifanyi() {
    promptAction.showToast({ message: `${Languages.noSelectedTextDetected[this.languages]}`, backgroundColor: Color.Red });
  }

  // 页面销毁时清理资源
  onDestroy(): void {
    console.log('VoiceTranslation页面正在销毁，清理所有资源...');

    // 清理翻译防抖定时器
    if (this.translateDebounceTimer) {
      clearTimeout(this.translateDebounceTimer);
      this.translateDebounceTimer = null;
    }

    // 清理语言选项缓存
    this.languageOptionsCache = null;
    this.languageFieldMap.clear();

    // 清理所有设备相关的资源
    try {
      // 清理ConnectDevice.Communication中的USB设备
      if (ConnectDevice && ConnectDevice.Communication) {
        for (let i = 0; i < ConnectDevice.Communication.length; i++) {
          const device = ConnectDevice.Communication[i];
          if (device && device.Communication && typeof device.Communication.dispose === 'function') {
            console.log(`清理Communication对象 ${i}...`);
            device.Communication.dispose();
          }
        }
        // 清空数组
        ConnectDevice.Communication = [];
      }

      // 清理AppStorage中的蓝牙设备
      const devicesInStorage = AppStorage.get('devices') as DeviceArrayType_Ble[] || [];
      for (let i = 0; i < devicesInStorage.length; i++) {
        const device = devicesInStorage[i];
        if (device && device.BlueTooth_devices && typeof device.BlueTooth_devices.dispose === 'function') {
          console.log(`清理AppStorage中的BlueTooth_devices对象 ${i}...`);
          device.BlueTooth_devices.dispose();
        }
      }
      // 清空AppStorage中的设备列表
      AppStorage.setOrCreate('devices', []);

    } catch (error) {
      console.error('清理设备对象时出错:', error);
    }

    console.log('VoiceTranslation页面资源清理完成');
  }
}