local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiFubenFashionFittingNew=XLuaUiManager.Register(XLuaUi,"UiFubenFashionFittingNew")
local XUiGridFashionStoryTrialStage=require('XUi/XUiFubenFashionStory/GroupType/XUiGridFashionStoryTrialStage')
--region 生命周期
function XUiFubenFashionFittingNew:OnAwake()
    self:Init()
    self:InitStagesList()
end

function XUiFubenFashionFittingNew:OnStart()
    self:RefreshStageList()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    local _, endTime = XMVCA.XFashionStory:GetActivityTime(XMVCA.XFashionStory:GetCurrentActivityId())
    self:SetAutoCloseInfo(endTime, function(isClose) self:UpdateLeftTime(isClose) end)
end

function XUiFubenFashionFittingNew:OnEnable()
    self:UpdateLeftTime(XMVCA.XFashionStory:GetLeftTimeStamp(XMVCA.XFashionStory:GetCurrentActivityId())<=0)

    -- 3.6需求, 因为此版本只有一关, 所以直接打开此关卡
    local stageIds=XMVCA.XFashionStory:GetFashionStoryTrialStages(XMVCA.XFashionStory:GetCurrentActivityId())
    local idOnlyOne = stageIds[1]
    self:OpenOneChildUi('UiFashionStoryStageTrialDetailNew', idOnlyOne,handler(self, self.Close))
end
--endregion

--region 初始化
function XUiFubenFashionFittingNew:Init()
    self.BtnBack.CallBack=function() self:Close() end
    self.BtnMainUi.CallBack=function() XLuaUiManager.RunMain() end
    self.BtnSkip1.CallBack=function() 
        --前往商店界面
        XFunctionManager.SkipInterface(XMVCA.XFashionStory:GetFashionStorySkipId(XMVCA.XFashionStory:GetCurrentActivityId(),XMVCA.XFashionStory.FashionStorySkip.SkipToStore))
    end
    
    self.GridFitting.gameObject:SetActiveEx(false)
end

function XUiFubenFashionFittingNew:InitStagesList() 
    local count=XMVCA.XFashionStory:GetFashionStoryTrialStageCount(XMVCA.XFashionStory:GetCurrentActivityId())
    self.UiStagesList={}
    self.StagesList={}
    for i=1,count do
        self.UiStagesList[i]=CS.UnityEngine.GameObject.Instantiate(self.GridFitting,self.GridFitting.transform.parent)
        self.StagesList[i]=XUiGridFashionStoryTrialStage.New(self,self.UiStagesList[i])
        self.UiStagesList[i].gameObject:SetActiveEx(true)
    end
end
--endgion

--region 数据更新

function XUiFubenFashionFittingNew:RefreshStageList()
    local stageIds=XMVCA.XFashionStory:GetFashionStoryTrialStages(XMVCA.XFashionStory:GetCurrentActivityId())
    for i, stageCtrl in ipairs(self.StagesList) do
        stageCtrl:RefreshData(stageIds[i])
    end
end

function XUiFubenFashionFittingNew:UpdateLeftTime(isClose)
    if isClose then
        XUiManager.TipText("FashionStoryActivityEnd")
        XLuaUiManager.RunMain()
    end
end
--endregion

return XUiFubenFashionFittingNew