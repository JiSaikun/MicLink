import { common, Want } from "@kit.AbilityKit";

@Entry
@Component
export struct Overlay {
  @Watch('changeText') @StorageLink('voiceInputText') voiceInputText: string = ''
  @StorageLink('voiceInputState') voiceInputState: boolean = true
  @StorageLink('isAI_assistant') isAI_assistant: boolean = false //是不是语音助手

  changeText() {
    if (this.isAI_assistant) {
      //执行AI助手方法
      if (this.voiceInputText) {
        this.openTheWebpage(this.voiceInputText)
      }
    }
  }

  openTheWebpage(text: string) {

    const context: common.UIAbilityContext = AppStorage.get('context') as common.UIAbilityContext;
    const encodedKeyword = encodeURIComponent(text);
    let uri: string = ''
    switch (AppStorage.get('EnhancedBrowserSearch') as number) {
      case 0: //百度
        uri = `https://www.baidu.com/s?wd=${encodedKeyword}`
        break
      case 1: //谷歌
        uri = `https://www.google.com/search?q=${encodedKeyword}`
        break
      // case 2: //必应
      //   uri = `https://www.bing.com/search?q=${encodedKeyword}`
      //   break
      // case 3: //搜狗
      //   uri = `https://www.sogou.com/web?query=${encodedKeyword}`
      //   break

    }
    let want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: uri,
      // parameters: {
      //   'ohos.ability.params.showDefaultPicker': true
      // }
    };
    context.startAbility(want)
  }

  build() {
    Flex({ direction: FlexDirection.Column }) {
      Flex() {
        Stack() {
          Image($r("app.media.float_window_deafult"))
            .width(100)
            .height(100)
          if (this.isAI_assistant) {
            Image($r(`${this.voiceInputState ? 'app.media.AI_assistant' : 'app.media.unAI_assistant'}`))
              .width(32)
              .height(32)
          } else {
            Image($r(`${this.voiceInputState ? 'app.media.voiceing_icon' : 'app.media.voice_icon'}`))
              .width(32)
              .height(32)
          }
        }
        .margin({ right: 24 })
        .width(100)

        Scroll() {
          Text(this.voiceInputText)
            .textAlign(TextAlign.Start)
            .padding({ right: 8, left: 8 })
            .fontSize(14)
            .fontWeight(400)
            .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
            .width('100%')
        }
        .align(Alignment.TopStart)
        .height('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .padding(24)
      .borderRadius(16)
      .backgroundColor(Color.White)
    }
  }
}