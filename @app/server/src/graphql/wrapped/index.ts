import { loadFilesSync } from '@graphql-tools/load-files'

import { WrapperResolver } from './index.d'

export default (): WrapperResolver[] => {
  return loadFilesSync(__dirname, {
    ignoreIndex: true,
    extensions: ['ts'],
  }) as WrapperResolver[]
}
