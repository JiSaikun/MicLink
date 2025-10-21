import { PopViewUtils, LaunchLogin_pop, PopParams_1 } from 'utils'
import CommonConstants from '../common/CommonConstants'
import { CommonConstants_pop, Languages } from "config" // 导入Languages
import { App, SymbolGlyphModifier } from '@kit.ArkUI';

// 新增：获取当前语言（与之前ConfigPage1组件保持一致）

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
  // 新增：当前语言状态
  @StorageLink('languages') languages: string = 'ZH_CN'
  // 模拟视频数据：替换中文标题为多语言
  @State video_data: videoModel[] = [
    { image: 'video_Command_Ai', title: Languages.create_certain_video_tutorial[this.languages] },
    { image: 'video_Command_Ai', title: `${Languages.create_certain_video_tutorial[this.languages]}1` },
    { image: 'video_Command_Ai', title: `${Languages.create_certain_video_tutorial[this.languages]}2` },
    { image: 'video_Command_Ai', title: `${Languages.create_certain_video_tutorial[this.languages]}3` },
    { image: 'video_Command_Ai', title: `${Languages.create_certain_video_tutorial[this.languages]}4` },
    { image: 'video_Command_Ai', title: `${Languages.create_certain_video_tutorial[this.languages]}5` },
    { image: 'video_Command_Ai', title: `${Languages.create_certain_video_tutorial[this.languages]}6` },
    { image: 'video_Command_Ai', title: `${Languages.create_certain_video_tutorial[this.languages]}7` },
    { image: 'video_Command_Ai', title: `${Languages.create_certain_video_tutorial[this.languages]}8` },
    { image: 'video_Command_Ai', title: Languages.create_certain_video_tutorial[this.languages] }
  ]
  // 模拟表格数据：替换中文为多语言
  @StorageLink('table_data') table_data: tableDataModel[] = [
    {
      category: Languages.file[this.languages],
      voice: Languages.custom_trigger_text[this.languages],
      execute: Languages.target_path[this.languages],
    }, {
    category: Languages.folder[this.languages],
    voice: Languages.custom_trigger_text[this.languages],
    execute: Languages.target_path[this.languages],
  }, {
    category: Languages.website[this.languages],
    voice: Languages.custom_trigger_text[this.languages],
    execute: Languages.target_url[this.languages],
  }, {
    category: Languages.fixed_text[this.languages],
    voice: Languages.custom_trigger_text[this.languages],
    execute: Languages.set_text[this.languages],
  }, {
    category: `${Languages.file[this.languages]}2`,
    voice: Languages.custom_trigger_text[this.languages],
    execute: Languages.target_path[this.languages],
  }, {
    category: `${Languages.file[this.languages]}3`,
    voice: Languages.custom_trigger_text[this.languages],
    execute: Languages.target_path[this.languages],
  }, {
    category: `${Languages.file[this.languages]}4`,
    voice: Languages.custom_trigger_text[this.languages],
    execute: Languages.target_path[this.languages],
  }, {
    category: `${Languages.file[this.languages]}5`,
    voice: Languages.custom_trigger_text[this.languages],
    execute: Languages.target_path[this.languages],
  },
  ]
  @Link isShow_CreateNewInstruction_pop: boolean
  @Link isShow_EditInstruction_pop: boolean
  @Link EditInstruction_pop_currIndex: number

  //弹窗函数
  down() {
    PopViewUtils.closePopView()
  }

  // 修改后（使用箭头函数自动绑定 this）
  confirm = () => {
    PopViewUtils.closePopView();
    this.table_data.splice(this.EditInstruction_pop_currIndex, 1)
  }

  build() {
    Flex({ direction: FlexDirection.Column }) {
      Flex() {
        // 替换：AI-指令
        Text(Languages.ai_command_page[this.languages])
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
          // 替换：创建新的指令
          Text(Languages.create_new_instruction[this.languages])
            .fontSize(14)
            .fontWeight(400)
            .fontColor(Color.White)
        }
        .backgroundColor(CommonConstants.COMMAND_SECOND_FONT_COLOR)
        .width(135)
        .borderRadius(8)
        .padding(12)
        .flexGS()
        .onClick(() => {
          this.isShow_CreateNewInstruction_pop = true
        })
      }
      .width('100%')
      .margin({ bottom: 10 })
      .flexGS()

      // 视频列表部分（已在数据中替换多语言，无需修改）
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

      // 表格表头：替换中文为多语言
      Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
        Text(Languages.instruction_category[this.languages])
          .style1()
        Text(Languages.voice_instruction[this.languages])
          .style1()
        Text(Languages.execution_target[this.languages])
          .style1()
        Text(Languages.operation[this.languages])
          .style1()
          .flexGrow(2)
          .flexShrink(2)
      }
      .backgroundColor('#f7f9fa')
      .height(40)
      .padding({ left: 16, right: 16 })
      .flexGS()

      // 表格内容（数据已替换多语言，操作列文本替换）
      List() {
        ForEach(this.table_data, (item: tableDataModel, index: number) => {
          ListItem() {
            Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
              Text(item.category)
                .style1()
                .fontWeight(400)
                //设置行数
                .maxLines(3)
                // 设置文本截取后用省略号占位
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(item.voice)
                .style1()
                .fontWeight(400)
                //设置行数
                .maxLines(3)
                // 设置文本截取后用省略号占位
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(item.execute)
              //设置行数
                .maxLines(3)
                // 设置文本截取后用省略号占位
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .style1()
                .fontWeight(400)
                .padding({ right: 15 })
              Row() {
                // 替换：编辑
                Text(Languages.edit[this.languages])
                  .fontColor(CommonConstants.COMMAND_SECOND_FONT_COLOR)
                  .margin({ right: 10 })
                  .fontWeight(CommonConstants.COMMAND_ICON_DEFAULT_WEIGHT)
                  .onClick(() => {
                    this.EditInstruction_pop_currIndex = index
                    this.isShow_EditInstruction_pop = true
                  })
                // 替换：删除
                Text(Languages.delete[this.languages])
                  .fontWeight(CommonConstants.COMMAND_ICON_DEFAULT_WEIGHT)
                  .fontColor(CommonConstants.COMMAND_SECOND_FONT_COLOR)
                  .onClick(() => {
                    this.EditInstruction_pop_currIndex = index
                    const params_1: PopParams_1 = {
                      // 替换：确定要删除吗?
                      content: Languages.confirm_delete[this.languages],
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
            .padding({
              left: 16,
              right: 16,
              top: 10,
              bottom: 10
            })
            .border({ width: { bottom: 1 }, color: '#e6e8eb' })
          }
        }, (item: tableDataModel) => item.category)
      }
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
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