#!/system/bin/sh
# Fortnite 一键注入脚本（MT 管理器以 root 执行）
DIR=$(cd "$(dirname "$0")" && pwd)
SO="$DIR/libFortniteOverlay.so"
SRC="$DIR/inject"
BIN="/data/local/tmp/fortnite_inject"
SO_BIN="/data/local/tmp/libFortniteOverlay.so"
PKG="com.epicgames.fortnite"

if [ ! -f "$SO" ]; then echo "未找到库: $SO"; exit 1; fi
if [ ! -f "$SRC" ]; then echo "未找到注入器: $SRC"; exit 1; fi

cp -f "$SRC" "$BIN" 2>/dev/null
chmod 755 "$BIN" 2>/dev/null
cp -f "$SO" "$SO_BIN" 2>/dev/null
chmod 644 "$SO_BIN" 2>/dev/null
# SELinux Enforcing 下 untrusted_app 不能 dlopen 默认标签的 so，需改为 app_data_file
chcon u:object_r:app_data_file:s0 "$SO_BIN" 2>/dev/null

if [ ! -x "$BIN" ] || [ ! -r "$SO_BIN" ]; then echo "文件准备失败"; exit 1; fi

PID=""
for p in /proc/[0-9]*; do
    name=$(tr '\0' '\n' < "$p/cmdline" 2>/dev/null | head -n 1)
    if [ "$name" = "$PKG" ]; then PID=${p##*/}; break; fi
done

if [ -z "$PID" ]; then echo "游戏未运行（未找到主进程 $PKG）"; exit 1; fi

echo "目标: $PKG pid=$PID"
echo "库:   $SO_BIN"
exec "$BIN" "$PID" "$SO_BIN"
