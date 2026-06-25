local XUiGridDyeMerge = require("XUi/XUiDyeMergeGame/UiDyeMergeGame/Grids/XUiGridDyeMerge")

--- 基础单色块
---@class XUiGridDyeMergeNormal: XUiGridDyeMerge
---@field protected _Control
---@field Parent
---@field RImgBg @地块UI，设置底色
---@field RImgObject @图标
---@field BtnMove|nil @点击按钮, 可移动的预制存在该引用，表示可点击选择并移动位置
---@field RImgDiban|nil @长条预制才有的引用
---@field ImgSelect|nil @选中时显示该节点
local XUiGridDyeMergeNormal = XClass(XUiGridDyeMerge, "XUiGridDyeMergeNormal")

function XUiGridDyeMergeNormal:OnStart()
    if self.BtnMove then
        self.BtnMove:AddEventListener(handler(self, self._OnBtnMoveClick))
    end
end

---@overload
--- 直接刷新显示状态
function XUiGridDyeMergeNormal:Refresh(uid)
    self.Uid = uid
    local block = self._Control.GamingControl.BlocksControl:GetBlockByUid(uid)
    if not block then return end
    local blockCfg = self._Control.GamingControl:GetTableDyeMergeBlockById(block:GetId())
    if not blockCfg then return end
    local colorCfg = self._Control.GamingControl:GetTableDyeMergeBlocksConfig(blockCfg.Color)
    if not colorCfg then return end

    self.RImgBg:SetRawImage(colorCfg.IconNormal)
    if self.RImgDiban then
        self.RImgDiban:SetRawImage(colorCfg.IconNormalBig)
    end

    self.RImgObject:SetRawImage(colorCfg.IconSupprtTop)
    self.RImgObject.gameObject:SetActiveEx(true)
    if self.RImgObjectEnd then
        self.RImgObjectEnd.gameObject:SetActiveEx(false)
    end

    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(false)
    end
end

--- 通关后将供色图标切换回 IconTop
function XUiGridDyeMergeNormal:RefreshOnStagePass(uid)
    local block = self._Control.GamingControl.BlocksControl:GetBlockByUid(uid)
    if not block then return end
    local blockCfg = self._Control.GamingControl:GetTableDyeMergeBlockById(block:GetId())
    if not blockCfg then return end
    local colorCfg = self._Control.GamingControl:GetTableDyeMergeBlocksConfig(blockCfg.Color)
    if not colorCfg then return end

    if self.RImgObjectEnd and colorCfg.IconTop then
        self.RImgObjectEnd.gameObject:SetActiveEx(true)
        self.RImgObjectEnd:SetRawImage(colorCfg.IconTop)
    end

    self.RImgObject.gameObject:SetActiveEx(false)
end

function XUiGridDyeMergeNormal:_OnBtnMoveClick()
    if self._SendGridClickSignal then
        self._SendGridClickSignal(self.Uid)
    end
end

return XUiGridDyeMergeNormal