import { PopViewUtils, LaunchLogin_pop, PopParams_1 } from 'utils'
import CommonConstants from '../common/CommonConstants'
import { CommonConstants_pop } from "config"
import { App, SymbolGlyphModifier } from '@kit.ArkUI';
/**
 * AI指令本地存储
 */
PersistentStorage.persistProp("table_data", [])

@Styles
function flexGS() {
  .flexGrow(1)
  .flexShrink(1)
}

@Extend(Text)
function style1() {
  .flexGrow(5)
  .flexShrink(5)
  .width(1)
  .fontWeight(CommonConstants.COMMAND_TITLE_FONT_WEIGHT)
  .fontSize(CommonConstants.COMMAND_DEFAULT_FONT_SIZE)
}

interface videoModel {
  image: string,
  title: string
}

export interface tableDataModel {
  category: string, //指令类别
  voice: string, //语音指令
  execute: string, //执行目标
}

@Component
export default struct Command_Ai {
  @State video_data: videoModel[] = [
    {
      image: 'video_Command_Ai', title: '创建某某视频教学'
    }, {
    image: 'video_Command_Ai', title: '创建某某视频教学1'
  }, {
    image: 'video_Command_Ai', title: '创建某某视频教学2'
  }, {
    image: 'video_Command_Ai', title: '创建某某视频教学3'
  }, {
    image: 'video_Command_Ai', title: '创建某某视频教学4'
  }, {
    image: 'video_Command_Ai', title: '创建某某视频教学5'
  }, {
    image: 'video_Command_Ai', title: '创建某某视频教学6'
  }, {
    image: 'video_Command_Ai', title: '创建某某视频教学7'
  }, {
    image: 'video_Command_Ai', title: '创建某某视频教学8'
  }, {
    image: 'video_Command_Ai', title: '创建某某视频教学'
  }
  ] //模拟数据
  @StorageLink('table_data') table_data: tableDataModel[] = [
    {
      category: '文件',
      voice: '自定义触发文字',
      execute: '目标路径',
    }, {
    category: '文件夹',
    voice: '自定义触发文字',
    execute: '目标路径',
  }, {
    category: '网站',
    voice: '自定义触发文字',
    execute: '目标网址',
  }, {
    category: '固定文本',
    voice: '自定义触发文字',
    execute: '设定的文本',
  }, {
    category: '文件2',
    voice: '自定义触发文字',
    execute: '目标路径',
  }, {
    category: '文件3',
    voice: '自定义触发文字',
    execute: '目标路径',
  }, {
    category: '文件4',
    voice: '自定义触发文字',
    execute: '目标路径',
  }, {
    category: '文件5',
    voice: '自定义触发文字',
    execute: '目标路径',
  },
  ] //模拟数据
  @Link isShow_CreateNewInstruction_pop: boolean
  @Link isShow_EditInstruction_pop: boolean
  @Link EditInstruction_pop_currIndex: number

  //弹窗函数
  down() {
    PopViewUtils.closePopView()
  }

  // 修改后（使用箭头函数自动绑定 this）
  confirm = () => {
    // 确定回调
    PopViewUtils.closePopView();
    this.table_data.splice(this.EditInstruction_pop_currIndex, 1)

  }

  build() {
    Flex({ direction: FlexDirection.Column }) {
      Flex() {
        Text('AI-指令')
          .flexGS()
          .fontColor(CommonConstants.COMMAND_DEFAULT_FONT_COLOR)
          .fontSize(CommonConstants.COMMAND_TITLE_FONT_SIZE)
          .fontWeight(CommonConstants.COMMAND_TITLE_FONT_WEIGHT)
        Column()
          .layoutWeight(1)
          .flexGS()
        Row() {
          Image($r('app.media.create_Command_Ai'))
            .width(CommonConstants.COMMAND_ICON_DEFAULT_WEIGHT)
            .height(CommonConstants.COMMAND_ICON_DEFAULT_HEIGHT)
            .margin({ right: 6 })
          Text('创建新的指令')
            .fontSize(14)
            .fontWeight(400)
            .fontColor(Color.White)
        }
        .backgroundColor(CommonConstants.COMMAND_SECOND_FONT_COLOR)
        .width(135)
        .height(40)
        .borderRadius(8)
        .padding(12)
        .flexGS()
        .onClick(() => {
          this.isShow_CreateNewInstruction_pop = true
        })
      }
      .width('100%')
      .height(40)
      .margin({ bottom: 10 })
      .flexGS()

      Flex() {
        List() {
          ForEach(this.video_data, (item: videoModel) => {
            ListItem() {
              Column() {
                Image($r(`app.media.${item.image}`)).width(154).height(100).borderRadius(8)
                Text(item.title)
                  .fontSize(14)
                  .fontWeight(CommonConstants.COMMAND_TITLE_FONT_WEIGHT)
                  .fontColor(CommonConstants.COMMAND_DEFAULT_FONT_COLOR)
              }
              .alignItems(HorizontalAlign.Start)
              .justifyContent(FlexAlign.SpaceBetween)
              .padding(8)
              .height('100%')
              .width(170)
            }
          }, (item: videoModel) => item.title)
        }
        .width('100%')
        .listDirection(Axis.Horizontal)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height(138)
      .flexGS()
      .margin({ bottom: 10 })

      Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
        Text('指令类别')
          .style1()
        Text('语音指令')
          .style1()
        Text('执行目标')
          .style1()
        Text('操作')
          .style1()
          .flexGrow(2)
          .flexShrink(2)
      }
      .backgroundColor('#f7f9fa')
      .height(40)
      .padding({ left: 16, right: 16 })
      .flexGS()

      List() {
        ForEach(this.table_data, (item: tableDataModel, index: number) => {
          ListItem() {
            Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
              Text(item.category)
                .style1()
                .fontWeight(400)
              Text(item.voice)
                .style1()
                .fontWeight(400)
              Text(item.execute)
                .style1()
                .fontWeight(400)
              Row() {
                Text('编辑')
                  .fontColor(CommonConstants.COMMAND_SECOND_FONT_COLOR)
                  .margin({ right: 10 })
                  .fontWeight(CommonConstants.COMMAND_ICON_DEFAULT_WEIGHT)
                  .onClick(() => {
                    // console.log('=================================::::', index)
                    this.EditInstruction_pop_currIndex = index
                    this.isShow_EditInstruction_pop = true
                  })
                Text('删除')
                  .fontWeight(CommonConstants.COMMAND_ICON_DEFAULT_WEIGHT)
                  .fontColor(CommonConstants.COMMAND_SECOND_FONT_COLOR)
                  .onClick(() => {
                    this.EditInstruction_pop_currIndex = index
                    const params_1: PopParams_1 = {
                      content: '确定要删除吗?',
                      down: this.down,
                      confirm: this.confirm
                    }
                    PopViewUtils.showPopView<PopParams_1>(wrapBuilder(LaunchLogin_pop), params_1,
                      { alignment: DialogAlignment.Center });
                  })
              }
              .height(40)
              .width(1)
              .justifyContent(FlexAlign.Start)
              .alignItems(VerticalAlign.Center)
              .flexGrow(2)
              .flexShrink(2)
            }
            .height('20%')
            .padding({ left: 16, right: 16 })
            .border({ width: { bottom: 1 }, color: '#e6e8eb' })
          }
        }, (item: tableDataModel) => item.category)

      }
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .height(200)
      .flexGS()


      Column()
        .layoutWeight(1)
        .flexGS()
    }
    .padding({
      left: 24,
      top: 90,
      right: 24,
      bottom: 24
    })
    .width('100%')
    .backgroundColor(Color.Transparent)
    .height('100%')
  }
}

