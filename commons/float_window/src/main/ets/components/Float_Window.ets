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
  static isCreating: boolean = false //防止并发创建窗口

  static creat(windowName = 'pages/Overlay', float_window_width = 1100, float_window_height = 300) {
    // 检查是否正在创建中，防止并发创建
    if (Float_Window.isCreating) {
      console.warn('Window creation already in progress, skipping duplicate creation');
      return;
    }

    // 先关闭已存在的主悬浮窗，再创建新的
    if (Float_Window.windowClass) {
      console.info('Main float window already exists, destroying before creating new one');
      Float_Window.destroyWindow(Float_Window.windowClass);
      Float_Window.windowClass = null;
    }

    // 设置创建锁
    Float_Window.isCreating = true;

    // 1.创建悬浮窗。
    let windowClass: window.Window | null = null;
    let config: window.Configuration = {
      name: "floatWindow", windowType: window.WindowType.TYPE_FLOAT, ctx: AppStorage.get('context')
    };
    window.createWindow(config, (err: BusinessError, data) => {
      let errCode: number = err.code;
      if (errCode) {
        console.error('Failed to create the floatWindow. Cause: ' + JSON.stringify(err));
        Float_Window.isCreating = false; // 释放创建锁
        return;
      }
      console.info('Succeeded in creating the floatWindow. Data: ' + JSON.stringify(data));
      windowClass = data;
      Float_Window.windowClass = windowClass
      Float_Window.windowClass?.setWindowFocusable(false);
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
      Float_Window.loadUIContentWithRetry(windowClass, windowName, 3, 200);
    });
  }

  static creat_VoiceTranslation(windowName = 'pages/VoiceTranslation', float_window_width = 1100,
    float_window_height = Float_Window.screen_height / 2) {
    // 检查是否正在创建中，防止并发创建
    if (Float_Window.isCreating) {
      console.warn('Window creation already in progress, skipping duplicate creation');
      return;
    }

    // 先关闭已存在的语音翻译悬浮窗，再创建新的
    if (Float_Window.window_VoiceTranslation) {
      console.info('Voice translation window already exists, destroying before creating new one');
      Float_Window.destroyWindow(Float_Window.window_VoiceTranslation);
      Float_Window.window_VoiceTranslation = null;
    }

    // 设置创建锁
    Float_Window.isCreating = true;

    // 1.创建悬浮窗。
    let windowClass: window.Window | null = null;
    let config: window.Configuration = {
      name: "floatWindow_VoiceTranslation", windowType: window.WindowType.TYPE_FLOAT, ctx: AppStorage.get('context')
    };
    window.createWindow(config, (err: BusinessError, data) => {
      let errCode: number = err.code;
      if (errCode) {
        console.error('Failed to create the floatWindow. Cause: ' + JSON.stringify(err));
        Float_Window.isCreating = false; // 释放创建锁
        return;
      }
      console.info('Succeeded in creating the floatWindow. Data: ' + JSON.stringify(data));
      windowClass = data;
      Float_Window.window_VoiceTranslation = windowClass
      Float_Window.windowClass?.setWindowFocusable(false);
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
      Float_Window.loadUIContentWithRetry(windowClass, windowName, 5, 300);
    });
  }

  static creat_hide(windowName = 'pages/FloatingWindow', float_window_width = 130, float_window_height = 130) {
    // 检查是否正在创建中，防止并发创建
    if (Float_Window.isCreating) {
      console.warn('Window creation already in progress, skipping duplicate creation');
      return;
    }

    // 先关闭已存在的隐藏悬浮窗，再创建新的
    if (Float_Window.window_hide) {
      console.info('Hide window already exists, destroying before creating new one');
      Float_Window.destroyWindow(Float_Window.window_hide);
      Float_Window.window_hide = null;
    }

    // 设置创建锁
    Float_Window.isCreating = true;

    // 1.创建悬浮窗。
    let windowClass: window.Window | null = null;
    let config: window.Configuration = {
      name: "floatWindow_hide", windowType: window.WindowType.TYPE_FLOAT, ctx: AppStorage.get('context')
    };
    window.createWindow(config, (err: BusinessError, data) => {
      let errCode: number = err.code;
      if (errCode) {
        console.error('Failed to create the floatWindow. Cause: ' + JSON.stringify(err));
        Float_Window.isCreating = false; // 释放创建锁
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
          console.error(`Failed to load the content for ${windowName}. Error code: ${errCode}, message: ${err.message}`);
          // 如果是timeout错误，尝试重试一次
          if (errCode === 1003 || err.message?.includes('timeout')) {
            console.info('UIContent timeout detected, attempting retry after delay');
            setTimeout(() => {
              windowClass?.setUIContent(windowName, (retryErr: BusinessError) => {
                if (retryErr.code) {
                  console.error(`Retry failed to load content for ${windowName}: ${JSON.stringify(retryErr)}`);
                  Float_Window.isCreating = false; // 重试失败，释放创建锁
                  return;
                }
                console.info('Retry succeeded in loading the content.');
                // 显示悬浮窗
                (windowClass as window.Window).showWindow((showErr: BusinessError) => {
                  if (showErr.code) {
                    console.error('Failed to show window after retry: ' + JSON.stringify(showErr));
                    Float_Window.isCreating = false; // 显示失败，释放创建锁
                    return;
                  }
                  console.info('Succeeded in showing window after retry.');
                  Float_Window.isCreating = false; // 显示成功，释放创建锁
                });
              });
            }, 100);
          } else {
            Float_Window.isCreating = false; // 非超时错误，释放创建锁
          }
          return;
        }
        console.info('Succeeded in loading the content.');
        // 3.显示悬浮窗。
        (windowClass as window.Window).showWindow((err: BusinessError) => {
          let errCode: number = err.code;
          if (errCode) {
            console.error('Failed to show the window. Cause: ' + JSON.stringify(err));
            Float_Window.isCreating = false; // 显示失败，释放创建锁
            return;
          }
          console.info('Succeeded in showing the window.');
          Float_Window.isCreating = false; // 显示成功，释放创建锁
        });
      });
      windowClass.setWindowCornerRadius(1000)
    });
  }

  static destroyWindow(windowClass: window.Window | null = Float_Window.windowClass) {
    // 检查窗口是否存在
    if (!windowClass) {
      console.log('Window is null, no need to destroy');
      return;
    }

    // 4.销毁悬浮窗。当不再需要悬浮窗时，可根据具体实现逻辑，使用destroy对其进行销毁。
    windowClass.destroyWindow((err: BusinessError) => {
      let errCode: number = err.code;
      if (errCode) {
        console.error('Failed to destroy the window. Cause: ' + JSON.stringify(err));
        return;
      }
      console.info('Succeeded in destroying the window.');
      // 重置窗口状态
      if (windowClass === Float_Window.windowClass) {
        Float_Window.windowClass = null;
        Float_Window.showVoiceInput = 0;
      } else if (windowClass === Float_Window.window_VoiceTranslation) {
        Float_Window.window_VoiceTranslation = null;
        Float_Window.showVoiceTranslation = false;
      } else if (windowClass === Float_Window.window_hide) {
        Float_Window.window_hide = null;
      }
    });
  }

  static minimize_float_window(windowClass: window.Window | null = Float_Window.windowClass) {
    // 检查窗口是否存在
    if (!windowClass) {
      console.log('Window is null, no need to minimize/destroy');
      return;
    }

    // 销毁悬浮窗（实际上是销毁而不是最小化）
    windowClass.destroyWindow((err: BusinessError) => {
      let errCode: number = err.code;
      if (errCode) {
        console.error('Failed to destroy the window. Cause: ' + JSON.stringify(err));
        return;
      }
      console.info('Succeeded in destroying the window.');
      // 重置窗口状态
      if (windowClass === Float_Window.windowClass) {
        Float_Window.windowClass = null;
        Float_Window.showVoiceInput = 0;
      } else if (windowClass === Float_Window.window_VoiceTranslation) {
        Float_Window.window_VoiceTranslation = null;
        Float_Window.showVoiceTranslation = false;
      } else if (windowClass === Float_Window.window_hide) {
        Float_Window.window_hide = null;
      }
    });
  }

  static show_float_window(windowClass: window.Window | null = Float_Window.windowClass) {
    // 检查窗口是否存在
    if (!windowClass) {
      console.log('Window is null, cannot show');
      return;
    }

    windowClass.show((err: BusinessError) => {
      const errCode: number = err.code;
      if (errCode) {
        console.error(`Failed to show the window. Cause code: ${err.code}, message: ${err.message}`);
        return;
      }
      console.info('Succeeded in showing the window.');
    });
  }

  // 增强的UI内容加载方法，带重试和超时处理
  private static loadUIContentWithRetry(windowClass: window.Window, windowName: string, maxRetries: number, baseDelay: number) {
    let retryCount = 0;

    const attemptLoad = () => {
      retryCount++;
      console.log(`Attempting to load UI content for ${windowName}, attempt ${retryCount}/${maxRetries + 1}`);

      windowClass.setUIContent(windowName, (err: BusinessError) => {
        const errCode: number = err.code;
        if (errCode) {
          console.error(`Failed to load content for ${windowName}. Error code: ${errCode}, message: ${err.message}`);

          // 检查是否是超时错误且还有重试次数
          const isTimeoutError = errCode === 1003 || err.message?.includes('timeout') || err.message?.includes('SetUIContent timeout');
          const shouldRetry = isTimeoutError && retryCount <= maxRetries;

          if (shouldRetry) {
            // 指数退避重试策略
            const delay = baseDelay * Math.pow(2, retryCount - 1);
            console.info(`UIContent timeout detected, retrying in ${delay}ms (attempt ${retryCount}/${maxRetries + 1})`);

            setTimeout(() => {
              attemptLoad();
            }, delay);
          } else {
            // 重试失败或非超时错误
            console.error(`Failed to load UI content after ${retryCount} attempts`);
            Float_Window.isCreating = false; // 释放创建锁
          }
          return;
        }

        console.info('Succeeded in loading the content.');
        // 显示悬浮窗
        (windowClass as window.Window).showWindow((showErr: BusinessError) => {
          const showErrCode: number = showErr.code;
          if (showErrCode) {
            console.error('Failed to show the window after content load: ' + JSON.stringify(showErr));
            Float_Window.isCreating = false; // 释放创建锁
            return;
          }
          console.info('Succeeded in showing the window.');
          Float_Window.isCreating = false; // 释放创建锁
        });
      });
    };

    // 开始首次尝试
    attemptLoad();
  }
}