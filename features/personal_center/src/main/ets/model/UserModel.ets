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
  goodsType: string //商品类型
  payType: string //支付方式
  token: string
}

export interface pay_Response extends BaseParams {
  orderId: string
  codeUrl: string
  orderStatus: string
}

/**
 * 查询订单状态
 */
export interface queryOrderStatus_Params extends BaseParams {
  orderNo: string //订单号
}

/**
 * 订单列表
 */
export interface orderList_Params extends BaseParams {
  token: string
}

export interface orderList_Response extends BaseParams {
  id: number
  memberId: number
  orderNo: string
  goodsId: number
  goodsSpecsId: number
  goodsType: string
  goodsSnapchat: string
  status: string
  appid: string
  payType: string
  thirdOrderNo: string
  thirdTransactionId: string
  fee: number
  createDate: Date
  updateDate: Date
  receipt: null
}

export interface goodsSnapchatInfo extends BaseParams {
  "createTime": Date,
  "goodsId": number,
  "goodsName": string,
  "id": number,
  "name": string,
  "num": number,
  "originPrice": number,
  "price": number,
  "priceShow": string,
  "remark": string,
  "status": number,
  "unit": string
}
