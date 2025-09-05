import { hilog } from '@kit.PerformanceAnalysisKit';
import testNapi from 'libusb_hid.so';

const DOMAIN = 0x0000;

export class Hid{
  // static Hid_init(){
  //   hilog.info(DOMAIN, 'testTag', 'Test NAPI 2 + 3 = %{public}d', testNapi.initddk());
  // }
  // static Hid_open(){
  //   hilog.info(DOMAIN, 'testTag', 'Test NAPI 2 + 3 = %{public}d', testNapi.open(111111,25554));
  // }
  // static Hid_sendReport(data:ArrayBuffer){
  //   hilog.info(DOMAIN, 'testTag', 'Test NAPI 2 + 3 = %{public}d', testNapi.sendReport(111111,data,25554));
  // }
  // static Hid_read(){
  //   hilog.info(DOMAIN, 'testTag', 'Test NAPI 2 + 3 = %{public}d', testNapi.read(111111));
  // }
  // static Hid_closeHidDevice(){
  //   hilog.info(DOMAIN, 'testTag', 'Test NAPI 2 + 3 = %{public}d', testNapi.closeHidDevice());
  // }
  static Hid_add():number{
    hilog.info(DOMAIN, 'testTag', 'Test NAPI 2 + 3 = %{public}d', testNapi.add());
    return testNapi.add()
  }

}