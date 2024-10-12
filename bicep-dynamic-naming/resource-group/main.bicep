
/* ###################################################### */
/* ### Made by Cédric Braekevelt (hybridbrothers.com) ### */
/* ###################################################### */

targetScope = 'subscription'

import { naming } from '../types/main.bicep'
import { resourceGroup } from 'types.bicep'
import { getResourceName } from '../functions/main.bicep'

// Located in a JSON file centralized
var abbreviations = {
  'Microsoft.Resources/resourceGroups': 'rg'
}

param resourceObject resourceGroup
param resourceNaming naming = union(resourceObject.sharedNaming, resourceObject.naming)

var abbreviation = abbreviations['Microsoft.Resources/resourceGroups']
var resourceName = getResourceName(resourceNaming, abbreviation, null)

resource resourceItem 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: resourceName
  location: resourceObject.location
}
