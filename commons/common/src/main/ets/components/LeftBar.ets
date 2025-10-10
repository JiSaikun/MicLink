import { Ai_Model, AiModel_data, bottom_data } from '../model/LeftBar_DataModel'
import { Languages } from 'config'

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
  @StorageLink('languages') languages: string = 'ZH_CN' //语言适配
  @State AiModel_data: Ai_Model[] = AiModel_data
  @State bottom_data: Ai_Model[] = bottom_data
  @Prop currentIndex: number = 0
  @State bottomCurrIndex: number = 10000
  @State mark: boolean = false //对话状态
  @State extend: boolean = true //状态栏延申
  @State width_length: number = 248

  @Styles
  flexGS(){
    .flexGrow(1)
    .margin({ top: 5, bottom: 5 })
    .flexShrink(1)
  }

  @Watch('WebLinkChange') @Link web: string

  WebLinkChange() {
    // console.log('===============',this.web)
    const param: paramModel = {
      web: this.web,
      currentIndex: this.currentIndex,
      bottomCurrIndex: this.bottomCurrIndex,
      extend: this.extend,
      width_length: this.width_length
    }
    this.pageInfo.clear()
    this.pageInfo.pushPath({ "name": 'indexPage', param })
  }

  aboutToAppear(): void {
    // console.log('=========================0', this.extend)
  }

  build() {
    Flex({ direction: FlexDirection.Column }) {
      Row() {
        Image($r('app.media.MicLink_title'))
          .width(133)
        Blank()
        Image($r('app.media.leftBar_back'))
          .width(32)
          .onClick(() => {
            this.extend = false
            animateTo({
              duration: 600,
              curve: Curve.Friction,
              delay: 500,
              iterations: 1, // 设置-1表示动画无限循环  ,循环次数
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
        Image($r('app.media.back_right'))
          .width(32)
          .alignRules({
            start: { anchor: '__container__', align: HorizontalAlign.Center },
            center: { anchor: '__container__', align: VerticalAlign.Center },
          })
          .margin({ left: 24 })
          .onClick(() => {
            animateTo({
              duration: 500,
              curve: Curve.Friction,
              delay: 500,
              iterations: 1, // 设置-1表示动画无限循环  ,循环次数
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
      // .width(88)
      .height(35)
      .margin({ bottom: 20 })
      .flexGS()


      ForEach(this.AiModel_data, (item: Ai_Model, index) => {
        Flex({ alignItems: ItemAlign.Center }) {
          Image(this.currentIndex === index ? $r(`app.media.${item.select}`) : $r(`app.media.${item.img}`))
            .width(16).height(16)
            .objectFit(ImageFit.Fill)
            .margin({ right: 13 })
          Text(item.title[this.languages])
            .fontSize(14)
            .fontWeight(400)
            .lineHeight(14)
            .fontColor(this.currentIndex === index ? '#00aecc' : '')
            .visibility(this.extend ? Visibility.Visible : Visibility.None)
        }
        .backgroundColor(this.currentIndex === index ? "#e0f1f4" : '#f8f8f8')
        .padding({ left: 13 })
        .height(40)
        .borderRadius(8)
        .width('100%')
        .onClick(() => {
          this.currentIndex = index
          this.bottomCurrIndex = 10000
          this.web = item.web

        })
        .flexGS()
      }, (item: Ai_Model) => item.img)
      Divider()
        .width('100%')
        .height(1)
        .margin({ top: 5, bottom: 5 })
        .backgroundColor('#eaeaea')
      // 对话记录
      Flex({alignItems:ItemAlign.Center}) {
        Image($r(`app.media.sessionSecord`))
          .width(16).height(16)
          .objectFit(ImageFit.Fill)
          .margin({ right: 13 })
        Text(Languages.sessionSecord[this.languages])
          .fontSize(14)
          .fontWeight(400)
          .lineHeight(14)
          .fontColor(this.mark ? '#00aecc' : '')
          .visibility(this.extend ? Visibility.Visible : Visibility.None)
        Blank()
        Image($r('app.media.showDown'))
          .width(16)
          .rotate({
            angle: this.mark ? 90 : 0
          })
          .visibility(this.extend ? Visibility.Visible : Visibility.None)
      }
      .flexGS()
      .backgroundColor(this.mark ? "#e0f1f4" : '#f8f8f8')
      .padding({ left: 13 })
      .height(40)
      .borderRadius(8)
      .width('100%')
      .onClick(() => {
        this.mark = !this.mark
      })

      Scroll() {
        Flex({ direction: FlexDirection.Column }) {
          ForEach(this.bottom_data, (item: Ai_Model, index) => {
            Flex({ alignItems: ItemAlign.Center }) {
              Image(this.currentIndex === index ? $r(`app.media.${item.select}`) : $r(`app.media.${item.img}`))
                .width(16).height(16)
                .objectFit(ImageFit.Fill)
                .margin({ right: 13 })
              Text(item.title[this.languages])
                .fontSize(14)
                .fontWeight(400)
                .lineHeight(14)
                .fontColor(this.currentIndex === index ? '#00aecc' : '')
            }
            .backgroundColor(this.currentIndex === index ? "#e0f1f4" : '#f8f8f8')
            .padding({ left: 13 })
            .height(40)
            .borderRadius(8)
            .width('100%')
            .onClick(() => {
              this.currentIndex = index
            })
            .flexGS()
          }, (item: Ai_Model) => item.img)
        }
        .width('100%')
        .height('100%')
      }
      .edgeEffect(EdgeEffect.Spring)
      .height(160)
      .visibility(this.extend && this.mark ? Visibility.Visible : Visibility.None)
      .width('100%')
      .scrollBar(BarState.Off)
      .flexGS()

      Column()
        .height(1)
        .margin(20)
        .flexGrow(50)
      //底部
      ForEach(this.bottom_data, (item: Ai_Model, index) => {
        Flex({ alignItems: ItemAlign.Center }) {
          Image(this.bottomCurrIndex === index ? $r(`app.media.${item.select}`) : $r(`app.media.${item.img}`))
            .width(16).height(16)
            .objectFit(ImageFit.Fill)
            .margin({ right: 13 })
          Text(item.title[this.languages])
            .fontSize(14)
            .fontWeight(400)
            .lineHeight(14)
            .fontColor(this.bottomCurrIndex === index ? '#00aecc' : '')
            .visibility(this.extend ? Visibility.Visible : Visibility.None)
        }
        .backgroundColor(this.bottomCurrIndex === index ? "#e0f1f4" : '#f8f8f8')
        .padding({ left: 13 })
        .height(40)
        .borderRadius(8)
        .width('100%')
        .onClick(() => {
          this.bottomCurrIndex = index
          this.currentIndex = 10000
          this.web = item.web
        })
        .flexGS()
      }, (item: Ai_Model) => item.img)

    }
    .width(this.width_length)
    .height('100%')
    .backgroundColor('#f8f8f8')
    .padding(24)
  }
}