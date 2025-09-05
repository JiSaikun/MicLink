#include "napi/native_api.h"
#include <cstdio>
#include <hid/hid_ddk_api.h>
#include <hid/hid_ddk_types.h>

static napi_value NAPI_Global_initddk(napi_env env, napi_callback_info info) {
    // 初始化HID DDK
    int32_t OH_Hid_Init(void);
    /**
     * 打开设备 (OH_Hid_Open)
     */
//    int32_t OH_Hid_Open(targetDeviceId, targetInterfaceIndex,&devHandle); // 成功后，devHandle
    int32_t OH_Hid_Open(uint64_t deviceId, uint8_t interfaceIndex, Hid_DeviceHandle * *dev);  //    指向一个有效的设备句柄，用于后续所有操作
    /**
     * 设置设备读取模式为非阻塞
     * @param dev
     * @param nonBlock
     * @return
     */
    int32_t OH_Hid_SetNonBlocking(Hid_DeviceHandle * dev, int nonBlock);
    /**
     * 从设备读取报告，默认为阻塞模式（阻塞等待直到有数据可读取），可以调用OH_Hid_SetNonBlocking改变模式。
     * @param dev
     * @param data
     * @param bufSize
     * @param bytesRead
     * @return
     */
    int32_t OH_Hid_Read(Hid_DeviceHandle *dev, uint8_t *data, uint32_t bufSize, uint32_t *bytesRead);
    /**
     * 获取设备报告描述符。
     * @param dev
     * @param buf
     * @param bufSize
     * @param bytesRead
     * @return
     */
    int32_t OH_Hid_GetReportDescriptor(Hid_DeviceHandle *dev, uint8_t *buf, uint32_t bufSize, uint32_t *bytesRead);
    /**
     * 关闭设备————通信完成后，关闭设备释放资源。
     * @param dev
     * @return
     */
//    int32_t OH_Hid_Close(Hid_DeviceHandle **dev);
    /**
     * 释放HID DDK————在所有设备都关闭后，最后调用此函数，释放HID DDK库占用的所有资源。
     * @param 
     * @return
     */
//    int32_t OH_Hid_Release(void);
    napi_value sum;
    napi_create_double(env, 100000, &sum);
    return sum;
}
static napi_value NAPI_Global_readHidData(napi_env env, napi_callback_info info)
{
    // TODO: implements the code;
}
EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
//        {"add", nullptr, Add, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"initddk", nullptr, NAPI_Global_initddk, nullptr, nullptr, nullptr, napi_default, nullptr},
{ "readHidData", nullptr, NAPI_Global_readHidData, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "hid_usb",
    .nm_priv = ((void *)0),
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterHid_usbModule(void) { napi_module_register(&demoModule); }
