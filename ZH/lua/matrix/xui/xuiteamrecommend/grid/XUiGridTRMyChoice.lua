-- 引用LuaUi：UiTeamRecommendMain
---@class XUiGridTRMyChoice : XUiNode 我的当前目标阵容格子
---@field RoleGridPool table[]
local XUiGridTRMyChoice = XClass(XUiNode, "XUiGridTRMyChoice")

function XUiGridTRMyChoice:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnCurTarget, self.OnBtnCurTargetClick)
    -- 隐藏模板GridRole
    self.GridRole.gameObject:SetActiveEx(false)
    self.RoleGridPool = {}
end

--- 刷新我的选择格子
---@param formationGridData table|nil { Formation=cfg, BaseFormation=cfg } nil则隐藏
function XUiGridTRMyChoice:Refresh(formationGridData)
    if not formationGridData then
        self:Close()
        return
    end
    self:Open()
    self.FormationGridData = formationGridData

    -- 使用中标签
    self.TagUsing.gameObject:SetActiveEx(true)

    -- 角色列表：按需生成GridRole
    self:RefreshRoleList(formationGridData)
end

function XUiGridTRMyChoice:RefreshRoleList(formationGridData)
    local roleList = XMVCA.XTeamRecommend:GetFormationRoleDisplayList(formationGridData, self.Parent.CharacterId)

    -- 先回收多余的
    for i = #roleList + 1, #self.RoleGridPool do
        self.RoleGridPool[i].GameObject:SetActiveEx(false)
    end

    for i, roleData in ipairs(roleList) do
        local item = self.RoleGridPool[i]
        if not item then
            local go = XUiHelper.Instantiate(self.GridRole.gameObject)
            go.transform:SetParent(self.ListRole, false)
            item = XTool.InitUiObjectByUi({}, go)
            self.RoleGridPool[i] = item
        end
        item.GameObject:SetActiveEx(true)

        local characterId = roleData.CharacterId
        if XTool.IsNumberValid(characterId) then
            item.RImgHead:SetRawImage(XMVCA.XCharacter:GetCharHalfBodyImage(characterId))
        end
    end
end

function XUiGridTRMyChoice:OnBtnCurTargetClick()
    if self.FormationGridData and self.Parent then
        -- true：从目标格子进入（FromOtherTarget身份）
        XLuaUiManager.Open("UiTeamRecommendDetail", self.FormationGridData, self.Parent.CharacterId, true)
    end
end

return XUiGridTRMyChoice
