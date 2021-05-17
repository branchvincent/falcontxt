import { cloneDeep } from '@apollo/client/utilities'
import { Alert, Button, Form, Input, Modal, Select } from 'antd'
import { GraphQLError } from 'graphql'
import { FC, useCallback, useState } from 'react'

import { useOrganizationContext } from '../../components/OrganizationContext'
import { Facility, FacilityInput, FacilityPatch } from '../../graphql'
import {
  GetDistinctTagsDocument,
  GetFacilitiesByOrganizationDocument,
  GetFacilitiesByOrganizationQuery,
  useCreateFacilityMutation,
  useUpdateFacilityMutation,
} from '../../queries/types/facilities'

type FacilityModalProps = {
  facility: Partial<Facility>
  onComplete(cancelled?: boolean): void
}

const FacilityModal: FC<FacilityModalProps> = ({ facility, onComplete }) => {
  const { current } = useOrganizationContext()
  const [error, setError] = useState<GraphQLError>()
  const [isUpdate] = useState(!!facility.id)
  const [createFacility, { loading: createLoading }] =
    useCreateFacilityMutation()
  const [updateFacility, { loading: updateLoading }] =
    useUpdateFacilityMutation()
  const [form] = Form.useForm()
  const onSubmit = useCallback(
    async (values: Partial<Facility>) => {
      try {
        setError(undefined)
        if (isUpdate) {
          await updateFacility({
            variables: {
              id: facility.id!,
              facility: values as FacilityPatch,
            },
            awaitRefetchQueries: true,
            refetchQueries: [
              {
                query: GetDistinctTagsDocument,
              },
            ],
            update: (proxy, { data }) => {
              if (data?.updateFacility?.facility) {
                const result = cloneDeep(
                  proxy.readQuery<GetFacilitiesByOrganizationQuery>({
                    query: GetFacilitiesByOrganizationDocument,
                    variables: {
                      slug: current!.slug,
                    },
                  }),
                )
                const found =
                  result?.organizationBySlug?.facilities?.nodes.findIndex(
                    ({ id }) => id === data.updateFacility?.facility?.id,
                  )
                if (typeof found !== 'undefined') {
                  result?.organizationBySlug?.facilities?.nodes.splice(
                    found,
                    1,
                    data.updateFacility.facility,
                  )
                }

                proxy.writeQuery({
                  query: GetFacilitiesByOrganizationDocument,
                  variables: {
                    slug: current!.slug,
                  },
                  data: result,
                })
              }
            },
          })
        } else {
          await createFacility({
            variables: {
              facility: {
                ...(values as FacilityInput),
                organizationId: current!.id,
              },
            },
            refetchQueries: [
              {
                query: GetDistinctTagsDocument,
              },
            ],
            update: (proxy, { data }) => {
              if (data?.createFacility?.facility) {
                const result = cloneDeep(
                  proxy.readQuery<GetFacilitiesByOrganizationQuery>({
                    query: GetFacilitiesByOrganizationDocument,
                    variables: {
                      slug: current!.slug,
                    },
                  }),
                )
                if (result) {
                  result?.organizationBySlug?.facilities?.nodes.push(
                    data.createFacility.facility,
                  )
                  proxy.writeQuery({
                    query: GetFacilitiesByOrganizationDocument,
                    variables: {
                      slug: current!.slug,
                    },
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
      title={isUpdate ? 'Edit Facility' : 'Create Facility'}
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
        initialValues={facility}
        form={form}
        name={`${isUpdate ? 'edit' : 'create'}-facility`}
        onFinish={(values) => onSubmit(values as Partial<Facility>)}
      >
        <Form.Item
          name="slug"
          required
          label="Slug"
          rules={[{ required: true }]}
        >
          <Input disabled={isUpdate} />
        </Form.Item>
        <Form.Item
          name="name"
          required
          label="Name"
          rules={[{ required: true }]}
        >
          <Input />
        </Form.Item>
        <Form.Item name="tags" required label="Tags">
          <Select
            mode="tags"
            style={{ width: '100%' }}
            placeholder="Tags Mode"
          />
        </Form.Item>
      </Form>
    </Modal>
  )
}

export default FacilityModal
