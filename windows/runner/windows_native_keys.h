#ifndef RUNNER_WINDOWS_NATIVE_KEYS_H_
#define RUNNER_WINDOWS_NATIVE_KEYS_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>

void RegisterWindowsNativeKeyChannels(
    flutter::BinaryMessenger* messenger,
    std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>* device_channel);

#endif  // RUNNER_WINDOWS_NATIVE_KEYS_H_
