import { CommonConfig } from "components_phone"
import { AIListType } from "../Tab_ai"
import { LengthMetrics } from "@kit.ArkUI"

@Extend(Text)
function commonText() {
  .fontSize(CommonConfig.fontSize_14)
  .fontColor(CommonConfig.hintTextColor)
  .fontWeight(CommonConfig.fontWeight_400)
}

interface requirementType {
  image: string
  title: string
}

@Component
export struct AllShowAIDrawing {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @State item: AIListType | null = null
  @Link showAIOption: boolean //是否选择展示具体某个ai，并控制List的滚动能力
  @Link currAIHeight: number //被查看的ai界面高度
  @Link currAIWidth: string //被查看的ai界面宽度
  @State aiDrawing_proportionList: string[] = ['1:1', '2:3', '4:3', '9:16', "16:9"] //绘图比例展示
  @State aiDrawing_requirementTypeList: requirementType[] = [
    {
      image: 'ai_drawing_erase',
      title: '擦除'
    }, {
    image: 'ai_drawing_sharpen',
    title: '变清晰'
  }, {
    image: 'ai_drawing_expand',
    title: '扩图'
  }, {
    image: 'ai_drawing_reference',
    title: '参考图'
  }
  ] //绘图要求展示
  @StorageLink("aiWriting_Scene") aiDrawing_Scene: number = 0 //写作场景
  @State showaiDrawing_proportion: boolean = false
  @StorageLink("aiDrawing_proportion") aiDrawing_proportion: number = 100000 //绘图比例索引
  @StorageLink("ai_drawing_erase") ai_drawing_erase: boolean = false //绘图:擦除要求
  @StorageLink("ai_drawing_sharpen") ai_drawing_sharpen: boolean = false //绘图:变清晰要求
  @StorageLink("ai_drawing_expand") ai_drawing_expand: boolean = false //绘图:扩图要求
  @StorageLink("ai_drawing_reference") ai_drawing_reference: boolean = false //绘图:参考图要求

  requirement(index: number) {
    switch (index) {
      case 0:
        this.ai_drawing_erase = !this.ai_drawing_erase
        break
      case 1:
        this.ai_drawing_sharpen = !this.ai_drawing_sharpen
        break
      case 2:
        this.ai_drawing_expand = !this.ai_drawing_expand
        break
      case 3:
      /**
       * 参考图：改变高度
       * 添加图片位置
       */

    }
  }

  requirementState(index: number): boolean {
    switch (index) {
      case 0:
        return this.ai_drawing_erase
      case 1:
        return this.ai_drawing_sharpen
      case 2:
        return this.ai_drawing_expand
    }
    return false
  }

  build() {
    Stack() {
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
              Text('要求')
                .commonText()

              Flex({ space: { main: LengthMetrics.vp(8) } }) {
                List() {
                  ListItem() {
                    Row() {
                      Image($r('app.media.proportion'))
                        .margin({ right: 4 })
                        .width(16)
                      Text('比例:')
                        .margin({ right: 4 })
                        .fontWeight(CommonConfig.fontWeight_400)
                        .fontSize(CommonConfig.fontSize_12)
                        .fontColor(CommonConfig.hintTextColor_select)
                      Text(this.aiDrawing_proportion !== 100000 ?
                      this.aiDrawing_proportionList[this.aiDrawing_proportion] : '不限')
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
                    .margin({ right: 8 })
                    .border({ width: 1, color: CommonConfig.commonBorderColor })
                    .onClick(() => {
                      this.showaiDrawing_proportion = !this.showaiDrawing_proportion
                    })
                  }

                  ForEach(this.aiDrawing_requirementTypeList, (item: requirementType, index) => {
                    ListItem() {
                      Row() {
                        Image($r(`app.media.${item.image}`))
                          .margin({ right: 4 })
                          .width(16)
                        Text(item.title)
                          .margin({ right: 4 })
                          .fontWeight(CommonConfig.fontWeight_400)
                          .fontSize(CommonConfig.fontSize_12)
                          .fontColor(this.requirementState(index) ? this.paletteTheme :
                          CommonConfig.hintTextColor_select)
                      }
                      .margin({ right: this.aiDrawing_requirementTypeList.length === index + 1 ? 0 : 8 })
                      .borderRadius(8)
                      .height(34)
                      .padding(8)
                      .border({
                        width: 1,
                        color: this.requirementState(index) ? this.paletteTheme : CommonConfig.commonBorderColor
                      })
                      .onClick(() => {
                        this.requirement(index)
                      })
                    }

                  }, (item: requirementType) => item.image)
                }
                .listDirection(Axis.Horizontal)
                .width('100%')
                .scrollBarWidth(0)
              }
              .zIndex(10)

              Text('画风')
                .commonText()
              Row() {
                List({ space: 8 }) {
                  ForEach(['海报', '风景', '插画', '写真', '水墨', '油画', '绘本'],
                    (item: string, index) => {
                      ListItem() {
                        Column() {
                          Image($r('app.media.Rectangle_497'))
                            .width(50)
                            .height(50)
                            .borderRadius(8)
                            .margin({bottom:8})
                          Text(item)
                            .fontSize(CommonConfig.fontSize_12)
                            .fontColor(CommonConfig.hintTextColor_select)
                            .fontWeight(CommonConfig.fontWeight_400)
                        }
                        .borderRadius(8)
                        .padding(8)
                        .border({
                          width: 1,
                          color: this.aiDrawing_Scene === index ? this.paletteTheme :
                          CommonConfig.commonBorderColor
                        })
                        .onClick(() => {
                          this.aiDrawing_Scene = index
                        })
                      }
                    }, (item: string) => item)
                }
                .listDirection(Axis.Horizontal)
                .layoutWeight(1)
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
      .backgroundColor(Color.White)
      .height(this.currAIHeight)
      .width(this.currAIWidth)
      .margin({ right: 8 })

      if (this.showaiDrawing_proportion) {
        Column()
          .width('100%')
          .height("100%")
          .backgroundColor("#000 ")
          .opacity(0.1)
          .onClick(() => this.showaiDrawing_proportion = false)
        Scroll() {
          Column() {
            ForEach(this.aiDrawing_proportionList, (item: string, index) => {
              Text(item)
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding(8)
                .fontWeight(CommonConfig.fontWeight_400)
                .fontSize(CommonConfig.fontSize_12)
                .fontColor(CommonConfig.hintTextColor_select)
                .border({ width: { bottom: 1 }, color: CommonConfig.commonBorderColor })
                .onClick(() => {
                  this.aiDrawing_proportion = index
                  this.showaiDrawing_proportion = false
                })
            }, (item: string) => item)
          }
        }
        .padding(8)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .width(120)
        .height(120)
        .margin({ left: 12, top: 95 })
      }

    }
    .align(Alignment.TopStart)

  }
}