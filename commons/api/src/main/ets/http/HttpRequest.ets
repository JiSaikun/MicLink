import instance from "./Config";

/**
 * 基础参数标记接口
 * 仅作为类型标记，不包含任何索引签名
 */
export interface BaseParams {
  // 空接口，用于类型标记
}

/**
 * 统一 API 响应类型
 */
interface ApiResponse<T> {
  statusCode?: number;
  status?: number;
  data: T | null;
  message: string;
}

/**
 * HTTP请求封装类
 * 完全符合ArkTS规范，不使用任何索引签名
 */
class HttpRequest {
  /**
   * GET请求
   * @param url 请求地址
   * @param params 查询参数（必须是实现BaseParams的具体类型）
   */
  get<TData, TParams extends BaseParams>(url: string, params?: TParams): Promise<ApiResponse<TData>> {
    return instance.get<TData, ApiResponse<TData>>(url, { params });
  }

  /**
   * POST请求 - 参数放query
   * @param url 请求地址
   * @param params 查询参数（必须是实现BaseParams的具体类型）
   */
  post<TData, TParams extends BaseParams>(url: string, params?: TParams): Promise<ApiResponse<TData>> {
    return instance.post<TData, ApiResponse<TData>>(url, null, { params });
  }

  /**
   * DELETE请求
   * @param url 请求地址
   * @param params 查询参数（必须是实现BaseParams的具体类型）
   */
  delete<TData, TParams extends BaseParams>(url: string, params?: TParams): Promise<ApiResponse<TData>> {
    return instance.delete<TData, ApiResponse<TData>>(url, { params });
  }

  /**
   * PUT请求
   * @param url 请求地址
   * @param params 查询参数（必须是实现BaseParams的具体类型）
   */
  put<TData, TParams extends BaseParams>(url: string, params?: TParams): Promise<ApiResponse<TData>> {
    return instance.put<TData, ApiResponse<TData>>(url, null, { params });
  }
}

export const http = new HttpRequest();
