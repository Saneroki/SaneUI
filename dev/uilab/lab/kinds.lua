-- The kinds of widgets the lab makes, each with the game's documentation of its methods (Lab.docs.widgets)
-- and the scripts it can have, as the game's: an unknown script is an error there and here.
return function(Lab)
    local K = Lab.Kind
    K("Object", nil, { "SimpleObjectAPI", "SimpleFrameScriptObjectAPI" })
    -- the scripts every region has, a texture or a font string too (the game's XML gives them OnLoad and the mouse's)
    K("ScriptRegion", "Object", { "SimpleScriptRegionAPI", "SimpleScriptRegionResizingAPI" },
        { "OnLoad", "OnShow", "OnHide", "OnEnter", "OnLeave", "OnMouseDown", "OnMouseUp" })
    K("Region", "ScriptRegion", { "SimpleRegionAPI" })
    K("TextureBase", "Region", { "SimpleTextureBaseAPI" })
    K("Texture", "TextureBase", { "SimpleTextureAPI" })
    K("MaskTexture", "TextureBase", { "SimpleMaskTextureAPI" })
    K("Line", "TextureBase", { "SimpleLineAPI" })
    K("FontString", "Region", { "SimpleFontStringAPI" })
    K("Font", "Object", { "SimpleFontAPI" })

    local frame = { "OnEvent", "OnUpdate", "OnSizeChanged", "OnMouseWheel", "OnDragStart", "OnDragStop", "OnReceiveDrag", "OnKeyDown", "OnKeyUp", "OnChar",
        "OnAttributeChanged", "OnHyperlinkClick", "OnHyperlinkEnter", "OnHyperlinkLeave", "OnEnable",
        "OnDisable", "OnGamePadButtonDown", "OnGamePadButtonUp", "OnGamePadStick", "OnTooltipSetItem",
        "OnTooltipCleared", "OnTooltipSetUnit", "OnTooltipSetSpell", "OnTooltipSetDefaultAnchor" }
    K("Frame", "ScriptRegion", { "SimpleFrameAPI" }, frame)
    K("Button", "Frame", { "SimpleButtonAPI" }, { "OnClick", "PreClick", "PostClick", "OnDoubleClick" })
    K("CheckButton", "Button", { "SimpleCheckboxAPI" })
    K("EditBox", "Frame", { "SimpleEditBoxAPI" }, { "OnEnterPressed", "OnEscapePressed", "OnTabPressed",
        "OnSpacePressed", "OnTextChanged", "OnTextSet", "OnEditFocusGained", "OnEditFocusLost", "OnCursorChanged",
        "OnInputLanguageChanged", "OnArrowPressed", "OnCharComposition" })
    K("ScrollFrame", "Frame", { "SimpleScrollFrameAPI" }, { "OnScrollRangeChanged", "OnVerticalScroll",
        "OnHorizontalScroll" })
    K("Slider", "Frame", { "SimpleSliderAPI" }, { "OnValueChanged", "OnMinMaxChanged" })
    K("StatusBar", "Frame", { "SimpleStatusBarAPI" }, { "OnValueChanged", "OnMinMaxChanged" })
    K("MessageFrame", "Frame", { "SimpleMessageFrameAPI" })
    K("ScrollingMessageFrame", "Frame", {})
    K("GameTooltip", "Frame", { "FrameAPITooltip" })
    K("Cooldown", "Frame", { "FrameAPICooldown" }, { "OnCooldownDone" })
    K("Model", "Frame", { "SimpleModelAPI" }, { "OnModelLoaded", "OnAnimFinished" })
    K("PlayerModel", "Model", { "FrameAPICharacterModelBase" })
    K("DressUpModel", "PlayerModel", { "FrameAPIDressUpModel" })

    local anim = { "OnPlay", "OnFinished", "OnStop", "OnLoop", "OnPause", "OnUpdate", "OnLoad" }
    K("AnimationGroup", "Object", { "SimpleAnimGroupAPI" }, anim)
    K("Animation", "Object", { "SimpleAnimAPI" }, anim)
    K("Alpha", "Animation", { "SimpleAnimAlphaAPI" })
    K("Translation", "Animation", { "SimpleAnimTranslationAPI" })
    K("Scale", "Animation", { "SimpleAnimScaleAPI" })
    K("Rotation", "Animation", { "SimpleAnimRotationAPI" })

    -- What CreateFrame makes, by the name it is given (any case, as the game takes it).
    Lab.frameKinds = {}
    for _, name in ipairs({ "Frame", "Button", "CheckButton", "EditBox", "ScrollFrame", "Slider", "StatusBar",
        "MessageFrame", "ScrollingMessageFrame", "GameTooltip", "Cooldown", "Model", "PlayerModel", "DressUpModel" }) do
        Lab.frameKinds[name:lower()] = name
    end
    Lab.ScriptMethods(Lab.kinds.ScriptRegion.methods)
end
