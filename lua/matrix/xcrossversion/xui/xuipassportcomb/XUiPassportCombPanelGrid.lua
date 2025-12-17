local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@field _Control XPassportCombControl
---@class XUiPassportCombPanelGrid:XUiNode
local XUiPassportCombPanelGrid = XClass(XUiNode, "XUiPassportCombPanelGrid")

--通行证面板中间一列的格子
function XUiPassportCombPanelGrid:Ctor(ui)
    self.GridObjs = {}
    self:AutoAddListener()
end

function XUiPassportCombPanelGrid:Init(rootUi)
    self.RootUi = rootUi
end

function XUiPassportCombPanelGrid:AutoAddListener()
    if self.Btn then
        XUiHelper.RegisterClickEvent(self, self.Btn, self.OnBtnClick)
    end
end

function XUiPassportCombPanelGrid:Refresh(levelId)
    self.LevelId = levelId
    self:UpdateLevelPanel()
    self:UpdatePermitPanel()
    self:UpdateRImgLock()
end

--当前等级没到显示黑色遮罩
function XUiPassportCombPanelGrid:UpdateRImgLock()
    local levelId = self:GetLevelId()
    local level = self._Control:GetPassportLevel(levelId)
    local baseInfo = self._Control:GetPassportBaseInfo()
    local currLevel = baseInfo:GetLevel()
    self.RImgLock.gameObject:SetActiveEx(currLevel < level)
end

--刷新物品格子
function XUiPassportCombPanelGrid:UpdatePermitPanel()
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
        if self["GridCommonPermit" .. i] and not grid then
            grid = XUiGridCommon.New(self.RootUi, self["GridCommonPermit" .. i])
            self.GridObjs[i] = grid
        end

        local passportRewardId = self._Control:GetRewardIdByPassportIdAndLevel(typeInfoId, level)
        rewardData = passportRewardId and self._Control:GetPassportRewardData(passportRewardId)
        if XTool.IsNumberValid(rewardData) then
            isReceiveReward = self._Control:IsReceiveReward(typeInfoId, passportRewardId)
            isCanReceiveReward = self._Control:IsCanReceiveReward(typeInfoId, passportRewardId)
            if not isReceiveReward and isCanReceiveReward then
                grid:SetClickCallback(function() self:GridOnClick(passportRewardId) end)
                self:SetGridCommonPermitEffectActive(i, true)
            else
                grid:AutoAddListener()
                self:SetGridCommonPermitEffectActive(i, false)
            end

            grid:Refresh(rewardData)
            grid.GameObject:SetActive(true)
        else
            isReceiveReward = nil
            grid.GameObject:SetActive(false)
            self:SetGridCommonPermitEffectActive(i, false)
        end

        --已领取标志
        if self["ImgGetOutPermit" .. i] then
            self["ImgGetOutPermit" .. i].gameObject:SetActiveEx(isReceiveReward or false)
        end

        --未解锁标志
        if self["ImgLockingPermit" .. i] then
            passportInfo = self._Control:GetPassportInfos(typeInfoId)
            isUnLock = passportInfo and true or false
            self["ImgLockingPermit" .. i].gameObject:SetActiveEx(not isUnLock)

            if self["GridCommonPermitCanvasGroup" .. i] then
                self["GridCommonPermitCanvasGroup" .. i].alpha = isUnLock and 1 or 0.5   --未解锁时半透明
            end
        end

        --贵重奖励
        isPrimeReward = self._Control:IsPassportPrimeReward(passportRewardId)
        if self["RImgIsPrimeReward" .. i] then
            self["RImgIsPrimeReward" .. i].gameObject:SetActiveEx(isPrimeReward)
        end

        -- 此处有更好的做法, 可以用一个新的Lua对象来脱离该脚本, 提高效率, 但是现在时间不允许, 后续有机会务必优化此处
        local passportInfo = self._Control:GetPassportInfos(typeInfoId)
        if passportInfo then
            local buyTimes = passportInfo:GetBuyTimes()
            if self["Permit" .. i .. "Lv2"] then
                self["Permit" .. i .. "Lv2"].gameObject:SetActiveEx(buyTimes == 2)
            end
            if self["Permit" .. i .. "Lv3"] then
                self["Permit" .. i .. "Lv3"].gameObject:SetActiveEx(buyTimes == 3)
            end
        end
    end
end

function XUiPassportCombPanelGrid:SetGridCommonPermitEffectActive(index, isActive)
    local effectObj = self["GridCommonPermitEffect" .. index]
    if effectObj then
        effectObj.gameObject:SetActiveEx(isActive)
    end
end

function XUiPassportCombPanelGrid:GridOnClick(passportRewardId)
    self._Control:RequestPassportRecvReward(passportRewardId, handler(self, self.UpdatePermitPanel))
end

function XUiPassportCombPanelGrid:UpdateLevelPanel()
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

function XUiPassportCombPanelGrid:GetLevelId()
    return self.LevelId
end

return XUiPassportCombPanelGrid