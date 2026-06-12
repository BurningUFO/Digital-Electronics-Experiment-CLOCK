# ClockLink Studio Release Guide

本文档说明 ClockLink Studio 上位机软件的 Git 管理和发行方式。

## 1. 仓库原则

Git 仓库保存可维护内容：

- Python 源码：`software/clocklink_studio/**/*.py`
- 协议和软件说明：`docs/UART_PROTOCOL.md`、`software/clocklink_studio/README.md`
- 依赖声明：`requirements.txt`、`requirements-build.txt`
- PyInstaller 配置：`ClockLinkStudio.spec`
- 本地打包脚本：`scripts/package_clocklink_studio.ps1`
- GitHub Actions workflow：`.github/workflows/clocklink-studio-release.yml`

Git 仓库不保存生成产物：

- `software/clocklink_studio/build/`
- `software/clocklink_studio/dist/`
- `artifacts/releases/`
- `.pytest_cache/`
- `__pycache__/`

发布给用户下载的 EXE/ZIP 应作为 GitHub Release 附件，而不是提交到源码历史。

## 2. 本地构建发行包

在仓库根目录运行：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\package_clocklink_studio.ps1 -Version v1.0.0
```

脚本会执行：

1. 安装构建依赖。
2. 运行 `python -m pytest`。
3. 使用 `ClockLinkStudio.spec` 打包 `ClockLinkStudio.exe`。
4. 生成 `artifacts/releases/ClockLinkStudio-v1.0.0-win64.zip`。

如果只是快速重打包，可跳过测试：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\package_clocklink_studio.ps1 -Version dev -SkipTests
```

## 3. GitHub 自动发行

推送版本标签即可触发 GitHub Actions：

```bash
git tag v1.0.0
git push origin v1.0.0
```

workflow 会在 Windows runner 上：

1. 安装 Python 和依赖。
2. 运行 pytest。
3. 使用 PyInstaller 构建 EXE。
4. 打包 ZIP。
5. 创建或更新 GitHub Release，并上传 ZIP。

也可以在 GitHub Actions 页面手动运行 `ClockLink Studio Release` workflow。手动运行只上传 workflow artifact；正式公开发行建议使用 `v*` 标签。

## 4. 建议版本号

建议使用语义化版本：

- `v1.0.0`：首次课程验收版。
- `v1.0.1`：只修复软件显示、串口连接或文档问题。
- `v1.1.0`：新增上位机功能或协议兼容扩展。
- `v2.0.0`：协议不兼容或 FPGA 固件接口大改。

## 5. Release 附件内容

发行 ZIP 建议包含：

- `ClockLinkStudio.exe`
- `README.md`
- `UART_PROTOCOL.md`
- `RELEASE_NOTES.txt`

用户只需要解压 ZIP 后运行 `ClockLinkStudio.exe`。Mock 模式不需要 FPGA；串口模式需要已烧录 ClockLink UART 固件的 Nexys A7。

## 6. 发布前检查

发布前建议确认：

```bash
cd software/clocklink_studio
python -m pytest
python desktop.py --self-test
```

如果涉及 FPGA 协议变更，还需要同步检查：

```bash
vivado -mode batch -source scripts/run_phase_synth_check.tcl
```

本项目当前首版协议仅支持可打印 ASCII 消息。Unicode/中文消息显示不属于当前发行包承诺范围。
