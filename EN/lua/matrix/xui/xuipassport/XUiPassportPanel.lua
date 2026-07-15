local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiPassportPanelGrid = require("XUi/XUiPassport/XUiPassportPanelGrid")

---@field _Control XPassportControl
---@class XUiPassportPanel:XUiNode
local XUiPassportPanel = XClass(XUiNode, "XUiPassportPanel")

--通行证面板
function XUiPassportPanel:OnStart(refreshOneKeyGetRewardsButton)
    self.RefreshOneKeyGetRewardsButton = refreshOneKeyGetRewardsButton or function() end
    self.LevelIdList = false
    self:InitRightGrids()
    self:InitDynamicList()
    self:AutoAddListener()
    self:InitData()
    self:Refresh()
end

function XUiPassportPanel:InitRightGrids()
    self.RightGrids = {}
    self.RightGridData = {}
    local typeInfoIdList = self._Control:GetPassportActivityIdToTypeInfoIdList()
    for i in ipairs(typeInfoIdList) do
        self.RightGrids[i] = XUiGridCommon.New(self.Parent, self["GridCommonRight" .. i])
        --只在初始化时绑定一次，点击时读取RightGridData决定行为
        local slotIndex = i
        self.RightGrids[i]:SetClickCallback(function() self:OnRightGridClick(slotIndex) end)
    end
end

--点击右侧固定格子：可领取则领取，否则走默认的查看tip逻辑
function XUiPassportPanel:OnRightGridClick(i)
    local data = self.RightGridData[i]
    if data and not data.isReceiveReward and data.isCanReceiveReward then
        self:GridOnClick(data.passportRewardId)
    else
        local grid = self.RightGrids[i]
        if grid then
            grid:OnBtnClickClick()
        end
    end

    self.RefreshOneKeyGetRewardsButton()
end

function XUiPassportPanel:InitData()
    local activityId = self._Control:GetDefaultActivityId()
    self.LevelIdList = self._Control:GetPassportLevelIdListByRewardType(activityId, XEnumConst.PASSPORT.REWARD_TYPE.NORMAL)
end

function XUiPassportPanel:InitDynamicList()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiPassportPanelGrid, self)
    self.DynamicTable:SetDelegate(self)
    self.Grid01.gameObject:SetActiveEx(false)

    local gridWidth = self.Grid01:GetComponent("RectTransform").rect.size.x
    local panelWidth = self.PanelItemList:GetComponent("RectTransform").rect.size.x
    self.DynamicTableOffsetIndex = math.floor(panelWidth / gridWidth / 2)
end

function XUiPassportPanel:AutoAddListener()
    local typeInfoIdList = self._Control:GetPassportActivityIdToTypeInfoIdList()
    for i, typeInfoId in ipairs(typeInfoIdList) do
        if self["BtnUnlockLeftGrid" .. i] then
            self["BtnUnlockLeftGrid" .. i]:AddEventListener(function()
                self:OnBtnUnlockLeftGridClick(typeInfoId)
            end)
        end
    end
end

function XUiPassportPanel:Refresh()
    self:UpdateDynamicTable()
    self:UpdateLeftGrid()
    self.RefreshOneKeyGetRewardsButton()
end

--遍历DynamicTable的Grid，根据最大等级的LevelId刷新
function XUiPassportPanel:UpdateRightGrid()
    local currMaxLevel = 0
    for _, v in pairs(self.DynamicTable:GetGrids()) do
        local levelIdCfg = v:GetLevelId()
        local levelCfg = self._Control:GetPassportLevel(levelIdCfg)
        if currMaxLevel < levelCfg then
            currMaxLevel = levelCfg
        end
    end

    local targetLevel = self._Control:GetPassportTargetLevel(currMaxLevel)
    if not targetLevel then
        self.PanelRewardRight.gameObject:SetActiveEx(false)
        return
    else
        self.PanelRewardRight.gameObject:SetActiveEx(true)
    end

    self.TxtLevelRight.text = targetLevel and CS.XTextManager.GetText("PassportLevelDesc", targetLevel) or ""

    local grid
    local rewardData
    local typeInfoIdList = self._Control:GetPassportActivityIdToTypeInfoIdList()

    local isReceiveReward
    local isCanReceiveReward
    local isShowEffect
    local isPrimeReward

    for i, typeInfoId in ipairs(typeInfoIdList) do
        local passportRewardId = self._Control:GetRewardIdByPassportIdAndLevel(typeInfoId, targetLevel)
        grid = self.RightGrids[i]

        if grid then
            rewardData = passportRewardId and self._Control:GetPassportRewardData(passportRewardId)
            if XTool.IsNumberValid(rewardData) then
                grid:Refresh(rewardData)
                grid.GameObject:SetActive(true)

                isReceiveReward = self._Control:IsReceiveReward(typeInfoId, passportRewardId)
                isCanReceiveReward = self._Control:IsCanReceiveReward(typeInfoId, passportRewardId)

                --只更新数据，不重新绑定按钮
                if not self.RightGridData[i] then
                    self.RightGridData[i] = {}
                end
                local slotData = self.RightGridData[i]
                slotData.passportRewardId = passportRewardId
                slotData.isReceiveReward = isReceiveReward
                slotData.isCanReceiveReward = isCanReceiveReward
            else
                isCanReceiveReward = nil
                isReceiveReward = nil
                self.RightGridData[i] = nil
                grid.GameObject:SetActive(false)
            end
        end

        --已领取标志
        if self["ImgGetOutRight" .. i] then
            self["ImgGetOutRight" .. i].gameObject:SetActiveEx(isReceiveReward)
        end

        --未解锁标志
        if self["ImgLockingRight" .. i] then
            local passportInfo = self._Control:GetPassportInfos(typeInfoId)
            local isUnLock = passportInfo and true or false
            self["ImgLockingRight" .. i].gameObject:SetActiveEx(not isUnLock)
        end

        --可领取特效
        isShowEffect = not isReceiveReward and isCanReceiveReward and XTool.IsNumberValid(rewardData)
        if self["PanelPermitEffect" .. i] then
            self["PanelPermitEffect" .. i].gameObject:SetActiveEx(isShowEffect)
        end

        --贵重奖励
        isPrimeReward = self._Control:IsPassportPrimeReward(passportRewardId)
        if self["RImgIsPrimeReward" .. i] then
            self["RImgIsPrimeReward" .. i].gameObject:SetActiveEx(isPrimeReward)
        end
    end
end

function XUiPassportPanel:UpdateLeftGrid()
    local typeInfoIdList = self._Control:GetPassportActivityIdToTypeInfoIdList()
    local passportInfo
    local isUnLock
    for i, typeInfoId in ipairs(typeInfoIdList) do
        passportInfo = self._Control:GetPassportInfos(typeInfoId)
        isUnLock = passportInfo and true or false
        if self["TxtNameLeftGrid" .. i] then
            self["TxtNameLeftGrid" .. i].text = self._Control:GetPassportTypeInfoName(typeInfoId)
        end
        if self["ImgLockLeftGrid" .. i] then
            self["ImgLockLeftGrid" .. i].gameObject:SetActiveEx(not isUnLock)
        end
        if self["BtnUnlockLeftGrid" .. i] then
            self["BtnUnlockLeftGrid" .. i].gameObject:SetActiveEx(true)
            self["BtnUnlockLeftGrid" .. i]:SetDisable(isUnLock)
        end
    end
end

function XUiPassportPanel:UpdateDynamicTable()
    local index = self:GetDefaultIndex()
    self.DynamicTable:SetDataSource(self.LevelIdList)
    self.DynamicTable:ReloadDataSync(index)
end

function XUiPassportPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.Parent, self.RefreshOneKeyGetRewardsButton)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local levelId = self.LevelIdList[index]
        grid:Refresh(levelId)
        self:UpdateRightGrid()
    end
end

-- 获得默认选中index
function XUiPassportPanel:GetDefaultIndex()
    local baseInfo = self._Control:GetPassportBaseInfo()
    local currLevel = baseInfo:GetLevel()
    local level = -1
    local index = 0

    for i, levelId in ipairs(self.LevelIdList) do
        level = self._Control:GetPassportLevel(levelId)
        if level >= currLevel then
            index = i
            break
        end
    end

    -- 当前等级超出配置，拉到最后
    if level < currLevel then
        index = #self.LevelIdList
    end

    index = math.max(1, index - self.DynamicTableOffsetIndex)
    return index
end

function XUiPassportPanel:OnBtnUnlockLeftGridClick()
    XLuaUiManager.Open("UiPassportCard", handler(self, self.Refresh), self.Parent)
end

function XUiPassportPanel:Show()
    self:Open()
    self:Refresh()
end

function XUiPassportPanel:Hide()
    self:Close()
end

function XUiPassportPanel:GridOnClick(passportRewardId)
    local cb = function()
        self.DynamicTable:ReloadDataASync()
    end
    self._Control:RequestPassportRecvReward(passportRewardId, cb, self.Parent)
end

function XUiPassportPanel:OpenLastPassport()
    local typeInfoIdList = self._Control:GetPassportActivityIdToTypeInfoIdList()
    local lastOne = typeInfoIdList[#typeInfoIdList]
    if lastOne then
        self:OnBtnUnlockLeftGridClick(lastOne)
    end
end

return XUiPassportPanel