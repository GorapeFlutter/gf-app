#ifndef FLUTTER_LINUX_NATIVE_KEYS_H_
#define FLUTTER_LINUX_NATIVE_KEYS_H_

#include <flutter_linux/flutter_linux.h>

void RegisterLinuxNativeKeyChannels(FlBinaryMessenger* messenger,
                                   FlMethodChannel** device_channel);

#endif  // FLUTTER_LINUX_NATIVE_KEYS_H_
