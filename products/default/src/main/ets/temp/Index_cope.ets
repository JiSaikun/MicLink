// import { LeftBar, Topbar, Content } from 'common'
// // import {Hid}from "usb_hid"
// import {BlueTooth_api}from "bluetooth"
// PersistentStorage.persistProp("login", false)
//
// @Entry
// @Component
// struct Index {
//   @StorageLink("login") login: boolean = true
//   @Provide('pageInfo') pageInfo: NavPathStack = new NavPathStack()
//   @State web: string = 'https://asrai.miclink.net?sno=123&productCode=999999&config=configMiclink_B_1755079145452'
//
//   aboutToAppear(): void {
//     BlueTooth_api.init_bluetoothState()
//     // Hid.Hid_add()
//     this.pageInfo.disableAnimation(true)
//     // console.log(JSON.stringify(this.login))
//     if (!this.login) {
//       this.pageInfo.pushPath({ 'name': 'login' })
//     }
//   }
//
//   build() {
//     Column() {
//       Navigation(this.pageInfo) {
//         Row() {
//           LeftBar({ web: this.web })
//           Stack() {
//             Topbar()
//               .zIndex(100)
//             Content({ web: this.web })
//           }
//           // .border({width:1})
//           .align(Alignment.TopStart)
//           .height('100%')
//           .layoutWeight(1)
//         }
//         // .backgroundColor(Color.Blue)
//         .width('100%')
//         .height('100%')
//         .onClick(() => {
//           // type Action = 'home'
//         })
//       }
//       .hideToolBar(true)
//       .hideTitleBar(true)
//       .mode(NavigationMode.Stack)
//
//     }
//
//   }
// }