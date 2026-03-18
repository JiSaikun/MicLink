import * as wxopensdk from '@tencent/wechat_open_sdk';
import { AppConstants } from 'config';

export type OnWXReq = (req: wxopensdk.BaseReq) => void

export type OnWXResp = (resp: wxopensdk.BaseResp) => void

const kTag = "WXApiEventHandlerImpl"

class WXApiEventHandlerImpl implements wxopensdk.WXApiEventHandler {
  private onReqCallbacks: Map<OnWXReq, OnWXReq> = new Map
  private onRespCallbacks: Map<OnWXResp, OnWXResp> = new Map

  registerOnWXReqCallback(on: OnWXReq) {
    this.onReqCallbacks.set(on, on)
  }

  unregisterOnWXReqCallback(on: OnWXReq) {
    this.onReqCallbacks.delete(on)
  }

  registerOnWXRespCallback(on: OnWXResp) {
    this.onRespCallbacks.set(on, on)
  }

  unregisterOnWXRespCallback(on: OnWXResp) {
    this.onRespCallbacks.delete(on)
  }

  onReq(req: wxopensdk.BaseReq): void {
    wxopensdk.Log.i(kTag, "onReq:%s", JSON.stringify(req))
    this.onReqCallbacks.forEach((on) => {
      on(req)
    })
  }

  onResp(resp: wxopensdk.BaseResp): void {
    wxopensdk.Log.i(kTag, "onResp:%s", JSON.stringify(resp))
    this.onRespCallbacks.forEach((on) => {
      on(resp)
    })
  }
}

// WXApi 是第三方app和微信通信的openApi接口，其实例通过WXAPIFactory获取，需要传入应用申请到的AppID（指的是移动应用Appid，不要填小程序Appid！！！
export const WXApi: wxopensdk.WXApi =
  wxopensdk.WXAPIFactory.createWXAPI(AppConstants.APP_ID)

export const WXEventHandler: WXApiEventHandlerImpl = new WXApiEventHandlerImpl
