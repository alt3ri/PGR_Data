--- BGM选择列表
---@class XUiPanelPBRMusicChooseList: XUiNode
---@field protected _Control XPBRGameControl
---@field Parent
---@field ButtonGroup XUiButtonGroup
---@field GridMusic UnityEngine.RectTransform bgm选项预制节点，用于克隆
local XUiPanelPBRMusicChooseList = XClass(XUiNode, "XUiPanelPBRMusicChooseList")

local XUiGridPBRMusic = require("XUi/XUiPBRGame/XUiPBRPopupMusicChoose/XUiGridPBRMusic")

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
end

function XUiPanelPBRMusicChooseList:_OnGroupSelect(index)
    local bgmId = self._BgmIds[index]
    if bgmId and self._SelectCallback then
        self._SelectCallback(bgmId)
    end
end

return XUiPanelPBRMusicChooseList
