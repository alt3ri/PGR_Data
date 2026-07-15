local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@field _Control XPassportControl
---@class XUiPassportPanelGrid:XUiNode
local XUiPassportPanelGrid = XClass(XUiNode, "XUiPassportPanelGrid")

--通行证面板中间一列的格子
function XUiPassportPanelGrid:Init(rootUi, onClick)
    self.OnClick = onClick
    self.RootUi = rootUi
    self.GridObjs = {}
    self.PermitSlotData = {}
    self:AutoAddListener()
end

function XUiPassportPanelGrid:AutoAddListener()
    if self.Btn then
        XUiHelper.RegisterClickEvent(self, self.Btn, self.OnBtnClick)
    end
end

function XUiPassportPanelGrid:Refresh(levelId)
    self.LevelId = levelId
    self:UpdateLevelPanel()
    self:UpdatePermitPanel()
    self:UpdateRImgLock()
end

--当前等级没到显示黑色遮罩
function XUiPassportPanelGrid:UpdateRImgLock()
    local levelId = self:GetLevelId()
    local level = self._Control:GetPassportLevel(levelId)
    local baseInfo = self._Control:GetPassportBaseInfo()
    local currLevel = baseInfo:GetLevel()
    self.RImgLock.gameObject:SetActiveEx(currLevel < level)
end

--刷新物品格子
function XUiPassportPanelGrid:UpdatePermitPanel()
    local levelId = self:GetLevelId()
    local typeInfoIdList = self._Control:GetPassportActivityIdToTypeInfoIdList()
    local rewardData
    local grid
    local level = self._Control:GetPassportLevel(levelId)
    local isReceiveReward       --是否已领取奖励
    local isCanReceiveReward    --是否可领取奖励
    local passportInfo
    local isUnLock              --是否已解锁当前通行证奖励
    local isPrimeReward         --是否贵重奖励

    for i, typeInfoId in ipairs(typeInfoIdList) do
        grid = self.GridObjs[i]
        local gridCommonPermit = self["GridCommonPermit" .. i]
        if gridCommonPermit and not grid then
            grid = XUiGridCommon.New(self.RootUi, gridCommonPermit)
            self.GridObjs[i] = grid
            --首次创建时绑定一次，点击时读取PermitSlotData决定行为
            local slotIndex = i
            grid:SetClickCallback(function() self:OnPermitSlotClick(slotIndex) end)
        end

        local passportRewardId = self._Control:GetRewardIdByPassportIdAndLevel(typeInfoId, level)
        rewardData = passportRewardId and self._Control:GetPassportRewardData(passportRewardId)
        if XTool.IsNumberValid(rewardData) then
            isReceiveReward = self._Control:IsReceiveReward(typeInfoId, passportRewardId)
            isCanReceiveReward = self._Control:IsCanReceiveReward(typeInfoId, passportRewardId)

            --只更新数据，不重新绑定按钮
            if not self.PermitSlotData[i] then
                self.PermitSlotData[i] = {}
            end
            local slotData = self.PermitSlotData[i]
            slotData.passportRewardId = passportRewardId
            slotData.isReceiveReward = isReceiveReward
            slotData.isCanReceiveReward = isCanReceiveReward

            self:SetGridCommonPermitEffectActive(i, not isReceiveReward and isCanReceiveReward)
            grid:Refresh(rewardData)
            grid.GameObject:SetActive(true)
        else
            isReceiveReward = nil
            self.PermitSlotData[i] = nil
            grid.GameObject:SetActive(false)
            self:SetGridCommonPermitEffectActive(i, false)
        end

        --已领取标志
        local imgGetOutPermit = self["ImgGetOutPermit" .. i]
        if imgGetOutPermit then
            imgGetOutPermit.gameObject:SetActiveEx(isReceiveReward or false)
        end

        --未解锁标志
        local imgLockingPermit = self["ImgLockingPermit" .. i]
        if imgLockingPermit then
            passportInfo = self._Control:GetPassportInfos(typeInfoId)
            isUnLock = passportInfo and true or false
            imgLockingPermit.gameObject:SetActiveEx(not isUnLock)
        end

        --贵重奖励
        isPrimeReward = self._Control:IsPassportPrimeReward(passportRewardId)
        local rImgIsPrimeReward = self["RImgIsPrimeReward" .. i]
        if rImgIsPrimeReward then
            rImgIsPrimeReward.gameObject:SetActiveEx(isPrimeReward)
        end
    end
end

--点击子物品格子：可领取则领取，否则走默认的查看tip逻辑
function XUiPassportPanelGrid:OnPermitSlotClick(i)
    local data = self.PermitSlotData[i]
    if data and not data.isReceiveReward and data.isCanReceiveReward then
        self:GridOnClick(data.passportRewardId)
    else
        local grid = self.GridObjs[i]
        if grid then
            grid:OnBtnClickClick()
            self.OnClick()
        end
    end
end

function XUiPassportPanelGrid:SetGridCommonPermitEffectActive(index, isActive)
    local effectObj = self["GridCommonPermitEffect" .. index]
    if effectObj then
        effectObj.gameObject:SetActiveEx(isActive)
    end
end

function XUiPassportPanelGrid:GridOnClick(passportRewardId)
    self._Control:RequestPassportRecvReward(
        passportRewardId,
        function()
            self:UpdatePermitPanel()
            self.OnClick()
        end,
        self.RootUi)
end

function XUiPassportPanelGrid:UpdateLevelPanel()
    local levelId = self:GetLevelId()
    local level = self._Control:GetPassportLevel(levelId)
    local baseInfo = self._Control:GetPassportBaseInfo()
    local currLevel = baseInfo:GetLevel()
    local levelDesc = CS.XTextManager.GetText("PassportLevelDesc", level)

    --当前等级
    self.NowLevel.gameObject:SetActiveEx(currLevel == level)
    self.TxtNowLevel.text = levelDesc

    --超过当前等级
    self.ReachLevel.gameObject:SetActiveEx(currLevel > level)
    self.TxtReachLevel.text = levelDesc

    --当前等级未到达
    self.NotreachedLevel.gameObject:SetActiveEx(currLevel < level)
    self.TxtNotReachedLevel.text = levelDesc
end

function XUiPassportPanelGrid:GetLevelId()
    return self.LevelId
end

return XUiPassportPanelGrid
