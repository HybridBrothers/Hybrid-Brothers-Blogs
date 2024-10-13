
/* ###################################################### */
/* ### Made by Cedric Braekevelt (hybridbrothers.com) ### */
/* ###################################################### */

import { naming } from '../types/main.bicep'

// Merge naming components
@export()
func getResourceNaming(sharedNaming naming, naming naming) naming => (union(sharedNaming, naming))

// Generate default CAF name using naming components
#disable-next-line prefer-interpolation
func getDefaultResourceName(resourceNaming naming) string => concat(join(concat(map(resourceNaming.?format!, x => resourceNaming[x])), resourceNaming.?delimiter! ?? '-'), resourceNaming.?suffix! ?? '')

// Generate a resource name
// 1. Check if forceFunctionAsFullName == true, use full name
// 2. Check if forceDefaultNaming == true, use CAF naming
// 3. Otterwise use customName, if not available, use CAF naming
@export()
func getResourceName(resourceNaming naming, abbreviation string, customName string?) string => (resourceNaming.?forceFunctionAsFullName! == true) ? resourceNaming.function : (resourceNaming.?forceDefaultNaming! == true ? getDefaultResourceName(union({ abbreviation: abbreviation }, resourceNaming)) : customName! ?? getDefaultResourceName(union({ abbreviation: abbreviation }, resourceNaming)))
