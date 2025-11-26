// import需要的模块
import { call, observer } from '@kit.TelephonyKit';
import { BusinessError } from '@kit.BasicServicesKit';
export function Call_PHONE(code:string){
  // 调用查询能力接口
  let isSupport = call.hasVoiceCapability();
  if (isSupport) {
    // 如果设备支持呼叫能力，则继续跳转到拨号界面，并显示拨号的号码
    // 从API15开始支持tel格式电话号码，如："tel:13xxxx"
    call.makeCall(code, (err: BusinessError) => {
      if (!err) {
        console.info("make call success.");
      } else {
        console.error("make call fail, err is:" + JSON.stringify(err));
      }
    });
    // // 订阅通话业务状态变化（可选）
    // class SlotId {slotId: number = 0}
    // class CallStateCallback {
    //   state: call.CallState = call.CallState.CALL_STATE_UNKNOWN;
    //   number: string = "";
    // }
    // let slotId: SlotId = {slotId: 0}
    // observer.on("callStateChange", slotId, (data: CallStateCallback) => {
    //   console.info("call state change, data is:" + JSON.stringify(data));
    // });
  }
}