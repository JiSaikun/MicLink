import { BaseParams } from 'api';


/**
 * 更新用户昵称
 */
export interface updateName_Params extends BaseParams {
  name: string //昵称
  token: string //令牌
}

/**
 * 商品列表
 */
export interface goods_Params extends BaseParams {
  type: string //商品类型
}

export interface goods_Response extends BaseParams {
  alipay: number
  createTime: number
  name: string
  wechat: number
  remark: string
  id: number
  ios: number
  type: string
  goodsSpecs: goodsSpecsItem[]
  status: number
}

export interface goodsSpecsItem extends BaseParams {
  unit: string
  createTime: Date
  goodsId: number
  price: number
  num: number
  name: string
  remark: string
  id: number
  originPrice: number
  goodsName: string
  priceShow: string
  status: number
}
/**
 * 下单
 */
export interface pay_Params extends BaseParams {
  goodsId: number //商品id
  goodsSpecsId: number //商品规格id
  goodsType:string//商品类型
  payType:string//支付方式
  token:string
}
export interface pay_Response extends BaseParams {
  orderId:string
  codeUrl:string
  orderStatus:string
}
/**
 * 查询订单状态
 */
export interface queryOrderStatus_Params extends BaseParams {
  orderNo: string //订单号
}

