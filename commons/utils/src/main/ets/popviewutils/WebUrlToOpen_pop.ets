import { Languages } from "config"
import { CursorController, promptAction } from "@kit.ArkUI"
import { pointer } from "@kit.InputKit"

@Component
export struct WebUrlToOpen_pop {
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State webUrlToOpen: string = '' //打开网页：输入网址
  @Link isShow_webUrlToOpen_pop: boolean
  @StorageLink("paletteTheme") paletteTheme: string = ''
  @State showProtocolSelection: boolean = false // 控制协议选择弹窗显示
  @State tempUrl: string = '' // 临时存储用户输入的URL
  cursorCustom: CursorController = this.getUIContext().getCursorController();

  aboutToAppear(): void {
    this.webUrlToOpen = AppStorage.get('webUrlToOpen') as string
    AppStorage.setOrCreate('webUrlToOpen', '')
    console.warn('webUrlToOpen:', AppStorage.get('webUrlToOpen') as string)
  }

  // 显示协议选择弹窗
  private showProtocolDialog(url: string): void {
    this.tempUrl = url;
    this.showProtocolSelection = true;
  }

  // 处理协议选择
  private handleProtocolSelection(protocol: string): void {
    const formattedUrl = protocol + this.tempUrl;
    AppStorage.setOrCreate('webUrlToOpen', formattedUrl);

    promptAction.showToast({
      message: `已使用 ${protocol} 协议`,
      duration: 1500
    });

    this.isShow_webUrlToOpen_pop = false;
    this.showProtocolSelection = false;
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Text(Languages.input_web_url[this.languages])
            .fontSize(16)
            .fontWeight(400)
            .fontColor(Color.White)
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .borderRadius({ topLeft: 8, topRight: 8 })
        .padding(10)
        .backgroundColor(this.paletteTheme)

        TextInput({
          placeholder: Languages.enter_web_url_placeholder[this.languages] + '\n例如: www.example.com 或 https://example.com',
          text: $$this.webUrlToOpen
        })
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
            .backgroundColor(this.paletteTheme)
            .borderRadius(5)
            .onHover((flag) => {
              if (flag) {
                this.cursorCustom.setCursor(pointer.PointerStyle.HAND_POINTING);
              } else {
                console.info("restoreDefault");
                this.cursorCustom.restoreDefault();
              }
            })
            .onClick(() => {
              const urlRegex = /^(https?:\/\/)?[\w.-]+\.[a-z]{2,}.*$/i;
              if (!urlRegex.test(this.webUrlToOpen)) {
                promptAction.showToast({
                  message: Languages.please_enter_valid_website[this.languages] + '\n例如: www.example.com 或 https://example.com',
                  duration: 2000
                });
                return
              }

              // 如果URL已包含协议，直接使用
              if (this.webUrlToOpen.startsWith('http://') || this.webUrlToOpen.startsWith('https://')) {
                AppStorage.setOrCreate('webUrlToOpen', this.webUrlToOpen);
                this.isShow_webUrlToOpen_pop = false;
              } else {
                // 如果不包含协议，显示协议选择弹窗
                this.showProtocolDialog(this.webUrlToOpen);
              }
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

      // 协议选择弹窗
      if (this.showProtocolSelection) {
        Column() {
          Column() {
            Row() {
              Text('选择协议类型')
                .fontSize(16)
                .fontWeight(500)
                .fontColor(Color.Black)
            }
            .justifyContent(FlexAlign.Center)
            .width('100%')
            .padding(15)

            Divider()

            // HTTPS 选项
            Row() {
              Text('使用 HTTPS (推荐)')
                .fontSize(14)
                .fontColor(Color.Black)
            }
            .width('100%')
            .padding(15)
            .onHover((flag) => {
              if (flag) {
                this.cursorCustom.setCursor(pointer.PointerStyle.HAND_POINTING);
              } else {
                console.info("restoreDefault");
                this.cursorCustom.restoreDefault();
              }
            })
            .onClick(() => {
              this.handleProtocolSelection('https://');
            })

            Divider()

            // HTTP 选项
            Row() {
              Text('使用 HTTP')
                .fontSize(14)
                .fontColor(Color.Black)
            }
            .width('100%')
            .padding(15)
            .onHover((flag) => {
              if (flag) {
                this.cursorCustom.setCursor(pointer.PointerStyle.HAND_POINTING);
              } else {
                console.info("restoreDefault");
                this.cursorCustom.restoreDefault();
              }
            })
            .onClick(() => {
              this.handleProtocolSelection('http://');
            })

            Divider()

            // 取消按钮
            Row() {
              Text('取消')
                .fontSize(14)
                .fontColor('#007DFF')
            }
            .width('100%')
            .padding(15)
            .onHover((flag) => {
              if (flag) {
                this.cursorCustom.setCursor(pointer.PointerStyle.HAND_POINTING);
              } else {
                console.info("restoreDefault");
                this.cursorCustom.restoreDefault();
              }
            })
            .onClick(() => {
              this.showProtocolSelection = false;
            })
          }
          .backgroundColor(Color.White)
          .borderRadius(12)
          .width(280)
          .shadow({ radius: 20, color: '#00000020' })
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .width('100%')
        .height('100%')
        .backgroundColor('#00000060')
        .zIndex(20)
      }

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