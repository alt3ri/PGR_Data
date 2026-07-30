--- 通用的技能格子展示，使用该类至少大体上结构是一致的
---@class XUiPBRCommonSkillGrid : XUiNode
---@field _Control XPBRGameControl
local XUiPBRCommonSkillGrid = XClass(XUiNode, "XUiPBRCommonSkillGrid")

function XUiPBRCommonSkillGrid:OnStart(...)
    self:InitComponents()
end

function XUiPBRCommonSkillGrid:OnEnable()
end

function XUiPBRCommonSkillGrid:OnDisable()
end

function XUiPBRCommonSkillGrid:OnDestroy()

end

function XUiPBRCommonSkillGrid:InitComponents()
    -- 初始化时默认按没有技能处理
    self:SetEmptyShow()

    if self.GridBtn then
        self.GridBtn:AddEventListener(handler(self, self.OnGridBtnClick))
    end
end


function XUiPBRCommonSkillGrid:SetEmptyShow()
    self.ImgStar.gameObject:SetActiveEx(false)
    self.RImgIcon.gameObject:SetActiveEx(false)

    if self.ImgEmpty then
        self.ImgEmpty.gameObject:SetActiveEx(true)
    end
end

---@param itemData PbrItem
function XUiPBRCommonSkillGrid:UpdateItem(itemData)
    self.ItemId = nil
    
    if not XTool.IsTableEmpty(itemData) then
        self.ItemId = itemData.ItemId

        self.RImgIcon.gameObject:SetActiveEx(true)

        if self.ImgEmpty then
            self.ImgEmpty.gameObject:SetActiveEx(false)
        end
        
        -- 显示道具图标
        local itemCfg = self._Control:GetPBRItemCfgById(self.ItemId)

        if itemCfg then
            if not string.IsNilOrEmpty(itemCfg.Icon) then
                self.RImgIcon:SetRawImage(itemCfg.Icon)
            end
            -- 显示星级
            self:ShowStartByLevel(itemCfg.ItemTier, itemCfg.OrbColor)
            
            self:AOPRefreshItemAdditionShow()
        else
            self.RImgIcon:SetRawImage("")
            self:ShowStartByLevel(0, 0)
        end
    else
        self:SetEmptyShow()
    end
end

function XUiPBRCommonSkillGrid:ShowStartByLevel(level, orbColor)
    local colorTextList = self._Control:GetClientPBRTextArray('SkillOrbStarColor')
    local colorStr = colorTextList[orbColor + 1] or ''
    
    XUiHelper.RefreshCustomizedList(self.PanelStar, self.ImgStar, level, function(index, go)
        local img = go:GetComponent(typeof(CS.UnityEngine.UI.Image))

        if img and not string.IsNilOrEmpty(colorStr) then
            img.color = XUiHelper.Hexcolor2Color(string.gsub(colorStr, "#", ""))
        end
    end)
end

function XUiPBRCommonSkillGrid:OnGridBtnClick()
    if XTool.IsNumberValidEx(self.ItemId) then
        self._Control:DispatchEvent(XMVCA.XPBRGame.EventId.EVENT_PBR_INNER_OPEN_ITEM_DETAIL, self.DetailPos, self.ItemId)
    end
end

--- 子类重写，有内容时的额外刷新显示内容
function XUiPBRCommonSkillGrid:AOPRefreshItemAdditionShow()
    
end

return XUiPBRCommonSkillGrid
