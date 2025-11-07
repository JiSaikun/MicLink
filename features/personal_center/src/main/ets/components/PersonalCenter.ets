import { ThemeConfig, UserLoginInfo } from 'common'
import { Languages } from 'config'
import { LengthMetrics } from '@kit.ArkUI'
import { RechargeRecord } from './RechargeRecord '
import { MemberCenter } from './MemberCenter '
import { Settings } from './Settings'
import { Rename_pop } from './Rename_pop'

@Builder
export function PersonalCenterBuilder() {
  PersonalCenter()
}

@Component
export struct PersonalCenter {
  @StorageLink("paletteTheme") paletteTheme: string = ThemeConfig.PaletteTheme
  @State userLoginInfo: UserLoginInfo = AppStorage.get('userLoginInfo') as UserLoginInfo
  @StorageLink('languages') @Watch('onLanguageChange') languages: string = 'ZH_CN'
  @Consume('pageInfo') pageInfo: NavPathStack
  @State tabBarList: string[] = []
  @State curr_Index: number = 0
  @State isShow_Rename_pop: boolean = false

  aboutToAppear(): void {
    this.updateTabBarList()
  }

  // 监听语言变化
  onLanguageChange(): void {
    this.updateTabBarList()
  }

  // 更新标签栏列表
  updateTabBarList(): void {
    this.tabBarList = [
      Languages.settings[this.languages],
      Languages.memberCenter[this.languages],
      Languages.rechargeRecords[this.languages]
    ]
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          Row() {
            Row() {
              Text(Languages.profile[this.languages])
                .fontWeight(ThemeConfig.TextWeight_500)
                .fontSize(ThemeConfig.TextSize_18)
                .fontColor(ThemeConfig.TextBodyColor)
              Blank()
              Image($r('app.media.Frame_12'))
                .width(44)
                .height(44)
                .onClick(() => {
                  this.pageInfo.pop()
                })
            }
            .width('100%')
            .height(66).border({ width: { bottom: 1 }, color: '#f8f8f8' })
          }.padding({ left: 24, right: 24 })


          Scroll() {
            Flex({ direction: FlexDirection.Column, space: { main: LengthMetrics.px(24) } }) {
              Row() {
                Image($r('app.media.avatar'))
                  .width(80)
                  .borderRadius('50%')
                  .margin({ right: 24 })
                  .padding({ right: 8 })
                Column() {
                  Row() {
                    Column() {
                      Row() {
                        Text(this.userLoginInfo ? this.userLoginInfo.name : '用户名称') //用户名称
                          .fontSize(ThemeConfig.TextSize_14)
                          .fontColor(ThemeConfig.TextBodyColor)
                          .fontWeight(ThemeConfig.TextWeight_400)
                          .margin({ right: 20 })
                        Text(Languages.edit[this.languages])//编辑
                          .fontColor(this.paletteTheme)
                          .fontSize(ThemeConfig.TextSize_14)
                          .fontWeight(ThemeConfig.TextWeight_400)
                          .onClick(() => {
                            this.isShow_Rename_pop = true
                          })
                      }
                      .margin({ bottom: 15 })

                      Row() {
                        Text(Languages.accountId[this.languages] + '：') //账户ID：
                          .fontSize(ThemeConfig.TextSize_12)
                          .fontColor(ThemeConfig.SecondaryTextColor)
                          .fontWeight(ThemeConfig.TextWeight_400)
                          .margin({ right: 20 })
                        Text(this.userLoginInfo ? this.userLoginInfo.id.toString() : '123456789')
                          .fontColor(ThemeConfig.TextBodyColor)
                          .fontSize(ThemeConfig.TextSize_12)
                          .fontWeight(ThemeConfig.TextWeight_400)
                      }

                    }
                    .alignItems(HorizontalAlign.Start)

                    Column() {
                      Row() {
                        Image($r('app.media.MembershipTier_1'))
                          .width(16)

                        Row() {
                          Text('V1')
                            .fontWeight(ThemeConfig.TextWeight_500)
                            .fontSize(ThemeConfig.TextSize_18)
                            .padding({ left: 10 })
                            .blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
                        }
                        .linearGradient({
                          direction: GradientDirection.Right,
                          colors: [[0xEFC15D, 0.0], [0xFFEABB, 1.0]] // 渐变颜色，可自定义
                        })
                        .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)
                      }
                      .margin({ bottom: 10 })

                      Text(Languages.memberLevel[this.languages])
                        .fontSize(ThemeConfig.TextSize_12)
                        .fontWeight(ThemeConfig.TextWeight_400)
                        .fontColor(ThemeConfig.SecondaryTextColor)
                    }
                    .padding({ right: 24 })
                    .height(80)
                    .alignItems(HorizontalAlign.End)
                    .layoutWeight(1)
                    .justifyContent(FlexAlign.Center)
                  }
                  .width('100%')
                  .height(80)

                  Row()
                    .width('100%')
                    .border({ width: { bottom: 1 }, color: '#eaeaea' })
                    .margin({ top: 10, bottom: 24 })
                  Column() {
                    Row() {
                      Image($r('app.media.MembershipTier_0'))
                        .width(16)
                      Text('V0')
                        .fontWeight(ThemeConfig.TextWeight_500)
                        .fontSize(ThemeConfig.TextSize_12)
                        .fontColor(ThemeConfig.SecondaryTextColor) // 文字颜色设为透明
                        .padding({ left: 5 })
                      Progress({ value: 50 })
                        .color(
                          '#f6d388'
                        )
                        .width(188)
                        .height(4)
                        .margin({ left: 10, right: 10 })
                      Image($r('app.media.MembershipTier_1'))
                        .width(16)
                      Row() {
                        Text('V1')
                          .fontWeight(ThemeConfig.TextWeight_500)
                          .fontSize(ThemeConfig.TextSize_12)
                          .fontColor(ThemeConfig.SecondaryTextColor) // 文字颜色设为透明
                          .padding({ left: 5 })
                          .blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
                      }
                      .linearGradient({
                        direction: GradientDirection.Right,
                        colors: [[0xEFC15D, 0.0], [0xFFEABB, 1.0]] // 渐变颜色，可自定义
                      })
                      .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)
                    }
                    .alignItems(VerticalAlign.Center)

                    Text(Languages.remainingToUpgrade[this.languages] + '50￥')
                      .fontWeight(ThemeConfig.TextWeight_400)
                      .fontSize(ThemeConfig.TextSize_12)
                      .fontColor(ThemeConfig.SecondaryTextColor)
                      .padding({ top: 8 })
                  }
                  .alignItems(HorizontalAlign.Center)

                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .alignItems(VerticalAlign.Top)
              .shadow({
                radius: 8,
                color: '#525A6614',
                offsetX: 2,
                offsetY: 2
              })
              .borderRadius(16)
              .width('100%')
              .margin({ top: 16 })
              .padding(24)

              Row() {
                ForEach(this.tabBarList, (item: string, index) => {
                  Text(item)
                    .padding({
                      left: 16,
                      top: 12,
                      right: 16,
                      bottom: 12
                    })
                    .borderRadius(4)
                    .onClick(() => {
                      this.curr_Index = index
                    })
                    .backgroundColor(this.curr_Index === index ? '#fff' : "#f8f8f8")
                }, (item: string) => item)
              }
              .padding(4)
              .backgroundColor('#f8f8f8')
              .borderRadius(8)

              if (this.curr_Index === 0) {
                Settings()
              }
              if (this.curr_Index === 1) {
                MemberCenter()
              }
              if (this.curr_Index === 2) {
                RechargeRecord()
              }
            }
            .padding({ left: 24, right: 24 })
            .width('100%')
          }
          .width('100%')
          .layoutWeight(1)
          .align(Alignment.TopStart)

          Row() {
            Text(Languages.softwareVersion[this.languages] + '：' + 'V2.7.17')
              .fontSize(ThemeConfig.TextSize_14)
              .fontColor(ThemeConfig.TextBodyColor)
              .fontWeight(ThemeConfig.TextWeight_400)
              .width('100%')
              .textAlign(TextAlign.Start)
              .padding({
                left: 16,
                top: 12,
                right: 16,
                bottom: 12
              })
              .border({ width: { top: 1 }, color: '#f8f8f8' })
          }.padding({ left: 24, right: 24 })

        }

        if (this.isShow_Rename_pop && this.userLoginInfo?.token) {
          Rename_pop({ isShow_Rename_pop: this.isShow_Rename_pop, token: this.userLoginInfo.token })
        }
      }
      .width('100%')
      .align(Alignment.TopStart)

    }
    .hideTitleBar(true)
    .hideToolBar(true)
    .title('个人中心')
  }
}