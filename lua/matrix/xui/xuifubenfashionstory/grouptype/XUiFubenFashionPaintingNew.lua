local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiFubenFashionPaintingNew=XLuaUiManager.Register(XLuaUi,"UiFubenFashionPaintingNew")
local XUiGridFashionStoryStage=require('XUi/XUiFubenFashionStory/GroupType/XUiGridFashionStoryStage')
--region 生命周期
function XUiFubenFashionPaintingNew:OnAwake()
    self:Init()
    self:InitGridStoryList()
end

function XUiFubenFashionPaintingNew:OnStart(groupId)
    self.GroupId=groupId
    self:RefreshBackground()
    self:RefreshProcess()
    self:RefreshStoryGrids()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    local _, endTime = XMVCA.XFashionStory:GetActivityTime(XMVCA.XFashionStory:GetCurrentActivityId())
    self:SetAutoCloseInfo(endTime, function(isClose) self:UpdateLeftTime(isClose) end)
end

function XUiFubenFashionPaintingNew:OnEnable()
    self:UpdateLeftTime(XMVCA.XFashionStory:GetLeftTimeStamp(XMVCA.XFashionStory:GetCurrentActivityId())<=0)
end
--endregion

--region 初始化
function XUiFubenFashionPaintingNew:Init()
    self.BtnBack.CallBack=function() self:Close() end
    self.BtnMainUi.CallBack=function() XLuaUiManager.RunMain() end
    self.BtnSkip1.CallBack=function()
        --前往商店界面
        XFunctionManager.SkipInterface(XMVCA.XFashionStory:GetFashionStorySkipId(XMVCA.XFashionStory:GetCurrentActivityId(),XMVCA.XFashionStory.FashionStorySkip.SkipToStore))
    end
end

function XUiFubenFashionPaintingNew:InitGridStoryList()
    self.GridStoryList={}
    
    for i=1,XMVCA.XFashionStory.StageCountInGroupUpperLimit do
        if self['GridStory'..i] then
            self.GridStoryList[i]=XUiGridFashionStoryStage.New(self,self['GridStory'..i])
        end
    end
end
--endregion

--region 数据更新
function XUiFubenFashionPaintingNew:RefreshBackground()
    self.RImgFestivalBg:SetRawImage(XMVCA.XFashionStory:GetSingleLineChapterBg(self.GroupId))
    --self.ImgRole:SetRawImage(XMVCA.XFashionStory:GetStoryEntranceBg(self.GroupId))
    self.ImgTitle:SetRawImage(XMVCA.XFashionStory:GetSingleLineSummerFashionTitleImg(self.GroupId))
    
    -- v3.6 改成根据groupId显隐prefab
    local panelPrefab = self.PanelPrefab
    if panelPrefab then
        for i = 0, panelPrefab.childCount - 1 do
            local child = panelPrefab:GetChild(i)
            child.gameObject:SetActiveEx(false)
        end
        
        local name = "Prefab" .. self.GroupId
        local prefab = panelPrefab:Find(name)
        if prefab then
            prefab.gameObject:SetActiveEx(true)
        else
            XLog.Warning("[XUiFubenFashionPaintingNew] 找不到group对应显示的ui prefab")    
        end
    end
end

function XUiFubenFashionPaintingNew:RefreshProcess()
    local stagesCount=XMVCA.XFashionStory:GetSingleLineStagesCount(self.GroupId)
    local passedCount=XMVCA.XFashionStory:GetGroupStagesPassCount(XMVCA.XFashionStory:GetSingleLineStages(self.GroupId))
    self.TxtChapterLeftTime.text=tostring(passedCount)..'/'..tostring(stagesCount)
    if XOverseaManager.IsOverSeaRegion() then
        if self.GroupId == 12 then
            self.TxtListen.gameObject:SetActiveEx(false)
        else
            self.TxtListen.gameObject:SetActiveEx(true)
        end
    end
end

function XUiFubenFashionPaintingNew:RefreshStoryGrids()
    local stagesCount=XMVCA.XFashionStory:GetSingleLineStagesCount(self.GroupId)
    local stages=XMVCA.XFashionStory:GetSingleLineStages(self.GroupId)
    for i=1,XMVCA.XFashionStory.StageCountInGroupUpperLimit do
        if self['GridStory'..i] then
            self['GridStory'..i].gameObject:SetActiveEx(false)
        end
    end
    for i=1,stagesCount do
        if self['GridStory'..i] then
            self['GridStory'..i].gameObject:SetActiveEx(true)
            self.GridStoryList[i]:RefreshData(stages[i])
        end
    end
end

function XUiFubenFashionPaintingNew:UpdateLeftTime(isClose)
    if isClose then
        XUiManager.TipText("FashionStoryActivityEnd")
        XLuaUiManager.RunMain()
    end
end
--endregion

return XUiFubenFashionPaintingNew