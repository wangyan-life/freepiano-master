BUILD.md

在 Windows 上使用 Visual Studio 构建 FreePiano（概要）

前提环境
--------
- Windows 7/10/11
- Visual Studio 2015/2017/2019/2022（含 MSVC 编译工具）
- Windows SDK（通常随 VS 安装）
- 可选: ASIO 驱动（如果需要测试 ASIO 输出）

第三方库
--------
项目包含 `3rd/` 目录下的若干第三方实现（freetype2、libpng、libfaac、libmp4v2、zlib、libx264 等）。构建时可使用项目中提供的子工程，或改为链接系统已安装/预编译的库。

构建步骤（简单）
----------------
1. 使用 Visual Studio 打开解决方案 `vc\freepiano.sln`。
2. 选择目标平台：x86（用于兼容大多数 32-bit VST 插件）或 x64。
3. 选择 Debug/Release 配置并构建解决方案（Build -> Build Solution）。

命令行（在 Visual Studio 的开发者命令提示符或 PowerShell 中）
```powershell
# x86 Release
msbuild .\vc\freepiano.sln /p:Configuration=Release /p:Platform=x86
# x64 Release
msbuild .\vc\freepiano.sln /p:Configuration=Release /p:Platform=x64
```

注意事项
--------
- VST 插件的位数必须与可执行文件位数一致（32-bit 插件只能被 32-bit 程序加载）。
- 如果你的系统没有安装某些第三方库，请使用 repo 中 `3rd/` 的源码或自行安装并调整项目的 include/lib 路径。
- ASIO 支持需要对应 ASIO SDK/驱动。测试 ASIO 需要安装 ASIO 驱动并在系统中可见。
- 若出现编译错误，先检查 `vcxproj` 中的 include 路径、库路径与预编译宏（如宏 `_CRT_SECURE_NO_WARNINGS` 等）。

调试与运行
----------
- 构建成功后在输出目录运行 `freepiano.exe`。
- 首次运行会加载 `freepiano.cfg`（若不存在将使用内置默认）。

交付与打包
---------
- 可使用 Inno Setup 或其它安装制作工具创建 Windows 安装包（项目根有 `nsis/` 目录用于 NSIS 脚本作为参考）。

CI 建议
------
- 使用 GitHub Actions 或 AppVeyor 实现自动构建（至少 x86 Release），并在构建成功时发布 artifacts。

如果你需要，我可以：
- 为你生成一个完整的 CI 配置示例（GitHub Actions workflow）以自动构建并打包 Release
- 为常见的第三方库给出编译脚本或更详细的构建说明
