import { CommonConstants_pop, Languages } from "config"
import CommonConstants from '../common/CommonConstants'
import { tableDataModel } from './Command_Ai'
// 拉起资源管理器
import { picker } from '@kit.CoreFileKit';
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { ThemeConfig } from "common";

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
  @StorageLink('languages') @Watch('onLanguagesChange') languages: string = 'ZH_CN'
  @Consume('pageInfo') pageInfo: NavPathStack

  // 使用 SelectOption[]
  @State array: SelectOption[] = []
  @State response_: response_interface[] = []

  @State currentindex: number = 0
  @Link isShow_CreateNewInstruction_pop: boolean
  @Link isShow_EditInstruction_pop: boolean
  @StorageLink('table_data') table_data: tableDataModel[] = []
  @Prop isParam: boolean = false
  @Prop currIndexParam: number

  // 关键修改：category 改为 number 类型，保存索引
  @State category: number = 0
  @State voice: string = ''
  @State execute: string = ''

  @State isLoading: boolean = false;

  aboutToAppear(): void {
    this.updateLanguageDependentData();
    if (this.isParam) {
      const originalData = this.table_data[this.currIndexParam];

      // 关键修改：category 现在直接保存索引值
      this.category = originalData.category as number;
      this.voice = originalData.voice;
      this.execute = originalData.execute;

      // 设置当前索引为 category 的值
      this.currentindex = this.category;
      console.log('编辑模式初始化:', JSON.stringify({
        category: this.category,
        voice: this.voice,
        execute: this.execute
      }));
    }
  }

  /**
   * 获取 SelectOption 的字符串值
   */
  private getSelectOptionValue(option: SelectOption): string {
    if (typeof option.value === 'string') {
      return option.value;
    } else {
      return String(option.value);
    }
  }

  /**
   * 监听语言变化
   */
  private onLanguagesChange(): void {
    this.updateLanguageDependentData();
  }

  /**
   * 更新语言相关的数据
   */
  private updateLanguageDependentData(): void {
    // 更新 array - 确保 value 是字符串
    this.array = [
      { value: Languages.file_option[this.languages] as string },
      { value: Languages.website_option[this.languages] as string },
      { value: Languages.generate_text_option[this.languages] as string },
      { value: Languages.folder_option[this.languages] as string },
    ];

    // 更新 response_
    this.response_ = [
      {
        title: `${Languages.execution_path[this.languages]}：`,
        isShow: true,
        response_: Languages.execution_path[this.languages],
        showFilePicker: true,
        showFolderPicker: false,
        showAppPicker: false
      },
      {
        title: Languages.website_text[this.languages],
        isShow: false,
        response_: Languages.enter_website[this.languages],
        showFilePicker: false,
        showFolderPicker: false,
        showAppPicker: false
      },
      {
        title: Languages.generate_text[this.languages],
        isShow: false,
        response_: Languages.enter_one_click_text[this.languages],
        showFilePicker: false,
        showFolderPicker: false,
        showAppPicker: false
      },
      {
        title: Languages.folder_path[this.languages],
        isShow: true,
        response_: Languages.select_any_file_in_folder[this.languages],
        showFilePicker: false,
        showFolderPicker: true,
        showAppPicker: false
      },
    ];

    // 关键修改：category 保存索引值，不再设置为字符串
    if (this.array.length > this.currentindex && !this.isParam) {
      this.category = this.currentindex;
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
          this.execute = result[0];
          console.log('文件信息', this.execute);
          promptAction.showToast({ message: Languages.file_selection_success[this.languages], duration: 2000 });
        }
      }).catch((err: BusinessError) => {
        console.error('文件选择失败: ' + err.message);
        promptAction.showToast({ message: Languages.file_selection_failed[this.languages], duration: 2000 });
      });
    } catch (err) {
      console.error('Failed to select file. Cause: ' + (err as BusinessError).message);
      promptAction.showToast({ message: Languages.file_selection_failed[this.languages], duration: 2000 });
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
      promptAction.showToast({ message: Languages.please_select_any_file_in_target_folder[this.languages], duration: 3000 });
      //
      // const documentSelectOptions = new picker.DocumentSelectOptions();
      // documentSelectOptions.maxSelectNumber = 1;
      //
      // const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      // const documentViewPicker = new picker.DocumentViewPicker(context);
      //
      // documentViewPicker.select(documentSelectOptions)
      let documentPicker = new picker.DocumentViewPicker();

      documentPicker.select({
        selectMode: picker.DocumentSelectMode.FOLDER
      })
        .then((result: string[]) => {
          if (!result || result.length === 0) {
            promptAction.showToast({ message: Languages.no_file_selected[this.languages], duration: 2000 });
            return;
          }

          const filePath = result[0];
          const lastSlashIndex = filePath.lastIndexOf('/');

          if (lastSlashIndex !== -1) {
            this.execute = result[0];
            console.log('提取的文件夹路径:', result[0]);
            promptAction.showToast({ message: `${Languages.folder_selected[this.languages]} ${result[0]}`, duration: 2500 });
          } else {
            promptAction.showToast({ message: Languages.cannot_parse_folder_path[this.languages], duration: 2000 });
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
      promptAction.showToast({
        message: Languages.folder_selection_function_exception[this.languages],
        duration: 3000
      });
      this.isLoading = false;
    }
  }

  /**
   * 辅助函数：根据错误码返回文件夹选择的友好提示
   */
  private getFolderSelectErrorMsg(errorCode: number): string {
    switch (errorCode) {
      case 1001:
        return Languages.need_file_access_permission[this.languages];
      case 1002:
        return Languages.folder_selection_canceled[this.languages];
      case 1003:
        return Languages.no_folder_access_permission[this.languages];
      default:
        return `${Languages.folder_selection_failed_with_code[this.languages]} ${errorCode})`;
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
        this.execute = 'com.example.app';
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
    if (!this.voice || this.voice.trim() === '') {
      promptAction.showToast({ message: Languages.please_enter_instruction_word[this.languages], duration: 2000 });
      return false;
    }

    if (!this.execute || this.execute.trim() === '') {
      promptAction.showToast({ message: Languages.please_set_execution_target[this.languages], duration: 2000 });
      return false;
    }

    // 网址验证
    if (this.currentindex === 1) {
      const urlRegex = /^(https?:\/\/)?[\w.-]+\.[a-z]{2,}.*$/i;
      if (!urlRegex.test(this.execute)) {
        promptAction.showToast({ message: Languages.please_enter_valid_website[this.languages], duration: 2000 });
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

    // 关键修改：category 现在保存的是索引值
    const newData: tableDataModel = {
      category: this.category, // 保存索引值
      voice: this.voice,
      execute: this.execute
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
      AppStorage.setOrCreate('table_data',[])
      console.log('err:'+JSON.stringify('table_data'))
      setTimeout(()=>{
        AppStorage.setOrCreate('table_data',updatedData)
        console.log('err:'+JSON.stringify('table_data'))
      },50)
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

    promptAction.showToast({ message: Languages.save_success[this.languages], duration: 2000 });
  }

  /**
   * 修改选择器选项变更处理
   */
  private onCategorySelect(index: number, value: string): void {
    console.log('选择功能:', index, value);
    this.currentindex = index;
    this.category = index; // 关键修改：保存索引值
    this.execute = ''; // 重置执行目标
  }

  /**
   * 修改指令词输入处理
   */
  private onVoiceChange(value: string): void {
    this.voice = value;
  }

  /**
   * 修改执行目标输入处理
   */
  private onExecuteChange(value: string): void {
    this.execute = value;
  }

  build() {
    Stack() {
      Column()// 背景蒙层
        .width('100%')
        .height('100%')
        .backgroundColor('#000')
        .opacity(0.2)

      Column() {
        // 标题栏
        Row() {
          Text(Languages.ai_instruction[this.languages])
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
            Text(Languages.function_text[this.languages])
              .fontSize(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_SIZE)
              .fontColor(CommonConstants.COMMAND_DEFAULT_FONT_COLOR)
              .fontWeight(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_WEIGHT)
            Select(this.array)
              .selected(this.currentindex)
              .width(410)
              .value(this.getSelectOptionValue(this.array[this.currentindex])) // 显示对应的文本值
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
            Text(Languages.instruction_word[this.languages])
              .fontSize(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_SIZE)
              .fontColor(CommonConstants.COMMAND_DEFAULT_FONT_COLOR)
              .fontWeight(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_WEIGHT)

            TextInput({
              placeholder: Languages.enter_trigger_text[this.languages],
              text: this.voice
            })
              .placeholderColor('#bbbdbf')
              .borderRadius(0)
              .backgroundColor('#fff')
              .padding({ left: 15 })
              .fontSize(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_SIZE)
              .fontColor(CommonConstants.COMMAND_DEFAULT_FONT_COLOR)
              .fontWeight(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_WEIGHT)
              .width(410)
              .borderRadius(4)
              .border({ width: 1, color: '#eaeaEa' })
              .onChange((value: string) => {
                this.onVoiceChange(value);
              })
          }
          .margin({ top: 15, bottom: 15 })

          // 执行目标输入
          Row() {
            Text(this.response_[this.currentindex]?.title || '')
              .fontSize(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_SIZE)
              .fontColor(CommonConstants.COMMAND_DEFAULT_FONT_COLOR)
              .fontWeight(CommonConstants.CreateNewInstruction_pop_DEFAULT_FONT_WEIGHT)
            Row() {
              TextInput({
                placeholder: this.response_[this.currentindex]?.response_ || '',
                text: this.execute
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
                  this.response_[this.currentindex]?.showFilePicker ||
                    this.response_[this.currentindex]?.showFolderPicker ||
                    this.response_[this.currentindex]?.showAppPicker ?
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
          Text(Languages.confirm[this.languages])
            .fontSize(14)
            .fontColor(ThemeConfig.PaletteTheme)
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