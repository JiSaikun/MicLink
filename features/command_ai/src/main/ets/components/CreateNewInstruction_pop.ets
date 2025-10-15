import { CommonConstants_pop } from "config"
import CommonConstants from '../common/CommonConstants'
import { tableDataModel } from './Command_Ai'
// 拉起资源管理器
import { picker } from '@kit.CoreFileKit';
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';

interface response_interface {
  title: string
  isShow: boolean
  response_: string
  showFilePicker?: boolean
  showFolderPicker?: boolean
  showAppPicker?: boolean
}

@Component
export struct CreateNewInstruction_pop {
  @Consume('pageInfo') pageInfo: NavPathStack
  @State array: SelectOption[] = [
    { value: '文件' },
    { value: '网址' },
    { value: '生成文本' },
    { value: '文件夹' },
  ]
  @State response_: response_interface[] = [
    {
      title: '执行路径：',
      isShow: true,
      response_: '执行路径',
      showFilePicker: true,
      showFolderPicker: false,
      showAppPicker: false
    },
    {
      title: '网址：',
      isShow: false,
      response_: '输入网址',
      showFilePicker: false,
      showFolderPicker: false,
      showAppPicker: false
    },
    {
      title: '生成文本：',
      isShow: false,
      response_: '输入要一键生成的文本',
      showFilePicker: false,
      showFolderPicker: false,
      showAppPicker: false
    },
    {
      title: '文件夹路径：',
      isShow: true,
      response_: '选择目标文件夹中的任意文件',
      showFilePicker: false,
      showFolderPicker: true,
      showAppPicker: false
    },
  ]
  @State currentindex: number = 0
  @Link isShow_CreateNewInstruction_pop: boolean
  @Link isShow_EditInstruction_pop: boolean
  @StorageLink('table_data') table_data: tableDataModel[] = []
  @Prop isParam: boolean = false
  @Prop currIndexParam: number
  @State currtableDataModel_data: tableDataModel = {
    category: '文件',
    voice: '',
    execute: '',
  }
  @State isLoading: boolean = false;

  aboutToAppear(): void {
    if (this.isParam) {
      // 使用显式赋值而不是展开操作符
      const originalData = this.table_data[this.currIndexParam];
      this.currtableDataModel_data.category = originalData.category;
      this.currtableDataModel_data.voice = originalData.voice;
      this.currtableDataModel_data.execute = originalData.execute;

      this.currentindex = this.array.findIndex(item => item.value === this.currtableDataModel_data.category);
      console.log('编辑模式初始化:', JSON.stringify(this.currtableDataModel_data));
    }
  }

  /**
   * 选择文件
   */
  private selectFile(): void {
    this.isLoading = true;
    try {
      const documentSelectOptions = new picker.DocumentSelectOptions();
      documentSelectOptions.maxSelectNumber = 1;

      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const documentViewPicker = new picker.DocumentViewPicker(context);

      documentViewPicker.select(documentSelectOptions).then((result) => {
        if (result && result.length > 0) {
          // 直接赋值而不是使用展开操作符
          this.currtableDataModel_data.execute = result[0];
          console.log('文件信息', JSON.stringify(this.currtableDataModel_data.execute));
          promptAction.showToast({ message: '文件选择成功', duration: 2000 });
        }
      }).catch((err: BusinessError) => {
        console.error('文件选择失败: ' + err.message);
        promptAction.showToast({ message: '文件选择失败', duration: 2000 });
      });
    } catch (err) {
      console.error('Failed to select file. Cause: ' + (err as BusinessError).message);
      promptAction.showToast({ message: '文件选择失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 选择文件夹
   */
  private selectFolder(): void {
    this.isLoading = true;
    try {
      promptAction.showToast({ message: '请选择目标文件夹中的任意一个文件', duration: 3000 });

      const documentSelectOptions = new picker.DocumentSelectOptions();
      documentSelectOptions.maxSelectNumber = 1;

      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const documentViewPicker = new picker.DocumentViewPicker(context);

      documentViewPicker.select(documentSelectOptions)
        .then((result: string[]) => {
          if (!result || result.length === 0) {
            promptAction.showToast({ message: '未选择任何文件', duration: 2000 });
            return;
          }

          const filePath = result[0];
          const lastSlashIndex = filePath.lastIndexOf('/');

          if (lastSlashIndex !== -1) {
            const folderPath = filePath.substring(0, lastSlashIndex);
            // 直接赋值而不是使用展开操作符
            this.currtableDataModel_data.execute = folderPath;

            console.log('提取的文件夹路径:', folderPath);
            const folderName = folderPath.substring(folderPath.lastIndexOf('/') + 1);
            promptAction.showToast({ message: `已选择文件夹: ${folderName}`, duration: 2500 });
          } else {
            promptAction.showToast({ message: '无法解析文件夹路径', duration: 2000 });
          }
        })
        .catch((err: BusinessError) => {
          const errorMsg = this.getFolderSelectErrorMsg(err.code);
          console.error('文件夹选择失败:', errorMsg, '错误码:', err.code);
          promptAction.showToast({ message: errorMsg, duration: 3000 });
        })
        .finally(() => {
          this.isLoading = false;
        });

    } catch (err) {
      console.error('文件夹选择代码异常:', (err as Error).message);
      promptAction.showToast({ message: '文件夹选择功能异常', duration: 3000 });
      this.isLoading = false;
    }
  }

  /**
   * 辅助函数：根据错误码返回文件夹选择的友好提示
   */
  private getFolderSelectErrorMsg(errorCode: number): string {
    switch (errorCode) {
      case 1001:
        return '需要文件访问权限，请在设置中开启';
      case 1002:
        return '已取消文件夹选择';
      case 1003:
        return '无文件夹访问权限，请授权后重试';
      default:
        return `选择失败（错误码: ${errorCode}）`;
    }
  }

  /**
   * 选择应用
   */
  private selectApp(): void {
    this.isLoading = true;
    try {
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

      const want: Want = {
        action: 'ohos.want.action.selectApp',
        parameters: {}
      };

      context.startAbility(want).then(() => {
        console.log('启动应用选择器');
      }).catch((err: BusinessError) => {
        console.error('启动应用选择器失败: ' + err.message);
        promptAction.showToast({ message: '暂不支持应用选择，请手动输入包名', duration: 3000 });
        // 直接赋值而不是使用展开操作符
        this.currtableDataModel_data.execute = 'com.example.app';
      });
    } catch (err) {
      console.error('应用选择失败: ' + (err as BusinessError).message);
      promptAction.showToast({ message: '应用选择失败，请手动输入包名', duration: 3000 });
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 处理选择器按钮点击
   */
  private handlePickerClick(): void {
    if (this.isLoading) {
      return;
    }

    const currentResponse = this.response_[this.currentindex];

    if (currentResponse.showFilePicker) {
      this.selectFile();
    } else if (currentResponse.showFolderPicker) {
      this.selectFolder();
    } else if (currentResponse.showAppPicker) {
      this.selectApp();
    }
  }

  /**
   * 获取选择器图标
   */
  private getPickerIcon(): Resource {
    const currentResponse = this.response_[this.currentindex];

    if (currentResponse.showFilePicker) {
      return $r('app.media.Frame_2093');
    } else if (currentResponse.showFolderPicker) {
      return $r('app.media.Frame_2093');
    } else if (currentResponse.showAppPicker) {
      return $r('app.media.Frame_2093');
    }

    return $r('app.media.Frame_2093');
  }

  /**
   * 验证输入数据
   */
  private validateInput(): boolean {
    if (!this.currtableDataModel_data.voice || this.currtableDataModel_data.voice.trim() === '') {
      promptAction.showToast({ message: '请输入指令词', duration: 2000 });
      return false;
    }

    if (!this.currtableDataModel_data.execute || this.currtableDataModel_data.execute.trim() === '') {
      promptAction.showToast({ message: '请设置执行目标', duration: 2000 });
      return false;
    }

    // 网址验证
    if (this.currentindex === 1) {
      const urlRegex = /^(https?:\/\/)?[\w.-]+\.[a-z]{2,}.*$/i;
      if (!urlRegex.test(this.currtableDataModel_data.execute)) {
        promptAction.showToast({ message: '请输入有效的网址', duration: 2000 });
        return false;
      }
    }

    return true;
  }

  /**
   * 保存指令
   */
  private saveInstruction(): void {
    if (!this.validateInput()) {
      return;
    }

    // 创建新的 tableDataModel 对象而不是使用展开操作符
    const newData: tableDataModel = {
      category: this.currtableDataModel_data.category,
      voice: this.currtableDataModel_data.voice,
      execute: this.currtableDataModel_data.execute
    };

    if (this.isParam) {
      // 编辑模式：创建新数组并更新指定位置
      const updatedData: tableDataModel[] = [];
      for (let i = 0; i < this.table_data.length; i++) {
        if (i === this.currIndexParam) {
          updatedData.push(newData);
        } else {
          updatedData.push(this.table_data[i]);
        }
      }
      this.table_data = updatedData;
      console.log('编辑指令完成:', JSON.stringify(newData));
      this.isShow_EditInstruction_pop = false;
    } else {
      // 创建模式：创建新数组并添加新项
      const updatedData: tableDataModel[] = [];
      for (let i = 0; i < this.table_data.length; i++) {
        updatedData.push(this.table_data[i]);
      }
      updatedData.push(newData);
      this.table_data = updatedData;
      console.log('创建指令完成:', JSON.stringify(newData));
      this.isShow_CreateNewInstruction_pop = false;
    }

    promptAction.showToast({ message: '保存成功', duration: 2000 });
  }

  /**
   * 修改选择器选项变更处理
   */
  private onCategorySelect(index: number, value: string): void {
    console.log('选择功能:', index, value);
    this.currentindex = index;

    // 直接赋值而不是使用展开操作符
    this.currtableDataModel_data.category = value;
    this.currtableDataModel_data.execute = ''; // 重置执行目标
  }

  /**
   * 修改指令词输入处理
   */
  private onVoiceChange(value: string): void {
    this.currtableDataModel_data.voice = value;
  }

  /**
   * 修改执行目标输入处理
   */
  private onExecuteChange(value: string): void {
    this.currtableDataModel_data.execute = value;
  }

  build() {
    Stack() {
      Column() {
        // 背景蒙层
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#000')
      .opacity(0.2)

      Column() {
        // 标题栏
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

        // 内容区域
        Column() {
          // 功能选择
          Row() {
            Text('功能：')
              .fontSize(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_SIZE)
              .fontColor(CommonConstants.COMMAND_DEFAULT_FONT_COLOR)
              .fontWeight(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_WEIGHT)
            Select(this.array)
              .selected(this.currentindex)
              .width(410)
              .value(this.currtableDataModel_data.category)
              .height(32)
              .font({
                weight: CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_WEIGHT,
                size: CommonConstants.COMMAND_DEFAULT_FONT_SIZE
              })
              .fontColor(CommonConstants.COMMAND_DEFAULT_FONT_COLOR)
              .borderRadius(4)
              .border({ width: 1, color: $r('app.string.DEFAULT_BORDER_COLOR') })
              .backgroundColor(Color.White)
              .onSelect((index: number, value: string) => {
                this.onCategorySelect(index, value);
              })
          }

          // 指令词输入
          Row() {
            Text('指令词：')
              .fontSize(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_SIZE)
              .fontColor(CommonConstants.COMMAND_DEFAULT_FONT_COLOR)
              .fontWeight(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_WEIGHT)

            TextInput({ placeholder: '输入触发文字', text: this.currtableDataModel_data.voice })
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
              .onChange((value: string) => {
                this.onVoiceChange(value);
              })
          }
          .margin({ top: 15, bottom: 15 })

          // 执行目标输入
          Row() {
            Text(this.response_[this.currentindex].title)
              .fontSize(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_SIZE)
              .fontColor(CommonConstants.COMMAND_DEFAULT_FONT_COLOR)
              .fontWeight(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_WEIGHT)
            Row() {
              TextInput({
                placeholder: this.response_[this.currentindex].response_,
                text: this.currtableDataModel_data.execute
              })
                .fontSize(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_SIZE)
                .placeholderColor('#bbbdbf')
                .borderRadius(0)
                .padding(0)
                .backgroundColor('#fff')
                .fontColor(CommonConstants.COMMAND_DEFAULT_FONT_COLOR)
                .fontWeight(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_WEIGHT)
                .layoutWeight(1)
                .onChange((value: string) => {
                  this.onExecuteChange(value);
                })

              // 选择器按钮
              Image(this.getPickerIcon())
                .width(24)
                .height(24)
                .visibility(
                  this.response_[this.currentindex].showFilePicker ||
                  this.response_[this.currentindex].showFolderPicker ||
                  this.response_[this.currentindex].showAppPicker ?
                  Visibility.Visible : Visibility.None
                )
                .onClick(() => {
                  this.handlePickerClick();
                })
            }
            .padding({ left: 15, right: 10 })
            .width(410)
            .height(32)
            .borderRadius(4)
            .border({ width: 1, color: '#eaeaEa' })
          }
        }
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.End)
        .padding({ right: 50 })

        // 确认按钮
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
              this.saveInstruction();
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