import { Languages } from "config"
import { updateName_Params } from "../model/UserModel"
import { _updateName } from "../viewmodel/UserViewModel"
import { promptAction } from "@kit.ArkUI"
import { ThemeConfig, UserLoginInfo } from "common"

@Component
export struct Rename_pop {
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State name: string = '' //新昵称
  @Link isShow_Rename_pop: boolean
  @Prop token: string = ''
  @StorageLink("paletteTheme") paletteTheme: string = ThemeConfig.PaletteTheme

  aboutToAppear(): void {

  }

  build() {
    Stack() {
      Column() {
        Row() {
          // Text('输入网页网址')
          Text(Languages.changeNickname[this.languages])
            .fontSize(16)
            .fontWeight(400)
            .fontColor(Color.White)
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .borderRadius({ topLeft: 8, topRight: 8 })
        .padding(10)
        .backgroundColor(this.paletteTheme)

        TextInput({ placeholder: Languages.enterNewNickname[this.languages], text: $$this.name })
        // TextInput({ placeholder: Languages.enter_web_url_placeholder[this.languages], text: $$this.webUrlToOpen })
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
            .backgroundColor(this.paletteTheme)
            .borderRadius(5)
            .onClick(() => {
              if (!this.name) {
                promptAction.showToast({ message: Languages.nicknameCannotBeEmpty[this.languages] })
              }
              let param: updateName_Params = {
                name: this.name,
                token: this.token
              }
              _updateName(param).then((res) => {
                console.log('更改昵称成功', JSON.stringify(res))
                if (res.statusCode === 200) {
                  // promptAction.showToast({ message: Languages.changeSuccess[this.languages] })
                  promptAction.showToast({ message: Languages.nicknameChangeSuccess[this.languages] })
                  let userLoginInfo: UserLoginInfo = AppStorage.get('userLoginInfo') as UserLoginInfo
                  userLoginInfo.name = this.name
                  AppStorage.setOrCreate('userLoginInfo', res.data)
                  this.isShow_Rename_pop = false
                }
              })
            })
            .margin({ right: 30 })

          Text(Languages.cancel[this.languages])
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
            .onClick(() => {
              this.isShow_Rename_pop = false
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