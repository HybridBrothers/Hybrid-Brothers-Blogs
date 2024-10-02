
/* ###################################################### */
/* ### Made by Cédric Braekevelt (hybridbrothers.com) ### */
/* ###################################################### */

import { naming } from '../types/main.bicep'

@export()
type resourceGroup = {
  @description('Reference to the naming')
  naming: naming
  @description('Reference to the default naming')
  sharedNaming: naming
  @description('Location of the resource')
  location: string
}
