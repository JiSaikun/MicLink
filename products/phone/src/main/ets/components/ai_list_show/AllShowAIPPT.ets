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
export struct AllShowAIPPT {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @State item: AIListType | null = null
  @Link showAIOption: boolean //是否选择展示具体某个ai，并控制List的滚动能力
  @Link currAIHeight: number //被查看的ai界面高度
  @Link currAIWidth: string //被查看的ai界面宽度  aiPpt
  @State aiPpt_StyleList: string[] = ['简洁', '正式']
  @State aiPpt_LengthList: string[] = ['短', '中', '长']
  @State aiPpt_LanguageList: string[] = ['中文', '英文']
  @StorageLink("aiaiPpt_Scene") aiaiPpt_Scene: number = 0 //写作场景
  @State showaiPpt_Scene: boolean = false
  @State showaiPpt_Length: boolean = false
  @State showaiPpt_Language: boolean = false
  @StorageLink("aiPpt_Style") aiPpt_Style: number = 100000 //写作风格
  @StorageLink("aiPpt_Length") aiPpt_Length: number = 100000 //写作长度
  @StorageLink("aiPpt_Language") aiPpt_Language: number = 100000 //写作语言
  @Watch('currTemplate') @StorageLink("aiPpt_template") aiPpt_template: number = 100000 //PPT模板

  currTemplate() {
    if (this.aiPpt_template !== 100000) {
      this.getUIContext()?.animateTo({
        duration: 500,
        curve: Curve.Friction,
        playMode: PlayMode.Alternate,
        expectedFrameRateRange: {
          min: 10,
          max: 120,
          expected: 0,
        }
      }, () => {
        this.currAIHeight = 358
      })
    }
  }

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
              this.showaiPpt_Scene = false
              this.showaiPpt_Length = false
              this.showaiPpt_Language = false
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
              ForEach(['通用', '工作计划', '内容策划', '市场分析', '年度总结', '旅行计划', '论文答辩'],
                (item: string, index) => {
                  ListItem() {
                    Text(item)
                      .fontSize(CommonConfig.fontSize_12)
                      .fontWeight(CommonConfig.fontWeight_400)
                      .fontColor(this.aiaiPpt_Scene === index ? this.paletteTheme :
                      CommonConfig.hintTextColor_select)
                      .borderRadius(8)
                      .padding(8)
                      .border({
                        width: 1,
                        color: this.aiaiPpt_Scene === index ? this.paletteTheme :
                        CommonConfig.commonBorderColor
                      })
                      .onClick(() => {
                        this.aiaiPpt_Scene = index
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
                  Text(this.aiPpt_Style !== 100000 ? this.aiPpt_StyleList[this.aiPpt_Style] : '不限')
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
                  this.showaiPpt_Scene = !this.showaiPpt_Scene
                  this.showaiPpt_Length = false
                  this.showaiPpt_Language = false
                })

                if (this.showaiPpt_Scene)
                Column() {
                  ForEach(this.aiPpt_StyleList, (item: string, index) => {
                    Text(item)
                      .width('100%')
                      .textAlign(TextAlign.Center)
                      .padding(8)
                      .fontWeight(CommonConfig.fontWeight_400)
                      .fontSize(CommonConfig.fontSize_12)
                      .fontColor(CommonConfig.hintTextColor_select)
                      .border({ width: { bottom: 1 }, color: CommonConfig.commonBorderColor })
                      .onClick(() => {
                        this.aiPpt_Style = index
                        this.showaiPpt_Scene = false
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
                  Text(this.aiPpt_Length !== 100000 ? this.aiPpt_LengthList[this.aiPpt_Length] : '不限')
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
                  this.showaiPpt_Length = !this.showaiPpt_Length
                  this.showaiPpt_Scene = false
                  this.showaiPpt_Language = false
                })

                if (this.showaiPpt_Length)
                List() {
                  ForEach(this.aiPpt_LengthList, (item: string, index) => {
                    ListItem() {
                      Text(item)
                        .width('100%')
                        .textAlign(TextAlign.Center)
                        .padding(8)
                        .fontWeight(CommonConfig.fontWeight_400)
                        .fontSize(CommonConfig.fontSize_12)
                        .fontColor(CommonConfig.hintTextColor_select)
                        .border({ width: { bottom: 1 }, color: CommonConfig.commonBorderColor })
                        .onClick(() => {
                          this.aiPpt_Length = index
                          this.showaiPpt_Length = false
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
                  Text(this.aiPpt_Language !== 100000 ? this.aiPpt_LanguageList[this.aiPpt_Language] :
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
                  this.showaiPpt_Language = !this.showaiPpt_Language
                  this.showaiPpt_Length = false
                  this.showaiPpt_Scene = false
                })

                if (this.showaiPpt_Language)
                Column() {
                  ForEach(this.aiPpt_LanguageList, (item: string, index) => {
                    Text(item)
                      .width('100%')
                      .textAlign(TextAlign.Center)
                      .padding(8)
                      .fontWeight(CommonConfig.fontWeight_400)
                      .fontSize(CommonConfig.fontSize_12)
                      .fontColor(CommonConfig.hintTextColor_select)
                      .border({ width: { bottom: 1 }, color: CommonConfig.commonBorderColor })
                      .onClick(() => {
                        this.aiPpt_Language = index
                        this.showaiPpt_Language = false
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

            }
            .height(34)

            Text('模板')
              .commonText()
            if (this.aiPpt_template !== 100000) {
              List() {
                ListItem() {
                  Row() {
                    Image($r('app.media.Rectangle_497'))
                      .height('100%')
                      .width(60)
                      .borderRadius(4)
                      .margin({ right: 8 })
                    Text('已选择模板')
                      .fontSize(CommonConfig.fontSize_11)
                      .fontColor(CommonConfig.hintTextColor)
                      .fontWeight(CommonConfig.fontWeight_400)
                  }
                  .height('100%')
                  .width('100%')
                  .alignItems(VerticalAlign.Center)
                  .padding({ bottom: 8, top: 8 })
                  .border({ width: { top: 1, bottom: 1 }, color: CommonConfig.commonBorderColor })
                }

              }
              .scrollBarWidth(0)
              .layoutWeight(1)
            }

            Row() {
              List({ space: 8 }) {
                ForEach(['5K', '5K', '5K', '5K', '5K', '5K', '5K'],
                  (item: string, index) => {
                    ListItem() {
                      Stack() {
                        Image($r('app.media.Rectangle_497'))
                          .width(159)
                          .height('100%')
                          .borderRadius(8)
                          .border({
                            width: 1,
                            color: this.aiPpt_template === index ? this.paletteTheme :
                            CommonConfig.commonBorderColor
                          })
                        Row() {
                          Image($r('app.media.Hot'))
                            .width(16)
                            .margin({ right: 4 })
                          Text(item)
                            .fontColor(Color.White)
                            .fontWeight(CommonConfig.fontWeight_400)
                            .fontSize(CommonConfig.fontSize_11)
                        }
                        .borderRadius(100)
                        .alignItems(VerticalAlign.Center)
                        .backgroundColor('#818589')
                        .padding({
                          left: 4,
                          top: 2,
                          bottom: 2,
                          right: 4
                        })
                        .margin(8)
                      }
                      .align(Alignment.BottomStart)
                      .onClick(() => {
                        if (this.aiPpt_template === index) {
                          this.getUIContext()?.animateTo({
                            duration: 500,
                            curve: Curve.Friction,
                            playMode: PlayMode.Alternate,
                            expectedFrameRateRange: {
                              min: 10,
                              max: 120,
                              expected: 0,
                            },
                            onFinish: () => this.aiPpt_template = 100000
                          }, () => {
                            this.currAIHeight = 300
                          })
                          return
                        }
                        this.aiPpt_template = index
                      })
                    }
                  }, (item: string) => item)
              }
              .listDirection(Axis.Horizontal)
              .height(90)
              .scrollBarWidth(0)
            }

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
    .backgroundColor((this.showaiPpt_Scene || this.showaiPpt_Length || this.showaiPpt_Language) ?
    CommonConfig.commonBackgroundColor : Color.White)
    .height(this.currAIHeight)
    .width(this.currAIWidth)
    .margin({ right: 8 })
  }
}