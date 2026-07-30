--- BGM选项
---@class XUiGridPBRMusic: XUiNode
---@field protected _Control XPBRGameControl
---@field Parent
---@field GridBtn XUiComponent.XUiButton
local XUiGridPBRMusic = XClass(XUiNode, "XUiGridPBRMusic")

---@param bgmCfg XTablePBRBgmList
function XUiGridPBRMusic:Refresh(bgmCfg, isCurrent)
    self.GridBtn:SetNameByGroup(0, bgmCfg.Name)

    if not string.IsNilOrEmpty(bgmCfg.CoverImg) then
        self.GridBtn:SetRawImage(bgmCfg.CoverImg)
    end
    
    self.GridBtn:ShowTag(isCurrent)
end

return XUiGridPBRMusic
