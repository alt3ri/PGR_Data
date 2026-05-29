---@class XUiTheatre6PopupCoverArchive : XLuaUi
---@field _Control XTheatre6Control
local XUiTheatre6PopupCoverArchive = XLuaUiManager.Register(XLuaUi, "UiTheatre6PopupCoverArchive")

function XUiTheatre6PopupCoverArchive:OnAwake()
    self.BtnTanchuangCloseWhite:AddEventListener(handler(self, self.Close))
    self.BtnCover:AddEventListener(handler(self,self.OnClickCover))
end

function XUiTheatre6PopupCoverArchive:OnStart(selectSlot, fileData, mode)
    self._SelectSlot = selectSlot
    self._Mode = mode
    local XUiPanelCharacterAttrDetail = require("XUi/XUiTheatre6/Character/Panel/XUiPanelTheatre6CharacterAttrDetail")

    --Old：选中槽位的存档数据
    if self.PanelDetailOld then
        local oldFileData = self._Control:GetFileDataBySlot(fileData.CharacterId, selectSlot)
        if oldFileData then
            ---@type XUiPanelTheatre6CharacterAttrDetail
            local oldGrid = XUiPanelCharacterAttrDetail.New(self.PanelDetailOld, self, oldFileData)
            oldGrid:ClearSkillNewFlag()
        else
            self.PanelDetailOld.gameObject:SetActiveEx(false)
        end
    end

    --New：当前局的实时数据
    if self.PanelDetailNew then
        ---@type XUiPanelTheatre6CharacterAttrDetail
        local newGrid = XUiPanelCharacterAttrDetail.New(self.PanelDetailNew, self, fileData)
        newGrid:ClearSkillNewFlag()
    end
end

function XUiTheatre6PopupCoverArchive:OnClickCover()
    self._Control:SaveSettlement(self._Mode, self._SelectSlot, function()
        XLuaUiManager.Close("UiTheatre6Settlement")
        self:Close()
    end)
end

function XUiTheatre6PopupCoverArchive:OnDisable()
end

function XUiTheatre6PopupCoverArchive:OnDestroy()
end

return XUiTheatre6PopupCoverArchive