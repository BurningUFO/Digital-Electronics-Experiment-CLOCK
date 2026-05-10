# PROJECT STATUS

## 当前定位

本目录是 `CLOCK` 项目的唯一开发工作区，面向 `Vivado + Nexys A7 100T`。

## 当前确认可用的主线

1. 统一按键 UI：`BTNL/BTNR/BTNU/BTND/BTNC`
2. `TIME / ALARM / COUNT` 三个主模式可编辑
3. OLED 模式显示、编辑边框和左右切换动画
4. 闹钟蜂鸣器提醒
5. `COUNT` 模式的 `RUN / STOP` 控制

## 最近关键改动

1. 已将工作区约定切换为本目录唯一主线
2. 已补 `README.md / PROJECT_STATUS.md / HANDOFF.md`
3. 已将当前有效文档同步到 `docs/`
4. 已尝试把倒计时结束事件接入蜂鸣器提醒链路

## 当前待验证 / 待处理

1. 倒计时结束提醒需要继续实板确认
2. `HOUR` 模式仍是占位功能
3. `SCHED` 模式仍是占位功能
4. 后续需要把 Git 仓库根迁到本目录

## 当前建议排查顺序

1. 先验证 `COUNT` 是否正常递减到 `00:00:00`
2. 再验证倒计时归零时蜂鸣器是否触发
3. 如果闹钟能响但倒计时不响，优先检查：
   - `countdown_ctrl.v`
   - `alarm_ctrl.v`
   - `clock.v`
4. 若代码已改但 Vivado 显示综合已是最新状态，先确认打开的是本目录的 `clock_amd.xpr`

## 下一步建议

1. 完成倒计时结束提醒实板验证
2. 同步修改日志和使用说明
3. 迁移 Git 仓库根到本目录
4. 清理无用的 Vivado 生成日志和缓存显示项
