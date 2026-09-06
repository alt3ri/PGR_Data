--[[
-- XUiPunishaarFightMainGridStage.lua
-- 节点进度 grid：单 grid 按节点类型显示图标 + 三态切换（已通关/当前/未到）。
-- 对标 PBR XUiPunishaarBaseWaveGrid 的 RefreshShow(waveId, waveIndex, nextWaveIndex) 模式 #53
--]]
---@class XUiPunishaarFightMainGridStage : XUiNode
---@field _Control XPunishaarControl
---@field UiImgIcon UnityEngine.UI.Image 节点类型图标（按 ContentType 取 ClientConfig NodeIcon Values[NodeType]）
---@field UiPanelFinish UnityEngine.RectTransform 已通关态根节点
---@field UiPanelUnfinished UnityEngine.RectTransform 未到/当前态根节点
---@field ImgLine UnityEngine.RectTransform 节点间连接线（除最后一个节点外都显示）
---@field ImgBgSelect UnityEngine.UI.Image 当前节点选中底图（nodeIndex==currentIndex 时显示，标识当前所在节点）
local XUiPunishaarFightMainGridStage = XClass(XUiNode, "XUiPunishaarFightMainGridStage")

function XUiPunishaarFightMainGridStage:InitComponents()
end

function XUiPunishaarFightMainGridStage:OnStart()
    self:InitComponents()
end

--- 刷新单个节点 grid。
---@param stageId number 关卡 Id
---@param nodeIndex number 该节点序号（1-based）
---@param currentIndex number 当前节点序号（1-based）
---@param total number 总节点数（用于判断是否末节点）
function XUiPunishaarFightMainGridStage:Refresh(stageId, nodeIndex, currentIndex, total)
    -- 三态切换：nodeIndex < currentIndex → 已通关；== → 当前；> → 未到
    local isFinished = nodeIndex < currentIndex
    local isCurrent = nodeIndex == currentIndex

    if self.UiPanelFinish then
        self.UiPanelFinish.gameObject:SetActiveEx(isFinished)
    end
    if self.UiPanelUnfinished then
        self.UiPanelUnfinished.gameObject:SetActiveEx(not isFinished)
    end

    -- 节点类型图标：单 Key NodeIcon，Values[ContentType] 取路径，Image:SetSprite 设图
    local contentType = self._Control:GetNodeContentType(stageId, nodeIndex)
    if self.UiImgIcon and contentType then
        local iconPath = self._Control:GetNodeIconPath(contentType)
        if iconPath and iconPath ~= "" then
            self.UiImgIcon:SetSprite(iconPath)
        end
    end

    -- 连接线：除最后一个节点外都显示（节点间基础链接样式）
    if self.ImgLine then
        self.ImgLine.gameObject:SetActiveEx(nodeIndex < (total or 0))
    end

    -- 当前节点选中底图：nodeIndex==currentIndex 时显示，标识当前所在节点
    if self.ImgBgSelect then
        self.ImgBgSelect.gameObject:SetActiveEx(isCurrent)
    end
end

return XUiPunishaarFightMainGridStage
