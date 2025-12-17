---@class XUiTheatre5CharacterTeaching: XUiNode
---@field protected _Control XTheatre5Control
local XUiTheatre5CharacterTeaching = XClass(XUiNode, 'XUiTheatre5CharacterTeaching')

function XUiTheatre5CharacterTeaching:OnStart()
    self._UiModelGo = XTool.InitUiObjectByUi({}, self.Parent.UiModelGo)
    self._ReCordObjectActiveDic = {}
    self._ReCordModelActiveDic = {}
end

function XUiTheatre5CharacterTeaching:OnEnable()
    XEventManager.AddEventListener(XMVCA.XTheatre5.EventId.EVENT_STORY_LINE_PROCESS_UPDATE, self.UpdateStoryLineProcess, self)
    self:Update()
end

function XUiTheatre5CharacterTeaching:OnDisable()
    XEventManager.RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_STORY_LINE_PROCESS_UPDATE, self.UpdateStoryLineProcess, self)
    local isInTeaching = self._Control.PVEControl:IsInTeachingStoryLine()
    if isInTeaching then
        self:Recover()
    end
end

--当前界面内的刷新
function XUiTheatre5CharacterTeaching:UpdateStoryLineProcess(storyLineId, contentId)
    local teachingStoryLineId = self._Control.PVEControl:GetTeachingStoryLineId()
    if storyLineId == teachingStoryLineId then
        if contentId and contentId <= 0 then --教学关结束
            self:Recover()
        end
    end       
end

function XUiTheatre5CharacterTeaching:Update()
    local isInTeaching = self._Control.PVEControl:IsInTeachingStoryLine()
    if not isInTeaching then
        return
    end
    local teachingStoryLineId = self._Control.PVEControl:GetTeachingStoryLineId()

    --设置按钮显隐
    local childCount = self.PanelFirst.transform.childCount
    for i = 0, childCount - 1 do
        local child = self.PanelFirst.transform:GetChild(i)
        local childName = child.gameObject.name
        local entranceCfg = self._Control.PVEControl:GetPveStoryEntranceCfg(childName)
        self._ReCordObjectActiveDic[child.gameObject] = child.gameObject.activeSelf
        if entranceCfg then
            local storyLineCfg = self._Control.PVEControl:GetStoryLineCfg(entranceCfg.StoryLine)
            local hasTeaching = entranceCfg.StoryLine == teachingStoryLineId 
                and storyLineCfg.StoryLineType == XMVCA.XTheatre5.EnumConst.PVEStoryLineType.Guide   
            child.gameObject:SetActiveEx(hasTeaching)
        else 
            child.gameObject:SetActiveEx(false)
        end    
    end

    self:SetModelVisible(false)
end

function XUiTheatre5CharacterTeaching:Recover()
   if not XTool.IsTableEmpty(self._ReCordObjectActiveDic) then
        for obj, active in pairs(self._ReCordObjectActiveDic) do
            if not XTool.UObjIsNil(obj) then
                obj:SetActiveEx(active)
            end    
        end
    end    

    if not XTool.IsTableEmpty(self._ReCordModelActiveDic) then
        for model, active in pairs(self._ReCordModelActiveDic) do
            if not XTool.UObjIsNil(model) then
                model:SetActiveEx(active)
            end    
        end
    end    
end

--设置模型显隐
function XUiTheatre5CharacterTeaching:SetModelVisible(enable)
    --目前只隐藏角色模型，物品模型保留显示，通过隐藏按钮规避交互
    local characterCfgs = self._Control:GetTheatre5CharacterCfgs()
    for i = 1, #characterCfgs do
        local model = self._UiModelGo['PanelRoleModel'..characterCfgs[i].Id]
        if model then
            self._ReCordModelActiveDic[model.gameObject] = model.gameObject.activeSelf  
            model.gameObject:SetActiveEx(enable)
        end
    end
    --self._ReCordModelActiveDic[self._UiModelGo.FxHeiban.gameObject] = not enable
    --self._UiModelGo.FxHeiban.gameObject:SetActiveEx(enable)

    --乌鸦反着来的，教学才显示
    self._ReCordModelActiveDic[self._UiModelGo.FxWuya.gameObject] = enable
    self._UiModelGo.FxWuya.gameObject:SetActiveEx(not enable)     
end

function XUiTheatre5CharacterTeaching:OnDestroy()
    self._ReCordObjectActiveDic = nil
    self._ReCordModelActiveDic = nil
end

return XUiTheatre5CharacterTeaching

