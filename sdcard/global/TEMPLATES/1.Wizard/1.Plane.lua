
-- Author: 3djc (2017)
-- Update by: Offer Shmuely (2023)
-- Update by: Alexander Gnauck (2025)

local engine = loadScript("/TEMPLATES/1.Wizard/core/core_engine.lua")()
local model = loadScript("/TEMPLATES/1.Wizard/lib/plane.lua")()

return engine.runWizard(model.pages)

