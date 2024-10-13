
/* ###################################################### */
/* ### Made by Cedric Braekevelt (hybridbrothers.com) ### */
/* ###################################################### */

targetScope = 'subscription'

import { naming } from 'types/main.bicep'
import { resourceGroup } from 'resource-group/types.bicep'

// ------------------------------------------------------------------------------------------------------
// Located in the shared.bicep / shared.bicepparam on the customer size
// ------------------------------------------------------------------------------------------------------
param sharedNaming naming = {
  format: [
    'abbreviation'
    'function'
    'environment'
    'location'
  ]
  function: 'placeholder'
  environment: 'prd'
  location: 'weu'
}

// ------------------------------------------------------------------------------------------------------
// Located in the main.bicep / main.bicepparam on the customer size
// ------------------------------------------------------------------------------------------------------
module resourceGroupDeployment 'resource-group/main.bicep' = {
  name: 'resourceGroupDeployment'
  params: {
    resourceObject: {
      location: deployment().location
      naming: {
        // Required value
        function: 'network'
        // Overload the default values define in sharedNaming
        environment: 'dev'
        location: 'neu'
        delimiter: '_'
        suffix: '-01'
      }
      sharedNaming: sharedNaming
    }
  }
}
