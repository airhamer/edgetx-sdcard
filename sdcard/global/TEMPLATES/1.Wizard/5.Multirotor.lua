local engine = loadScript("/TEMPLATES/1.Wizard/core/core_engine.lua")()
local model = loadScript("/TEMPLATES/1.Wizard/lib/multi-rotor.lua")()

return engine.runWizard(pages)

