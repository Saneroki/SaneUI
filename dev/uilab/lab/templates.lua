-- The templates CreateFrame knows in the lab, made as the game's XML makes them: BackdropTemplate is Blizzard's
-- own mixin (Backdrop.lua) with the scripts its XML gives it. Templates of Blizzard's that are more than that are
-- not in the lab yet: CreateFrame says so and makes the frame without them.
return function(Lab)
    local G = Lab.G
    local S = Lab.S

    -- A template that is a mixin and scripts calling its methods, as <Frame mixin="..."> with <OnLoad method="..."/>.
    function Lab.MixinTemplate(mixinName, scripts)
        return function(f)
            local mixin = G[mixinName]
            if not mixin then
                Lab.Warn("the template's mixin " .. mixinName .. " did not load in the lab")
                return
            end
            G.Mixin(f, mixin)
            for script, method in pairs(scripts or {}) do
                S[f].scripts[script] = function(self, ...) return self[method](self, ...) end
            end
        end
    end

    Lab.templates.BackdropTemplate = Lab.MixinTemplate("BackdropTemplateMixin",
        { OnLoad = "OnBackdropLoaded", OnSizeChanged = "OnBackdropSizeChanged" })
end
