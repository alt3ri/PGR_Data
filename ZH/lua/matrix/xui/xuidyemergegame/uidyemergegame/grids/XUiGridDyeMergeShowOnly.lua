local XUiGridDyeMerge = require("XUi/XUiDyeMergeGame/UiDyeMergeGame/Grids/XUiGridDyeMerge")

--- 展示块，结构类似基础块
---@class XUiGridDyeMergeShowOnly: XUiGridDyeMerge
---@field protected _Control
---@field Parent
local XUiGridDyeMergeShowOnly = XClass(XUiGridDyeMerge, "XUiGridDyeMergeShowOnly")

---@overload
--- 直接刷新显示状态
function XUiGridDyeMergeShowOnly:Refresh(uid)
    self.Uid = uid
    local block = self._Control.GamingControl.BlocksControl:GetBlockByUid(uid)
    if not block then
        return
    end
    local blockCfg = self._Control.GamingControl:GetTableDyeMergeBlockById(block:GetId())
    if not blockCfg then
        return
    end
    local colorCfg = self._Control.GamingControl:GetTableDyeMergeBlocksConfig(blockCfg.Color)
    if not colorCfg then
        return
    end

    self.RImgBg:SetRawImage(colorCfg.IconNormal)
    
    if self.RImgDiban then
        self.RImgDiban:SetRawImage(colorCfg.IconNormalBig)
    end

    if self.RImgObject then
        self.RImgObject:SetRawImage(colorCfg.IconSupprtTop)
        self.RImgObject.gameObject:SetActiveEx(true)
    end
    
    if self.RImgObjectEnd then
        self.RImgObjectEnd.gameObject:SetActiveEx(false)
    end

    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(false)
    end
end

--- 通关后将供色图标切换回 IconTop
function XUiGridDyeMergeShowOnly:RefreshOnStagePass(uid)
    local block = self._Control.GamingControl.BlocksControl:GetBlockByUid(uid)
    if not block then
        return
    end
    local blockCfg = self._Control.GamingControl:GetTableDyeMergeBlockById(block:GetId())
    if not blockCfg then
        return
    end
    local colorCfg = self._Control.GamingControl:GetTableDyeMergeBlocksConfig(blockCfg.Color)
    if not colorCfg then
        return
    end

    if self.RImgObjectEnd and colorCfg.IconTop then
        self.RImgObjectEnd.gameObject:SetActiveEx(true)
        self.RImgObjectEnd:SetRawImage(colorCfg.IconTop)
    end

    if self.RImgObject then
        self.RImgObject.gameObject:SetActiveEx(false)
    end
end

return XUiGridDyeMergeShowOnly