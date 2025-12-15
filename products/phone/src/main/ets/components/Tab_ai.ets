import { AudioRecorderManager } from "api"
import { CommonConfig } from "components_phone"
import { common } from "@kit.AbilityKit"
import { FocusController } from "@ohos.arkui.UIContext"
import { LengthMetrics } from "@kit.ArkUI"
import { AllShowAIWriting } from "./aiWriting/AllShowAIWriting"
import { AllShowAIDrawing } from "./aiWriting/AllShowAIDrawing"

export interface AIListType {
  image: string
  title: string
  AIline: string
}

export interface ModelsItem { //大模型列表
  image: string
  name: string
  title: string
  recommended: boolean //是否被推荐
}


@Component
export struct Tab_ai {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @Consume('pageInfo') pageInfo: NavPathStack
  @State Frame_29_select: boolean = false
  @State online_thinking_select: boolean = false
  @State aiList: AIListType[] = [
    {
      image: 'aiMeeting',
      title: 'AI 会议',
      AIline: ''
    }, {
    image: 'aiWriting',
    title: 'AI 写作',
    AIline: ''
  }, {
    image: 'aiDrawing',
    title: 'AI 绘图',
    AIline: ''
  }, {
    image: 'aiPpt',
    title: 'AI PPT',
    AIline: ''
  }, {
    image: 'imageAnalysis',
    title: '图片分析',
    AIline: ''
  }, {
    image: 'documentConversion',
    title: '文档转换',
    AIline: ''
  }, {
    image: 'aiVideo',
    title: 'AI视频',
    AIline: ''
  }
  ]
  @State models: ModelsItem[] = [
    {
      image: 'deepseek',
      name: 'DeepSeck-V3 ',
      title: '长文本强，逻辑推理。',
      recommended: true
    }, {
    image: 'deepseek',
    name: 'DeepSeek-Rl',
    title: '数学专精，代码优化。',
    recommended: false
  }, {
    image: 'Frame_2511',
    name: '豆包',
    title: '响应迅速，轻量高效。',
    recommended: false
  }, {
    image: 'tyqw',
    name: '通义千问',
    title: '多轮对话，知识丰富。',
    recommended: false
  }, {
    image: 'wxyy',
    name: '文心一言',
    title: '中文理解，创作力强。',
    recommended: false
  }, {
    image: 'Kimi',
    name: 'KIMI',
    title: '简洁交互，信息精准。',
    recommended: false
  }, {
    image: 'xfxh',
    name: '讯飞星火',
    title: '多轮对话，响应迅捷。',
    recommended: false
  }, {
    image: 'xfxh',
    name: '讯飞星火-X1',
    title: '多模态强，视觉理解。',
    recommended: false
  }]
  @State showModels: boolean = false; // 展开大模型列表
  @State currModels: number = 2; // 当前大模型
  @State inputCapable: boolean = false; // 具备输入能力
  @State showAnimate: boolean = true; // 按住语音图片变化
  @State showAnimate_flax: boolean = false; //是否显示录音UI
  @State isTextAllShow: boolean = false //输入文本是否全部展开
  @State downAnimate: number = -100000
  @State audioRecorderManager: AudioRecorderManager =
    new AudioRecorderManager(this.getUIContext().getHostContext() as common.UIAbilityContext)
  @State inputText: string = ''
  @State showAIOption: boolean = false //是否选择展示具体某个ai，并控制List的滚动能力
  @State currAIOption: number = 10000 //被点击查看的ai索引
  @State currAIHeight: number = 34 //被查看的ai界面高度
  @State currAIWidth: string = '30%' //被查看的ai界面宽度
  private focusController: FocusController = this.getUIContext().getFocusController();
  private listScroller: ListScroller = new ListScroller()

  AI_ListOnclick(index: number) {
    switch (index) {
      case 0:
        if (this.showAIOption) {
          break
        }
        this.pageInfo.pushPath({ "name": 'AI_Meeting' })
        break
      case 1:
        if (this.showAIOption) {
          return
        }
        this.showAIOption = true
        this.currAIOption = 1
        this.listScroller.scrollToIndex(1)
        this.getUIContext()?.animateTo({
          duration: 1200,
          curve: Curve.Friction,
          playMode: PlayMode.Alternate,
          expectedFrameRateRange: {
            min: 10,
            max: 120,
            expected: 60,
          }
        }, () => {
          this.currAIHeight = 177
          this.currAIWidth = '100%'
        })
        break
      case 2:
        if (this.showAIOption) {
          return
        }
        this.showAIOption = true
        this.currAIOption = 2
        this.listScroller.scrollToIndex(2)
        this.getUIContext()?.animateTo({
          duration: 1200,
          curve: Curve.Friction,
          playMode: PlayMode.Alternate,
          expectedFrameRateRange: {
            min: 10,
            max: 120,
            expected: 60,
          }
        }, () => {
          this.currAIHeight = 230
          this.currAIWidth = '100%'
        })
        break

    }
  }

  build() {
    Stack() {
      Stack() {
        Column() {
          //没有数据时默认显示
          Image($r('app.media.Vector_ai'))
            .height(45)
          Text('嗨！我是智能AI')
            .fontSize(CommonConfig.fontSize_14)
            .fontColor(CommonConfig.hintTextColor_select)
            .fontWeight(CommonConfig.fontWeight_400)
            .margin({ top: 16, bottom: 7 })
          Text('我可以帮你搜索、解答问题、写作，请把你的任务交给我把~')
            .width(198)
            .textAlign(TextAlign.Center)
            .fontSize(CommonConfig.fontSize_11)
            .fontColor(CommonConfig.secondaryTextColorMain)
            .fontWeight(CommonConfig.fontWeight_400)
        }
        .height('100%')
        .width('100%')
        .justifyContent(FlexAlign.Center)

        Column() {
          Row() {
            Text('智能AI')
              .width(60)
              .fontColor(CommonConfig.hintTextColor_select)
              .fontWeight(CommonConfig.fontWeight_700)
              .fontSize(CommonConfig.fontSize_18)
              .margin({ right: 8 })

            Row() {
              Image($r(`app.media.${this.models[this.currModels].image}`))
                .width(16)
                .margin({ right: 4 })
              Text(this.models[this.currModels].name)
                .fontSize(CommonConfig.fontSize_12)
                .fontWeight(CommonConfig.fontWeight_400)
                .fontColor(CommonConfig.secondaryTextColorMain)
            }
            .alignItems(VerticalAlign.Center)
            .backgroundColor(Color.White)
            .borderRadius(4)
            .padding({
              left: 4,
              top: 2,
              right: 4,
              bottom: 2
            })
            .onClick(() => {
              this.showModels = !this.showModels
            })

            Blank()
            Image($r('app.media.new_chat'))
              .height(40)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          if (this.showModels) {
            Scroll() {
              Column() {
                ForEach(this.models, (item: ModelsItem, index) => {
                  Column() {
                    Row() {
                      Text(item.name)
                        .fontWeight(CommonConfig.fontWeight_400)
                        .fontColor(CommonConfig.hintTextColor_select)
                        .fontSize(CommonConfig.fontSize_12)
                      Text('推荐')
                        .backgroundColor('#e6f7fa')
                        .visibility(item.recommended ? Visibility.Visible : Visibility.None)
                        .padding({
                          left: 4,
                          top: 2,
                          right: 4,
                          bottom: 2
                        })
                        .fontWeight(CommonConfig.fontWeight_400)
                        .fontColor(this.paletteTheme)
                        .fontSize(CommonConfig.fontSize_12)
                    }
                    .margin({ bottom: 4 })
                    .alignItems(VerticalAlign.Center)

                    Row() {
                      Text(item.title)
                        .fontWeight(CommonConfig.fontWeight_400)
                        .fontColor(CommonConfig.hintTextColor)
                        .fontSize(CommonConfig.fontSize_12)
                    }
                    .alignItems(VerticalAlign.Center)
                  }
                  .alignItems(HorizontalAlign.Start)
                  .padding(8)
                  .border({ width: { bottom: 1 }, color: '#EAEAEA' })
                  .onClick(() => {
                    this.currModels = index
                    this.showModels = false
                  })
                }, (item: ModelsItem) => item.name)
              }
            }
            .height(250)
            .align(Alignment.TopStart)
            .padding(8)
            .scrollBarWidth(2)
            .borderRadius(8)
            .backgroundColor(Color.White)
            .margin({ left: 68 })
          }
        }
        .alignItems(HorizontalAlign.Start)

      }
      .height("100%")
      .align(Alignment.TopStart)
      .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      Column() {
        Stack() {
          List({ scroller: this.listScroller }) {
            ForEach(this.aiList, (item: AIListType, index) => {
              ListItem() {
                if (this.showAIOption && (this.currAIOption === index && this.currAIOption === 1)) {
                  /**
                   * AI写作，配置选项
                   */
                  AllShowAIWriting({
                    item: item,
                    showAIOption: this.showAIOption,
                    currAIHeight: this.currAIHeight,
                    currAIWidth: this.currAIWidth
                  })
                } else if (this.showAIOption && (this.currAIOption === index && index === 2)) {
                  /**
                   * AI绘图，配置选项
                   */
                  AllShowAIDrawing({
                    item: item,
                    showAIOption: this.showAIOption,
                    currAIHeight: this.currAIHeight,
                    currAIWidth: this.currAIWidth
                  })
                } else {
                  Flex({ alignItems: ItemAlign.Center }) {
                    Image($r(`app.media.${item.image}`))
                      .width(16)
                      .margin({ right: 8 })
                      .backgroundColor(Color.White)
                      .flexShrink(1)
                      .flexGrow(1)
                    Text(item.title)
                      .fontSize(CommonConfig.fontSize_12)
                      .fontWeight(CommonConfig.fontWeight_400)
                      .fontColor(CommonConfig.hintTextColor_select)
                      .flexShrink(1)
                      .flexGrow(1)
                  }
                  .borderRadius(8)
                  .padding({
                    left: 12,
                    top: 8,
                    right: 12,
                    bottom: 8
                  })
                  .border({ width: 1, color: '#EAEAEA' })
                  .margin({ right: this.aiList.length === index + 1 ? 0 : 8 })
                  .backgroundColor(Color.White)
                  .onClick(() => {
                    this.AI_ListOnclick(index)
                  })
                }

              }

            }, (item: AIListType) => item.AIline)
          }
          .width('100%')
          .margin({ bottom: 12 })
          .alignListItem(ListItemAlign.End)
          .scrollBar(this.showAIOption ? BarState.Off : BarState.On)
          .height(this.currAIHeight)
          .listDirection(Axis.Horizontal)
          .scrollBarWidth(0)
          .onScrollStop(() => {
            if (this.showAIOption) {
              this.listScroller.scrollToIndex(this.currAIOption)
            }
          })


          if (this.showAnimate_flax) {
            Image(this.showAnimate ? $r('app.media.audioanimate1') : $r('app.media.audioanimate2'))
              .width('100%')
              .height(40)
              .margin({ bottom: 12 })
          } //语音条
        }
        .align(Alignment.Bottom)

        if (this.inputCapable) { //对话输入页面
          Column() {
            if (this.isTextAllShow) {
              Flex() {
                TextArea({ text: $$this.inputText })
                  .backgroundColor(Color.White)
                  .padding(0)
                  .fontSize(CommonConfig.fontSize_14)
                  .fontWeight(CommonConfig.fontWeight_400)
                  .fontColor(CommonConfig.hintTextColor_select)
                  .defaultFocus(true)
                  .height(152)
                  .borderRadius(0)
                  .focusable(true)
                  .key('myTextArea')
                Column() {
                  Image($r('app.media.delete_ai'))
                    .width(24)
                    .margin({ left: 8, bottom: 8 })
                    .onClick(() => {
                      // this.inputText = ''
                      this.inputCapable = false
                    })
                  Image($r('app.media.textShow_ai'))
                    .width(24)
                    .margin({ left: 8 })
                    .onClick(() => {
                      this.isTextAllShow = false
                    })
                }

              }
              .margin({ bottom: 8 })
            } else {
              Flex() {
                TextArea({ text: $$this.inputText })
                  .backgroundColor(Color.White)
                  .padding(0)
                  .fontSize(CommonConfig.fontSize_14)
                  .fontWeight(CommonConfig.fontWeight_400)
                  .fontColor(CommonConfig.hintTextColor_select)
                  .defaultFocus(true)
                  .height(40)
                  .borderRadius(0)
                  .focusable(true)
                  .key('myTextArea')
                Image($r('app.media.delete_ai'))
                  .width(24)
                  .margin({ left: 8, right: 8 })
                  .onClick(() => {
                    // this.inputText = ''
                    this.inputCapable = false
                  })
                Image($r('app.media.textShow_ai'))
                  .width(24)
                  .onClick(() => {
                    this.isTextAllShow = true
                  })
              }
              .margin({ bottom: 8 })
            }


            Flex() {
              Image(this.Frame_29_select ? $r('app.media.network_thinking_enabled') :
              $r('app.media.network_thinking_disabled'))
                .height(32)
                .onClick(() => {
                  this.Frame_29_select = !this.Frame_29_select
                })
                .flexShrink(1)
                .flexGrow(1)
                .margin({ right: 8 })
              Image(this.online_thinking_select ? $r('app.media.deep_thinking_filled') :
              $r('app.media.deep_thinking_outline'))
                .height(32)
                .margin({ right: 8 })
                .onClick(() => {
                  this.online_thinking_select = !this.online_thinking_select
                })
                .flexShrink(1)
                .flexGrow(1)
                .margin({ right: 8 })


              Image($r('app.media.audio'))
                .width(32)
                .margin({ left: 27, right: 8 })
                .onDragStart((event: DragEvent) => {
                  // 关键代码：返回DRAG_CANCELED阻止拖出
                  event.setResult(DragResult.DRAG_CANCELED);
                })
                .onTouch((event) => {
                  if (event.type === TouchType.Down) { // 按下时改变状态
                    this.audioRecorderManager.startRecording().then((res) => {
                      if (res) {
                        if (!this.showAnimate_flax) {
                          this.downAnimate = setInterval(() => {
                            this.showAnimate = !this.showAnimate;
                          }, 180)
                        }
                        this.showAnimate_flax = true
                      }
                    })

                  } else if (event.type === TouchType.Up) {
                    this.audioRecorderManager.stopAndUploadRecording().then((res) => {
                      console.log(JSON.stringify(res))
                      this.showAnimate_flax = false
                      clearInterval(this.downAnimate)
                    })

                  }
                })
              Image($r('app.media.multi_functional'))
                .width(32)
                .margin({ right: 8 })
              Image($r('app.media.Frame_32'))
                .width(32)
            }
          }
          .backgroundColor(Color.White)
          .borderRadius(8)
          .padding(8)
        } else {
          Flex({ alignItems: ItemAlign.Center }) {
            Image(this.Frame_29_select ? $r('app.media.Frame_29_select') : $r('app.media.Frame_29'))
              .width(32)
              .margin({ right: 8 })
              .onClick(() => {
                this.Frame_29_select = !this.Frame_29_select
              })
            Image(this.online_thinking_select ? $r('app.media.online_thinking_select') :
            $r('app.media.online_thinking'))
              .width(32)
              .margin({ right: 8 })
              .onClick(() => {
                this.online_thinking_select = !this.online_thinking_select
              })
            Text(this.inputText ? this.inputText : '给 AI 发送消息')
              .layoutWeight(1)
              .fontWeight(CommonConfig.fontWeight_400)
              .fontSize(CommonConfig.fontSize_14)
              .maxLines(2)
              .fontColor(this.inputText ? CommonConfig.hintTextColor_select : CommonConfig.hintTextColor)
              .backgroundColor(Color.White)
              .onClick(() => {
                this.inputCapable = true
                setTimeout(() => {
                  this.focusController.requestFocus('myTextArea');
                }, 50)
              })
            Image($r('app.media.audio'))
              .width(32)
              .margin({ right: 8 })
              .onDragStart((event: DragEvent) => {
                // 关键代码：返回DRAG_CANCELED阻止拖出
                event.setResult(DragResult.DRAG_CANCELED);
              })
              .onTouch((event) => {
                if (event.type === TouchType.Down) { // 按下时改变状态
                  this.audioRecorderManager.startRecording().then((res) => {
                    if (res) {
                      if (!this.showAnimate_flax) {
                        this.downAnimate = setInterval(() => {
                          this.showAnimate = !this.showAnimate;
                        }, 180)
                      }
                      this.showAnimate_flax = true
                    }
                  })

                } else if (event.type === TouchType.Up) {
                  this.audioRecorderManager.stopAndUploadRecording().then((res) => {
                    console.log(JSON.stringify(res))
                    this.showAnimate_flax = false
                    clearInterval(this.downAnimate)
                  })

                }
              })
            Image($r('app.media.multi_functional'))
              .width(32)
          }
          .width('100%')
          .borderRadius(8)
          .padding(8)
          .backgroundColor(Color.White)
        }

      }
      .margin({ bottom: 12 })

    }
    .align(Alignment.Bottom)
    .width('100%')
    .height('100%')
  }
}