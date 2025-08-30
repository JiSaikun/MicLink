import instance from "./Config";

interface ApiResponse<T> { //根据项目实际项目修改
  code?: number;
  data: T | null;
  message?: string;
}

// 封装请求方法
class HttpRequest {
  get<T>(url: string, params?: object): Promise<ApiResponse<T>> {
    return instance.get<T, ApiResponse<T>>(url, { params })
  }

  // 封装post方法
  post<T>(url: string, data?: object): Promise<ApiResponse<T>> {
    return instance.post<T, ApiResponse<T>>(url, data)
  }

  // 封装delete方法
  delete<T>(url: string, data?: object): Promise<ApiResponse<T>> {
    return instance.delete<T, ApiResponse<T>>(url, data)
  }

  // 封装put方法
  put<T>(url: string, data?: object): Promise<ApiResponse<T>> {
    return instance.put<T, ApiResponse<T>>(url, data)
  }
}

export const http = new HttpRequest();