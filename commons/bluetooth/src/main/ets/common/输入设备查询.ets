import { inputDevice } from '@kit.InputKit';

@Entry
@Component
struct Index {
  build() {
    RelativeContainer() {
      Text('asdbhjk')
        .onClick(() => {
          try {
            inputDevice.getDeviceList((error: Error, ids: Array<Number>) => {
              if (error) {
                console.error(`Failed to get device id list, error: ${JSON.stringify(error, [`code`, `message`])}`);
                return;
              }
              console.info(`Device id list: ${JSON.stringify(ids)}`);
              for (let item of ids){
                try {
                  let deviceData: inputDevice.InputDeviceData = inputDevice.getDeviceInfoSync(item as number);
                  console.info(`Device info: ${JSON.stringify(deviceData)}`);
                } catch (error) {
                  console.error(`Failed to get device info, error: ${JSON.stringify(error, [`code`, `message`])}`);
                }
              }
            });
          } catch (error) {
            console.error(`Failed to get device id list, error: ${JSON.stringify(error, [`code`, `message`])}`);
          }
        })
    }
  }
}