import axios, { InternalAxiosRequestConfig, AxiosResponse, AxiosError, AxiosInstance } from '@ohos/axios';
import { promptAction } from '@kit.ArkUI';
import { checkStatus } from './CheckStatus';
import { logger } from './Logger';

// 创建实例：移除 Content-Type: application/json 头
const instance: AxiosInstance = axios.create({
  baseURL: 'http://att.miclink.net',
  timeout: 100000,
  headers: {
    'Content-Language': 'zh_CN' // 仅保留语言头，删除 JSON 格式头
  },
});

// 请求拦截器（可选：如需添加 token，仍按原逻辑）
instance.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    logger.debug('发起请求：', JSON.stringify(config.url), JSON.stringify(config.params));
    // 示例：添加 token（如有需求）
    // const token = getToken(); // 需自行实现 token 获取逻辑
    // if (token) {
    //   config.headers['Authorization'] = `Bearer ${token}`;
    // }
    return config;
  },
  (error: AxiosError) => {
    promptAction.showToast({ message: '请求初始化失败' });
    return Promise.reject(error);
  }
);

// 响应拦截器：保持逻辑不变，但注意后端可能返回的状态码格式
instance.interceptors.response.use(
  (response: AxiosResponse) => {
    logger.debug('响应成功：', JSON.stringify(response), JSON.stringify(response.data));
    // 注意：后端可能返回的状态码字段是 code 而非 statusCode，需根据实际调整
    if (response.data.code === 200 || response.data.statusCode === 200) { // 兼容两种常见状态码字段
      return Promise.resolve(response.data);
    } else {
      promptAction.showToast({
        message: response.data.message || '请求失败，请稍后重试',
        duration: 2000,
        alignment: 4 // 鸿蒙 Alignment.Center 的枚举值为 4，避免直接引用可能的类型问题
      });
      return Promise.reject(response.data);
    }
  },
  (error: AxiosError) => {
    logger.error('响应报错：', JSON.stringify(error.message));
    // 超时/网络错误处理
    if (error.message.includes('timeout')) {
      promptAction.showToast({ message: '请求超时！请您稍后重试' });
    }
    if (error.message.includes('Network Error')) {
      promptAction.showToast({ message: '网络错误！请您稍后重试' });
    }
    // 服务器状态码处理
    const status = error.response?.status;
    if (status) {
      checkStatus(status);
    }
    return Promise.reject(error);
  }
);

export default instance;