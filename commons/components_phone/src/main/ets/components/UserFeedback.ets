import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"
import { TopTitle } from "../common/TopTitle"
import { LengthMetrics } from "@kit.ArkUI"
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { promptAction } from '@kit.ArkUI';
import { fileIo } from '@kit.CoreFileKit';
import { common } from "@kit.AbilityKit";
import { ImageUploader, UserLoginInfo } from "common";
import { _feedbackAdd } from "../viewmodel/UserViewModel";
import { feedbackAddy_Response, feedbackAdd_Params } from "../model/UserModel";
import { DeviceInfo } from "mouse";
import { AxiosResponse } from "@ohos/axios";

@Builder
export function UserFeedbackBuilder() {
  UserFeedback()
}


@Component
struct UserFeedback {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @Consume('pageInfo') pageInfo: NavPathStack
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State feedbackText: string = ''
  @State imageUris: string[] = []
  @State dstPath: string[] = []
  @StorageLink('dstPath_imgs') dstPath_imgs: string[] = []
  @State userLoginInfo: UserLoginInfo = AppStorage.get('userLoginInfo') as UserLoginInfo
  @StorageLink("mouseconfig") mouseconfig: DeviceInfo | null = null

  build() {
    NavDestination() {
      Column() {
        TopTitle({ title: Languages.userFeedback[this.languages], isback: false })
          .margin({ bottom: 12 })
        Text(Languages.problemsAndSuggestions[this.languages])
          .fontSize(CommonConfig.fontSize_14)
          .fontWeight(CommonConfig.fontWeight_400)
          .fontColor(CommonConfig.hintTextColor)
          .margin({ bottom: 12 })
        Column() {
          TextArea({ text: $$this.feedbackText, placeholder: Languages.describeYourProblem[this.languages] })
            .placeholderColor(CommonConfig.hintTextColor)
            .fontColor(CommonConfig.hintTextColor_select)
            .fontWeight(CommonConfig.fontWeight_400)
            .fontSize(CommonConfig.fontSize_14)
            .maxLength(300)
            .width('100%')
            .height(200)
            .backgroundColor(Color.White)
            .padding(0)
            .borderRadius(0)
          Text(this.feedbackText.length + '/300')
            .fontColor(CommonConfig.hintTextColor)
            .fontWeight(CommonConfig.fontWeight_400)
            .fontSize(CommonConfig.fontSize_11)

        }
        .alignItems(HorizontalAlign.End)
        .width('100%')
        .padding(12)
        .borderRadius(12)
        .backgroundColor(Color.White)
        .margin({ bottom: 12 })

        Scroll() {
          Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.px(30), cross: LengthMetrics.px(30) } }) {
            ForEach(this.imageUris, (item: string) => {
              Image(item)
                .width(77)
                .height(77)
                .borderRadius(12)
            }, (item: string) => item)
            Column() {
              Image($r('app.media.Frame_image'))
                .width(24)
                .height(24)
                .margin({ bottom: 10 })
              Text(Languages.addImage[this.languages])
                .fontColor(CommonConfig.hintTextColor)
                .fontSize(CommonConfig.fontSize_11)
                .fontWeight(CommonConfig.fontWeight_400)
            }
            .width(77)
            .height(77)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .padding(12)
            .onClick(() => this.uploadImage())
          }
        }
        .layoutWeight(1)
        .margin({ bottom: 12 })
        .align(Alignment.TopStart)

        Blank()
        Text(Languages.submit[this.languages])
          .width('100%')
          .padding(12)
          .borderRadius(12)
          .textAlign(TextAlign.Center)
          .fontSize(CommonConfig.fontSize_16)
          .fontWeight(CommonConfig.fontWeight_400)
          .fontColor(Color.White)
          .backgroundColor(this.paletteTheme)
          .onClick(() => {
            if (!(this.userLoginInfo && this.mouseconfig)) {
              return
            }
            if (!(this.feedbackText)) {
              this.getUIContext().getPromptAction().showToast({
                message: ('意见反馈需要描述你遇到的问题')
              });
              return
            }
            this.dstPath_imgs = []
            let parmas: feedbackAdd_Params = {
              content: JSON.stringify({
                "remark": this.feedbackText,
                "imgs": this.dstPath_imgs
              }),
              memberId: this.userLoginInfo.id,
              phone: this.userLoginInfo.account,
              productName: this.mouseconfig.productType.toString(),
              serialNo: this.mouseconfig.sn,
              title: 'AI用户反馈'
            }
            if (this.imageUris.length) {
              // 1. 创建上传器
              const uploader = new ImageUploader(this.getUIContext().getHostContext() as common.UIAbilityContext, {
                uploadToken: 'miclink'
              });
              // 2. 上传单张图片
              // const result = await uploader.uploadImage('/沙箱路径/image.jpg');

              // 3. 批量上传图片
              uploader.uploadImages(this.dstPath, (current, total, filePath) => {
                console.log(`上传进度: ${current}/${total}`);
              }).then((results) => {

                parmas.content = JSON.stringify({
                  "remark": this.feedbackText,
                  "imgs": this.dstPath_imgs
                })
                // 上传成功,上传反馈问题
                _feedbackAdd(parmas).then((res:AxiosResponse<feedbackAddy_Response<string>>) => {
                  console.log("问题上传反馈:", JSON.stringify(res.data))
                  if (res.data.statusCode===200) {
                    this.feedbackText = ''
                    this.imageUris = []
                    this.getUIContext().getPromptAction().showToast({
                      message: ('反馈意见已上传')
                    });
                  }else {
                    console.log('问题反馈失败：',res.data.statusCode)
                    this.getUIContext().getPromptAction().showToast({
                      message: (res.data.message)
                    });
                  }
                })
              })

            } else {
              /**
               * 没有图片，直接上传问题
               */
              _feedbackAdd(parmas).then((res:AxiosResponse<feedbackAddy_Response<string>>) => {
                console.log("问题上传反馈:", JSON.stringify(res.data))
                if (res.data.statusCode===200) {
                  this.feedbackText = ''
                  this.imageUris = []
                  this.getUIContext().getPromptAction().showToast({
                    message: ('反馈意见已上传')
                  });
                }else {
                  console.log('问题反馈失败：',res.data.statusCode)
                  this.getUIContext().getPromptAction().showToast({
                    message: (res.data.message)
                  });
                }
              })
            }

          })
      }
      .height('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .padding({ left: 16, right: 16, })
    .backgroundColor(CommonConfig.commonBackgroundColor)
    .hideTitleBar(true)
    .hideToolBar(true)
  }

  uploadImage() {
    this.fileSelect().then((uri: string[]) => {
      const allUris = [...this.imageUris, ...uri || []]
      const uniqueUris = Array.from(new Set(allUris));
      this.imageUris = uniqueUris;
      this.dstPath = [...uniqueUris];
      console.warn('图片长度：' + this.imageUris.length, JSON.stringify(this.imageUris))
      this.imageUris.forEach((item, index) => {
        this.savePhotoToSandbox(this.getUIContext().getHostContext() as common.UIAbilityContext, item, index)
      })

      // this.imageUris.forEach((item: string) => {
      //   savePhotoToSandbox(AppStorage.get('context') as common.UIAbilityContext, item)
      // })
    });

  }

  //从相册选择图片
  async fileSelect(): Promise<string[]> {
    let photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    photoSelectOptions.maxSelectNumber = 15;
    // photoSelectOptions.isPhotoTakingSupported = false; // 隐藏拍照功能
    let photoPicker = new photoAccessHelper.PhotoViewPicker();
    try {
      let photoSelectResult = await photoPicker.select(photoSelectOptions);
      if (photoSelectResult && photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
        return photoSelectResult.photoUris;
      } else {
        return [];
      }
    } catch (err) {
      console.log('失败')
      return [];
    }
  }

  savePhotoToSandbox(context: Context, fileUri: string, index: number) {
    // 获取应用的沙箱路径
    let cacheDir = context.cacheDir;
    // 获取到文件名
    let imgName = fileUri.split('/').pop() as string
    // this.imgNames.push(imgName);
    // 图片保存到沙箱中的目标路径
    let dstPath = cacheDir + '/' + imgName;
    console.log('你好你好', dstPath)
    this.dstPath.splice(index, 1, dstPath)
    console.warn("你好你好", JSON.stringify(this.imageUris))
    // fileIo.openSync: 以同步的方式打开文件
    // srcFile.fd 获取文件描述符
    let srcFile = fileIo.openSync(fileUri); // 以只读方式打开

    // fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE
    // 如果没有该文件，则创建并打开，如果有，以可读可写的方式打开
    let dstFile = fileIo.openSync(dstPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
    // 把源文件复制到沙箱中的目标文件
    fileIo.copyFileSync(srcFile.fd, dstFile.fd);
    fileIo.closeSync(srcFile);
    fileIo.closeSync(dstFile);
    console.log('已经把图片放入沙箱,可以开始上传了')
  }
}

