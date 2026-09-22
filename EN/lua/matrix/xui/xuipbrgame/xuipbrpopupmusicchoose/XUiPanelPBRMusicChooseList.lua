--- BGM选择列表
---@class XUiPanelPBRMusicChooseList: XUiNode
---@field protected _Control XPBRGameControl
---@field Parent
---@field ButtonGroup XUiButtonGroup
---@field GridMusic UnityEngine.RectTransform bgm选项预制节点，用于克隆
local XUiPanelPBRMusicChooseList = XClass(XUiNode, "XUiPanelPBRMusicChooseList")

local XUiGridPBRMusic = require("XUi/XUiPBRGame/XUiPBRPopupMusicChoose/XUiGridPBRMusic")

-- 默认选中项滚动到视窗中心的 tween 时长（秒）
local SCROLL_TO_TWEEN_TIME = 0.3

--- 初始化列表
---@param bgmIds number[] BGM ID 列表
---@param currentBgmId number 当前选中的 BGM ID
---@param selectCallback function 选中回调 function(bgmId)
function XUiPanelPBRMusicChooseList:Init(bgmIds, currentBgmId, selectCallback)
    self._BgmIds = bgmIds
    self._CurrentBgmId = currentBgmId
    self._SelectCallback = selectCallback
    self:_InitGrids()
end

function XUiPanelPBRMusicChooseList:_InitGrids()
    self.GridMusic.gameObject:SetActiveEx(false)
    if #self._BgmIds == 0 then
        return
    end
    self._Grids = {}
    local btns = {}
    local defaultIndex = 1

    for i, bgmId in ipairs(self._BgmIds) do
        local go = CS.UnityEngine.Object.Instantiate(self.GridMusic.gameObject, self.GridMusic.transform.parent)
        local grid = XUiGridPBRMusic.New(go.transform, self)
        local bgmCfg = self._Control.MusicControl:GetTablePBRBgmCfgById(bgmId)
        local isCurrent = (bgmId == self._CurrentBgmId)
        grid:Open()
        grid:Refresh(bgmCfg, isCurrent)
        self._Grids[i] = grid
        btns[i] = grid.GridBtn

        if bgmId == self._CurrentBgmId then
            defaultIndex = i
        end
    end

    self.ButtonGroup:Init(btns, handler(self, self._OnGroupSelect))
    self.ButtonGroup:SelectIndex(defaultIndex)
    self:_ScrollToDefault(defaultIndex)
end

function XUiPanelPBRMusicChooseList:_OnGroupSelect(index)
    local bgmId = self._BgmIds[index]
    if bgmId and self._SelectCallback then
        self._SelectCallback(bgmId)
    end
end

--- 默认选中项滚动到视窗中心（弹性 tween，Clamp 不强制居中）
---@param defaultIndex number 当前选中 BGM 在列表中的下标
function XUiPanelPBRMusicChooseList:_ScrollToDefault(defaultIndex)
    local grid = self._Grids and self._Grids[defaultIndex]
    if not grid then
        return
    end

    -- content 容器 = GridMusic 模板的父节点；ScrollRect 挂在其祖先链上（不改 prefab 字段，运行时反查）
    local content = self.GridMusic.transform.parent
    if XTool.UObjIsNil(content) then
        return
    end
    local scrollRect = content:GetComponentInParent(typeof(CS.UnityEngine.UI.ScrollRect))
    if XTool.UObjIsNil(scrollRect) then
        return
    end

    -- 等一帧待 LayoutGroup/ContentSizeFitter 重建后再定位，避免克隆后 content 尺寸未稳定导致偏移失真
    if self._ScrollTimer then
        XScheduleManager.UnSchedule(self._ScrollTimer)
    end
    self._ScrollTimer = XScheduleManager.ScheduleNextFrame(function()
        self._ScrollTimer = nil
        if XTool.UObjIsNil(scrollRect) or XTool.UObjIsNil(grid.Transform) then
            return
        end
        XUiHelper.ScrollTo(scrollRect, grid.Transform, true, SCROLL_TO_TWEEN_TIME)
    end)
end

function XUiPanelPBRMusicChooseList:OnDestroy()
    if self._ScrollTimer then
        XScheduleManager.UnSchedule(self._ScrollTimer)
        self._ScrollTimer = nil
    end
end

return XUiPanelPBRMusicChooseList
