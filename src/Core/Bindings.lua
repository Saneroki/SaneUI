local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  SaneUI - Core - Bindings
--  The words of SaneUI's keys in the game's key bindings (Esc > Options >
--  Keybindings): their section, SaneUI, and what each does. What a key does
--  is in Bindings.xml, which the game reads from the addon's folder by itself;
--  a module's keys are in its own Bindings.xml, in the same section.
-------------------------------------------------------------------------------
local TEXT = { options = "Open SaneUI's options" }

BINDING_HEADER_SANEUI = Core.TITLE
BINDING_NAME_SANEUI_OPTIONS = TEXT.options
