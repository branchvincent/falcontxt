import {
  PageHeader as AntPageHeader,
  PageHeaderProps as AntPageHeaderProps,
} from 'antd'
import { FC } from 'react'
import { useHistory } from 'react-router-dom'

const PageHeader: FC<AntPageHeaderProps> = (props) => {
  const history = useHistory()

  return <AntPageHeader onBack={() => history.goBack()} {...props} />
}

export default PageHeader
