# 关于头号特训
## 特别鸣谢
- [@HuYiDao](https://github.com/huyudai)<br>
- [@ZGXaimware](https://github.com/zgxaimware)<br>
- [@nata](https://github.com/explodingdigg)<br>
- [@Aviarita](https://github.com/Aviarita)<br>
---
## 更新日志
**DangerZone[Gamesense]v6.5**<br>
- 修改避免大盾的逻辑 当玩家背着盾在设定的角度背对你时 自动调整hitbox为feet 当玩家举着盾在设定的角度正对你时 支持三种模式热键切换:**只打头 只打脚 关闭暴力机器人**<br>
- 添加哨戒枪自瞄 支持掩体判定墙后不锁定 可开关距离和可见度数值绘制<br>
- 改进距离指示器<br>
- 添加关闭Jammer效果<br>
- (不稳定)添加最终圈检测<br>
---
**DangerZone[Gamesense]v6.4**<br>
- 添加了购买/复活/死亡/断开连接 监听器<br>
- 改进无人机检测，识别人工控制和物品运送无人机，不锁定没用的无人机，支持掩体判定墙后不锁定<br>
- 去除无用的鸡ESP 添加爆炸桶自瞄 支持掩体判定墙后不锁定<br>
- 改进大盾检测 当玩家举着盾牌时不再将FEET作为HIT部位<br>
- PUNCHBOT不再只支持拳头 而是支持全部近战武器和盾牌<br>
- 添加了距离指示器 支持鼠标拖动保存位置<br>
---
## 配置建议
不建议笔记本用户游玩<br>
内存 RAM 需要 **24G 及以上**。如果不足，请设置虚拟内存。<br>
建议虚拟内存设置： <br> 
[虚拟内存正确的认识和详细的设置](https://www.bilibili.com/video/BV1Zj411g73o/) <br>

---
## 测试
- SK/AW 较为稳定，中高端电脑可一直不崩溃。<br>
- NL 频繁闪退。<br>
- 其他作弊器暂无数据，自行测试。<br>
- 头号特训服务器作为季节性服务器，视玩家数量决定是否开放。请加群 **474728011** 获得最新地址。<br>
- 关闭**DoubleTap HideShots**是强制性的，**FakeLag**最好不超过**6**，不然会导致走不动路。<br>
---
## DangerZone.lua — Gamesense
此 LUA 可以有效地将你的头号特训作弊强度提升 **200% - 1000%+**。<br>
只需要加载 `!!!DangerZone.lua` 即可一键加载全部子 lua。你可以自行更改这个lua的require来去除和添加子lua。<br>
如果你的电脑配置较低，建议加载 `!!!DangerZone Lite.lua`，可减缓 FPS 损耗。<br>
- 当你启用 **avoidshield** 功能时，**停止使用一切武器库 lua** 是强制性的，因为武器库会强制回调你的 HITBOX 设定导致工作异常，你必须启用Gamesense本体的Flag功能才可以看见玩家右侧的FEET/ACTIVE指示器。<br>
- 当你操纵 **无人机** 时，**关闭 BODYYAW 是强制性的**，最好完全关闭 ANTIAIM，让操纵无人机变得完全稳定，但需要注意躲藏的位置安全且不被发现。<br>
- 当你使用 **speedhack** 功能时，建议绑定除了speedhack以外的第二个键；装备 EXO弹射装置 时 **关闭 BUNNYHOP 是强制性的**，不然无法进行二次起跳。<br>
- 锁定无人机和油桶的掩体判断不是精准的，通常会有不准确性，注意子弹距离衰减再设定。<br>
- 使用 **betterbox** 功能时，应当注意你的设定与 Gamesense 本体 ESP 的冲突。<br>
- 使用 **betterbox** 的 `DangerZoneMode` 和 `DzSniffer` 在单排 HVH 模式下，检测玩家复活时间是无用的，请忽略。<br>
- 使用 **距离指示器** 时，可以用鼠标按住指示器进行拖动到你想要的位置，并且支持数值设定和保存。
  
---
## DangerZone.lua — Aimware
- 添加了 `hvh.cfg`，这是在 ZGXAIMWARE 的 mm.cfg 版本的基础上修改的。<br>
- 这个 lua 仍为 **2023 年年底的官匹 MM 版本**，并未对 HVH 模式进行特殊优化和适配。<br>
- 当你启用 Lua 时，**AIMSTEP 功能是强制性的**。<br>
- 在 HVH 模式下，强烈建议你设定背身键位。<br>
- `DzViusal` 和 `DzSniffer` 在单排 HVH 模式下，检测玩家复活时间是无用的，请忽略。<br>
- 当你使用 **speedhack** 功能时，建议绑定除了speedhack以外的第二个键；装备 EXO弹射装置 时 **关闭 BUNNYHOP 是强制性的**，不然无法进行二次起跳。在加速过程中 **停止使用方向键是强制性的**<br>
<br>

---

## DangerZone.lua — Primordial
`DzSniffer` 适配了 HVH 模式。<br>
请务必使用 **Stable 版本**，目前只能加载 `DzSniffer` Lua。<br>
