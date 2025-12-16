import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"
import { TopTitle } from "../common/TopTitle"
import { LengthMetrics } from "@kit.ArkUI"
import { updateAvatar, UpdateAvatar_Camera, UserLoginInfo } from "common"
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
      UpdateAvatar_Camera()
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

    try {
      // 设置沙箱路径
      let filePath = getContext().cacheDir + '/test' + Date.now() + '.png';

      // 创建下载任务
      const task = await request.downloadFile(getContext(), {
        // 设置图片的源地址
        url: this.userLoginInfo.avatar,
        // 设置图片存储路径
        filePath: filePath
      });

      // 等待下载完成
      const result = await task;
      // if (result.code !== 0) {
      //   console.error(`下载失败: ${result.code}, ${result.message}`);
      //   return;
      // }

      console.info('下载成功，开始保存到媒体库');

      // 获取图片的沙箱路径对应的URI
      const srcFileUri = fileUri.getUriFromPath(filePath);
      console.info(`转换后的路径为：${srcFileUri}`);

      let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(getContext());

      // 指定待保存到媒体库的位于应用沙箱的图片uri
      let srcFileUris: Array<string> = [srcFileUri];

      // 指定待保存照片的创建选项
      let photoCreationConfigs: Array<photoAccessHelper.PhotoCreationConfig> = [
        {
          fileNameExtension: 'png',
          photoType: photoAccessHelper.PhotoType.IMAGE,
          // 可以添加标题
          title: 'avatar_' + Date.now()
        }
      ];

      // 基于弹窗授权的方式获取媒体库的目标uri
      let desFileUris: Array<string> = await phAccessHelper.showAssetsCreationDialog(
        srcFileUris,
        photoCreationConfigs
      );

      if (!desFileUris || desFileUris.length === 0) {
        console.info('用户取消了保存操作');
        // 删除临时文件
        fileIo.unlinkSync(filePath);
        return;
      }

      // 将来源于应用沙箱的照片内容写入媒体库的目标uri
      let desFile = await fileIo.open(
        desFileUris[0],
        fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE
      );

      let srcFile = await fileIo.open(srcFileUri, fileIo.OpenMode.READ_ONLY);
      await fileIo.copyFile(srcFile.fd, desFile.fd);

      fileIo.closeSync(srcFile);
      fileIo.closeSync(desFile);

      console.info('保存到媒体库成功');

      // 删除沙箱中的临时图片
      try {
        fileIo.unlinkSync(filePath);
        console.info('临时文件已删除');
      } catch (unlinkErr) {
        console.error(`删除临时文件失败: ${unlinkErr.message}`);
      }

    } catch (err) {
      console.error(`保存头像失败: ${err.code}, ${err.message}`);

      // // 确保出错时也尝试删除临时文件
      // if (filePath && await fileIo.access(filePath)) {
      //   try {
      //     fileIo.unlinkSync(filePath);
      //   } catch (cleanupErr) {
      //     console.error(`清理临时文件失败: ${cleanupErr.message}`);
      //   }
      // }
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

      Column() {
        Image(this.userLoginInfo?.avatar ? this.userLoginInfo.avatar : $r('app.media.avatar'))
          .width('100%')
      }
      .justifyContent(FlexAlign.Center)
      .layoutWeight(1)
      .width('100%')

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
    Column({ space: 8 }) {
      Text('更换头像')
        .fontColor(CommonConfig.hintTextColor_select)
        .fontSize(CommonConfig.fontSize_16)
        .fontWeight(CommonConfig.fontWeight_400)
        .margin({ bottom: 8 })

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