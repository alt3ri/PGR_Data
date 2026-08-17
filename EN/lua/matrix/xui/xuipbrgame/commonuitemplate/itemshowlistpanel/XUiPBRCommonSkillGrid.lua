--- 通用的技能格子展示，使用该类至少大体上结构是一致的
---@class XUiPBRCommonSkillGrid : XUiNode
---@field _Control XPBRGameControl
--- 以下为 prefab 自动注入的 UI 节点
---@field ShowRoot UnityEngine.RectTransform 有技能时显示的根节点（内含图标/星级）
---@field EmptyRoot UnityEngine.RectTransform 无技能时显示的空占位根节点
---@field GridBtn XUiComponent.XUiButton 格子点击按钮（打开技能详情）
---@field RImgIcon UnityEngine.UI.RawImage 技能图标
---@field PanelStar UnityEngine.RectTransform 星级列表容器
---@field ImgStar UnityEngine.RectTransform 单颗星级图标模板（按品阶数量动态生成并按颜色染色）
---@field DetailPos UnityEngine.RectTransform 详情弹窗的锚点位置
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
    -- 无技能：整体切到空占位根节点
    if self.ShowRoot then
        self.ShowRoot.gameObject:SetActiveEx(false)
    end

    if self.EmptyRoot then
        self.EmptyRoot.gameObject:SetActiveEx(true)
    end
end

---@param itemData PbrItem
function XUiPBRCommonSkillGrid:UpdateItem(itemData)
    self.ItemId = nil

    if not XTool.IsTableEmpty(itemData) then
        self.ItemId = itemData.ItemId

        -- 有技能：整体切到内容根节点
        if self.ShowRoot then
            self.ShowRoot.gameObject:SetActiveEx(true)
        end

        if self.EmptyRoot then
            self.EmptyRoot.gameObject:SetActiveEx(false)
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
    XUiHelper.RefreshCustomizedList(self.PanelStar, self.ImgStar, level, nil)
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
