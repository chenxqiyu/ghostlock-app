Set-Location $PSScriptRoot

# === ghostlock-app: 注入模式编译 (一个真正的 preload.so 共享库) ===
# 参考旧版 bian.ps1 (duchamp-root) 的注入方式:
#   - 用 -shared -fPIC 编成纯共享库 (无 PT_INTERP), 可被 LD_PRELOAD 注入
#   - 入口是 src/core/preload.c 的构造函数, 加载即跑完整 exploit
#   - 偏移表: src/kernels/offsets.h (仅 6.1.138-android14-11-g0c3d559bcd85-ab14529422, Xiaomi 14 Pro / shennong)
# 用法:
#   adb push build/shennong/bin/preload.so /data/local/tmp/
#   adb shell "LD_PRELOAD=/data/local/tmp/preload.so /system/bin/true"
# 注意: 不能再用 -fPIE -pie (那是可执行文件, linker 拒绝预加载).

$clang = "C:\Users\Administrator\AppData\Local\Android\Sdk\ndk\28.2.13676358\toolchains\llvm\prebuilt\windows-x86_64\bin\clang.exe"

New-Item -ItemType Directory -Force -Path "build\shennong\bin" | Out-Null

# 单引号字符串: 内层双引号作为字面量传给 clang, 使 offset.h 里的 #include "target.h" 合法
$TARGET_DEFINE = '-DTARGET_CONFIG_H="target.h"'
$srcs = @("src/core/main.c","src/core/preload.c","src/core/offsets_json.c","src/core/util.c","src/core/fops.c")

& "$clang" --target=aarch64-linux-android35 -shared -fPIC -O2 -g0 -Wall -Wextra `
  -Wno-unused-parameter -Wno-sign-compare -Wno-unused-function `
  -Isrc/core -Isrc/kernels $TARGET_DEFINE $srcs `
  -o build/shennong/bin/preload.so -pthread

if ($LASTEXITCODE -ne 0) {
  Write-Host "BUILD FAILED" -ForegroundColor Red
  exit 1
}

Get-FileHash build/shennong/bin/preload.so -Algorithm SHA256 | Format-List
Write-Host "BUILD OK: build\shennong\bin\preload.so (shared library, LD_PRELOAD injectable)" -ForegroundColor Green
