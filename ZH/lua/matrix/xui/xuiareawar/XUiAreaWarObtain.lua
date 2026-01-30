local XUiObtain = require("XUi/XUiObtain/XUiObtain")
local XUiGridAreaWarItem = require("XUi/XUiAreaWar/XUiGridAreaWarItem")

---@class XUiAreaWarObtain
---@field _Control XAreaWarControl
local XUiAreaWarObtain =  XLuaUiManager.Register(XUiObtain, "UiAreaWarObtain")

function XUiAreaWarObtain:OnStart(rewardGoodsList,areaWarItemList, title, closeCb, sureCb, horizontalNormalizedPosition, customParams)

    if not self.GridAreawarItem then
        self.GridAreawarItem = self.Transform:Find("SafeAreaContentPane/ScrView/Viewport/PanelContent/GridItem")
        self.GridAreawarItem.gameObject:SetActiveEx(false)
    end
    self.CustomParams = customParams or {}
    self.Items = {}
    self.GridCommon.gameObject:SetActive(false)
    self.CancelBtnPosX = self.BtnCancel.transform.localPosition.x
    self.SureBtnPosX = self.BtnSure.transform.localPosition.x
    if title then
        self.TxtTitle.text = title
    end
    self.OkCallback = sureCb
    self.CancelCallback = closeCb
    if not XTool.IsTableEmpty(rewardGoodsList) then
        self:Refresh(rewardGoodsList, horizontalNormalizedPosition)
        self:Layout()
        self:CheckIsTimelimitGood(rewardGoodsList)
    end

    if not XTool.IsTableEmpty(areaWarItemList) then
        self:RefreshAreaWarItem(areaWarItemList, horizontalNormalizedPosition)
        self:Layout()
    end


    self:PlayAnimationAniObtain()
   
end

function XUiAreaWarObtain:RefreshAreaWarItem(areaWarItemList,horizontalNormalizedPosition)
    local isPlayItemAudio = false
    for _, itemData in pairs(areaWarItemList) do
        local go = XUiHelper.Instantiate(self.GridAreawarItem, self.PanelContent)
        go.gameObject:SetActiveEx(true)
        local grid = XUiGridAreaWarItem.New(go, self)
        grid:RefreshItem(itemData.ItemId, itemData.Num)
        grid:SetDefaultClickCallBack()
        
        -- 掉落超过金色品质的道具，播放音效
        local quality = self._Control:GetConfig():GetItemQuality(itemData.ItemId)
        if quality > XMVCA.XAreaWar.EnumConst.ITEM_QUALITY.GOLD then
            isPlayItemAudio = true
        end
    end

    if isPlayItemAudio then
        self:PlaySound("awardplus")
    end

    if horizontalNormalizedPosition then
        self.ScrView.horizontalNormalizedPosition = horizontalNormalizedPosition
    end
end

-- 播放音效
function XUiAreaWarObtain:PlaySound(name)
    self.AudioPlayer = self.AudioPlayer or self.Transform:GetComponent(typeof(CS.XAudioObjectPlayer))
    if self.AudioPlayer then
        self.AudioPlayer:PlayByKeyName(name)
    end
end

return XUiAreaWarObtain