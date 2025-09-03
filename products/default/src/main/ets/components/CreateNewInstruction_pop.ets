import {CommonConstants_pop}from "config"
import CommonConstants from '../common/CommonConstants'
@Builder function CreateNewInstruction_pop(){
  Flex({direction:FlexDirection.Column}) {
    Row(){
      Text('AI 指令')
        .fontWeight(CommonConstants_pop.login_dafault_text_font_weight)
        .fontSize(CommonConstants_pop.login_dafault_text_font_size)
        .fontColor(CommonConstants_pop.login_dafault_text_font_color)
      Blank()
      Image($r('app.media.pop_down'))
        .height(44)
        .width(44)
        .onClick(()=>{

        })
    }
    .width($r('app.float.pop_launch_column_width'))
    .padding($r('app.float.pop_launch_column_default_padd'))
    .height(64)
    Column(){
      Text('功能：')
        .fontSize(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_SIZE)
        .fontColor(CommonConstants.COMMAND_DEFAULT_FONT_COLOR)
        .fontWeight(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_WEIGHT)

    }
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.End)
    .padding({right:100})
    .border({width:1,color:CommonConstants_pop.login_dafault_text_font_border_color})
    Row(){
      Text('确认')
        .fontSize(14)
        .fontColor('#00aecc')
        .borderRadius(4)
        .padding({top:9,right:24,bottom:9,left:24})
        .onClick(()=>{

        })
    }
    .justifyContent(FlexAlign.End)
    .height(64)
    .width($r('app.float.pop_launch_column_width'))
    .padding($r('app.float.pop_launch_column_default_padd'))


  }
  .shadow({radius:10,color:'#e9e9eb'})
  .width($r('app.float.pop_launch_column_width'))
  .borderRadius($r('app.float.pop_launch_column_defaultRadius'))
  .backgroundColor(Color.White)
}