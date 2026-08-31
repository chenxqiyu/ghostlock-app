Set-Location $PSScriptRoot

# === ghostlock-app: 只编译一个 so (libghostlock.so) ===
# 参考旧版 bian.ps1 的单 clang 直编方式, 但源码改用本仓库 src/core (与 Makefile 同源):
#   - 源码: src/core/main.c + offsets_json.c + util.c + fops.c
#   - 偏移表: src/kernels/offsets.h (已裁剪为仅 6.1.138-android14-11-g0c3d559bcd85-ab14529422, Xiaomi 14 Pro / shennong)
#   - 输出: build\shennong\bin\libghostlock.so
# 注意: ghostlock 核心是带 main() 的可执行程序, 必须用 -fPIE -pie (不能 -shared),
#       与 App 内按可执行文件解包运行的 libghostlock.so 行为一致。

$clang = "C:\Users\Administrator\AppData\Local\Android\Sdk\ndk\28.2.13676358\toolchains\llvm\prebuilt\windows-x86_64\bin\clang.exe"

New-Item -ItemType Directory -Force -Path "build\shennong\bin" | Out-Null

# 单引号字符串: 内层双引号作为字面量传给 clang, 使 offset.h 里的 #include "target.h" 合法
$TARGET_DEFINE = '-DTARGET_CONFIG_H="target.h"'
$srcs = @("src/core/main.c","src/core/offsets_json.c","src/core/util.c","src/core/fops.c")

& "$clang" --target=aarch64-linux-android35 -fPIE -pie -O2 -g0 -Wall -Wextra `
  -Wno-unused-parameter -Wno-sign-compare -Wno-unused-function `
  -Isrc/core -Isrc/kernels $TARGET_DEFINE $srcs `
  -o build/shennong/bin/preload.so -pthread

if ($LASTEXITCODE -ne 0) {
  Write-Host "BUILD FAILED" -ForegroundColor Red
  exit 1
}

Get-FileHash build/shennong/bin/libghostlock.so -Algorithm SHA256 | Format-List
Write-Host "BUILD OK: build\shennong\bin\preload.so" -ForegroundColor Green
