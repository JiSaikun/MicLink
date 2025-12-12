import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"
import { TopTitle } from "../common/TopTitle"
import { LengthMetrics, promptAction } from "@kit.ArkUI"
import { AudioRecorderManager } from "api"
import { common } from "@kit.AbilityKit"

@Builder
export function AI_MeetingBuilder() {
  AI_Meeting()
}


@Component
struct AI_Meeting {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @Consume('pageInfo') pageInfo: NavPathStack
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State isPlayAudio: boolean = false //是否开始采集录音
  @State isPause: boolean = false //是否处于暂停状态
  @State isEnd: boolean = false //是否处于结束状态
  @State isSave: boolean = false //是否将录音采用保存
  @Watch('addTime') @State audioTime: number = 0 //采集时长记录
  @State audioInterval: number = 0 //音频采集时长定时器变化
  @State audioTimeText: string = '00:00' //采集时长显示文本
  @State audioRecorderManager: AudioRecorderManager =
    new AudioRecorderManager(this.getUIContext().getHostContext() as common.UIAbilityContext) //麦克风管理

  addTime() {
    // 将audioTime（秒）转换为时间格式 MM:SS
    const minutes = Math.floor(this.audioTime / 60);
    const seconds = this.audioTime % 60;

    // 格式化为两位数：01:05 而不是 1:5
    this.audioTimeText = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  }

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        TopTitle({ title: 'AI 会议', isback: false })
          .margin({ bottom: 12 })
        Column() {
          Image($r('app.media.Rectangle_522'))
            .width(200)
          Text('点击下方按钮记录会议吧~')
            .fontSize(CommonConfig.fontSize_14)
            .fontWeight(CommonConfig.fontWeight_400)
            .fontColor(CommonConfig.hintTextColor)
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .layoutWeight(1)

        if (!this.isPlayAudio) {
          Stack() {
            Row()
              .width(44)
              .height(44)
              .backgroundColor(CommonConfig.hintTextColor_select)
              .borderRadius(100)
            Image($r('app.media.Frame_2407'))
              .width(12)
              .onDragStart((event: DragEvent) => {
                // 关键代码：返回DRAG_CANCELED阻止拖出
                event.setResult(DragResult.DRAG_CANCELED);
              })
          }
          .onClick(() => {
            this.audioRecorderManager.startRecording().then((res) => {
              if (res) {
                this.isPlayAudio = true
                this.audioTime = 0
                this.audioInterval = setInterval(() => {
                  this.audioTime += 1
                }, 1000)
              }
            })

          })
          .margin({ top: 12 })
        } else {
          Row() {
            Image('')
              .width(56)
              .margin({ right: 8 })
            Row() {
              Text('·')
                .fontColor(Color.White)
                .fontSize(CommonConfig.fontSize_14)
                .fontWeight(CommonConfig.fontWeight_400)
                .width(24)
                .textAlign(TextAlign.Center)
              Text(this.audioTimeText)
                .fontColor(Color.White)
                .fontSize(CommonConfig.fontSize_14)
                .fontWeight(CommonConfig.fontWeight_400)
                .margin({ right: 10 })
              Image(this.isPause ? $r('app.media.Frame_2407') : $r('app.media.Pause'))
                .width(24)
                .padding(this.isPause ? 6 :0)
                .margin({ right: 10 })
                .onClick(() => {
                  if (!this.isEnd) { //非结束状态下
                    this.isPause = !this.isPause
                    if (this.isPause) { //暂停
                      console.log('暂停')
                      this.audioRecorderManager.pauseRecording().then((res) => {
                        console.log(JSON.stringify(res))
                        clearInterval(this.audioInterval)
                      })
                    } else { //恢复
                      console.log('恢复')
                      this.audioRecorderManager.resumeRecording().then((res) => {
                        console.log(JSON.stringify(res))
                        this.audioInterval = setInterval(() => {
                          this.audioTime += 1
                        }, 1000)
                      })
                    }
                  }
                })
                .onDragStart((event: DragEvent) => {
                  // 关键代码：返回DRAG_CANCELED阻止拖出
                  event.setResult(DragResult.DRAG_CANCELED);
                })
              Image(this.isEnd ? $r('app.media.newCreatAudio') : $r('app.media.end'))
                .width(24)
                .padding(this.isEnd ? 4 :0)
                .onClick(() => {
                  if (!this.isEnd) {
                    this.audioRecorderManager.stopAndUploadRecording().then((res) => {
                      this.isPause = true
                      this.isEnd = true
                      console.log(JSON.stringify(res))
                      clearInterval(this.audioInterval)
                    })
                  } else {
                    /**
                     * 判断录音是否已经保存过了
                     * 如果保存过了则直接开始新的录音
                     */
                    if (this.isSave) {
                      this.audioRecorderManager.startRecording().then((res) => {
                        if (res) {
                          this.isEnd = false
                          this.isPause = false
                          this.audioTime = 0
                          this.audioInterval = setInterval(() => {
                            this.audioTime += 1
                          }, 1000)
                        }
                      })
                    } else {
                      this.getUIContext().getPromptAction().showDialog({
                        title: ('录音确认'),
                        buttons: [{ text: '保存上一次录音', color: '#007DFF' },
                          { text: '开始新的录音', color: '#007DFF' }, { text: '取消', color: '#FF3B30' }]
                      }).then((res: promptAction.ShowDialogSuccessResponse) => {
                        switch (res.index) {
                          case 0: //保存录音
                            this.isSave = true
                            break
                          case 1:
                            this.audioRecorderManager.startRecording().then((res) => {
                              if (res) {
                                this.isPause = false
                                this.isEnd = false
                                this.audioTime = 0
                                this.audioInterval = setInterval(() => {
                                  this.audioTime += 1
                                }, 1000)
                              }
                            })
                            break
                        }
                      })
                    }

                  }

                })
                .onDragStart((event: DragEvent) => {
                  // 关键代码：返回DRAG_CANCELED阻止拖出
                  event.setResult(DragResult.DRAG_CANCELED);
                })

            }
            .alignItems(VerticalAlign.Center)
          }
          .backgroundColor(CommonConfig.hintTextColor_select)
          .borderRadius(100)
          .padding({
            top: 10,
            bottom: 10,
            left: 12,
            right: 12
          })
          .margin({ top: 12 })

        }

      }.height('100%')

    }
    .padding({ left: 16, right: 16 })
    .backgroundColor(CommonConfig.commonBackgroundColor)
    .backgroundImage($r('app.media.background_1'))
    .backgroundImageSize({ width: '100%', height: '100%' })
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}