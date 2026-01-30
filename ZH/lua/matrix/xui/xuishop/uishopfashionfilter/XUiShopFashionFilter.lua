--- 涂装选择筛选界面
---@class XUiShopFashionFilter: XLuaUi
local XUiShopFashionFilter = XLuaUiManager.Register(XLuaUi, 'UiShopFashionFilter')

local XUiPanelFilterCareer = require('XUi/XUiShop/UiShopFashionFilter/XUiPanelFilterCareer')
local XUiPanelFilterCharacterList = require('XUi/XUiShop/UiShopFashionFilter/XUiPanelFilterCharacterList')
local XUiPanelFilterElement = require('XUi/XUiShop/UiShopFashionFilter/XUiPanelFilterElement')

function XUiShopFashionFilter:OnAwake()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnClose, self.OnCancelFliter)
    self:RegisterClickEvent(self.BtnConfirm, self.OnSubmitFliter)
end

function XUiShopFashionFilter:OnStart(SelectData, dataProvider, selectCallBack,screenGroupCfg)
    self.DataProvider = dataProvider
    self.OrginDataProvider = dataProvider
    self.SelectCallBack = selectCallBack
    self.CurData = SelectData
    self.GroupCfgExtendData = screenGroupCfg
    self:InitTagGroups()

    self.PanelFliterCareer = XUiPanelFilterCareer.New(self.PanelCareer, self,
        self._FliterTagGroupList[CharacterFilterTagTypeNum.Career], SelectData.careerTags)
    self.PanelFliterElement = XUiPanelFilterElement.New(self.PanelElement, self,
        self._FliterTagGroupList[CharacterFilterTagTypeNum.Element], SelectData.elementTags)
    self.PanelFliterCharacterList = XUiPanelFilterCharacterList.New(self.PanelCharacterList, self, SelectData
        .selectId)

    self.PanelFliterCareer:Open()
    self.PanelFliterElement:Open()
    self.PanelFliterCharacterList:Open()
    self:RefreshCharacterListShow()
end

function XUiShopFashionFilter:RefreshViewUI()
    self.TxtSelectTitle.gameObject:SetActiveEx(self.GroupCfgExtendData )
    if not self.GroupCfgExtendData then
        return
    end
    local characterId = self.PanelFliterCharacterList:GetCurSelectedCharacterId()
    if not characterId or not  XTool.IsNumberValid(characterId) or not self.GroupCfgExtendData[characterId] then 
      self.TxtSelectState.text = CS.XTextManager.GetText("UnChoose")
      return
    end
    
    self.TxtSelectState.text = self.GroupCfgExtendData[characterId]

end
function XUiShopFashionFilter:InitTagGroups()
    -- 拿到该筛选类型要显示的所有标签
    local allTags = XRoomCharFilterTipsConfigs.GetFilterTagCommonGroupTags(CharacterFilterGroupType.FashionShop)
    -- 将标签按组分类
    local allTagGroups = XRoomCharFilterTipsConfigs.GetFilterTagGroup()
    local groupTagDic = {} -- key为CharacterFilterTagGroup.tab对应的group的Id, value = { {TagId = 标签id1, Order = 1}，{TagId = 标签id2, Order = 2} ...}
    for i, tagId in pairs(allTags) do
        local currTagGroupId = nil
        local currTagOrder = 1
        --1.找到该tag的groupId
        for groupId, v in pairs(allTagGroups) do
            local isContainInThisGroup = table.contains(v.Tags, tagId)
            if isContainInThisGroup then
                currTagGroupId = groupId
                currTagOrder = i
            end
        end
        --2.插入字典
        if not groupTagDic[currTagGroupId] then
            groupTagDic[currTagGroupId] = {}
        end
        if currTagGroupId then
            table.insert(groupTagDic[currTagGroupId], { TagId = tagId, Order = currTagOrder })
        end
    end

    self._FliterTagGroupList = groupTagDic
end

function XUiShopFashionFilter:RefreshCharacterListShow()
    local careerTags = self.PanelFliterCareer:GetSelectedTags()
    local elementTags = self.PanelFliterElement:GetSelectedTags()
    local tempList = {}
    local tempMap = {}
 
    local isCareerTags = function(characterId)
        if not XTool.IsTableEmpty(careerTags) then
            local charaCareer = XMVCA.XCharacter:GetCharacterCareer(characterId)
            local isSatisfyAnyCareer = true
            for careerTag, _ in pairs(careerTags) do
                local career = XRoomCharFilterTipsConfigs.GetFilterTagValue(careerTag)
                if charaCareer == career then
                    isSatisfyAnyCareer = false
                end
            end
            return isSatisfyAnyCareer
        end
        return false
    end
    -- 剔除非选中元素的角色
    local isElementTags = function(characterId)
        if not XTool.IsTableEmpty(elementTags) then
            local charaElement = XMVCA.XCharacter:GetCharacterElement(characterId)
            local isSatisfyAnyElementr = true
            for elementTag, _ in pairs(elementTags) do
                local element = XRoomCharFilterTipsConfigs.GetFilterTagValue(elementTag)
                if charaElement == element then
                    isSatisfyAnyElementr = false
                end
            end
            return isSatisfyAnyElementr
        end
        return false
    end
    for i, data in ipairs(self.DataProvider) do
        if data.characterId~= 0 and not tempMap[data.characterId] then
            tempMap[data.characterId] = true
            if not isCareerTags(data.characterId) and not isElementTags(data.characterId)then 
                table.insert(tempList,data)
            end
        end
    end

    table.sort(tempList, function(a, b)
        local priorityA = XMVCA.XCharacter:GetCharacterPriority(a.characterId)
        local priorityB = XMVCA.XCharacter:GetCharacterPriority(b.characterId)

        if priorityA ~= priorityB then
            return priorityA > priorityB
        end

        return a.characterId > b.characterId
    end)

    self.PanelFliterCharacterList:RefreshList(tempList)
    self:RefreshSubmitBtnState()

end

function XUiShopFashionFilter:RefreshSubmitBtnState()
    local characterId = self.PanelFliterCharacterList:GetCurSelectedCharacterId()

    self._IsCanSubmit = XTool.IsNumberValid(characterId)

    self.BtnConfirm:SetButtonState(self._IsCanSubmit and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self:RefreshViewUI()
end

function XUiShopFashionFilter:OnCancelFliter()
    self:Close()
    if self.SelectCallBack then
         local resultData ={
                selectId = nil,
                careerTags = nil,
                elementTags = nil
            }
        self.SelectCallBack(resultData)
    end
end

function XUiShopFashionFilter:OnSubmitFliter()
    if self._IsCanSubmit then
        self:Close()
        if self.SelectCallBack then
            local resultData ={
                selectId = self.PanelFliterCharacterList:GetCurSelectedCharacterId(),
                careerTags = self.PanelFliterCareer:GetSelectedTags(),
                elementTags = self.PanelFliterElement:GetSelectedTags()
            }
            self.SelectCallBack(resultData)
        end
    else
        XUiManager.TipText('UiShopFashionFilterSubmitFaultTips')
    end
end

return XUiShopFashionFilter