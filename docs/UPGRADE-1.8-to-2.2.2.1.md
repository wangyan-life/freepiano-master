UPGRADE GUIDE: FreePiano 1.8 -> 2.2.2.1

概述
----
本指南汇总了将 FreePiano 从仓库中现有的 1.8 版本升级到目标版本 2.2.2.1 所需的功能补齐、Bug 修复和工程化工作。

注意：仓库当前仅包含 1.8 源码，官方 2.2.2.1 的完整源码/二进制未包含于本仓库，下面的指南用于指导代码修改、补丁实现与测试以达到或接近 2.2.2.1 的特性。

优先级与时间线
----------------
- Critical（优先）：保证稳定性与基础功能
  - 修复 64-bit 下输出设备配置保存问题
  - 修复退出/卸载时音源（VST/SF2 等）导致的崩溃
  - 修复 ASIO 输出相关问题
  - 修复更新检测失败导致崩溃
- Important（次优先）：用户可见特性与兼容
  - 弹性 VST 错误提示与日志
  - 支持打开 MIDI 文件与导出 MIDI
  - 支持 SF2（SoundFont）音源（集成 FluidSynth）
  - 实现“序列”命令、发送按键、菜单命令
- Optional（可选）：工程化与增强
  - CI、自动构建、打包
  - 增强文档、示例曲、性能优化

关键改动清单（摘要）
-------------------
1. 修复 config 的设备持久化（保存 device name 而非指针/句柄；确保跨 x86/x64 可读）
2. 在关闭流程中，先停止音频输出与播放线程，等待回调完成，再卸载插件/释放 DLL
3. 在 VST 加载/卸载中增加详细错误码和可读错误信息用于 GUI 提示
4. 为 update_check_async 添加异常处理与超时保护
5. 新增 MIDI 文件导入/导出模块（SMF parser/writer）
6. 新增 SF2 支持（建议集成 FluidSynth）
7. 键映射/脚本增强：序列命令、sendkey、menu、release 恢复、bend 平滑、升/降记号
8. GUI/UX：MINI 模式、最大化全屏选项、保存随机力度参数、键盘布局对子目录支持
9. 构建：提供 Win32/x64 构建支持，编写 `BUILD.md` 指南与自动化脚本（CI）

实现细节（重点）
-----------------
- plugin 卸载顺序：
  1. 通知 UI 停止播放（song_stop_playback）
  2. 停止音频设备输出并等待回调返回（signal/flag）
  3. 锁住 vsti 线程锁，调用 effStopProcess、effEditClose、effClose
  4. delete[] temp buffers
  5. FreeLibrary(module)

- config 保存/加载：避免保存内存地址或依赖平台字长类型；确定使用 UTF-8 或 UTF-16 并统一使用转换

- VST 错误提示：在 `vsti_load_plugin` 各失败点返回可解释错误码，并由 GUI 处用 MessageBox 显示描述与建议（例如："插件与应用位数不匹配（32-bit vs 64-bit）"）

测试要点
--------
- 在 x86/x64 上 round-trip 测试 config 保存/加载
- 退出时插件不会导致崩溃（加载常见插件、播放、退出）
- ASIO/WASAPI/DirectSound 在不同设备下能正常选中并保存
- 导入/导出 MIDI 的正确性（外部工具检验）

逐步实施建议
--------------
1. 优先实现 plugin 卸载与 config 保存修复（保证稳定）
2. 修复 update 检查异常处理
3. 增强 VST 加载提示与日志
4. 在稳定后逐步实现 MIDI 导入/导出与 SF2 支持
5. 完成用户可见特性（UI/脚本扩展）
6. 最后补充 CI、BUILD 文档与打包

参考
----
- 本仓库源码（1.8）位于 repo 根的 `src/`、`vc/` 等目录
- BUILD 细节请见仓库根的 `BUILD.md`（已经添加）


作者注：如果你授权我修改仓库，我可以先行实现关键修复（plugin 卸载顺序、config 保存与 vsti 错误信息），并提交可运行的补丁以便你在本地验证。