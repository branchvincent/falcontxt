import { cloneDeep } from '@apollo/client/utilities'
import { Alert, Button, Form, Input, Modal } from 'antd'
import { GraphQLError } from 'graphql'
import { FC, useCallback, useState } from 'react'

import {
  MetricDefinition,
  MetricDefinitionInput,
  MetricDefinitionPatch,
} from '../../graphql'
import {
  GetMetricDefinitionsDocument,
  GetMetricDefinitionsQuery,
  useCreateMetricDefinitionMutation,
  useUpdateMetricDefinitionMutation,
} from '../../queries/types/metricDefinitions'

type MetricsDefinitionModalProps = {
  definition: Partial<MetricDefinition>
  onComplete(cancelled?: boolean): void
}

const MetricsDefinitionModal: FC<MetricsDefinitionModalProps> = ({
  definition,
  onComplete,
}) => {
  const [error, setError] = useState<GraphQLError>()
  const [isUpdate] = useState(!!definition.id)
  const [createMetricDefinition, { loading: createLoading }] =
    useCreateMetricDefinitionMutation()
  const [updateMetricDefinition, { loading: updateLoading }] =
    useUpdateMetricDefinitionMutation()
  const [form] = Form.useForm()
  const onSubmit = useCallback(
    async (values: Partial<MetricDefinition>) => {
      try {
        setError(undefined)
        if (isUpdate) {
          await updateMetricDefinition({
            variables: {
              id: definition.id!,
              metricDefinition: values as MetricDefinitionPatch,
            },
            update: (proxy, { data }) => {
              if (data?.updateMetricDefinition?.metricDefinition) {
                const result = cloneDeep(
                  proxy.readQuery<GetMetricDefinitionsQuery>({
                    query: GetMetricDefinitionsDocument,
                  }),
                )
                const found = result?.metricDefinitions?.nodes.findIndex(
                  ({ id }) =>
                    id === data.updateMetricDefinition?.metricDefinition?.id,
                )
                if (typeof found !== 'undefined') {
                  result?.metricDefinitions?.nodes.splice(
                    found,
                    1,
                    data.updateMetricDefinition.metricDefinition,
                  )
                }

                proxy.writeQuery({
                  query: GetMetricDefinitionsDocument,
                  data: result,
                })
              }
            },
          })
        } else {
          await createMetricDefinition({
            variables: {
              metricDefinition: values as MetricDefinitionInput,
            },
            update: (proxy, { data }) => {
              if (data?.createMetricDefinition?.metricDefinition) {
                const result = cloneDeep(
                  proxy.readQuery<GetMetricDefinitionsQuery>({
                    query: GetMetricDefinitionsDocument,
                  }),
                )
                if (result) {
                  result?.metricDefinitions?.nodes.push(
                    data.createMetricDefinition.metricDefinition,
                  )
                  proxy.writeQuery({
                    query: GetMetricDefinitionsDocument,
                    data: { ...result },
                  })
                }
              }
            },
          })
        }
        return onComplete()
      } catch (e) {
        setError(e as GraphQLError)
      }
    },
    [onComplete, isUpdate],
  )
  const onCancel = useCallback(() => {
    return onComplete(true)
  }, [onComplete])

  return (
    <Modal
      title={isUpdate ? 'Edit Metric Definition' : 'Create Metric Definition'}
      centered
      closable={false}
      visible={true}
      footer={[
        <Button key="back" onClick={onCancel}>
          Cancel
        </Button>,
        <Button
          key="submit"
          type="primary"
          loading={updateLoading || createLoading}
          onClick={() => form.submit()}
        >
          Submit
        </Button>,
      ]}
      okText={isUpdate ? 'Update' : 'Create'}
    >
      {error ? (
        <Alert
          style={{ marginBottom: '20px' }}
          key={error.name}
          showIcon
          type="error"
          message={error.name}
          description={error.message}
        />
      ) : null}
      <Form
        labelCol={{ span: 6 }}
        wrapperCol={{ span: 16 }}
        initialValues={definition}
        form={form}
        name={`${isUpdate ? 'edit' : 'create'}-definition`}
        onFinish={(values) => onSubmit(values as Partial<MetricDefinition>)}
      >
        <Form.Item
          name="name"
          required
          label="Name"
          rules={[{ required: true }]}
        >
          <Input disabled={isUpdate} />
        </Form.Item>
        <Form.Item name="description" label="Description">
          <Input />
        </Form.Item>
        <Form.Item
          name="query"
          required
          label="Query"
          rules={[{ required: true }]}
        >
          <Input.TextArea />
        </Form.Item>
        <Form.Item name="units" label="Units">
          <Input />
        </Form.Item>
      </Form>
    </Modal>
  )
}

export default MetricsDefinitionModal
