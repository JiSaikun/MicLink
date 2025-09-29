// import EntryAbility from "default/src/main/ets/entryability/EntryAbility";
import { BusinessError } from "@kit.BasicServicesKit";
import { display, window } from "@kit.ArkUI";

export class Float_Window {
  static screen_width = display.getDefaultDisplaySync().width
  static screen_height = display.getDefaultDisplaySync().height
  static windowClass: window.Window | null = null;
  static window_VoiceTranslation: window.Window | null = null;
  static window_hide: window.Window | null = null;
  static showVoiceInput: number = 0 //判断在窗口显示期间再次进行语音输入的话，不必在执行创建，打断60s窗口关闭的倒计时
  static showVoiceTranslation: boolean = false //判断语音翻译窗口是否已将打开

  static creat(windowName = 'pages/Overlay', float_window_width = 1100, float_window_height = 300) {
    // 1.创建悬浮窗。
    let windowClass: window.Window | null = null;
    let config: window.Configuration = {
      name: "floatWindow", windowType: window.WindowType.TYPE_FLOAT, ctx: AppStorage.get('context')
    };
    window.createWindow(config, (err: BusinessError, data) => {
      let errCode: number = err.code;
      if (errCode) {
        console.error('Failed to create the floatWindow. Cause: ' + JSON.stringify(err));
        return;
      }
      console.info('Succeeded in creating the floatWindow. Data: ' + JSON.stringify(data));
      windowClass = data;
      Float_Window.windowClass = windowClass
      // 2.悬浮窗窗口创建成功后，设置悬浮窗的位置、大小及相关属性等。
      windowClass.moveWindowTo(Float_Window.screen_width - float_window_width - 10,
        Float_Window.screen_height - float_window_height - 250, (err: BusinessError) => {
          let errCode: number = err.code;
          if (errCode) {
            console.error('Failed to move the window. Cause:' + JSON.stringify(err));
            return;
          }
          console.info('Succeeded in moving the window.');
        });
      windowClass.resize(float_window_width, float_window_height, (err: BusinessError) => {
        let errCode: number = err.code;
        if (errCode) {
          console.error('Failed to change the window size. Cause:' + JSON.stringify(err));
          return;
        }
        console.info('Succeeded in changing the window size.');
      });
      // 3.为悬浮窗加载对应的目标页面。
      windowClass.setUIContent(windowName, (err: BusinessError) => {
        let errCode: number = err.code;
        if (errCode) {
          console.error('Failed to load the content. Cause:' + JSON.stringify(err));
          return;
        }
        console.info('Succeeded in loading the content.');
        // 3.显示悬浮窗。
        (windowClass as window.Window).showWindow((err: BusinessError) => {
          let errCode: number = err.code;
          if (errCode) {
            console.error('Failed to show the window. Cause: ' + JSON.stringify(err));
            return;
          }
          console.info('Succeeded in showing the window.');
        });
      });
    });
  }

  static creat_VoiceTranslation(windowName = 'pages/VoiceTranslation', float_window_width = 1100,
    float_window_height = this.screen_height / 2) {
    // 1.创建悬浮窗。
    let windowClass: window.Window | null = null;
    let config: window.Configuration = {
      name: "floatWindow_VoiceTranslation", windowType: window.WindowType.TYPE_FLOAT, ctx: AppStorage.get('context')
    };
    window.createWindow(config, (err: BusinessError, data) => {
      let errCode: number = err.code;
      if (errCode) {
        console.error('Failed to create the floatWindow. Cause: ' + JSON.stringify(err));
        return;
      }
      console.info('Succeeded in creating the floatWindow. Data: ' + JSON.stringify(data));
      windowClass = data;
      Float_Window.window_VoiceTranslation = windowClass
      // 2.悬浮窗窗口创建成功后，设置悬浮窗的位置、大小及相关属性等。
      windowClass.moveWindowTo(Float_Window.screen_width - float_window_width - 10,
        Float_Window.screen_height - float_window_height - 250, (err: BusinessError) => {
          let errCode: number = err.code;
          if (errCode) {
            console.error('Failed to move the window. Cause:' + JSON.stringify(err));
            return;
          }
          console.info('Succeeded in moving the window.');
        });
      windowClass.resize(float_window_width, float_window_height, (err: BusinessError) => {
        let errCode: number = err.code;
        if (errCode) {
          console.error('Failed to change the window size. Cause:' + JSON.stringify(err));
          return;
        }
        console.info('Succeeded in changing the window size.');
      });
      // 3.为悬浮窗加载对应的目标页面。
      windowClass.setUIContent(windowName, (err: BusinessError) => {
        let errCode: number = err.code;
        if (errCode) {
          console.error('Failed to load the content. Cause:' + JSON.stringify(err));
          return;
        }
        console.info('Succeeded in loading the content.');
        // 3.显示悬浮窗。
        (windowClass as window.Window).showWindow((err: BusinessError) => {
          let errCode: number = err.code;
          if (errCode) {
            console.error('Failed to show the window. Cause: ' + JSON.stringify(err));
            return;
          }
          console.info('Succeeded in showing the window.');
        });
      });
    });
  }

  static creat_hide(windowName = 'pages/FloatingWindow', float_window_width = 130, float_window_height = 130) {
    // 1.创建悬浮窗。
    let windowClass: window.Window | null = null;
    let config: window.Configuration = {
      name: "floatWindow_hide", windowType: window.WindowType.TYPE_FLOAT, ctx: AppStorage.get('context')
    };
    window.createWindow(config, (err: BusinessError, data) => {
      let errCode: number = err.code;
      if (errCode) {
        console.error('Failed to create the floatWindow. Cause: ' + JSON.stringify(err));
        return;
      }
      console.info('Succeeded in creating the floatWindow. Data: ' + JSON.stringify(data));
      windowClass = data;
      Float_Window.window_hide = windowClass
      // 2.悬浮窗窗口创建成功后，设置悬浮窗的位置、大小及相关属性等。
      windowClass.moveWindowTo(Float_Window.screen_width - float_window_width,
        (Float_Window.screen_height - float_window_height) / 2, (err: BusinessError) => {
          let errCode: number = err.code;
          if (errCode) {
            console.error('Failed to move the window. Cause:' + JSON.stringify(err));
            return;
          }
          console.info('Succeeded in moving the window.');
        });
      windowClass.resize(float_window_width, float_window_height, (err: BusinessError) => {
        let errCode: number = err.code;
        if (errCode) {
          console.error('Failed to change the window size. Cause:' + JSON.stringify(err));
          return;
        }
        console.info('Succeeded in changing the window size.');
      });
      // 3.为悬浮窗加载对应的目标页面。
      windowClass.setUIContent(windowName, (err: BusinessError) => {
        let errCode: number = err.code;
        if (errCode) {
          console.error('Failed to load the content. Cause:' + JSON.stringify(err));
          return;
        }
        console.info('Succeeded in loading the content.');
        // 3.显示悬浮窗。
        (windowClass as window.Window).showWindow((err: BusinessError) => {
          let errCode: number = err.code;
          if (errCode) {
            console.error('Failed to show the window. Cause: ' + JSON.stringify(err));
            return;
          }
          console.info('Succeeded in showing the window.');
        });
      });
      windowClass.setWindowCornerRadius(1000)
    });
  }

  static destroyWindow(windowClass: window.Window | null = Float_Window.windowClass) {

    // 4.销毁悬浮窗。当不再需要悬浮窗时，可根据具体实现逻辑，使用destroy对其进行销毁。
    (windowClass as window.Window).destroyWindow((err: BusinessError) => {
      let errCode: number = err.code;
      if (errCode) {
        console.error('Failed to destroy the window. Cause: ' + JSON.stringify(err));
        return;
      }
      console.info('Succeeded in destroying the window.');
    });
  }

  static minimize_float_window(windowClass: window.Window | null = Float_Window.windowClass) {
    // 调用最小化方法
    (windowClass as window.Window).minimize((err: BusinessError) => {
      if (err) {
        console.error(`最小化窗口失败，错误码: ${err.code}, 信息: ${err.message}`);
        AppStorage.setOrCreate('voiceInputText', '')
        return;
      }
      console.info('窗口最小化成功');
      AppStorage.setOrCreate('voiceInputText', '')
    });
  }

  static show_float_window(windowClass: window.Window | null = Float_Window.windowClass) {
    (windowClass as window.Window).show((err: BusinessError) => {
      const errCode: number = err.code;
      if (errCode) {
        console.error(`Failed to show the window. Cause code: ${err.code}, message: ${err.message}`);
        return;
      }
      console.info('Succeeded in showing the window.');
    });
  }
}