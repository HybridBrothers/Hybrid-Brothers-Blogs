/* ###################################################### */
/* ### Made by Cédric Braekevelt (hybridbrothers.com) ### */
/* ###################################################### */

targetScope = 'subscription'

// ------------------------------------------------------------------------------------------------------
// Located in a JSON file centralized
var abbreviations = {
  'Microsoft.Resources/resourceGroups': 'rg'
}

// ------------------------------------------------------------------------------------------------------
// Located in main.bicep file of the types module folder
@export()
type naming = {
  @description('Use the function value as the full name of the resource')
  forceFunctionAsFullName: bool?
  @minLength(1)
  @description('Override the abbreviation of this resource with this parameter')
  abbreviation: string?
  @minLength(1)
  @description('The resource environment (for example: dev, tst, acc, prd)')
  environment: string?
  @minLength(1)
  @description('The resource location (for example: weu, we, westeurope)')
  location: string?
  @minLength(1)
  @description('The name of the customer')
  customer: string?
  @minLength(1)
  @description('The delimiter between resources (default: -)')
  delimiter: string?
  @description('The order of the array defines the order of elements in the naming scheme')
  format: ('abbreviation' | 'function' | 'environment' | 'location' | 'customer' | 'param1' | 'param2' | 'param3')[]?
  @minLength(1)
  @description('Extra parameter self defined')
  param1: string?
  @minLength(1)
  @description('Extra parameter self defined')
  param2: string?
  @minLength(1)
  @description('Extra parameter self defined')
  param3: string?
  @minLength(1)
  @description('Function of the resource [can be app, db, security,...]')
  function: string
  @minLength(1)
  @description('Suffix for the resource, if empty non will be appended, otherwise will be added to the end [can be index, ...]')
  suffix: string?
  @description('Force the CAF naming instead of default company naming')
  forceDefaultNaming: bool?
}

// ------------------------------------------------------------------------------------------------------
// Located in the main.bicep file of the functions module folder
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

// ------------------------------------------------------------------------------------------------------
// Located in the types.bicep file of the resource-group module folder
type resourceGroup = {
  @description('Reference to the naming')
  naming: naming
  @description('Reference to the default naming')
  sharedNaming: naming
  @description('Location of the resource')
  location: string
}

// ------------------------------------------------------------------------------------------------------
// Located in the main.bicep file of the resource-group module folder
param resourceObject resourceGroup
param resourceNaming naming = union(resourceObject.sharedNaming, resourceObject.naming)

var abbreviation = abbreviations['Microsoft.Resources/resourceGroups']
var resourceName = getResourceName(resourceNaming, abbreviation, null)

resource resourceItem 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: resourceName
  location: resourceObject.location
}

// ------------------------------------------------------------------------------------------------------
// Located in the shared.bicep / shared.bicepparam on the customer size
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
param resourceParam resourceGroup = {
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
