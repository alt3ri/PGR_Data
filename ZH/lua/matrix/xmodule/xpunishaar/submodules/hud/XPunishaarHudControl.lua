--- HUD 调度（关卡内，GameControl partial）：节点推进时按规则随机选一 HUD + 缓存；FightMain 显时读缓存显（未手动关）；节点/关卡结束清。
--- condition 求值（CheckHudCondition 调用 + PunishaarHud.Condition[] 过滤）TODO；选时仅 Weight 随机（condition 不判）。#86
--- 显隐时机（规则3）：a. 节点推进（OnHudNodeAdvance）选+缓存；b. FightMain 显时读 GetDisplayHud 显（未 DismissHud）；玩家 DismissHud 标关闭；节点推进重置。
local XPunishaarGameControl = XClassPartial("XPunishaarGameControl")

-- 背包暂存区开合的局内表现层事件（ComBottomBagBase 派发 → FightMain 订阅隐/恢复 HUD）#背包HUD互斥
XPunishaarGameControl.BagEventId = {
    Open  = "PunishaarBagOpen",  -- 背包展开：纯遮蔽隐 HUD（不标 DismissHud，收起可恢复）
    Close = "PunishaarBagClose", -- 背包收起：恢复 HUD 显隐（读 GetDisplayHud，未手动关才显）
}

--- 节点推进时选 HUD：当前节点 StageContent.HudGroupId → GetHudCfgsByGroup（规则1 Id=GroupId*100+index 连续读）→
---   过滤本关卡已抽 GameNoRepeat=1 的（不放回；配空放回每次参与）→ Weight 随机选一 → 缓存 + 登记。
--- condition 过滤（CheckHudCondition）TODO，当前直接 Weight 随机不判 condition。
function XPunishaarGameControl:OnHudNodeAdvance()
    XLog.Debug("[HudTrace][1触发] OnHudNodeAdvance 入口")
    -- 入口无条件清旧缓存 + 复位 Dismissed：覆盖 contentId 空 / groupId 空 / 正常三路径（对齐原实现 + ClearHud 注释「节点推进时已清旧」）。
    -- 推进到无 HudGroupId 节点时上一节点选中的 HUD 必须清，否则 GetDisplayHud 仍返旧 _HudCfg 致切态仍显旧 HUD。
    self._HudCfg = nil
    self._IsHudDismissed = false
    -- 理论最正确：直接用 stage.CurrentNode.NodeId（节点配置 Id = StageContent.Id）取 StageContent，
    --   不经 #HistoryNodeList+1 序号→contentIds 映射，避 AdvanceNode 时 History 时机依赖（审核问题1 修复）。
    local stage = self._Model:GetCurrentStage()
    local node = stage and stage.CurrentNode
    local contentId = node and node.NodeId
    if not contentId or contentId == 0 then
        XLog.Debug("[HudTrace][2判定] contentId 空 return")
        return
    end
    local content = XMVCA.XPunishaar:GetTablePunishaarStageContent(contentId, true)
    local groupId = content and content.HudGroupId or 0
    if not groupId or groupId == 0 then
        XLog.Debug("[HudTrace][2判定] contentId=" .. contentId .. " HudGroupId 空 return")
        return
    end
    self:SelectHudByGroup(groupId)
end

--- 按 groupId 选 HUD（抽 OnHudNodeAdvance 选 HUD 逻辑，供补强商店用默认 group 复用）。
--- 复位 Dismissed + 局部加载组 + 过滤 GameNoRepeat 已抽 + Weight 随机选一 + 缓存 + 登记。#补强HUD
---@param groupId number
function XPunishaarGameControl:SelectHudByGroup(groupId)
    self._HudCfg = nil
    self._IsHudDismissed = false
    if not groupId or groupId == 0 then return end
    -- 规则1 局部加载组（填充复用 buffer，零 GC）
    local cfgs = self._HudCfgBuffer
    local count = self:GetHudCfgsByGroup(groupId, cfgs)
    XLog.Debug("[HudTrace][2判定] SelectHudByGroup groupId=" .. groupId .. " group内cfg数=" .. count)
    if count == 0 then return end
    -- 过滤本关卡已抽 GameNoRepeat=1 的（不放回；配空=放回每次参与，不过滤）
    local candidates = self._HudCandidateBuffer
    for k in pairs(candidates) do candidates[k] = nil end
    local drawn = self._DrawnHudNoRepeatSet
    local candCount = 0
    for i = 1, count do
        local cfg = cfgs[i]
        if not (cfg.GameNoRepeat and drawn[cfg.Id]) then
            candCount = candCount + 1
            candidates[candCount] = cfg
        end
    end
    if candCount == 0 then
        XLog.Debug("[HudTrace][2判定] groupId=" .. groupId .. " candCount=0 NoRepeat全抽完 return")
        return
    end  -- group 内 GameNoRepeat=1 全抽完，本节点不再显
    -- Weight 随机选一（condition 过滤 TODO）
    local total = 0
    for i = 1, candCount do total = total + (candidates[i].Weight or 0) end
    if total <= 0 then
        self._HudCfg = candidates[1]  -- 无 Weight 兜底取首
    else
        local r = CS.UnityEngine.Random.Range(1, total + 1)  -- [1, total] 整数（含两端）
        local acc = 0
        for i = 1, candCount do
            acc = acc + (candidates[i].Weight or 0)
            if r <= acc then
                self._HudCfg = candidates[i]
                break
            end
        end
        if not self._HudCfg then self._HudCfg = candidates[candCount] end  -- 浮点兜底
    end
    XLog.Debug("[HudTrace][2判定] 选中 cfg Id=" .. tostring(self._HudCfg and self._HudCfg.Id) .. " groupId=" .. groupId .. " candCount=" .. candCount)
    -- 登记 GameNoRepeat=1（本关卡 group 内不放回；下次同 group 节点推进时过滤）
    if self._HudCfg.GameNoRepeat then
        drawn[self._HudCfg.Id] = true
    end
end

--- 取应显示的 HUD（未手动关闭则返当前缓存 cfg；关闭/无则 nil）。
---@return XTablePunishaarHud|nil
function XPunishaarGameControl:GetDisplayHud()
    if self._IsHudDismissed then return nil end
    return self._HudCfg
end

--- 玩家手动关闭当前 HUD（标记，本次节点不再显；节点推进时 OnHudNodeAdvance 重置）。
function XPunishaarGameControl:DismissHud()
    self._IsHudDismissed = true
end

--- 清 HUD 缓存（节点结束/关卡结束调；节点推进时 OnHudNodeAdvance 已清旧选 cfg+Dismissed，关卡结束清 GameNoRepeat 不放回缓存）。
function XPunishaarGameControl:ClearHud()
    self._HudCfg = nil
    self._IsHudDismissed = false
    local drawn = self._DrawnHudNoRepeatSet
    for k in pairs(drawn) do drawn[k] = nil end
end

return XPunishaarGameControl
