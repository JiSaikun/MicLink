import { Languages } from "config"

@Component
export struct WebUrlToOpen_pop {
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State webUrlToOpen: string = '' //打开网页：输入网址
  @Link isShow_webUrlToOpen_pop: boolean

  aboutToAppear(): void {
    this.webUrlToOpen = AppStorage.get('webUrlToOpen') as string
    AppStorage.setOrCreate('webUrlToOpen', '')
    console.warn( 'webUrlToOpen:',AppStorage.get('webUrlToOpen') as string)
  }

  build() {
    Stack() {
      Column() {
        Row() {
          // Text('输入网页网址')
          Text(Languages.input_web_url[this.languages])
            .fontSize(16)
            .fontWeight(400)
            .fontColor(Color.White)
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .borderRadius({ topLeft: 8, topRight: 8 })
        .padding(10)
        .backgroundColor('#00afcc')

        // TextInput({ placeholder: '请输入打开网页的网址', text: $$this.webUrlToOpen })
        TextInput({ placeholder: Languages.enter_web_url_placeholder[this.languages], text: $$this.webUrlToOpen })
          .backgroundColor('#fff')
          .placeholderColor('#bbbdbf')
          .margin({
            top: 50,
            bottom: 50,
            left: 20,
            right: 20
          })
          .placeholderFont({ size: 14, weight: 400 })
          .border({ width: 1, color: '#eaeaea' })
          .borderRadius(5)

        Flex({ justifyContent: FlexAlign.Center }) {
          // Text('确定')
          Text(Languages.confirm_btn[this.languages])
            .fontSize(16)
            .fontWeight(400)
            .fontColor(Color.White)
            .padding({
              top: 15,
              bottom: 15,
              left: 35,
              right: 35
            })
            .backgroundColor('#00afcc')
            .borderRadius(5)
            .onClick(() => {
              AppStorage.setOrCreate('webUrlToOpen', this.webUrlToOpen)
              console.error( 'webUrlToOpen:',AppStorage.get('webUrlToOpen') as string)
              this.isShow_webUrlToOpen_pop = false
            })
        }
        .width('100%')
      }
      .shadow({ radius: 10, color: '#e9e9eb' })
      .width(340)
      .borderRadius(8)
      .backgroundColor('#f5f5f5')
      .zIndex(10)
      .padding({ bottom: 20 })


      Column() {

      }
      .width('100%')
      .height('100%')
      .backgroundColor('#000')
      .opacity(0.2)
    }
    .width('100%')
    .height('100%')

  }
}