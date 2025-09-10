import { CommonConstants_pop } from "config"
import CommonConstants from '../common/CommonConstants'
import {tableDataModel}from './Command_Ai'
interface response_interface{
  title:string
  isShow:boolean
  response_:string
}
@Component
export struct CreateNewInstruction_pop {
  @Consume('pageInfo') pageInfo: NavPathStack
  @State array: SelectOption[] = [{ value: '文件' }, { value: '网址' }, { value: '生成文本' }]
  @State response_: response_interface[] = [{title:'执行路径',isShow:true,response_:'执行路径'},{title:'网址',isShow:false,response_:'输入网址'},{title:'生成文本',isShow:false,response_:'输入要一键生成的文本'}]
  @State currentindex: number = 0
  @Link isShow_CreateNewInstruction_pop: boolean //创建指令弹窗
  @Link isShow_EditInstruction_pop:boolean //编辑指令弹窗
  @StorageLink('table_data') table_data:tableDataModel[]=[]
  @Prop isParam:boolean=false
  @Prop currIndexParam:number
  @State currtableDataModel_data:tableDataModel={
    category: '文件', //指令类别
    voice: '', //语音指令
    execute: '', //执行目标
  }
  aboutToAppear(): void {
    if (this.isParam) {
      // console.log(this.currIndexParam.toString(),'---------------------------------------------------')
      // console.log(JSON.stringify(this.table_data))
      this.currtableDataModel_data=this.table_data[this.currIndexParam]
    }
  }
  build() {
    Stack() {
      Column() {

      }
      .width('100%')
      .height('100%')
      .backgroundColor('#000')
      .opacity(0.2)

      Column() {
        Row() {
          Text('AI 指令')
            .fontWeight(CommonConstants_pop.login_dafault_text_font_weight)
            .fontSize(CommonConstants_pop.login_dafault_text_font_size)
            .fontColor(CommonConstants_pop.login_dafault_text_font_color)
          Blank()
          Image($r('app.media.pop_down'))
            .height(44)
            .width(44)
            .onClick(() => {
              this.isShow_CreateNewInstruction_pop = false
              this.isShow_EditInstruction_pop = false
            })
        }
        .width($r('app.float.pop_launch_column_width'))
        .padding($r('app.float.pop_launch_column_default_padd'))
        .height(64)

        Column() {
          Row() {
            Text('功能：')
              .fontSize(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_SIZE)
              .fontColor(CommonConstants.COMMAND_DEFAULT_FONT_COLOR)
              .fontWeight(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_WEIGHT)
            Select(this.array)
              .selected(0)
              .width(410)
              .value(this.isParam?this.currtableDataModel_data.category:'文件')
              .height(32)
              .font({
                weight: CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_WEIGHT,
                size: CommonConstants.COMMAND_DEFAULT_FONT_SIZE
              })
              .fontColor(CommonConstants.COMMAND_DEFAULT_FONT_COLOR)
              .borderRadius(4)
              .border({ width: 1, color: '#eaeaEa' })
              .backgroundColor(Color.White)
              .onSelect((index, value) => {
                console.log(index.toString(), value)
                this.currentindex = index
                this.currtableDataModel_data.category = value
              })

          }

          Row() {
            Text('指令词：')
              .fontSize(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_SIZE)
              .fontColor(CommonConstants.COMMAND_DEFAULT_FONT_COLOR)
              .fontWeight(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_WEIGHT)

            TextInput({ placeholder: '输入触发文字',text:$$this.currtableDataModel_data.voice })
              .placeholderColor('#bbbdbf')
              .borderRadius(0)
              .backgroundColor('#fff')
              .padding({ left: 15 })
              .fontSize(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_SIZE)
              .fontColor(CommonConstants.COMMAND_DEFAULT_FONT_COLOR)
              .fontWeight(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_WEIGHT)
              .width(410)
              .height(32)
              .borderRadius(4)
              .border({ width: 1, color: '#eaeaEa' })
          }
          .margin({ top: 15, bottom: 15 })

          Row() {
            Text(this.response_[this.currentindex].title)
              .fontSize(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_SIZE)
              .fontColor(CommonConstants.COMMAND_DEFAULT_FONT_COLOR)
              .fontWeight(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_WEIGHT)
            Row() {
              TextInput({placeholder:this.response_[this.currentindex].response_,text:$$this.currtableDataModel_data.execute})
                .fontSize(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_SIZE)
                .placeholderColor('#bbbdbf')
                .borderRadius(0)
                .padding(0)
                .backgroundColor('#fff')
                .fontColor(CommonConstants.COMMAND_DEFAULT_FONT_COLOR)
                .fontWeight(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_WEIGHT)
                .layoutWeight(1)
              Image($r('app.media.Frame_2093'))
                .width(24)
                .visibility(this.response_[this.currentindex].isShow?Visibility.Visible:Visibility.None)
            }
            .padding({ left: 15, right:10})
            .width(410)
            .height(32)
            .borderRadius(4)
            .border({ width: 1, color: '#eaeaEa' })
          }
        }
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.End)
        .padding({ right: 50 })


        // .border({ width: 1, color: CommonConstants_pop.login_dafault_text_font_border_color })

        Row() {
          Text('确认')
            .fontSize(14)
            .fontColor('#00aecc')
            .borderRadius(4)
            .padding({
              top: 9,
              right: 24,
              bottom: 9,
              left: 24
            })
            .onClick(() => {
              if (this.isParam) {
                //编辑
                console.log(this.table_data.length.toString())
                this.table_data[this.currIndexParam]=this.currtableDataModel_data
                console.log(this.table_data.length.toString())
                console.log(JSON.stringify(this.table_data[this.table_data.length-1]))
                this.isShow_EditInstruction_pop=false

              }else {
                //创建
                console.log(this.table_data.length.toString())
                this.table_data.push(this.currtableDataModel_data)
                console.log(this.table_data.length.toString())
                console.log(JSON.stringify(this.table_data[this.table_data.length-1]))
                this.isShow_CreateNewInstruction_pop=false
                // AppStorage.setOrCreate('table_data',this.table_data)
                console.log(JSON.stringify(AppStorage.get('table_data')))
              }

            })
        }
        .justifyContent(FlexAlign.End)
        .height(64)
        .width($r('app.float.pop_launch_column_width'))
        .padding($r('app.float.pop_launch_column_default_padd'))

      }
      .shadow({ radius: 10, color: '#e9e9eb' })
      .width($r('app.float.pop_launch_column_width'))
      .borderRadius($r('app.float.pop_launch_column_defaultRadius'))
      .backgroundColor(Color.White)
    }
    .width('100%')
    .height('100%')

  }
}