// import common from '@ohos.app.ability.common';
// import wantConstant from '@ohos.app.ability.wantConstant';
//
// // 在Ability或UI组件中
// export default class ReturnToDesktop {
//   // 返回系统桌面
//   static returnToDesktop(context: common.Context) {
//     try {
//       let want = {
//         action: wantConstant.Action.HOME,
//         entities: [wantConstant.Entity.HOME]
//       };
//       context.startAbility(want).then(() => {
//         console.log('Return to desktop successfully');
//       }).catch((error) => {
//         console.error('Failed to return to desktop. Error: ' + JSON.stringify(error));
//       });
//     } catch (error) {
//       console.error('Error returning to desktop: ' + JSON.stringify(error));
//     }
//   }
// }
//
// @Component
// struct C {
//   build() {
//
//   }
// }
