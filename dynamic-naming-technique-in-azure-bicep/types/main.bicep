
/* ###################################################### */
/* ### Made by Cédric Braekevelt (hybridbrothers.com) ### */
/* ###################################################### */

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
