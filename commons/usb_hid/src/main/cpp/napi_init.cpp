#include "napi/native_api.h"
#include <cstdint>
#include <cstdio>
#include <cstring> // 添加 memcpy 头文件
#include <hid/hid_ddk_api.h>
#include <hid/hid_ddk_types.h>

// 全局变量
static Hid_DeviceHandle *g_dev = NULL;
static Hid_DeviceHandle *g_devFeature = NULL;
static napi_value NAPI_Global_initddk(napi_env env, napi_callback_info info) {
    // TODO: implements the code;
    // 初始化HID DDK
    int32_t result = OH_Hid_Init();

    napi_value retValue;
    napi_create_int32(env, result, &retValue);
    return retValue;
}
static napi_value NAPI_Global_open(napi_env env, napi_callback_info info) {
    // TODO: implements the code;
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2) {
        napi_throw_error(env, nullptr, "Wrong number of arguments");
        return nullptr;
    }

    // 获取参数 - 使用 int64 然后转换为 uint64
    int64_t deviceIdInt64;
    uint32_t interfaceIndex;

    napi_status status = napi_get_value_int64(env, args[0], &deviceIdInt64);
    if (status != napi_ok) {
        napi_throw_error(env, nullptr, "Failed to get deviceId");
        return nullptr;
    }

    status = napi_get_value_uint32(env, args[1], &interfaceIndex);
    if (status != napi_ok) {
        napi_throw_error(env, nullptr, "Failed to get interfaceIndex");
        return nullptr;
    }

    // 将 int64 转换为 uint64
    uint64_t deviceId = static_cast<uint64_t>(deviceIdInt64);

    // 打开设备
    int32_t result = OH_Hid_Open(deviceId, static_cast<uint8_t>(interfaceIndex), &g_dev);

    napi_value retValue;
    napi_create_int32(env, result, &retValue);
    return retValue;
}
static napi_value NAPI_Global_sendReport(napi_env env, napi_callback_info info) {
    // TODO: implements the code;
    size_t argc = 3;
    napi_value args[3];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 3) {
        napi_throw_error(env, nullptr, "Wrong number of arguments");
        return nullptr;
    }

    // 获取参数
    int32_t reportType;
    napi_get_value_int32(env, args[0], &reportType);

    // 获取数据数组
    uint8_t *data = nullptr;
    size_t dataLength;
    napi_get_arraybuffer_info(env, args[1], (void **)&data, &dataLength);

    uint32_t length;
    napi_get_value_uint32(env, args[2], &length);

    // 检查数据长度是否足够
    if (dataLength < length) {
        napi_throw_error(env, nullptr, "ArrayBuffer too small");
        return nullptr;
    }

    // 发送报告
    int32_t result = OH_Hid_SendReport(g_dev, static_cast<Hid_ReportType>(reportType), data, length);

    napi_value retValue;
    napi_create_int32(env, result, &retValue);
    return retValue;
}
static napi_value NAPI_Global_read(napi_env env, napi_callback_info info) {
    // TODO: implements the code;
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "Wrong number of arguments");
        return nullptr;
    }

    uint32_t bufSize;
    int32_t timeout = -1; // 默认阻塞模式

    napi_get_value_uint32(env, args[0], &bufSize);
    if (argc > 1) {
        napi_get_value_int32(env, args[1], &timeout);
    }

    uint8_t *data = new uint8_t[bufSize];
    uint32_t bytesRead = 0;
    int32_t result;

    if (timeout < 0) {
        // 阻塞读取
        result = OH_Hid_Read(g_dev, data, bufSize, &bytesRead);
    } else {
        // 超时读取
        result = OH_Hid_ReadTimeout(g_dev, data, bufSize, timeout, &bytesRead);
    }

    // 创建返回的ArrayBuffer
    napi_value arraybuffer;
    void *arraybufferData;
    napi_create_arraybuffer(env, bytesRead, &arraybufferData, &arraybuffer);

    // 复制数据到ArrayBuffer
    if (bytesRead > 0) {
        memcpy(arraybufferData, data, bytesRead); // 现在 memcpy 可用
    }
    delete[] data;

    napi_value retObj;
    napi_create_object(env, &retObj);

    napi_value resultValue;
    napi_create_int32(env, result, &resultValue);
    napi_set_named_property(env, retObj, "result", resultValue);

    napi_value bytesReadValue;
    napi_create_uint32(env, bytesRead, &bytesReadValue);
    napi_set_named_property(env, retObj, "bytesRead", bytesReadValue);

    napi_set_named_property(env, retObj, "data", arraybuffer);

    return retObj;
}
static napi_value NAPI_Global_closeHidDevice(napi_env env, napi_callback_info info) {
    // TODO: implements the code;
    int32_t result1 = 0;
    int32_t result2 = 0;
    int32_t result3 = 0;

    if (g_dev) {
        result1 = OH_Hid_Close(&g_dev);
        g_dev = NULL;
    }

    if (g_devFeature) {
        result2 = OH_Hid_Close(&g_devFeature);
        g_devFeature = NULL;
    }

    result3 = OH_Hid_Release();

    napi_value retValue;
    napi_create_int32(env, result1 + result2 + result3, &retValue);
    return retValue;
}
static napi_value NAPI_Global_add(napi_env env, napi_callback_info info) {
    // TODO: implements the code;
    napi_value retValue;
    napi_create_int32(env, 100, &retValue);
    return retValue;
}
EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        {"initddk", nullptr, NAPI_Global_initddk, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"open", nullptr, NAPI_Global_open, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"sendReport", nullptr, NAPI_Global_sendReport, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"read", nullptr, NAPI_Global_read, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"closeHidDevice", nullptr, NAPI_Global_closeHidDevice, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"add", nullptr, NAPI_Global_add, nullptr, nullptr, nullptr, napi_default, nullptr}};
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "usb_hid",
    .nm_priv = ((void *)0),
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterUsb_hidModule(void) { napi_module_register(&demoModule); }
