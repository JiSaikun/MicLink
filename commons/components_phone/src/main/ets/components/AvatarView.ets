import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"
import { TopTitle } from "../common/TopTitle"
import { LengthMetrics } from "@kit.ArkUI"
import { updateAvatar, UserLoginInfo } from "common"
import { request } from "@kit.BasicServicesKit"
import { fileIo, fileUri } from "@kit.CoreFileKit"
import { photoAccessHelper } from "@kit.MediaLibraryKit"

@Builder
export function AvatarViewBuilder() {
  AvatarView()
}


@Component
struct AvatarView {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @Consume('pageInfo') pageInfo: NavPathStack
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State userLoginInfo: UserLoginInfo = AppStorage.get('userLoginInfo') as UserLoginInfo
  context = getContext(this)
  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: SelectImageMode({
      takeAPhoto: () => {
        this.takeAPhoto();
      },
      imageLibrary: () => {
        this.imageLibrary();
      },
      saveImage: () => {
        this.saveImage();
      },
      confirm: () => {
        this.onAccept();
      }
    }),
    cancel: this.exitApp,
    autoCancel: true,
    alignment: DialogAlignment.Bottom,
    offset: { dx: 0, dy: -20 },
    gridCount: 4,
    customStyle: false,
    cornerRadius: 16
  })

  takeAPhoto() {
    console.info('单击第一个按钮时回调');
    if (this.userLoginInfo?.token) {
      updateAvatar()
    }
  }

  imageLibrary() {
    console.info('单击第一个按钮时回调');
    if (this.userLoginInfo?.token) {
      updateAvatar()
    }
  }

  async saveImage() {
    console.info('保存头像到图库');

    // 设置沙箱路径
    let filePath = getContext().cacheDir + '/test' + Date.now() + '.png'
    // 创建下载任务
    const task = await request.downloadFile(getContext(), {
      // 设置图片的源地址
      url: this.userLoginInfo.avatar,
      // 设置图片存储路径
      filePath: filePath
    })
    // 监听下载任务
    async () => {
      // 保存图片的沙箱路径
      console.info(`转换后的路径为：${fileUri.getUriFromPath(filePath)}`)
      // 获取图片的沙箱路径
      filePath = fileUri.getUriFromPath(filePath)
      console.info(`filePath:${filePath}`)
      let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(this.context);
      try {
        // 指定待保存到媒体库的位于应用沙箱的图片uri
        let srcFileUri = filePath;
        let srcFileUris: Array<string> = [
          fileUri.getUriFromPath(srcFileUri)
        ];
        // 指定待保存照片的创建选项，包括文件后缀和照片类型，标题和照片子类型可选
        let photoCreationConfigs: Array<photoAccessHelper.PhotoCreationConfig> = [
          {
            fileNameExtension: 'png',
            photoType: photoAccessHelper.PhotoType.IMAGE,
          }
        ];
        // 基于弹窗授权的方式获取媒体库的目标uri
        let desFileUris: Array<string> =
          await phAccessHelper.showAssetsCreationDialog(srcFileUris, photoCreationConfigs);
        // 将来源于应用沙箱的照片内容写入媒体库的目标uri
        let desFile: fileIo.File =
          await fileIo.open(desFileUris[0], fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
        let srcFile: fileIo.File = await fileIo.open(srcFileUri, fileIo.OpenMode.READ_ONLY);
        await fileIo.copyFile(srcFile.fd, desFile.fd);
        fileIo.closeSync(srcFile);
        fileIo.closeSync(desFile);
        console.info('create asset by dialog successfully');
        // 删除沙箱中的图片
        fileIo.rmdirSync(filePath)
      } catch (err) {
        console.error(`failed to create asset by dialog successfully errCode is: ${err.code}, ${err.message}`);
      }
      console.info("Succeeded in creating PixelMap")
    }
  }

  onAccept() {
    console.info('取消');
  }

  // 在自定义组件即将析构销毁时将dialogController置空
  aboutToDisappear() {
    this.dialogController = null; // 将dialogController置空
  }

  exitApp() {
    console.info('单击空白区域中的回拨');
  }

  build() {
    NavDestination() {
      Row() {
        Image($r('app.media.page_back_icon'))
          .width(32)
          .height(32)
          .onClick(() => {
            this.pageInfo.pop()
          })
        Text(Languages.editProfile[this.languages])
          .fontWeight(CommonConfig.fontWeight_700)
          .fontSize(CommonConfig.fontSize_16)
          .fontColor(CommonConfig.hintTextColor_select)

        Image($r('app.media.Frame_2696'))
          .width(24)
          .height(24)
          .onClick(() => {
            this.dialogController?.open()
          })
      }
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')
      .padding({
        top: 6,
        bottom: 6,
        left: 16,
        right: 16
      })
      .margin({ left: 16, right: 16, bottom: 12 })

    }
    .backgroundColor(CommonConfig.commonBackgroundColor)
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}

@CustomDialog
@Component
struct SelectImageMode {
  // 若尝试在CustomDialog中传入多个其他的Controller，以实现在CustomDialog中打开另一个或另一些CustomDialog，那么此处需要将指向自己的controller放在所有controller的后面
  takeAPhoto: () => void = () => {
  }
  imageLibrary: () => void = () => {
  }
  saveImage: () => void = () => {
  }
  confirm: () => void = () => {
  }
  controller?: CustomDialogController;
  @StorageLink('languages') languages: string = 'ZH_CN'

  build() {
    Column() {
      Text('更换头像')
        .fontColor(CommonConfig.hintTextColor_select)
        .fontSize(CommonConfig.fontSize_16)
        .fontWeight(CommonConfig.fontWeight_400)
        .margin({ bottom: 16 })

      Text('拍照')
        .backgroundColor('#EAEAEA')
        .fontSize(CommonConfig.fontSize_16)
        .fontColor(CommonConfig.hintTextColor_select)
        .fontWeight(CommonConfig.fontWeight_400)
        .width('100%')
        .borderRadius(8)
        .textAlign(TextAlign.Center)
        .padding(12)
        .onClick(() => {
          this.takeAPhoto()
          this.controller?.close()
        })
      Text('从手机相册选择')
        .backgroundColor('#EAEAEA')
        .fontSize(CommonConfig.fontSize_16)
        .fontColor(CommonConfig.hintTextColor_select)
        .fontWeight(CommonConfig.fontWeight_400)
        .width('100%')
        .borderRadius(8)
        .textAlign(TextAlign.Center)
        .padding(12)
        .onClick(() => {
          this.imageLibrary()
          this.controller?.close()
        })
      Text('保存图片')
        .backgroundColor('#EAEAEA')
        .fontSize(CommonConfig.fontSize_16)
        .fontColor(CommonConfig.hintTextColor_select)
        .fontWeight(CommonConfig.fontWeight_400)
        .width('100%')
        .borderRadius(8)
        .textAlign(TextAlign.Center)
        .padding(12)
        .onClick(() => {
          this.saveImage()
          this.controller?.close()
        })
      Text('取消')
        .backgroundColor('#EAEAEA')
        .fontSize(CommonConfig.fontSize_16)
        .fontColor(CommonConfig.hintTextColor_select)
        .fontWeight(CommonConfig.fontWeight_400)
        .width('100%')
        .borderRadius(8)
        .textAlign(TextAlign.Center)
        .padding(12)
        .onClick(() => this.controller?.close())

    }
    .alignItems(HorizontalAlign.Center)
    .borderRadius(16)
    .padding(16)
  }
}