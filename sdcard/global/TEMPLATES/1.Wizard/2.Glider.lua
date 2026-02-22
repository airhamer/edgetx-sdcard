---- #########################################################################
---- #                                                                       #
---- # Glider Wizard Entry Point                                            #
---- #                                                                       #
---- # License GPLv2: http://www.gnu.org/licenses/gpl-2.0.html               #
---- #                                                                       #
---- #########################################################################

local RUN_DIR = "/TEMPLATES/1.Wizard"

-- Load the fixed-wing wizard with glider mode
local wizard = loadScript(RUN_DIR .. "/lib/fixed-wing.lua")("glider")

return {
    init = wizard.init,
    run = wizard.run,
    useLvgl = true
}
