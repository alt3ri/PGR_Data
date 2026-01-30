local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGridNewPlayerTaskActive: XUiNode
local XUiGridNewPlayerTaskActive = XClass(XUiNode, "XUiGridNewPlayerTaskActive")

function XUiGridNewPlayerTaskActive:OnStart(rootUi, index, activeness, maxProgress)
    self.RootUi = rootUi

    self:InitAutoScript()

    self.Index = index or 1
    self.Activeness = activeness or 0
    self.MaxProgress = maxProgress

    self.NewbieActiveness = XTaskConfig.GetTaskNewbieActivenessTemplate()
    self:InitView()
end

function XUiGridNewPlayerTaskActive:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiGridNewPlayerTaskActive:AutoInitUi()
    self.BtnActive = self.Transform:Find("BtnActive"):GetComponent("Button")
    self.TxtValue = self.Transform:Find("TxtValue"):GetComponent("Text")
    self.PanelEffect = self.Transform:Find("PanelEffect")
    self.BigEffect = self.Transform:Find("BigEffect")
    self.ImgRe = self.Transform:Find("ImgRe"):GetComponent("Image")
    self.GridCommon = self.Transform:Find("Grid128")
end

function XUiGridNewPlayerTaskActive:AutoAddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnActive, self.OnBtnActiveClick)
end

function XUiGridNewPlayerTaskActive:InitView()
    self.TxtValue.text = self.Activeness
    
    local rewardId = self.NewbieActiveness.RewardId[self.Index]
    local data = XRewardManager.GetRewardList(rewardId)
    if #data >= 1 then
        self.GridCommon = XUiGridCommon.New(self.RootUi, self.GridCommon)
        self.GridCommon:Refresh(data[1])
    end 
    if self.BigEffect then
        self.BigEffect.gameObject:SetActive(self:GetActiveBigEffect())
    end
end

function XUiGridNewPlayerTaskActive:Refresh(progressNumber)
    self.CurrentProgress = progressNumber

    if XDataCenter.TaskManager.CheckNewbieActivenessRecord(self.Activeness) then
        self:ChangeActiveState(true, false)
    else
        if self.CurrentProgress >= self.Activeness then
            self:ChangeActiveState(false, true)
        else
            self:ChangeActiveState(false, false)
        end
    end
end

function XUiGridNewPlayerTaskActive:ChangeActiveState(imgRe, effect)
    self.ImgRe.gameObject:SetActive(imgRe)
    self.PanelEffect.gameObject:SetActive(effect)
end

function XUiGridNewPlayerTaskActive:OnBtnActiveClick()
    if self.CurrentProgress and self.MaxProgress then
        local rewardId = self.NewbieActiveness.RewardId[self.Index]
        local rewardList = XRewardManager.GetRewardList(rewardId)

        if XDataCenter.TaskManager.CheckNewbieActivenessRecord(self.Activeness) then
            self:ShowTips(rewardList)
        else
            if self.CurrentProgress >= self.Activeness then
                XDataCenter.TaskManager.GetNewPlayerRewardReq(self.Activeness, rewardList, function(rewards)
                    -- 刷新所有
                    self.Parent:RefreshProgress()
                    self.Parent:CheckIsNewPlayerTaskOver()
                end)
            else
                self:ShowTips(rewardList)
            end
        end
    end
end

function XUiGridNewPlayerTaskActive:ShowTips(rewardList)
    for _, v in pairs(rewardList or {}) do
        local templateId = v.TemplateId
        local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(templateId)
        if goodsShowParams.RewardType == XRewardManager.XRewardType.Character then
            if self.RootUi.Ui.UiData.UiType == CsXUiType.Tips then
                self.RootUi:Close()
            end
            XLuaUiManager.Open("UiCharacterDetail", templateId)
        elseif goodsShowParams.RewardType == XRewardManager.XRewardType.Equip then
            if self.RootUi.Ui.UiData.UiType == CsXUiType.Tips then
                self.RootUi:Close()
            end
            XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipPreview(templateId)
        else
            XLuaUiManager.Open("UiTip", templateId)
        end
        break
    end
end

function XUiGridNewPlayerTaskActive:GetActiveBigEffect()
    local bigReward = self.NewbieActiveness.BigReward
    if not bigReward then
        return false
    end
    local info = string.Split(bigReward,"|")
    for _, id in pairs(info or {}) do
        if tonumber(id) == self.Index then
            return true
        end
    end
    return false
end

return XUiGridNewPlayerTaskActive