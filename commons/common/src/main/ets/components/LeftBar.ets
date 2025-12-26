import { Ai_Model, AiModel_data, bottom_data } from '../model/LeftBar_DataModel'
import { Languages, sideFunctionList } from 'config'
import { ThemeConfig } from '../common/ThemeConfig'
import { CursorController } from '@kit.ArkUI'
import { pointer } from '@kit.InputKit'

export interface paramModel {
  web: string,
  currentIndex: number,
  bottomCurrIndex: number,
  extend: boolean,
  width_length: number
}

@Component
export struct LeftBar {
  @Consume('pageInfo') pageInfo: NavPathStack
  @StorageLink('languages') languages: string = 'ZH_CN'
  @StorageLink('tabsControllerIndex') tabsControllerIndex: number = 0
  @StorageLink("paletteTheme") paletteTheme: string = ThemeConfig.PaletteTheme
  @State aiModelData: Ai_Model[] = AiModel_data
  @State bottom_data: Ai_Model[] = bottom_data
  @Prop currentIndex: number = 0
  @Prop bottomCurrIndex: number = 10000
  @State mark: boolean = false
  @State extend: boolean = true
  @State width_length: number = 248
  @State back_right: string = 'back_right'
  @State leftBar_back: string = 'leftBar_back_Gray'
  // 添加调试状态
  @State debugInfo: string = ''
  @StorageLink("sideFunctionList") flax: sideFunctionList |null=null
  cursorCustom: CursorController = this.getUIContext().getCursorController();

  // 方法：为16进制颜色添加透明度
  addOpacityToHex(hexColor: string, opacity: number): string {
    // 如果颜色值无效，返回默认值
    if (!hexColor || typeof hexColor !== 'string') {
      return `rgba(0, 174, 204, ${opacity})` // 默认颜色 #00aecc
    }

    // 移除 # 号
    let cleanHex = hexColor.replace('#', '');

    // 检查长度
    if (cleanHex.length !== 3 && cleanHex.length !== 6) {
      return `rgba(0, 174, 204, ${opacity})`
    }

    // 处理3位简写格式
    if (cleanHex.length === 3) {
      cleanHex = cleanHex.split('').map(char => char + char).join('');
    }

    // 解析RGB值
    const r = parseInt(cleanHex.substring(0, 2), 16);
    const g = parseInt(cleanHex.substring(2, 4), 16);
    const b = parseInt(cleanHex.substring(4, 6), 16);

    // 检查解析结果
    if (isNaN(r) || isNaN(g) || isNaN(b)) {
      return `rgba(0, 174, 204, ${opacity})`
    }

    return `rgba(${r}, ${g}, ${b}, ${opacity})`
  }

  // 获取带透明度的颜色（每次调用都会重新计算）
  getPaletteThemeWithOpacity(): string {
    const result = this.addOpacityToHex(this.paletteTheme, 0.1)
    // console.log('当前主题颜色:', this.paletteTheme, '带透明度:', result)
    this.debugInfo = `主题: ${this.paletteTheme}, 带透明度: ${result}`
    return result
  }

  @Styles
  flexGS(){
    .flexGrow(1)
    .margin({ top: 5, bottom: 5 })
    .flexShrink(1)
  }

  @Link web: string

  aboutToAppear(): void {
    // console.log('AiModel_data length:', this.aiModelData.length)
    // console.log('初始主题颜色:', this.paletteTheme)
  }

  isShow(name: string): boolean {
    if (name === 'deviceSettings') {
      return true
    }
    // console.warn('',JSON.stringify(this.flax?.Function))
    if (this.flax) {
      switch (name) {
        case "assistant":
          if (this.flax.Function.findIndex(item => item.name === "ai-助手") === -1) {
            return false
          }
          break
        case "office":
          if (this.flax.Function.findIndex(item => item.name === "ai-办公") === -1) {
            return false
          }
          break
        case "agent":
          if (this.flax.Function.findIndex(item => item.name === "ai-智能体") === -1) {
            return false
          }
          break
        case "navigation":
          if (this.flax.Function.findIndex(item => item.name === "导航库") === -1) {
            return false
          }
          break
        case "video":
          if (this.flax.Function.findIndex(item => item.name === "视频库") === -1) {
            return false
          }
          break
        case "template":
          if (this.flax.Function.findIndex(item => item.name === "模板库") === -1) {
            return false
          }
          break
      }

    } else {
      return false
    }

    return true
  }

  build() {
    // 每次构建时更新调试信息
    // this.debugInfo = `主题: ${this.paletteTheme}, 带透明度: ${this.getPaletteThemeWithOpacity()}`

    Flex({ direction: FlexDirection.Column }) {
      Row() {
        Image($r('app.media.MicLink_title'))
          .width(133)
        Blank()
        Image($r(`app.media.${this.leftBar_back}`))
          .width(32)
          .onClick(() => {
            this.extend = false
            animateTo({
              duration: 600,
              curve: Curve.Friction,
              delay: 500,
              iterations: 1,
              playMode: PlayMode.Alternate,
              expectedFrameRateRange: {
                min: 10,
                max: 120,
                expected: 60,
              },
              onFinish: () => {
              }
            }, () => {
              this.width_length = 88;
            })
          })
          .onHover((flag) => {
            if (flag) {
              this.cursorCustom.setCursor(pointer.PointerStyle.HAND_POINTING);
              this.leftBar_back = 'leftBar_back'

            } else {
              console.info("restoreDefault");
              this.cursorCustom.restoreDefault();
              this.leftBar_back = 'leftBar_back_Gray'
            }
          })
      }
      .visibility(this.extend ? Visibility.Visible : Visibility.None)
      .width('100%')
      .margin({ bottom: 20 })
      .flexGS()

      RelativeContainer() {
        Image($r('app.media.trademark'))
          .width(35)
          .alignRules({
            middle: { anchor: '__container__', align: HorizontalAlign.Center },
            center: { anchor: '__container__', align: VerticalAlign.Center },
          })
        Image($r(`app.media.${this.back_right}`))
          .width(32)
          .height(32)
          .alignRules({
            start: { anchor: '__container__', align: HorizontalAlign.Center },
            center: { anchor: '__container__', align: VerticalAlign.Center },
          })
          .margin({ left: 24 })
          .onHover((flag) => {
            if (flag) {
              this.cursorCustom.setCursor(pointer.PointerStyle.HAND_POINTING);
              this.back_right = "back_right_White"
            } else {
              console.info("restoreDefault");
              this.cursorCustom.restoreDefault();
              this.back_right = "back_right"

            }
          })
          .onClick(() => {
            animateTo({
              duration: 500,
              curve: Curve.Friction,
              delay: 500,
              iterations: 1,
              playMode: PlayMode.Alternate,
              expectedFrameRateRange: {
                min: 10,
                max: 120,
                expected: 60,
              },
              onFinish: () => {
                this.extend = true
              }
            }, () => {
              this.width_length = 248;
            })
          })
      }
      .visibility(this.extend ? Visibility.None : Visibility.Visible)
      .height(35)
      .margin({ bottom: 20 })
      .flexGS()

        // 顶部选项 - 每次构建时动态计算颜色
        ForEach(this.aiModelData, (item: Ai_Model, index) => {

          if (this.isShow(item.img)) {
            Flex({ alignItems: ItemAlign.Center }) {
              Image(this.currentIndex === index ? $r(`app.media.${item.select}`) : $r(`app.media.${item.img}`))
                .width(16).height(16)
                .objectFit(ImageFit.Fill)
                .margin({ right: 13 })
              Text(item.title[this.languages])
                .fontSize(14)
                .fontWeight(400)
                .lineHeight(14)
                .fontColor(this.currentIndex === index ? this.paletteTheme : '')
                .visibility(this.extend ? Visibility.Visible : Visibility.None)
            }
            .onHover((flag) => {
              if (flag) {
                this.cursorCustom.setCursor(pointer.PointerStyle.HAND_POINTING);
              } else {
                console.info("restoreDefault");
                this.cursorCustom.restoreDefault();
              }
            })
            .backgroundColor(this.currentIndex === index ? this.getPaletteThemeWithOpacity() : '#f8f8f8')
            .padding({ left: 13 })
            .height(40)
            .borderRadius(8)
            .width('100%')
            .onClick(() => {
              console.log('Top item clicked:', index, item.title[this.languages])
              this.web = item.web
              this.tabsControllerIndex = index
              setTimeout(() => {
                this.pageInfo.clear()
              }, 200)
            })
            .flexGS()
          }

        }, (item: Ai_Model) => item.img)

        Divider()
          .width('100%')
          .height(1)
          .margin({ top: 5, bottom: 5 })
          .backgroundColor('#eaeaea')

        /*      // 对话记录 - 每次构建时动态计算颜色
              Flex({ alignItems: ItemAlign.Center }) {
                Image(this.mark ? $r(`app.media.select_sessionSecord`) : $r(`app.media.sessionSecord`))
                  .width(16).height(16)
                  .objectFit(ImageFit.Fill)
                  .margin({ right: 13 })
                Text(Languages.sessionSecord[this.languages])
                  .fontSize(14)
                  .fontWeight(400)
                  .lineHeight(14)
                  .fontColor(this.mark ? this.paletteTheme : '')
                  .visibility(this.extend ? Visibility.Visible : Visibility.None)
                Blank()
                Image($r('app.media.showDown'))
                  .width(16)
                  .rotate({
                    angle: this.mark ? 90 : 0
                  })
                  .visibility(this.extend ? Visibility.Visible : Visibility.None)
                  .margin({ right: 13 })
              }
              .onHover((flag) => {
                if (flag) {
                  this.cursorCustom.setCursor(pointer.PointerStyle.HAND_POINTING);
                } else {
                  console.info("restoreDefault");
                  this.cursorCustom.restoreDefault();
                }
              })
              .flexGS()
              .backgroundColor(this.mark ? this.getPaletteThemeWithOpacity() : '#f8f8f8')
              .padding({ left: 13 })
              .height(40)
              .borderRadius(8)
              .width('100%')
              .onClick(() => {
                this.mark = !this.mark
              })

              Scroll() {
                // 对话记录内容可以在这里添加
              }
              .edgeEffect(EdgeEffect.Spring)
              .height(160)
              .visibility(this.extend && this.mark ? Visibility.Visible : Visibility.None)
              .width('100%')
              .scrollBar(BarState.Off)
              .flexGS()*/

        Column()
          .height(1)
          .margin(20)
          // .flexGrow(50)
          .layoutWeight(1)
        // 底部选项 - 每次构建时动态计算颜色
        ForEach(this.bottom_data, (item: Ai_Model, index) => {

          if (this.isShow(item.img)) {
            Flex({ alignItems: ItemAlign.Center }) {
              Image(this.bottomCurrIndex === index ? $r(`app.media.${item.select}`) : $r(`app.media.${item.img}`))
                .width(16).height(16)
                .objectFit(ImageFit.Fill)
                .margin({ right: 13 })
              Text(item.title[this.languages])
                .fontSize(14)
                .fontWeight(400)
                .lineHeight(14)
                .fontColor(this.bottomCurrIndex === index ? this.paletteTheme : '')
                .visibility(this.extend ? Visibility.Visible : Visibility.None)
            }
            .onHover((flag) => {
              if (flag) {
                this.cursorCustom.setCursor(pointer.PointerStyle.HAND_POINTING);
              } else {
                console.info("restoreDefault");
                this.cursorCustom.restoreDefault();
              }
            })
            .backgroundColor(this.bottomCurrIndex === index ? this.getPaletteThemeWithOpacity() : '#f8f8f8')
            .padding({ left: 13 })
            .height(40)
            .borderRadius(8)
            .width('100%')
            .onClick(() => {
              console.log('Bottom item clicked:', index, item.title[this.languages])
              this.web = item.web
              this.tabsControllerIndex = index + this.aiModelData.length
              setTimeout(() => {
                this.pageInfo.clear()
              }, 200)
            })
            .flexGS()
          }

        }, (item: Ai_Model) => item.img)


    }
    .width(this.width_length)
    .height('100%')
    .backgroundColor('#f8f8f8')
    .padding(24)
  }
}