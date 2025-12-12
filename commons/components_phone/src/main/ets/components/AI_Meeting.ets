import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"
import { TopTitle } from "../common/TopTitle"
import { LengthMetrics, promptAction } from "@kit.ArkUI"
import { AudioPlayerEvents, AudioRecorderManager, OnlineAudioPlayer, PlaybackState } from "api"
import { common } from "@kit.AbilityKit"
import { audio } from "@kit.AudioKit"


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

  // 添加播放器相关状态
  private audioPlayer: OnlineAudioPlayer | null = null
  @State private currentAudioUrl: string = ''
  @State private isPlayingBack: boolean = false // 是否正在播放音频

  // 设置播放器事件监听
  private setupAudioPlayerEvents(): AudioPlayerEvents {
    return {
      onStateChange: (state: PlaybackState) => {
        console.info(`播放器状态变化: ${state}`)
        this.handlePlayerStateChange(state)
      },
      onProgress: (currentOffset: number, totalSize: number) => {
        // 更新播放时间显示
        if (totalSize > 0) {
          const totalSeconds = this.audioPlayer?.getDuration() || 0
          const progressPercent = (currentOffset / totalSize) * 100
          this.audioTime = Math.floor((progressPercent / 100) * totalSeconds)
          this.updateTimeText()
        }
      },
      onError: (error) => {
        console.error(`播放器错误: ${error}`)
        promptAction.showToast({
          message: `播放失败: ${error}`,
          duration: 3000
        })
      },
      onPlaybackEnd: () => {
        console.info('播放完成')
        this.isPlayingBack = false
        this.isPause = true // 播放结束后，按钮显示播放图标
        // 重置播放时间
        this.audioTime = 0
        this.updateTimeText()
      }
    }
  }

  // 处理播放器状态变化
  private handlePlayerStateChange(state: PlaybackState): void {
    switch (state) {
      case PlaybackState.PLAYING:
        this.isPlayingBack = true
        break
      case PlaybackState.PAUSED:
      case PlaybackState.STOPPED:
        this.isPlayingBack = false
        break
    }
  }

  // 初始化音频播放器
  private async initAudioPlayer(audioUrl: string): Promise<boolean> {
    try {
      // 如果已有播放器实例，先释放
      if (this.audioPlayer) {
        await this.audioPlayer.release()
        this.audioPlayer = null
      }

      // 创建新的播放器实例
      this.audioPlayer = new OnlineAudioPlayer(
        {
          url: audioUrl,
          samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
          channels: audio.AudioChannel.CHANNEL_1,
          sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
          encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW,
          usage: audio.StreamUsage.STREAM_USAGE_MUSIC
        },
        this.setupAudioPlayerEvents()
      )

      // 加载音频
      const loadSuccess = await this.audioPlayer.load()
      if (!loadSuccess) {
        promptAction.showToast({
          message: '音频加载失败',
          duration: 3000
        })
        return false
      }

      console.info(`音频播放器初始化成功，URL: ${audioUrl}`)
      return true
    } catch (error) {
      console.error(`初始化播放器失败: ${error}`)
      promptAction.showToast({
        message: '播放器初始化失败',
        duration: 3000
      })
      return false
    }
  }

  // 开始播放
  private async startPlayback(): Promise<void> {
    if (!this.audioPlayer) {
      console.error('播放器未初始化')
      return
    }

    const playSuccess = await this.audioPlayer.play()
    if (playSuccess) {
      console.info('开始播放录音')
      this.isPause = false // 播放时，按钮显示暂停图标
    } else {
      console.error('播放失败')
      promptAction.showToast({
        message: '播放失败，请重试',
        duration: 3000
      })
    }
  }

  // 暂停播放
  private async pausePlayback(): Promise<void> {
    if (!this.audioPlayer) {
      console.error('播放器未初始化')
      return
    }

    const pauseSuccess = await this.audioPlayer.pause()
    if (pauseSuccess) {
      console.info('播放已暂停')
      this.isPause = true // 暂停时，按钮显示播放图标
    }
  }

  // 释放播放器资源
  private async releasePlayer(): Promise<void> {
    if (this.audioPlayer) {
      await this.audioPlayer.release()
      this.audioPlayer = null
      console.info('播放器资源已释放')
    }
  }

  addTime() {
    // 将audioTime（秒）转换为时间格式 MM:SS
    const minutes = Math.floor(this.audioTime / 60);
    const seconds = this.audioTime % 60;

    // 格式化为两位数：01:05 而不是 1:5
    this.audioTimeText = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  }

  // 更新时间显示文本
  private updateTimeText(): void {
    const minutes = Math.floor(this.audioTime / 60)
    const seconds = this.audioTime % 60
    this.audioTimeText = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
  }

  // 组件即将消失时释放资源
  aboutToDisappear() {
    // 清除定时器
    if (this.audioInterval) {
      clearInterval(this.audioInterval)
    }

    // 释放播放器资源
    this.releasePlayer()

    // 如果正在录音，停止录音
    if (this.isPlayAudio && !this.isEnd) {
      this.audioRecorderManager.stopRecording()
    }
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
                this.isEnd = false
                this.isSave = false
                this.audioTime = 0
                this.updateTimeText()

                // 开始计时
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
                  } else {//已经结束状态下，播放
                    this.isPause = !this.isPause
                    /**
                     * 暂时先将语音地址固定死,后面传具体的
                     */
                    /**
                     * 判断当前是否处于暂停状态
                     */
                    if (this.isPause) { //暂停
                      console.log('暂停')
                      // 执行语音播放暂停操作
                      this.pausePlayback()
                    } else { //恢复
                      console.log('恢复')
                      // 执行语音播放暂停后的继续播放操作操作、或最开始的播放操作
                      // 如果还没有初始化播放器，先初始化
                      if (!this.audioPlayer && this.currentAudioUrl) {
                        this.initAudioPlayer(this.currentAudioUrl).then((success) => {
                          if (success) {
                            this.startPlayback()
                          }
                        })
                      } else if (this.audioPlayer) {
                        // 如果播放器已经初始化，直接播放
                        this.startPlayback()
                      }

                      // this.audioTime ：显示当前播放了多少秒
                      //语音数据整体播放完毕后  this.isPause = false
                      // 这会在onPlaybackEnd回调中自动处理
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
                .onClick(async () => {
                  if (!this.isEnd) {
                    // 结束录音并上传
                    try {
                      const result = await this.audioRecorderManager.stopAndUploadRecording()
                      console.log('录音上传结果:', JSON.stringify(result))

                      // 假设result中包含音频URL，这里需要根据实际API调整
                      if (result) {
                        // TODO: 根据实际API返回的URL调整
                        this.currentAudioUrl = result.data
                        // 初始化音频播放器
                        await this.initAudioPlayer(this.currentAudioUrl)
                      }


                      // 更新状态
                      this.isPause = true // 初始为暂停状态
                      this.isEnd = true
                      clearInterval(this.audioInterval)

                      promptAction.showToast({
                        message: '录音已保存',
                        duration: 2000
                      })
                    } catch (error) {
                      console.error('停止录音失败:', error)
                      promptAction.showToast({
                        message: '录音保存失败',
                        duration: 3000
                      })
                    }
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
                          this.isPlayAudio = true
                          this.audioTime = 0
                          this.updateTimeText()

                          // 释放播放器资源
                          this.releasePlayer()

                          // 开始计时
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
                            promptAction.showToast({
                              message: '录音已保存',
                              duration: 2000
                            })
                            break
                          case 1:
                            // 开始新的录音
                            this.audioRecorderManager.startRecording().then((res) => {
                              if (res) {
                                this.isEnd = false
                                this.isPause = false
                                this.isPlayAudio = true
                                this.audioTime = 0
                                this.updateTimeText()

                                // 释放播放器资源
                                this.releasePlayer()

                                // 开始计时
                                this.audioInterval = setInterval(() => {
                                  this.audioTime += 1
                                }, 1000)
                              }
                            })
                            break
                          case 2:
                            // 取消，不执行任何操作
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