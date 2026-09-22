---@class XUiGridDALFestivalActivityStage: XUiNode
---@field Parent XUiDALFestivalActivityMain
local XUiGridDALFestivalActivityStage = XClass(XUiNode, 'XUiGridDALFestivalActivityStage')

function XUiGridDALFestivalActivityStage:OnStart()

end

function XUiGridDALFestivalActivityStage:SetNormalStage()
    if self.ImgNor then
        self.ImgNor:SetRawImage(self.FStage:GetIcon(), function()
            self.ImgNor:SetNativeSize()
        end)
    end

    local chapter = self.FStage:GetChapter()

    if chapter then
        self.TxtStageOrder.text = string.format("%s%d", chapter:GetStagePrefix(), self.FStage:GetOrderIndex())
    end
    self.TxtStageName.text = self.FStage:GetName()
    -- SetLockStage
    self.PanelStageLock.gameObject:SetActiveEx(self.IsLock)
end


function XUiGridDALFestivalActivityStage:SetPassStage()
    self.PanelStagePass.gameObject:SetActiveEx(self.FStage:GetIsPass())
end

function XUiGridDALFestivalActivityStage:UpdateNode(festivalId, stageId)
    local fStage = XDataCenter.FubenFestivalActivityManager.GetFestivalStageByFestivalIdAndStageId(festivalId, stageId)
    if not fStage then
        return
    end
    self.FestivalId = festivalId
    self.StageId = stageId
    self.FStage = fStage
    self.FChapter = fStage:GetChapter()
    self.StageIndex = fStage:GetOrderIndex()
    local stagePrefabName = fStage:GetStagePrefab()
    local isOpen, description = self.FStage:GetCanOpen()
    local isShow = self.FStage:GetIsShow()

    if isShow then
        self:Open()
    else
        self:Close()
    end

    local gridGameObject = self.Transform:LoadPrefab(stagePrefabName)
    local uiObj = gridGameObject.transform:GetComponent("UiObject")
    for i = 0, uiObj.NameList.Count - 1 do
        self[uiObj.NameList[i]] = uiObj.ObjList[i]
    end

    if self.ImageSelected then
        self.ImageSelected.gameObject:SetActiveEx(false)
    end

    -- AddEventListener 默认 clear=true(覆盖注册,非叠加)
    if self._BindedBtnStage ~= self.BtnStage then
        self.BtnStage:AddEventListener(function() self:OnBtnStageClick() end)
        self._BindedBtnStage = self.BtnStage
    end
    self.IsLock = not isOpen
    self.Description = description
    self:SetNormalStage()
    self:SetPassStage()
    self:SetClock()
    self:PlayStoryAnim()
end

-- 剧情关节点按配置循环播放 Timeline 动画：需配置动画名 + 条件ID，条件满足才播；条件ID为0(默认)不播
function XUiGridDALFestivalActivityStage:PlayStoryAnim()
    local animName = self.FStage:GetStoryAnimName()
    if not animName or animName == "" then return end
    local conditionId = self.FStage:GetStoryAnimCondition()
    if conditionId <= 0 then return end
    if not XConditionManager.CheckCondition(conditionId) then return end
    if XTool.UObjIsNil(self.Animation) then return end
    local animTrans = self.Animation:FindTransform(animName)
    if not animTrans or not animTrans.gameObject.activeInHierarchy then return end
    animTrans:PlayTimelineAnimation(nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
end

-- 返回可视图标 ImgNor 的屏幕中心像素 x（Camera 模式下用 WorldToScreenPoint 实测，兼容相机投影）。
function XUiGridDALFestivalActivityStage:GetFocusScreenCenterX()
    local node = self.ImgNor
    if not node then return nil end
    local tf = node.transform:GetComponent(typeof(CS.UnityEngine.RectTransform))
    if XTool.UObjIsNil(tf) then return nil end
    local corners = CS.System.Array.CreateInstance(typeof(CS.UnityEngine.Vector3), 4)
    tf:GetWorldCorners(corners)
    local canvas = self.GameObject:GetComponentInParent(typeof(CS.UnityEngine.Canvas))
    local cam = canvas and canvas.worldCamera or nil
    local sp0 = CS.UnityEngine.RectTransformUtility.WorldToScreenPoint(cam, corners[0])
    local sp2 = CS.UnityEngine.RectTransformUtility.WorldToScreenPoint(cam, corners[2])
    return (sp0.x + sp2.x) / 2
end

-- 时钟指针静态指向:时针 ImgHour、分针 ImgMinute 为独立图层节点
function XUiGridDALFestivalActivityStage:SetClock()
    local hour = self.FStage:GetClockHour()
    local minute = self.FStage:GetClockMinute()
    -- 12小时制:分针每分钟6°；时针每小时30°，并叠加分钟带来的偏移(每分钟0.5°)
    local minuteAngle = (minute % 60) * 6
    local hourAngle = ((hour % 12) * 60 + (minute % 60)) * 0.5
    if self.ImgMinute then
        self.ImgMinute.transform:SetLocalRotation(0, 0, -minuteAngle)
    end
    if self.ImgHour then
        self.ImgHour.transform:SetLocalRotation(0, 0, -hourAngle)
    end
end

function XUiGridDALFestivalActivityStage:OnBtnStageClick()
    if self.FStage then
        if not self.IsLock then
            self.Parent:UpdateNodesSelect(self.StageId)
            -- 打开详细界面
            self.Parent:OpenStageDetails(self.StageId, self.FestivalId)
        else
            XUiManager.TipMsg(self.Description)
        end

    end
end

function XUiGridDALFestivalActivityStage:SetNodeSelect(isSelect)
    if not self.IsLock then
        self.ImageSelected.gameObject:SetActiveEx(isSelect)
    end
end

-- 彩蛋关节点重定位:框架通用接口(见 XUiFubenChristmasMainLineChapter),DAL 暂无彩蛋关未调用,保留以备接入
function XUiGridDALFestivalActivityStage:ResetItemPosition(pos)
    if self.ImgHideLine then
        local rect = self.ImgHideLine:GetComponent(typeof(CS.UnityEngine.RectTransform)).rect
        self.Transform:SetLocalPosition(pos.x, pos.y - rect.height, pos.z)
    end
end

return XUiGridDALFestivalActivityStage
