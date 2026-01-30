--- 序章动态漫入口专用
---@class XUiGridStageExNewbie
local XUiGridStageExNewbie = XClass(nil, 'XUiGridStageExNewbie')

function XUiGridStageExNewbie:Ctor(ui, parent, rootUi, stageCfg)
    XTool.InitUiObjectByUi(self, ui)
    self.Parent = parent
    self.RootUi = rootUi
    self.StageCfg = stageCfg
    
    self.GridStoryStage:AddEventListener(handler(self, self.OnBtnStageClick))
    self.GridStoryStage:SetNameByGroup(0, XMVCA.XMainLine2:GetClientConfigParams('NewbiePreChapterExStageName', 1))
    
    -- 设置底图
    local img = XMVCA.XMainLine2:GetClientConfigParams('NewbiePreChapterExStageImg', 1)

    if not string.IsNilOrEmpty(img) then
        self.GridStoryStage:SetRawImage(img)
    end
    
    -- 设置标签
    local tags = XMVCA.XMainLine2:GetClientConfigParams('NewbiePreChapterExStageLabels')

    XUiHelper.RefreshCustomizedList(self.PanelTag.transform, self.GridTag, tags and #tags or 0, function(index, go)
        local txtTag = go:GetComponentInChildren(typeof(CS.UnityEngine.UI.Text))

        if txtTag then
            txtTag.text = tags[index]
        end
    end)
    
    self:Refresh()
end

function XUiGridStageExNewbie:Refresh()
    -- 判断是否通关
    local isPass = XMVCA.XFuben:CheckStageIsPass(self.StageCfg.StageId)

    if self.Clear then
        self.Clear.gameObject:SetActiveEx(isPass)
    end
end

function XUiGridStageExNewbie:OnBtnStageClick()
    XLuaUiManager.Open('UiMainLineExhibitionPopupComic', self.StageCfg)
end

return XUiGridStageExNewbie