---@class XUiFangKuaiPopupCollectionUpgrade : XLuaUi 藏品升级弹框
---@field _Control XFangKuaiControl
local XUiFangKuaiPopupCollectionUpgrade = XLuaUiManager.Register(XLuaUi, "UiFangKuaiPopupCollectionUpgrade")

function XUiFangKuaiPopupCollectionUpgrade:OnAwake()
    self.BtnClose.CallBack = handler(self, self.Close)
end

function XUiFangKuaiPopupCollectionUpgrade:OnStart()
    local data = self._Control:GetCollectionRecordData()
    local rounds = self._Control:GetCollectionRound()

    local index
    if data.FinalRound > tonumber(rounds[#rounds]) then
        index = #rounds
    else
        for i, score in ipairs(rounds) do
            if data.FinalRound <= tonumber(score) then
                index = i
                break
            end
        end
    end

    self.TxtRound.text = data.FinalRound
    self.TxtTitle.text = XUiHelper.GetText("FangKuaiCollectionTitle")
    self.ImgIcon:SetRawImage(self._Control:GetClientConfig("CollectionIcon", index))
    self.TxtTips.text = self._Control:GetClientConfig("CollectionText", index)
end

function XUiFangKuaiPopupCollectionUpgrade:OnDestroy()
    self._Control:ClearCollection()
end

return XUiFangKuaiPopupCollectionUpgrade