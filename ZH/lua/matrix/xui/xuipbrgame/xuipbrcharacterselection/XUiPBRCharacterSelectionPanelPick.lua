local XUiPBRCharacterDetailPanelPick = require('XUi/XUiPBRGame/XUiPBRCharacterDetail/XUiPBRCharacterDetailPanelPick')

---@class XUiPBRCharacterSelectionPanelPick : XUiPBRCharacterDetailPanelPick
---@field _Control XPBRGameControl
---@field GridBtnGroup XUiButtonGroup
local XUiPBRCharacterSelectionPanelPick = XClass(XUiPBRCharacterDetailPanelPick, "XUiPBRCharacterSelectionPanelPick")


function XUiPBRCharacterSelectionPanelPick:OnBtnGroupSelect(index, force)
    if self._CurSelectIndex == index and not force then
        return
    end
    
    self._CurSelectIndex = index
    
    local cfg = self.CharacterCfgList[index]

    if self._SelectCharCb then
        self._SelectCharCb(cfg)
    end
    
    self._Control:SetCurSelectCharId(cfg.CharacterId)
end

return XUiPBRCharacterSelectionPanelPick
