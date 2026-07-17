---@class XUiGridGachaLiv4P5StageItem : XUiNode
---@field Parent XUiGachaLiv4P5StageLine
local XUiGridGachaLiv4P5StageItem = XClass(XUiNode, "XUiGridGachaLiv4P5StageItem")

function XUiGridGachaLiv4P5StageItem:OnStart()
    self._PlayEnableAnimHandler = function()
        if self._LoadedGo then
            -- 动画挂载在预制下，并伴随显示自动激活
            self._LoadedGo.gameObject:SetActiveEx(true)
        end
    end
end

function XUiGridGachaLiv4P5StageItem:SetNormalStage()
    self.PanelStageNormal.gameObject:SetActiveEx(not self._IsLock)
    if self.RImgStory then
        -- 战斗角色头像
        self.RImgStory:SetRawImage(self._FStage:GetStoryIcon())
    end
    if self.RImgTittle then
        -- 名字图片
        local url = XGachaConfigs.GetClientConfig("StageNameImgUrl", self._Index)
        self.RImgTittle:SetRawImage(url)
    end
    if self.TxtStageName then
        self.TxtStageName.text = self._FStage:GetName()
    end
    self.TxtStageOrder.text = self._FStage:GetOrderName()
    self.PanelStageLock.gameObject:SetActiveEx(self._IsLock)
end

function XUiGridGachaLiv4P5StageItem:SetPassStage()
    self.PanelStagePass.gameObject:SetActiveEx(self._FStage:GetIsPass())
end

function XUiGridGachaLiv4P5StageItem:UpdateNode(index, festivalId, stageId)
    local fStage = XDataCenter.FubenFestivalActivityManager.GetFestivalStageByFestivalIdAndStageId(festivalId, stageId)
    if not fStage then
        return
    end
    self._Index = index
    self._FestivalId = festivalId
    self._StageId = stageId
    self._FStage = fStage
    self._FChapter = fStage:GetChapter()
    self._StageIndex = fStage:GetOrderIndex()
    local stagePrefabName = fStage:GetStagePrefab()
    local isOpen, description = self._FStage:GetCanOpen()

    if isOpen then
        self:Open()
    else
        self:Close()    
    end
    
    local gridGameObject = self.Transform:LoadPrefab(stagePrefabName)
    local uiObj = gridGameObject.transform:GetComponent("UiObject")
    for i = 0, uiObj.NameList.Count - 1 do
        self[uiObj.NameList[i]] = uiObj.ObjList[i]
    end
    --self.RImgStory.transform:SetCanvasSortingOrder()
    --self.PanelStagePass:SetCanvasSortingOrder(1)
    self.BtnStage.CallBack = function()
        self:OnBtnStageClick()
    end
    self._IsLock = not isOpen
    self._Description = description
    self:SetNormalStage()
    self:SetPassStage()
    local isEgg = self._FStage:GetIsEggStage()
    self.ImgStageOrder.gameObject:SetActiveEx(not isEgg)
    if self.ImgStageHide then
        self.ImgStageHide.gameObject:SetActiveEx(isEgg)
    end
    if self.ImgHideLine then
        self.ImgHideLine.gameObject:SetActiveEx(isEgg)
    end
    
    self._LoadedGo = gridGameObject
end

function XUiGridGachaLiv4P5StageItem:OnBtnStageClick()
    if self._FStage then
        if not self._IsLock then
            self.Parent:UpdateNodesSelect(self._StageId)
            -- 打开详细界面
            self.Parent:OpenStageDetails(self._StageId, self._FestivalId)
        else
            XUiManager.TipMsg(self._Description)
        end
    end
end

function XUiGridGachaLiv4P5StageItem:SetNodeSelect(isSelect)
    if not self._IsLock and self.ImageSelected then
        self.ImageSelected.gameObject:SetActiveEx(isSelect)
    end
end

function XUiGridGachaLiv4P5StageItem:ResetItemPosition(pos)
    if self.ImgHideLine then
        local rect = self.ImgHideLine:GetComponent(typeof(CS.UnityEngine.RectTransform)).rect
        self.Transform.localPosition = CS.UnityEngine.Vector3(pos.x, pos.y - rect.height, pos.z)
    end
end


--region 入场间隔动画相关

function XUiGridGachaLiv4P5StageItem:PreEnableAnim()
    if self._LoadedGo then
        self._LoadedGo.gameObject:SetActiveEx(false)
    end
end

function XUiGridGachaLiv4P5StageItem:PlayEnableAnim(interval)
    self:DelayCall(self._PlayEnableAnimHandler, interval)
end

--endregion

return XUiGridGachaLiv4P5StageItem