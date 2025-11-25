import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"
import { TopTitle } from "../common/TopTitle"
import { LengthMetrics } from "@kit.ArkUI"
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { promptAction } from '@kit.ArkUI';
import { fileIo } from '@kit.CoreFileKit';
import { common } from "@kit.AbilityKit";

@Builder
export function UserFeedbackBuilder() {
  UserFeedback()
}


@Component
struct UserFeedback {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @Consume('pageInfo') pageInfo: NavPathStack
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State feedbackText: string = '你可以描述你遇到的问题'
  @State imageUris: string[] = []

  build() {
    NavDestination() {
      Column() {
        // TopTitle({ title: Languages.membershipPackage[this.languages], isback: false })
        TopTitle({ title: '用户反馈', isback: false })
          .margin({ bottom: 12 })
        Text('问题和意见')
          .fontSize(CommonConfig.fontSize_14)
          .fontWeight(CommonConfig.fontWeight_400)
          .fontColor(CommonConfig.hintTextColor)
          .margin({ bottom: 12 })
        Column() {
          TextArea({ text: $$this.feedbackText })
            .fontColor(CommonConfig.hintTextColor)
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
            Text('添加图片')
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

        Blank()
        Text('提交')
          .width('100%')
          .padding(12)
          .borderRadius(12)
          .textAlign(TextAlign.Center)
          .fontSize(CommonConfig.fontSize_16)
          .fontWeight(CommonConfig.fontWeight_400)
          .fontColor(Color.White)
          .backgroundColor(this.paletteTheme)
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
    fileSelect().then((uri: string[]) => {
      this.imageUris = uri || [];
      this.imageUris.forEach((item: string) => {
        savePhotoToSandbox(AppStorage.get('context') as common.UIAbilityContext, item)
      })
    });

  }
}


//从相册选择图片
async function fileSelect(): Promise<string[]> {
  let photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
  photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
  photoSelectOptions.maxSelectNumber = 9;
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

function savePhotoToSandbox(context: Context, fileUri: string) {
  // 获取应用的沙箱路径
  let cacheDir = context.cacheDir;
  // 获取到文件名
  let imgName = fileUri.split('/').pop() as string
  // this.imgNames.push(imgName);
  // 图片保存到沙箱中的目标路径
  let dstPath = cacheDir + '/' + imgName;

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

