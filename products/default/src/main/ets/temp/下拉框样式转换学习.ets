// import {
//   LengthMetrics,
//   Flex,
//   FlexDirection,
//   Text,
//   Select,
//   Color,
//   ForEach,
//   SelectOption // 关键：从ArkUI引入官方SelectOption类型
// } from "@kit.ArkUI"
// import {
//   getModelInfoModel,
//   keyInfosModel,
//   LanguageNames,
//   keyInfos_childsModel,
//   keyInfos_childs_childsModel
// } from 'config'
//
// /**
//  * 按键设置页面组件
//  */
// @Component
// export struct ConfigPage2 {
//   // 从AppStorage获取设备按键信息：显式指定泛型类型，防空兜底
//   @State getModelInfo: getModelInfoModel = AppStorage.get<getModelInfoModel>('getModelInfo') || {} as getModelInfoModel;
//   // 当前语言（默认中文，可对接多语言切换逻辑）
//   @State languages: string = 'ZH_CN';
//
//   /**
//    * 将子项转换为ArkUI官方SelectOption数组
//    * （使用官方类型，避免自定义对象导致的“未声明类型”报错）
//    */
//   private convertChildsToOptions(childs: keyInfos_childs_childsModel[]): SelectOption[] {
//     return childs.map((child, index) => {
//       // 多语言适配：优先取当前语言文本，无则按顺序兜底
//       const displayText = (child.names as LanguageNames)[this.languages]
//         || child.cmdName
//         || '未命名选项';
//
//       // 返回ArkUI官方SelectOption类型的对象（非自定义类型，符合规范）
//       return {
//         value: index.toString(), // 选项值：用索引保证唯一性
//         content: displayText     // 选项显示文本
//       } as SelectOption; // 显式断言为官方类型，消除“未声明类型”警告
//     });
//   }
//
//   /**
//    * 获取默认选中索引（childs中first=1的项为默认选中）
//    */
//   private getDefaultSelectedIndex(childs: keyInfos_childs_childsModel[]): number {
//     for (let i = 0; i < childs.length; i++) {
//       if (childs[i].first === 1) {
//         return i;
//       }
//     }
//     return 0; // 无默认项时选中第一个
//   }
//
//   build() {
//     Flex({
//       space: { main: LengthMetrics.px(15) }, // 主轴间距15px（显式单位）
//       direction: FlexDirection.Column         // 垂直排列（子组件从上到下）
//     }) {
//       // 遍历顶层按键组（keyInfos）：防空处理，避免undefined导致崩溃
//       ForEach(
//         this.getModelInfo.keyInfos || [],
//         (item: keyInfosModel) => {
//           Flex({ direction: FlexDirection.Column }) {
//             // 顶层按键组标题（多语言适配）
//             Text((item.names as LanguageNames)[this.languages] || '按键设置组')
//               .fontSize(LengthMetrics.px(14))
//               .lineHeight(LengthMetrics.px(14))
//               .fontWeight(400)
//               .fontColor('#a4aab2')
//               .margin({
//                 bottom: LengthMetrics.px(10),
//                 top: LengthMetrics.px(10)
//               });
//
//             // 遍历子按键（childs）：每个子按键对应一个下拉选择器
//             ForEach(
//               item.childs || [], // 防空处理
//               (childItem: keyInfos_childsModel) => {
//                 Flex({ direction: FlexDirection.Column }) {
//                   // 子按键标题（多语言适配）
//                   Text((childItem.names as LanguageNames)[this.languages] || '子按键')
//                     .fontSize($r('app.float.default_text_font_size_14'))
//                     .fontWeight(400)
//                     .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
//                     .margin({ bottom: LengthMetrics.px(5) });
//
//                   // 核心：修复Select组件参数（符合ArkUI官方规范）
//                   // 写法：Select(选项数组: SelectOption[], 默认选中索引?: number)
//                   Select(
//                     // 第一个参数：下拉选项列表（官方SelectOption数组）
//                     this.convertChildsToOptions(childItem.childs || []),
//                     // 第二个参数：默认选中索引（可选，数字类型）
//                     this.getDefaultSelectedIndex(childItem.childs || [])
//                   )
//                     .width('100%') // 下拉框宽度占满父容器
//                     .font({
//                       size: $r('app.float.default_text_font_size_14'),
//                       weight: 400
//                     })
//                     .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
//                     .borderRadius(LengthMetrics.px(4)) // 显式单位
//                     .border({
//                       width: LengthMetrics.px(1), // 显式单位
//                       color: $r('app.string.DEFAULT_BORDER_COLOR')
//                     })
//                     .backgroundColor(Color.White)
//                     .onSelect((selectedIndex: number) => {
//                       // 选择变化事件：可补充“保存选中状态”等业务逻辑
//                       const selectedOption = this.convertChildsToOptions(childItem.childs || [])[selectedIndex];
//                       console.log(`
//                         子按键：${childItem.name || '未命名'}
//                         选中索引：${selectedIndex}
//                         选中选项：${selectedOption.content}
//                       `);
//                     });
//                 }
//                 .margin({ bottom: LengthMetrics.px(15) }); // 子组件底部间距
//               },
//               // ForEach的key：确保子按键唯一（避免组件复用异常）
//               (childItem: keyInfos_childsModel) => childItem.name || `child_${childItem.hashCode || Math.random()}`
//             );
//           };
//         },
//         // ForEach的key：确保顶层按键组唯一
//         (item: keyInfosModel) => item.keyName || `key_${item.hashCode || Math.random()}`
//       );
//     }
//     .width('100%')
//     .padding(LengthMetrics.px(10)); // 根容器内边距（显式单位）
//   }
// }