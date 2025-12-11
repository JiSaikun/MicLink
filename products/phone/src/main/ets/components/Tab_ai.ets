import { AudioRecorderManager } from "api"
import { CommonConfig } from "components_phone"
import { common } from "@kit.AbilityKit"

interface AIListType {
  image: string
  title: string
  AIline: string
}

export interface ModelsItem { //大模型列表
  name: string
  title: string
  recommended: boolean //是否被推荐
}

@Component
export struct Tab_ai {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
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
      name: 'DeepSeck-V3 ',
      title: '长文本强，逻辑推理。',
      recommended: true
    }, {
    name: 'DeepSeek-Rl',
    title: '数学专精，代码优化。',
    recommended: false
  }, {
    name: '豆包',
    title: '响应迅速，轻量高效。',
    recommended: false
  }, {
    name: '通义千问',
    title: '多轮对话，知识丰富。',
    recommended: false
  }, {
    name: '文心一言',
    title: '中文理解，创作力强。',
    recommended: false
  }, {
    name: 'KIMI',
    title: '简洁交互，信息精准。',
    recommended: false
  }, {
    name: '讯飞星火',
    title: '多轮对话，响应迅捷。',
    recommended: false
  }, {
    name: '讯飞星火-X1',
    title: '多模态强，视觉理解。',
    recommended: false
  }]
  @State showModels: boolean = false; // 展开大模型列表
  @State currModels: string = '豆包'; // 当前大模型
  @State inputCapable: boolean = false; // 具备输入能力
  @State showAnimate: boolean = true; // 按住语音图片变化
  @State showAnimate_flax: boolean = false; //是否显示录音UI
  @State downAnimate: number = -100000
  @State audioRecorderManager: AudioRecorderManager =
    new AudioRecorderManager(this.getUIContext().getHostContext() as common.UIAbilityContext)
  @State inputText: string = ''

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
              Image($r('app.media.Frame_2511'))
                .width(16)
                .margin({ right: 4 })
              Text(this.currModels)
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
                ForEach(this.models, (item: ModelsItem) => {
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
                    this.currModels = item.name
                    this.showModels = false
                  })
                }, (item: ModelsItem) => item.name)
              }
            }
            .height(250)
            .align(Alignment.TopStart)
            .padding(8)
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
          List() {
            ForEach(this.aiList, (item: AIListType, index) => {
              ListItem() {
                Flex({ alignItems: ItemAlign.Center }) {
                  Image($r(`app.media.${item.image}`))
                    .width(16)
                    .margin({ right: 8 })
                    .backgroundColor(Color.White)
                  Text(item.title)
                    .fontSize(CommonConfig.fontSize_12)
                    .fontWeight(CommonConfig.fontWeight_400)
                    .fontColor(CommonConfig.hintTextColor_select)
                }
                .borderRadius(8)
                .padding({
                  left: 12,
                  top: 8,
                  right: 12,
                  bottom: 8
                })
                .margin({ right: this.aiList.length === index + 1 ? 0 : 8 })
                .backgroundColor(Color.White)
              }

            }, (item: AIListType) => item.AIline)
          }
          .width('100%')
          .margin({ bottom: 12 })
          .height(34)
          .listDirection(Axis.Horizontal)
          .scrollBarWidth(0)

          if (this.showAnimate_flax) {
            Image(this.showAnimate ? $r('app.media.audioanimate1') : $r('app.media.audioanimate2'))
              .width('100%')
              .height(40)
              .margin({ bottom: 12 })
          }
        }
        .align(Alignment.Bottom)

        if (this.inputCapable) {
          Column() {
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
              Image($r('app.media.delete_ai'))
                .width(24)
                .margin({ left: 8, right: 8 })
                .onClick(() => {
                  this.inputText = ''
                })
              Image($r('app.media.textShow_ai'))
                .width(24)
                .onClick(() => {
                  this.inputText = ''
                  this.inputCapable = false
                })
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
                  console.warn(JSON.stringify(event.type))
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
            Text('给 AI 发送消息')
              .layoutWeight(1)
              .fontWeight(CommonConfig.fontWeight_400)
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor)
              .backgroundColor(Color.White)
              .onClick(() => {
                this.inputCapable = true
              })
            Image($r('app.media.audio'))
              .width(32)
              .margin({ right: 8 })
              .onDragStart((event: DragEvent) => {
                // 关键代码：返回DRAG_CANCELED阻止拖出
                event.setResult(DragResult.DRAG_CANCELED);
              })
              .onTouch((event) => {
                console.warn(JSON.stringify(event.type))
                if (event.type === TouchType.Down) { // 按下时改变状态
                  if (!this.showAnimate_flax) {
                    this.downAnimate = setInterval(() => {
                      this.showAnimate = !this.showAnimate;
                    }, 180)
                  }
                  this.showAnimate_flax = true
                } else if (event.type === TouchType.Up) {
                  this.showAnimate_flax = false
                  clearInterval(this.downAnimate)
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