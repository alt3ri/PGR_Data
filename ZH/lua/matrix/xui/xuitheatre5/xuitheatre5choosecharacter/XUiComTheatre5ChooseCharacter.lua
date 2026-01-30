--- 挂在XLuaUi的GameObject上的“组件”基类，因为目前Ui框架并不方便XLuaUi在不新增注册配置的情况下复用，新增子节点方便PVP、PVE后续的扩展
---@class XUiComTheatre5ChooseCharacter: XUiNode
---@field protected _Control XTheatre5Control
---@field Parent UiTheatre5ChooseCharacter
local XUiComTheatre5ChooseCharacter = XClass(XUiNode, 'XUiComTheatre5ChooseCharacter')
local XUiPanelTheatre5CharacterList = require('XUi/XUiTheatre5/XUiTheatre5ChooseCharacter/XUiPanelTheatre5CharacterList')
local XUiPanelTheatre5CharacterDetail = require('XUi/XUiTheatre5/XUiTheatre5ChooseCharacter/XUiPanelTheatre5CharacterDetail')
local XUiPanelTheatre5PVECharacterDetail = require('XUi/XUiTheatre5/XUiTheatre5ChooseCharacter/PVE/XUiPanelTheatre5PVECharacterDetail')
local XUiPanelTheatre5CharacterShows = require('XUi/XUiTheatre5/XUiTheatre5ChooseCharacter/XUiPanelTheatre5CharacterShows')
local XUiPanelTheatre5PVECharacterShows = require('XUi/XUiTheatre5/XUiTheatre5ChooseCharacter/PVE/XUiPanelTheatre5PVECharacterShows')
local XUiModelTheatre5ChooseCharacter3D = require('XUi/XUiTheatre5/XUiTheatre5ChooseCharacter/XUiModelTheatre5ChooseCharacter3D')

function XUiComTheatre5ChooseCharacter:Init()
    self:_InitPanels()
    self:_InitButtons()
end

--- 初始化各个子面板，子类可重写
function XUiComTheatre5ChooseCharacter:_InitPanels()
    self.TxtName = self.TxtName or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/DetailRoot/PanelName/TxtName (1)", "Text")
    
    if self.PanelDetail then
        self.PanelDetail.gameObject:SetActiveEx(false)
    end
    if self.PanelDetail02 then    
        self.PanelDetail02.gameObject:SetActiveEx(false)
    end    

    ---@type XUiPanelTheatre5CharacterList
    self.ListCharacter.gameObject:SetActiveEx(false)
    self.PanelCharacterList = XUiPanelTheatre5CharacterList.New(self.ListCharacter, self)

    local gameMode = self._Control:GetCurPlayingMode()
    if gameMode == XMVCA.XTheatre5.EnumConst.GameMode.PVP then
        ---@type XUiPanelTheatre5CharacterShows
        self.PanelCharacterShows = XUiPanelTheatre5CharacterShows.New(self.PanelFirst, self)
        self.PanelCharacterShows:Open()
        ---@type XUiPanelTheatre5CharacterDetail
        self.PanelCharacterDetail = XUiPanelTheatre5CharacterDetail.New(self.PanelDetail, self)
    elseif gameMode == XMVCA.XTheatre5.EnumConst.GameMode.PVE then
        ---@type XUiPanelTheatre5PVECharacterShows
        self.PanelCharacterShows = XUiPanelTheatre5PVECharacterShows.New(self.PanelFirst, self)
        self.PanelCharacterShows:Open()
        ---@type XUiPanelTheatre5PVECharacterDetail
        self.PanelCharacterDetail = XUiPanelTheatre5PVECharacterDetail.New(self.PanelDetail02, self)
    end

    ---@type XUiModelTheatre5ChooseCharacter3D
    self.Model3D = XUiModelTheatre5ChooseCharacter3D.New(self.Parent.UiModelGo, self)
    self.Model3D:LoadCharacters(self._Control:GetTheatre5CharacterCfgs())

    self:_SetChooseDetailShow(false)
end

--- 按钮控件初始化，子类可重写
function XUiComTheatre5ChooseCharacter:_InitButtons()
    
end


--- 刷新右侧角色详情
function XUiComTheatre5ChooseCharacter:RefreshDetailShow(index, cfg)
    self.Model3D:SetCharacterFocus(index)
    -- 检查引导
    XDataCenter.GuideManager.CheckGuideOpen()

    local gameMode = self._Control:GetCurPlayingMode()
    if gameMode == XMVCA.XTheatre5.EnumConst.GameMode.PVP then
        self.TxtName.text = cfg.Name
    else
        self.TxtName.transform.parent.gameObject:SetActiveEx(false)
    end
    if self:CheckIsShowDetail() then
        self:PlayAnimation('FadeOut', function()
            self.PanelCharacterDetail:RefreshShow(cfg)
            self:PlayAnimation('FadeIn')
        end)
    else
        self.PanelCharacterDetail:RefreshShow(cfg)
        self:PlayAnimation('Enable')
    end
    
    self.Parent:SetSkipId(cfg.SkipId)
end

--- 从全角色预览子界面切换到详情
function XUiComTheatre5ChooseCharacter:OnSelectCharacter(index)
    self.Model3D:SetCharacterFocus(index)
    self:_SetChooseDetailShow(true)
    self.PanelCharacterList:OnBtnSelect(index, true)
    self._IsShowDetail = true
end

function XUiComTheatre5ChooseCharacter:_SetChooseDetailShow(isShow)
    if isShow then
        self.DetailRoot.gameObject:SetActiveEx(true)
        self.PanelCharacterDetail:Open()
        self.PanelCharacterList:Open()
    else
        self.PanelCharacterDetail:Close()
        self.PanelCharacterList:Close()
        self.DetailRoot.gameObject:SetActiveEx(false)
        self.Model3D:SetCharacterFocus(0)
    end
end

--- 从详情子界面切换到全角色预览
function XUiComTheatre5ChooseCharacter:SwitchToFullView()
    self.Model3D:SetCharacterFocus(nil)
    self:_SetChooseDetailShow(false)
    self.PanelCharacterList:OnBtnSelect(nil, true)
    self.PanelCharacterShows:Open()
    self._IsShowDetail = false
end

function XUiComTheatre5ChooseCharacter:SetCharactersVisible(characters, enable)
    self.Model3D:SetCharactersVisible(characters, enable)
end

function XUiComTheatre5ChooseCharacter:CheckIsShowDetail()
    return self._IsShowDetail
end

return XUiComTheatre5ChooseCharacter