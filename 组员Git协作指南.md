# CLOCK 项目 Git 协作指南

本指南面向第一次接触 Git 的组员，目标是让大家能完成这几件事：

1. 把项目从 GitHub 克隆到本地。
2. 在自己的分支上开发，不直接改 `main`。
3. 把自己的修改提交并推送到远端。
4. 在开始新任务前先同步最新代码。

本项目仓库地址：

```text
https://github.com/BurningUFO/Digital-Electronics-Experiment-CLOCK.git
```

## 1. 先安装 Git

如果电脑里还没有 Git：

1. 去 Git 官网下载安装包。
2. 安装完成后打开 `Git Bash`，或者在终端里执行：

```bash
git --version
```

如果能看到版本号，说明安装成功。

## 2. 第一次把项目下载到本地

选择一个你自己的工作目录，然后执行：

```bash
git clone https://github.com/BurningUFO/Digital-Electronics-Experiment-CLOCK.git
cd Digital-Electronics-Experiment-CLOCK
```

检查当前状态：

```bash
git status
```

正常情况下会看到当前分支是 `main`，并且工作区是干净的。

## 3. 分支协作规则

为了避免互相覆盖代码，所有组员都按下面规则操作：

1. 不直接在 `main` 上写功能。
2. 每次做新功能或修 bug，都新建自己的分支。
3. 分支改完后，把分支推送到 GitHub。
4. 合并回 `main` 前，先让组长或负责整合的人检查。

推荐分支命名：

```text
feat/姓名-功能名
fix/姓名-问题名
docs/姓名-文档名
```

例如：

```text
feat/zhangsan-alarm
feat/lisi-hourly-chime
fix/wangwu-display-bcd
```

## 4. 开始一个新任务的标准流程

每次开始写代码前，先进入项目目录：

```bash
cd Digital-Electronics-Experiment-CLOCK
```

先切回主分支并拉取最新代码：

```bash
git checkout main
git pull origin main
```

然后基于最新的 `main` 创建自己的分支：

```bash
git checkout -b feat/你的名字-你的功能
```

例如：

```bash
git checkout -b feat/zhangsan-alarm
```

## 5. 开发过程中常用命令

查看哪些文件改了：

```bash
git status
```

查看具体改动：

```bash
git diff
```

如果你只想看某个文件：

```bash
git diff clock.v
```

## 6. 完成一次功能后的提交流程

修改完成后，先看状态：

```bash
git status
```

把本次功能需要提交的文件加入暂存区：

```bash
git add 文件名
```

如果这次改动比较集中，也可以：

```bash
git add .
```

然后提交：

```bash
git commit -m "实现闹钟基础功能"
```

提交信息尽量写清楚“做了什么”，不要只写 `update` 或 `修改`。

推荐写法：

```text
实现整点报时基础功能
修复数码管 BCD 位序问题
补充校时模式和闪烁显示
更新功能日志文档
```

## 7. 把自己的分支推送到 GitHub

第一次推送自己的分支：

```bash
git push -u origin feat/你的名字-你的功能
```

例如：

```bash
git push -u origin feat/zhangsan-alarm
```

以后在同一个分支上继续提交，只需要：

```bash
git push
```

## 8. 如何把远端最新代码同步到自己的分支

如果别的组员已经更新了 `main`，你在继续开发前最好先同步一次。

先更新本地 `main`：

```bash
git checkout main
git pull origin main
```

再切回自己的分支：

```bash
git checkout feat/你的名字-你的功能
```

把 `main` 的最新内容合并到你的分支：

```bash
git merge main
```

如果出现冲突，Git 会提示冲突文件。解决冲突后再：

```bash
git add .
git commit -m "解决与 main 的合并冲突"
```

## 9. 功能完成后如何合并回 main

推荐做法：

1. 把自己的分支推到 GitHub。
2. 在 GitHub 页面发起 Pull Request。
3. 由组长或负责整合的人审核并合并到 `main`。

如果你们组暂时不走 Pull Request，也至少要做到：

1. 先确认自己的分支代码能正常编译。
2. 在群里说明改了什么。
3. 由一位固定成员负责把分支合并回 `main`。

## 10. 这个项目里建议提交什么，不建议提交什么

建议提交：

1. `clock.v`
2. `clock.qsf`
3. `clock.qpf`
4. `inf.md`
5. `管脚.md`
6. 说明文档、设计文档、日志文档

不建议提交：

1. Quartus 自动生成的 `db/`
2. `incremental_db/`
3. `*.rpt`
4. `*.summary`
5. `*.qws`
6. `*.bak`
7. 其他本地临时文件

这些文件已经在 `.gitignore` 里做了忽略。

## 11. 最常用的命令速查

克隆仓库：

```bash
git clone https://github.com/BurningUFO/Digital-Electronics-Experiment-CLOCK.git
```

查看状态：

```bash
git status
```

拉取主分支：

```bash
git checkout main
git pull origin main
```

创建新分支：

```bash
git checkout -b feat/名字-功能
```

提交改动：

```bash
git add .
git commit -m "你的说明"
```

推送分支：

```bash
git push -u origin 分支名
```

## 12. 组内协作建议

1. 一个人只负责一到两个明确模块，不要多人同时改同一个文件的大段逻辑。
2. 改动前先看 `功能与修改日志.md`，避免和别人撞任务。
3. 每次提交前先本地编译，至少保证不会把明显坏掉的代码推上去。
4. 改完功能后及时在日志里登记日期、分支名、改动内容和测试结果。
