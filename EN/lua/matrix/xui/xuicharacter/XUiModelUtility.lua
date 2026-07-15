local XUiModelUtility = {}

function XUiModelUtility.UpdateMonsterBossModel(panelRoleModel, modelId, targetUiName)
    panelRoleModel:UpdateBossModel(modelId, targetUiName)
    panelRoleModel:ShowRoleModel()
end

function XUiModelUtility.UpdateMonsterArchiveModel(ui, panelRoleModel, modelId, targetUiName, npcId, npcState,
    updateModelCallback)
    if string.IsNilOrEmpty(modelId) then
        return
    end

    local npcId = npcId or XMVCA.XArchive.MonsterArchiveAgency:GetMonsterNpcIdByModelId(modelId)

    if not XTool.IsNumberValid(npcId) then
        return
    end

    local effectDatas = XMVCA.XArchive.MonsterArchiveAgency:GetMonsterEffectDatas(npcId, npcState or 1)

    if not XTool.IsTableEmpty(ui.ModelUtilEffects) then
        for _, effect in pairs(ui.ModelUtilEffects) do
            if not XTool.UObjIsNil(effect) then
                effect.gameObject:SetActiveEx(false)
            end
        end
    end

    ui.ModelUtilEffects = {}
    panelRoleModel:SetDefaultAnimation(XModelManager.GetUiDefaultAnimationPath(modelId))
    panelRoleModel:UpdateArchiveMonsterModel(modelId, targetUiName, nil, updateModelCallback)
    panelRoleModel:ShowRoleModel()

    if effectDatas then
        for node, effectPath in pairs(effectDatas) do
            local parts = panelRoleModel.GameObject:FindTransform(node)

            if not XTool.UObjIsNil(parts) then
                local effect = parts.gameObject:LoadPrefab(effectPath, false)

                if effect then
                    effect.gameObject:SetActiveEx(true)
                    table.insert(ui.ModelUtilEffects, effect)
                end
            else
                XLog.Error("EffectNodeName Is Wrong :" .. node)
            end
        end
    end
end

return XUiModelUtility
