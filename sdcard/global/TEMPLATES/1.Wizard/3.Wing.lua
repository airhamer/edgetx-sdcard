---- #########################################################################
---- #                                                                       #
-----#                                                                       #
---- # License GPLv2: http://www.gnu.org/licenses/gpl-2.0.html               #
---- #                                                                       #
---- # This program is free software; you can redistribute it and/or modify  #
---- # it under the terms of the GNU General Public License version 2 as     #
---- # published by the Free Software Foundation.                            #
---- #                                                                       #
---- # This program is distributed in the hope that it will be useful        #
---- # but WITHOUT ANY WARRANTY; without even the implied warranty of        #
---- # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
---- # GNU General Public License for more details.                          #
---- #                                                                       #
---- #########################################################################

-- Author: Offer Shmuely
-- Date: 2023-2024
-- version: 1.3
local engine = loadScript("/TEMPLATES/1.Wizard/core/core_engine.lua")()
local model = loadScript("/TEMPLATES/1.Wizard/lib/wing.lua")()

return engine.runWizard(model.pages)

