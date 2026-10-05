# Safehouse Random Events

Left 4 Dead 2 SourceMod 插件：随机抽取持续与即时事件，支持多个持续事件叠加。

## 依赖

- SourceMod 1.11 或更新版本
- Left4DHooks 1.155 或更新版本（硬依赖）
- Safehouse Inventory 1.2.3 或更新版本（武器随机事件需要）

## 编译与安装

将 `safehouse_random_events.sp` 放入 SourceMod 的 `scripting` 目录，并确保 `left4dhooks.inc` 位于 `scripting/include`，然后用 `spcomp` 编译。把生成的 `safehouse_random_events.smx` 放入 `plugins` 目录。

插件首次运行会生成 `cfg/sourcemod/safehouse_random_events.cfg`。
