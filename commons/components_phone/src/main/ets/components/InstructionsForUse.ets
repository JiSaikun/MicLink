import { DeviceArrayType_Ble } from "bluetooth"
import { UserLoginInfo } from "common"
import { getModelInfoModel } from "config"
import { ConnectDevice } from "mouse"
import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"
import { TopTitle } from "../common/TopTitle"
import { Languages_params } from "../view/SmartSettings"

@Builder
export function InstructionsForUseBuilder() {
  InstructionsForUse()
}

@Component
struct InstructionsForUse {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @Consume('pageInfo') pageInfo: NavPathStack
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State search: string = ''
  @State currTitleIndex: number = 0
  @State userLoginInfo: UserLoginInfo = AppStorage.get('userLoginInfo') as UserLoginInfo

  // 原始常见问题数据
  private originalCommonQuestions: string[] = ['问题的标题', '问题的标题', '问题的标题', '问题的标题']
  // 原始使用手册数据
  private originalManuals: string[] = [
    'M20 使用手册', 'D8 使用手册', 'M191 使用手册', 'M131 使用手册',
    'M20 使用手册', 'D8 使用手册', 'M191 使用手册', 'M131 使用手册',
    'M20 使用手册', 'D8 使用手册', 'D8 使用手册', 'D8 使用手册', 'D8 使用手册'
  ]

  // 获取过滤后的常见问题
  private getFilteredCommonQuestions(): string[] {
    if (this.search === '') {
      return this.originalCommonQuestions
    }
    return this.originalCommonQuestions.filter(item => item.includes(this.search))
  }

  // 获取过滤后的使用手册
  private getFilteredManuals(): string[] {
    if (this.search === '') {
      return this.originalManuals
    }
    return this.originalManuals.filter(item => item.includes(this.search))
  }

  build() {
    NavDestination() {
      Column() {
        // TopTitle({ title: Languages.editProfile[this.languages] })
        TopTitle({ title: "" })
          .margin({ bottom: 24 })
        Text('Hi，'+`${this.userLoginInfo ? this.userLoginInfo.name : '用户123456'}`)
          .fontWeight(CommonConfig.fontWeight_400)
          .fontColor(CommonConfig.hintTextColor_select)
          .fontSize(CommonConfig.fontSize_24)

        Row() {
          Image($r('app.media.search'))
            .width(24)
            .margin({ right: 8 })
          TextInput({ placeholder: '搜索问题', text: $$this.search })
            .placeholderColor(CommonConfig.hintTextColor)
            .fontSize(CommonConfig.fontSize_14)
            .fontWeight(400)
            .layoutWeight(1)
            .padding(0)
            .backgroundColor(Color.White)
            .borderRadius(0)
            .onChange((value: string) => {
              this.search = value
            })
        }
        .width('100%')
        .backgroundColor(Color.White)
        .alignItems(VerticalAlign.Center)
        .padding({
          left: 12,
          top: 8,
          bottom: 8,
          right: 12
        })
        .borderRadius(12)
        .margin({ top: 24, bottom: 12 })


        Column() {
          Row() {
            Column() {
              Text('常见问题')
                .fontWeight(CommonConfig.fontWeight_400)
                .fontSize(CommonConfig.fontSize_14)
                .fontColor(this.currTitleIndex === 0 ? this.paletteTheme : CommonConfig.hintTextColor_select)
                .onClick(() => {
                  this.currTitleIndex = 0
                })
              Divider()
                .width(24)
                .strokeWidth(24)
                .height(2)
                .backgroundColor(this.paletteTheme)
                .visibility(this.currTitleIndex === 0 ? Visibility.Visible : Visibility.None)
                .margin({ top: 2 })
            }
            .margin({ right: 16 })

            Column() {
              Text('使用手册')
                .fontWeight(CommonConfig.fontWeight_400)
                .fontSize(CommonConfig.fontSize_14)
                .fontColor(this.currTitleIndex === 1 ? this.paletteTheme : CommonConfig.hintTextColor_select)
                .onClick(() => {
                  this.currTitleIndex = 1
                })
              Divider()
                .width(24)
                .strokeWidth(24)
                .height(2)
                .backgroundColor(this.paletteTheme)
                .margin({ top: 2 })
                .visibility(this.currTitleIndex === 1 ? Visibility.Visible : Visibility.None)
            }
            .margin({ right: 16 })

          }
          .padding(12)
          .width('100%')

          Scroll() {
            Column() {
              if (this.currTitleIndex === 0) {
                ForEach(this.getFilteredCommonQuestions(), (item: string, index) => {
                  Row() {
                    Text(item)
                      .fontColor(CommonConfig.hintTextColor_select)
                      .fontSize(CommonConfig.fontSize_14)
                      .fontWeight(CommonConfig.fontWeight_400)
                    Blank()
                    Image($r('app.media.Arrow_to_the_right'))
                      .width(16)
                      .height(16)
                  }
                  .width('100%')
                  .padding({ top: 12, bottom: 12 })
                  .border({
                    width: {
                      bottom: index === this.getFilteredCommonQuestions().length - 1 ? 0 : 1
                    },
                    color: CommonConfig.commonBackgroundColor
                  })
                  .onClick(() => {

                  })
                })
              } else {
                ForEach(this.getFilteredManuals(), (item: string, index) => {
                  Row() {
                    Text(item)
                      .fontColor(CommonConfig.hintTextColor_select)
                      .fontSize(CommonConfig.fontSize_14)
                      .fontWeight(CommonConfig.fontWeight_400)
                    Blank()
                    Image($r('app.media.Arrow_to_the_right'))
                      .width(16)
                      .height(16)
                  }
                  .width('100%')
                  .padding({ top: 12, bottom: 12 })
                  .border({
                    width: {
                      bottom: index === this.getFilteredManuals().length - 1 ? 0 : 1
                    },
                    color: CommonConfig.commonBackgroundColor
                  })
                  .onClick(() => {

                  })
                })
              }
            }
            .padding({ right: 12 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .align(Alignment.TopStart)
          // .edgeEffect(EdgeEffect.Spring)
          .scrollBarWidth(2)
          .edgeEffect(EdgeEffect.Spring)
          .padding({ left: 12 })

        }
        .borderRadius(12)
        .backgroundColor(Color.White)
        .layoutWeight(1)
      }
      .alignItems(HorizontalAlign.Start)
    }
    .padding({ left: 16, right: 16, bottom: 16 })
    .backgroundColor(CommonConfig.commonBackgroundColor)
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}