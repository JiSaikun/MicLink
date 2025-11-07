import { CommonConstants_pop, Languages } from "config"

// 步骤1：定义参数对象类型
export interface PopParams_1 {
  content: string;
  down: () => void;
  confirm: () => void;
}

// let languages: string = AppStorage.get('languages') as string || 'ZH_CN' //语言适配

@Builder
export function LaunchLogin_pop(params: PopParams_1) {
  Flex({ direction: FlexDirection.Column }) {
    Row() {
      Text(Languages.prompt[AppStorage.get('languages') as string])
        .fontWeight(CommonConstants_pop.login_dafault_text_font_weight)
        .fontSize(CommonConstants_pop.login_dafault_text_font_size)
        .fontColor(CommonConstants_pop.login_dafault_text_font_color)
      Blank()
      Image($r('app.media.pop_down'))
        .height(44)
        .width(44)
        .onClick(params.down)
    }
    .width($r('app.float.pop_launch_column_width'))
    .padding($r('app.float.pop_launch_column_default_padd'))
    .height(1)
    .flexGrow(1)

    Text(params.content)
      .width($r('app.float.pop_launch_column_width'))
      .fontWeight(CommonConstants_pop.login_dafault_text_font_weight)
      .fontSize(CommonConstants_pop.login_dafault_text_font_size)
      .fontColor(CommonConstants_pop.login_dafault_text_font_color)
      .height(1)
      .flexGrow(1)
      .padding($r('app.float.pop_launch_column_default_padd'))
      .border({ width: 1, color: CommonConstants_pop.login_dafault_text_font_border_color })
    Row() {
      Text(Languages.confirm[AppStorage.get('languages') as string])
        .fontSize(14)
        .backgroundColor(AppStorage.get('paletteTheme'))
        .fontColor('#fff')
        .borderRadius(4)
        .padding({
          top: 9,
          right: 24,
          bottom: 9,
          left: 24
        })
        .onClick(params.confirm)
    }
    .justifyContent(FlexAlign.End)
    .height(1)
    .flexGrow(1)
    .width($r('app.float.pop_launch_column_width'))
    .padding($r('app.float.pop_launch_column_default_padd'))

  }
  .shadow({ radius: 10, color: '#e9e9eb' })
  .width($r('app.float.pop_launch_column_width'))
  .height($r('app.float.pop_launch_column_height'))
  .borderRadius($r('app.float.pop_launch_column_defaultRadius'))
  .backgroundColor(Color.White)
}
