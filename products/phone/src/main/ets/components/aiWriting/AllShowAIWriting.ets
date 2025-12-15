import { CommonConfig } from "components_phone"
import { AIListType } from "../Tab_ai"
import { LengthMetrics } from "@kit.ArkUI"

@Extend(Text)
function commonText() {
  .fontSize(CommonConfig.fontSize_14)
  .fontColor(CommonConfig.hintTextColor)
  .fontWeight(CommonConfig.fontWeight_400)
}

@Component
export struct AllShowAIWriting {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @State item: AIListType | null = null
  @Link showAIOption: boolean //是否选择展示具体某个ai，并控制List的滚动能力
  @Link currAIHeight: number //被查看的ai界面高度
  @Link currAIWidth: string //被查看的ai界面宽度
  @State aiWriting_StyleList: string[] = ['简洁', '正式']
  @State aiWriting_LengthList: string[] = ['短', '中', '长']
  @State aiWriting_LanguageList: string[] = ['中文', '英文']
  @StorageLink("aiWriting_Scene") aiWriting_Scene: number = 0 //写作场景
  @State showaiWriting_Scene: boolean = false
  @State showaiWriting_Length: boolean = false
  @State showaiWriting_Language: boolean = false
  @StorageLink("aiWriting_Style") aiWriting_Style: number = 100000 //写作风格
  @StorageLink("aiWriting_Length") aiWriting_Length: number = 100000 //写作长度
  @StorageLink("aiWriting_Language") aiWriting_Language: number = 100000 //写作语言

  build() {
    Column() {
      List() {
        ListItem() {
          Flex() {
            Image($r(`app.media.${this.item?.image}`))
              .width(16)
              .margin({ right: 8 })
              .backgroundColor(Color.White)
            Text(this.item?.title)
              .fontSize(CommonConfig.fontSize_12)
              .fontWeight(CommonConfig.fontWeight_400)
              .fontColor(CommonConfig.hintTextColor_select)
            Blank()
            Row() {
              Image($r("app.media.clearpop"))
                .width('100%')
            }
            .flexShrink(1)
            .width(24)
            .onClick(() => {
              this.showaiWriting_Scene = false
              this.showaiWriting_Length = false
              this.showaiWriting_Language = false
              this.getUIContext()?.animateTo({
                duration: 1200,
                curve: Curve.Friction,
                playMode: PlayMode.Alternate,
                expectedFrameRateRange: {
                  min: 10,
                  max: 120,
                  expected: 60,
                },
                onFinish: () => {
                  this.showAIOption = false
                }
              }, () => {
                this.currAIWidth = '30%'
                this.currAIHeight = 34
              })
            })

          }
          .width(319)
        }
      }
      .listDirection(Axis.Horizontal)
      .height(24)
      .scrollBarWidth(0)

      Scroll() {
        Column() {
          Column({ space: 8 }) {
            Text('场景')
              .commonText()
            List({ space: 8 }) {
              ForEach(['通用', '论文', '作文', '文章', '宣传文案', '小说', '改写'],
                (item: string, index) => {
                  ListItem() {
                    Text(item)
                      .fontSize(CommonConfig.fontSize_12)
                      .fontWeight(CommonConfig.fontWeight_400)
                      .fontColor(this.aiWriting_Scene === index ? this.paletteTheme :
                      CommonConfig.hintTextColor_select)
                      .borderRadius(8)
                      .padding(8)
                      .border({
                        width: 1,
                        color: this.aiWriting_Scene === index ? this.paletteTheme :
                        CommonConfig.commonBorderColor
                      })
                      .onClick(() => {
                        this.aiWriting_Scene = index
                      })
                  }
                }, (item: string) => item)
            }
            .listDirection(Axis.Horizontal)
            .height(34)
            .scrollBarWidth(0)

            Text('要求')
              .commonText()
            Flex({ space: { main: LengthMetrics.vp(8) } }) {
              RelativeContainer() {
                Row() {
                  Text('风格:')
                    .margin({ right: 4 })
                    .fontWeight(CommonConfig.fontWeight_400)
                    .fontSize(CommonConfig.fontSize_12)
                    .fontColor(CommonConfig.hintTextColor_select)
                  Text(this.aiWriting_Style !== 100000 ? this.aiWriting_StyleList[this.aiWriting_Style] : '不限')
                    .margin({ right: 4 })
                    .fontWeight(CommonConfig.fontWeight_400)
                    .fontSize(CommonConfig.fontSize_12)
                    .fontColor(CommonConfig.hintTextColor_select)
                  Image($r('app.media.back_ai'))
                    .width(16)
                }
                .borderRadius(8)
                .height(34)
                .padding(8)
                .border({ width: 1, color: CommonConfig.commonBorderColor })
                .id('bot')
                .onClick(() =>{
                  this.showaiWriting_Scene = !this.showaiWriting_Scene
                  this.showaiWriting_Length=false
                  this.showaiWriting_Language=false
                })

                if (this.showaiWriting_Scene)
                Column() {
                  ForEach(this.aiWriting_StyleList, (item: string, index) => {
                    Text(item)
                      .width('100%')
                      .textAlign(TextAlign.Center)
                      .padding(8)
                      .fontWeight(CommonConfig.fontWeight_400)
                      .fontSize(CommonConfig.fontSize_12)
                      .fontColor(CommonConfig.hintTextColor_select)
                      .border({ width: { bottom: 1 }, color: CommonConfig.commonBorderColor })
                      .onClick(() => {
                        this.aiWriting_Style = index
                        this.showaiWriting_Scene = false
                      })
                  }, (item: string) => item)
                }
                .padding(8)
                .backgroundColor(Color.White)
                .borderRadius(8)
                .width(120)
                .height(80)
                .alignRules({
                  bottom: { anchor: 'bot', align: VerticalAlign.Top },
                  start: { anchor: 'bot', align: HorizontalAlign.Start }
                })
                .margin({ bottom: 8 })
              }
              .align(Alignment.BottomStart)

              RelativeContainer() {
                Row() {
                  Text('长度:')
                    .margin({ right: 4 })
                    .fontWeight(CommonConfig.fontWeight_400)
                    .fontSize(CommonConfig.fontSize_12)
                    .fontColor(CommonConfig.hintTextColor_select)
                  Text(this.aiWriting_Style !== 100000 ? this.aiWriting_LengthList[this.aiWriting_Length] : '不限')
                    .margin({ right: 4 })
                    .fontWeight(CommonConfig.fontWeight_400)
                    .fontSize(CommonConfig.fontSize_12)
                    .fontColor(CommonConfig.hintTextColor_select)
                  Image($r('app.media.back_ai'))
                    .width(16)
                }
                .borderRadius(8)
                .height(34)
                .padding(8)
                .border({ width: 1, color: CommonConfig.commonBorderColor })
                .id('bot')
                .onClick(() =>{
                  this.showaiWriting_Length = !this.showaiWriting_Length
                  this.showaiWriting_Scene=false
                  this.showaiWriting_Language=false
                })

                if (this.showaiWriting_Length)
                List() {
                    ForEach(this.aiWriting_LengthList, (item: string, index) => {
                      ListItem(){
                        Text(item)
                          .width('100%')
                          .textAlign(TextAlign.Center)
                          .padding(8)
                          .fontWeight(CommonConfig.fontWeight_400)
                          .fontSize(CommonConfig.fontSize_12)
                          .fontColor(CommonConfig.hintTextColor_select)
                          .border({ width: { bottom: 1 }, color: CommonConfig.commonBorderColor })
                          .onClick(() => {
                            this.aiWriting_Length = index
                            this.showaiWriting_Length = false
                          })
                      }

                    }, (item: string) => item)

                }
                .padding(8)
                .backgroundColor(Color.White)
                .borderRadius(8)
                .width(120)
                .height(90)
                .alignRules({
                  bottom: { anchor: 'bot', align: VerticalAlign.Top },
                  start: { anchor: 'bot', align: HorizontalAlign.Start }
                })
                .scrollBarWidth(2)
                .margin({ bottom: 8 })
                .align(Alignment.TopStart)
              }
              .align(Alignment.BottomStart)

              RelativeContainer() {
                Row() {
                  Text('语言:')
                    .margin({ right: 4 })
                    .fontWeight(CommonConfig.fontWeight_400)
                    .fontSize(CommonConfig.fontSize_12)
                    .fontColor(CommonConfig.hintTextColor_select)
                  Text(this.aiWriting_Language !== 100000 ? this.aiWriting_LanguageList[this.aiWriting_Language] :
                    '不限')
                    .margin({ right: 4 })
                    .fontWeight(CommonConfig.fontWeight_400)
                    .fontSize(CommonConfig.fontSize_12)
                    .fontColor(CommonConfig.hintTextColor_select)
                  Image($r('app.media.back_ai'))
                    .width(16)
                }
                .borderRadius(8)
                .height(34)
                .padding(8)
                .border({ width: 1, color: CommonConfig.commonBorderColor })
                .id('bot')
                .onClick(() => {
                  this.showaiWriting_Language = !this.showaiWriting_Language
                  this.showaiWriting_Length=false
                  this.showaiWriting_Scene=false
                })

                if (this.showaiWriting_Language)
                Column() {
                  ForEach(this.aiWriting_LanguageList, (item: string, index) => {
                    Text(item)
                      .width('100%')
                      .textAlign(TextAlign.Center)
                      .padding(8)
                      .fontWeight(CommonConfig.fontWeight_400)
                      .fontSize(CommonConfig.fontSize_12)
                      .fontColor(CommonConfig.hintTextColor_select)
                      .border({ width: { bottom: 1 }, color: CommonConfig.commonBorderColor })
                      .onClick(() => {
                        this.aiWriting_Language = index
                        this.showaiWriting_Language=false
                      })
                  }, (item: string) => item)
                }
                .padding(8)
                .backgroundColor(Color.White)
                .borderRadius(8)
                .width(120)
                .height(80)
                .alignRules({
                  bottom: { anchor: 'bot', align: VerticalAlign.Top },
                  end: { anchor: 'bot', align: HorizontalAlign.End }
                })
                .margin({ bottom: 8 })
              }
              .align(Alignment.BottomStart)

              Blank()
            }
            .layoutWeight(1)
          }
          .alignItems(HorizontalAlign.Start)
        }

      }
      .align(Alignment.Start)
      .scrollBar(BarState.Off)
      .layoutWeight(1)

    }
    .borderRadius(8)
    .padding({
      left: 12,
      top: 8,
      right: 12,
      bottom: 8
    })
    .border({ width: 1, color: '#EAEAEA' })
    .backgroundColor((this.showaiWriting_Scene||this.showaiWriting_Length||this.showaiWriting_Language)?CommonConfig.commonBackgroundColor:Color.White)
    .height(this.currAIHeight)
    .width(this.currAIWidth)
    .margin({right:8})
  }
}