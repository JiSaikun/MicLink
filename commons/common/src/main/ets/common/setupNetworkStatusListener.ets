import { connection } from '@kit.NetworkKit';

export function setupNetworkStatusListener() {
  // 创建监听器（关注所有网络类型）
  let netConnection = connection.createNetConnection();

  // 注册网络可用事件
  netConnection.on('netAvailable', (netHandle: connection.NetHandle) => {
    console.log("网络已连接，ID：" + netHandle.netId);
    AppStorage.setOrCreate('netAvailable',true)
    // 此处添加网络恢复后的业务逻辑
  });

  // 注册网络丢失事件
  netConnection.on('netLost', (netHandle: connection.NetHandle) => {
    console.log("网络已断开");
    AppStorage.setOrCreate('netAvailable',false)
    // 此处添加断网处理逻辑
  });

  // 启动监听
  netConnection.register((error) => {
    if (error) {
      console.error("监听失败：" + JSON.stringify(error));
    }
  });
}