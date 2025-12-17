
---@class XUiGridRaceFightUltraSkill : XUiNode
---@field Parent XUiRaceFightMain
local XUiGridRaceFightUltraSkill = XClass(XUiNode, "XUiGridRaceFightUltraSkill")
local SceneIds = require("XModule/XScene/XScene/XLuaSceneDefine").SceneIds

function XUiGridRaceFightUltraSkill:OnStart(...)
    -- self:_RegisterButtonClicks()

    self._Scene = XMVCA.XScene:GetScene(SceneIds.XRaceScene)
    self._renderTexture = CS.XRenderTextureManager.GetTemporary(154, 154, 0, CS.UnityEngine.RenderTextureFormat.Default, CS.UnityEngine.RenderTextureReadWrite.Default, false)
    self.PanelCam.texture = self._renderTexture
end

function XUiGridRaceFightUltraSkill:ClearCamera()
    if not self._Camera then return end
    self._Camera.targetTexture = nil
    self._Camera.gameObject:SetActive(false)
    self._Camera = nil
end

function XUiGridRaceFightUltraSkill:OnDestroy()
    self:ClearCamera()
    CS.XRenderTextureManager.ReleaseTemporary(self._renderTexture)
    self:RemoveTimer()
end

function XUiGridRaceFightUltraSkill:RemoveTimer()
    if not self._WaitTimerId then return end
    XScheduleManager.UnSchedule(self._WaitTimerId)
    self._WaitTimerId = nil
end

function XUiGridRaceFightUltraSkill:Update(charCfg, actorIndex, index)
    local skillCfg = self._Control:GetRaceCharacterSkillById(charCfg.UltraSkill)
    self.TxtTalk.text = skillCfg.UltraShout
    self.TxtName.text = charCfg.Name
    self.RImgHead:SetRawImage(charCfg.Icon)
    
    self:ClearCamera()
    self._Camera = self._Scene:GetActorUiCamera(actorIndex)
    if self._Camera then
        self._Camera.targetTexture = self._renderTexture
        self._Camera.gameObject:SetActive(true)
    end
    self:RemoveTimer()
    self._WaitTimerId = XScheduleManager.ScheduleOnce(function()
        self:ClearCamera()
        self.Parent:HideTips(charCfg, self)
    end, tonumber(self._Control:GetClientConfig("UtlraSkillShowTime")) or 2000)

    self.Transform:SetAsLastSibling()
end

function XUiGridRaceFightUltraSkill:_RegisterButtonClicks()
    -- self.GridMapCharacter.CallBack = Handler(self, self.OnBtnClick)
end

return XUiGridRaceFightUltraSkill
