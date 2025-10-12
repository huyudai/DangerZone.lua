# 关于头号特训


## 配置建议
不建议笔记本用户游玩
内存 RAM 需要 **24G 及以上**。如果不足，请设置虚拟内存。<br>
建议虚拟内存设置：  
【虚拟内存正确的认识和详细的设置】: https://www.bilibili.com/video/BV1Zj411g73o/ <br>
<br>

## 崩溃测试
- SK/AW 较为稳定，中高端电脑可一直不崩溃。<br>
- NL 频繁闪退。<br>
- 其他作弊器暂无数据，自行测试。<br>
<br>

头号特训服务器作为季节性服务器，视玩家数量决定是否开放。请加群 **474728011** 获得最新地址。<br>
<br>

---

## DangerZone.lua — Gamesense
此 LUA 可以有效地将你的头号特训作弊强度提升 **超过 200% - 1000%**。<br>
只需要加载 `!!!DangerZone Stable.lua` 即可一键加载全部子 lua。<br>
如果你的电脑配置较低，建议加载 `!!!DangerZone Lite.lua`，可减缓 FPS 损耗。<br>
<br>
这是本 LUA 的 **HVH 专用版本**，MM 版本在官匹叱咤风云，吊打各路主播，详见作者空间： https://space.bilibili.com/673717708/ （视频强度可查）。<br>
<br>
- 当你启用 **shieldbot** 功能时，**停止使用一切武器库 lua** 是强制性的，因为武器库会强制回调你的 HITBOX 设定导致 shieldbot 工作异常。<br>
- 当你操纵 **无人机** 时，**关闭 BODYYAW 是强制性的**，最好完全关闭 ANTIAIM，让操纵无人机变得完全稳定，但需要注意躲藏的位置安全且不被发现。<br>
- 当你使用 **speedhack** 功能时，建议绑定除了跳跃以外的第二个键；装备 EXOJUMP 时 **关闭 BUNNYHOP 是强制性的**，不然无法进行二次起跳。<br>
- 锁定无人机和油桶的掩体判断不是精准的，通常会有不准确性，注意子弹距离衰减再设定。<br>
- 使用 **BETTERBOX** 功能时，应当注意你的设定与 Gamesense 本体 ESP 的冲突。<br>
- 使用 BETTERBOX 的 `DangerZoneMode` 和 `DzSniffer` 在单排 HVH 模式下，检测玩家复活时间是无用的，请忽略。<br>
<br>

---

## DangerZone.lua — Aimware
添加了 `hvh.cfg`，这是在 ZGXAIMWARE 的 mm.cfg 版本的基础上修改的。<br>
这个 lua 仍为 **2023 年年底的官匹 MM 版本**，并未对 HVH 模式进行特殊优化和适配。<br>
当你启用 Lua 时，**AIMSTEP 功能是强制性的**。<br>
在 HVH 模式下，强烈建议你设定背身键位。<br>
`DzViusal` 和 `DzSniffer` 在单排 HVH 模式下，检测玩家复活时间是无用的，请忽略。<br>
<br>

---

## DangerZone.lua — Primordial
`DzSniffer` 适配了 HVH 模式。<br>
请务必使用 **Stable 版本**，目前只能加载 `DzSniffer` 功能。<br>
