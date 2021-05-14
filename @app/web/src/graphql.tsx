/* eslint-disable */
export type Maybe<T> = T | null;
export type Exact<T extends { [key: string]: unknown }> = { [K in keyof T]: T[K] };
export type MakeOptional<T, K extends keyof T> = Omit<T, K> & { [SubKey in K]?: Maybe<T[SubKey]> };
export type MakeMaybe<T, K extends keyof T> = Omit<T, K> & { [SubKey in K]: Maybe<T[SubKey]> };
/** All built-in and custom scalars, mapped to their actual values */
export type Scalars = {
  ID: string;
  String: string;
  Boolean: boolean;
  Int: number;
  Float: number;
  /** A location in a connection that can be used for resuming pagination. */
  Cursor: any;
  /**
   * A point in time as described by the [ISO
   * 8601](https://en.wikipedia.org/wiki/ISO_8601) standard. May or may not include a timezone.
   */
  Datetime: any;
};

/** All input for the create `Facility` mutation. */
export type CreateFacilityInput = {
  /**
   * An arbitrary string value with no semantic meaning. Will be included in the
   * payload verbatim. May be used to track mutations by the client.
   */
  clientMutationId?: Maybe<Scalars['String']>;
  /** The `Facility` to be created by this mutation. */
  facility: FacilityInput;
};

/** The output of our create `Facility` mutation. */
export type CreateFacilityPayload = {
  __typename?: 'CreateFacilityPayload';
  /**
   * The exact same `clientMutationId` that was provided in the mutation input,
   * unchanged and unused. May be used by a client to track mutations.
   */
  clientMutationId?: Maybe<Scalars['String']>;
  /** The `Facility` that was created by this mutation. */
  facility?: Maybe<Facility>;
  /** An edge for our `Facility`. May be used by Relay 1. */
  facilityEdge?: Maybe<FacilitiesEdge>;
  /** Reads a single `Organization` that is related to this `Facility`. */
  organization?: Maybe<Organization>;
  /** Our root query field type. Allows us to run any query from our mutation payload. */
  query?: Maybe<Query>;
};


/** The output of our create `Facility` mutation. */
export type CreateFacilityPayloadFacilityEdgeArgs = {
  orderBy?: Maybe<Array<FacilitiesOrderBy>>;
};

/** All input for the create `Organization` mutation. */
export type CreateOrganizationInput = {
  /**
   * An arbitrary string value with no semantic meaning. Will be included in the
   * payload verbatim. May be used to track mutations by the client.
   */
  clientMutationId?: Maybe<Scalars['String']>;
  /** The `Organization` to be created by this mutation. */
  organization: OrganizationInput;
};

/** The output of our create `Organization` mutation. */
export type CreateOrganizationPayload = {
  __typename?: 'CreateOrganizationPayload';
  /**
   * The exact same `clientMutationId` that was provided in the mutation input,
   * unchanged and unused. May be used by a client to track mutations.
   */
  clientMutationId?: Maybe<Scalars['String']>;
  /** The `Organization` that was created by this mutation. */
  organization?: Maybe<Organization>;
  /** An edge for our `Organization`. May be used by Relay 1. */
  organizationEdge?: Maybe<OrganizationsEdge>;
  /** Our root query field type. Allows us to run any query from our mutation payload. */
  query?: Maybe<Query>;
};


/** The output of our create `Organization` mutation. */
export type CreateOrganizationPayloadOrganizationEdgeArgs = {
  orderBy?: Maybe<Array<OrganizationsOrderBy>>;
};



/** All input for the `deleteFacilityByNodeId` mutation. */
export type DeleteFacilityByNodeIdInput = {
  /**
   * An arbitrary string value with no semantic meaning. Will be included in the
   * payload verbatim. May be used to track mutations by the client.
   */
  clientMutationId?: Maybe<Scalars['String']>;
  /** The globally unique `ID` which will identify a single `Facility` to be deleted. */
  nodeId: Scalars['ID'];
};

/** All input for the `deleteFacilityBySlug` mutation. */
export type DeleteFacilityBySlugInput = {
  /**
   * An arbitrary string value with no semantic meaning. Will be included in the
   * payload verbatim. May be used to track mutations by the client.
   */
  clientMutationId?: Maybe<Scalars['String']>;
  /** The facility’s slug. */
  slug: Scalars['String'];
};

/** All input for the `deleteFacility` mutation. */
export type DeleteFacilityInput = {
  /**
   * An arbitrary string value with no semantic meaning. Will be included in the
   * payload verbatim. May be used to track mutations by the client.
   */
  clientMutationId?: Maybe<Scalars['String']>;
  /** The primary unique identifier for the facility. */
  id: Scalars['Int'];
};

/** The output of our delete `Facility` mutation. */
export type DeleteFacilityPayload = {
  __typename?: 'DeleteFacilityPayload';
  /**
   * The exact same `clientMutationId` that was provided in the mutation input,
   * unchanged and unused. May be used by a client to track mutations.
   */
  clientMutationId?: Maybe<Scalars['String']>;
  deletedFacilityNodeId?: Maybe<Scalars['ID']>;
  /** The `Facility` that was deleted by this mutation. */
  facility?: Maybe<Facility>;
  /** An edge for our `Facility`. May be used by Relay 1. */
  facilityEdge?: Maybe<FacilitiesEdge>;
  /** Reads a single `Organization` that is related to this `Facility`. */
  organization?: Maybe<Organization>;
  /** Our root query field type. Allows us to run any query from our mutation payload. */
  query?: Maybe<Query>;
};


/** The output of our delete `Facility` mutation. */
export type DeleteFacilityPayloadFacilityEdgeArgs = {
  orderBy?: Maybe<Array<FacilitiesOrderBy>>;
};

/** All input for the `deleteOrganizationByNodeId` mutation. */
export type DeleteOrganizationByNodeIdInput = {
  /**
   * An arbitrary string value with no semantic meaning. Will be included in the
   * payload verbatim. May be used to track mutations by the client.
   */
  clientMutationId?: Maybe<Scalars['String']>;
  /** The globally unique `ID` which will identify a single `Organization` to be deleted. */
  nodeId: Scalars['ID'];
};

/** All input for the `deleteOrganizationBySlug` mutation. */
export type DeleteOrganizationBySlugInput = {
  /**
   * An arbitrary string value with no semantic meaning. Will be included in the
   * payload verbatim. May be used to track mutations by the client.
   */
  clientMutationId?: Maybe<Scalars['String']>;
  /** The org’s slug. */
  slug: Scalars['String'];
};

/** All input for the `deleteOrganization` mutation. */
export type DeleteOrganizationInput = {
  /**
   * An arbitrary string value with no semantic meaning. Will be included in the
   * payload verbatim. May be used to track mutations by the client.
   */
  clientMutationId?: Maybe<Scalars['String']>;
  /** The primary unique identifier for the org. */
  id: Scalars['Int'];
};

/** The output of our delete `Organization` mutation. */
export type DeleteOrganizationPayload = {
  __typename?: 'DeleteOrganizationPayload';
  /**
   * The exact same `clientMutationId` that was provided in the mutation input,
   * unchanged and unused. May be used by a client to track mutations.
   */
  clientMutationId?: Maybe<Scalars['String']>;
  deletedOrganizationNodeId?: Maybe<Scalars['ID']>;
  /** The `Organization` that was deleted by this mutation. */
  organization?: Maybe<Organization>;
  /** An edge for our `Organization`. May be used by Relay 1. */
  organizationEdge?: Maybe<OrganizationsEdge>;
  /** Our root query field type. Allows us to run any query from our mutation payload. */
  query?: Maybe<Query>;
};


/** The output of our delete `Organization` mutation. */
export type DeleteOrganizationPayloadOrganizationEdgeArgs = {
  orderBy?: Maybe<Array<OrganizationsOrderBy>>;
};

/** A connection to a list of `Facility` values. */
export type FacilitiesConnection = {
  __typename?: 'FacilitiesConnection';
  /** A list of edges which contains the `Facility` and cursor to aid in pagination. */
  edges: Array<FacilitiesEdge>;
  /** A list of `Facility` objects. */
  nodes: Array<Facility>;
  /** Information to aid in pagination. */
  pageInfo: PageInfo;
  /** The count of *all* `Facility` you could get from the connection. */
  totalCount: Scalars['Int'];
};

/** A `Facility` edge in the connection. */
export type FacilitiesEdge = {
  __typename?: 'FacilitiesEdge';
  /** A cursor for use in pagination. */
  cursor?: Maybe<Scalars['Cursor']>;
  /** The `Facility` at the end of the edge. */
  node: Facility;
};

/** Methods to use when ordering `Facility`. */
export enum FacilitiesOrderBy {
  CREATED_AT_ASC = 'CREATED_AT_ASC',
  CREATED_AT_DESC = 'CREATED_AT_DESC',
  ID_ASC = 'ID_ASC',
  ID_DESC = 'ID_DESC',
  NAME_ASC = 'NAME_ASC',
  NAME_DESC = 'NAME_DESC',
  NATURAL = 'NATURAL',
  ORGANIZATION_ID_ASC = 'ORGANIZATION_ID_ASC',
  ORGANIZATION_ID_DESC = 'ORGANIZATION_ID_DESC',
  PRIMARY_KEY_ASC = 'PRIMARY_KEY_ASC',
  PRIMARY_KEY_DESC = 'PRIMARY_KEY_DESC',
  SLUG_ASC = 'SLUG_ASC',
  SLUG_DESC = 'SLUG_DESC',
  UPDATED_AT_ASC = 'UPDATED_AT_ASC',
  UPDATED_AT_DESC = 'UPDATED_AT_DESC'
}

/** A facility. */
export type Facility = Node & {
  __typename?: 'Facility';
  /** The time this facility was created. */
  createdAt?: Maybe<Scalars['Datetime']>;
  /** The primary unique identifier for the facility. */
  id: Scalars['Int'];
  /** The facility’s name. */
  name: Scalars['String'];
  /** A globally unique identifier. Can be used in various places throughout the system to identify this single value. */
  nodeId: Scalars['ID'];
  /** Reads a single `Organization` that is related to this `Facility`. */
  organization?: Maybe<Organization>;
  /** The facility’s associated organization. */
  organizationId: Scalars['Int'];
  /** The facility’s slug. */
  slug: Scalars['String'];
  /** The time this facility was updated. */
  updatedAt?: Maybe<Scalars['Datetime']>;
};

/**
 * A condition to be used against `Facility` object types. All fields are tested
 * for equality and combined with a logical ‘and.’
 */
export type FacilityCondition = {
  /** Checks for equality with the object’s `createdAt` field. */
  createdAt?: Maybe<Scalars['Datetime']>;
  /** Checks for equality with the object’s `id` field. */
  id?: Maybe<Scalars['Int']>;
  /** Checks for equality with the object’s `name` field. */
  name?: Maybe<Scalars['String']>;
  /** Checks for equality with the object’s `organizationId` field. */
  organizationId?: Maybe<Scalars['Int']>;
  /** Checks for equality with the object’s `slug` field. */
  slug?: Maybe<Scalars['String']>;
  /** Checks for equality with the object’s `updatedAt` field. */
  updatedAt?: Maybe<Scalars['Datetime']>;
};

/** An input for mutations affecting `Facility` */
export type FacilityInput = {
  /** The time this facility was created. */
  createdAt?: Maybe<Scalars['Datetime']>;
  /** The primary unique identifier for the facility. */
  id?: Maybe<Scalars['Int']>;
  /** The facility’s name. */
  name: Scalars['String'];
  /** The facility’s associated organization. */
  organizationId: Scalars['Int'];
  /** The facility’s slug. */
  slug: Scalars['String'];
  /** The time this facility was updated. */
  updatedAt?: Maybe<Scalars['Datetime']>;
};

/** Represents an update to a `Facility`. Fields that are set will be updated. */
export type FacilityPatch = {
  /** The time this facility was created. */
  createdAt?: Maybe<Scalars['Datetime']>;
  /** The primary unique identifier for the facility. */
  id?: Maybe<Scalars['Int']>;
  /** The facility’s name. */
  name?: Maybe<Scalars['String']>;
  /** The facility’s associated organization. */
  organizationId?: Maybe<Scalars['Int']>;
  /** The facility’s slug. */
  slug?: Maybe<Scalars['String']>;
  /** The time this facility was updated. */
  updatedAt?: Maybe<Scalars['Datetime']>;
};

/** The root mutation type which contains root level fields which mutate data. */
export type Mutation = {
  __typename?: 'Mutation';
  /** Creates a single `Facility`. */
  createFacility?: Maybe<CreateFacilityPayload>;
  /** Creates a single `Organization`. */
  createOrganization?: Maybe<CreateOrganizationPayload>;
  /** Deletes a single `Facility` using a unique key. */
  deleteFacility?: Maybe<DeleteFacilityPayload>;
  /** Deletes a single `Facility` using its globally unique id. */
  deleteFacilityByNodeId?: Maybe<DeleteFacilityPayload>;
  /** Deletes a single `Facility` using a unique key. */
  deleteFacilityBySlug?: Maybe<DeleteFacilityPayload>;
  /** Deletes a single `Organization` using a unique key. */
  deleteOrganization?: Maybe<DeleteOrganizationPayload>;
  /** Deletes a single `Organization` using its globally unique id. */
  deleteOrganizationByNodeId?: Maybe<DeleteOrganizationPayload>;
  /** Deletes a single `Organization` using a unique key. */
  deleteOrganizationBySlug?: Maybe<DeleteOrganizationPayload>;
  /** Updates a single `Facility` using a unique key and a patch. */
  updateFacility?: Maybe<UpdateFacilityPayload>;
  /** Updates a single `Facility` using its globally unique id and a patch. */
  updateFacilityByNodeId?: Maybe<UpdateFacilityPayload>;
  /** Updates a single `Facility` using a unique key and a patch. */
  updateFacilityBySlug?: Maybe<UpdateFacilityPayload>;
  /** Updates a single `Organization` using a unique key and a patch. */
  updateOrganization?: Maybe<UpdateOrganizationPayload>;
  /** Updates a single `Organization` using its globally unique id and a patch. */
  updateOrganizationByNodeId?: Maybe<UpdateOrganizationPayload>;
  /** Updates a single `Organization` using a unique key and a patch. */
  updateOrganizationBySlug?: Maybe<UpdateOrganizationPayload>;
};


/** The root mutation type which contains root level fields which mutate data. */
export type MutationCreateFacilityArgs = {
  input: CreateFacilityInput;
};


/** The root mutation type which contains root level fields which mutate data. */
export type MutationCreateOrganizationArgs = {
  input: CreateOrganizationInput;
};


/** The root mutation type which contains root level fields which mutate data. */
export type MutationDeleteFacilityArgs = {
  input: DeleteFacilityInput;
};


/** The root mutation type which contains root level fields which mutate data. */
export type MutationDeleteFacilityByNodeIdArgs = {
  input: DeleteFacilityByNodeIdInput;
};


/** The root mutation type which contains root level fields which mutate data. */
export type MutationDeleteFacilityBySlugArgs = {
  input: DeleteFacilityBySlugInput;
};


/** The root mutation type which contains root level fields which mutate data. */
export type MutationDeleteOrganizationArgs = {
  input: DeleteOrganizationInput;
};


/** The root mutation type which contains root level fields which mutate data. */
export type MutationDeleteOrganizationByNodeIdArgs = {
  input: DeleteOrganizationByNodeIdInput;
};


/** The root mutation type which contains root level fields which mutate data. */
export type MutationDeleteOrganizationBySlugArgs = {
  input: DeleteOrganizationBySlugInput;
};


/** The root mutation type which contains root level fields which mutate data. */
export type MutationUpdateFacilityArgs = {
  input: UpdateFacilityInput;
};


/** The root mutation type which contains root level fields which mutate data. */
export type MutationUpdateFacilityByNodeIdArgs = {
  input: UpdateFacilityByNodeIdInput;
};


/** The root mutation type which contains root level fields which mutate data. */
export type MutationUpdateFacilityBySlugArgs = {
  input: UpdateFacilityBySlugInput;
};


/** The root mutation type which contains root level fields which mutate data. */
export type MutationUpdateOrganizationArgs = {
  input: UpdateOrganizationInput;
};


/** The root mutation type which contains root level fields which mutate data. */
export type MutationUpdateOrganizationByNodeIdArgs = {
  input: UpdateOrganizationByNodeIdInput;
};


/** The root mutation type which contains root level fields which mutate data. */
export type MutationUpdateOrganizationBySlugArgs = {
  input: UpdateOrganizationBySlugInput;
};

/** An object with a globally unique `ID`. */
export type Node = {
  /** A globally unique identifier. Can be used in various places throughout the system to identify this single value. */
  nodeId: Scalars['ID'];
};

/** An organization. */
export type Organization = Node & {
  __typename?: 'Organization';
  /** The time this org was created. */
  createdAt?: Maybe<Scalars['Datetime']>;
  /** Reads and enables pagination through a set of `Facility`. */
  facilities: FacilitiesConnection;
  /** The primary unique identifier for the org. */
  id: Scalars['Int'];
  /** The org’s name. */
  name: Scalars['String'];
  /** A globally unique identifier. Can be used in various places throughout the system to identify this single value. */
  nodeId: Scalars['ID'];
  /** The org’s slug. */
  slug: Scalars['String'];
  /** The time this org was updated. */
  updatedAt?: Maybe<Scalars['Datetime']>;
};


/** An organization. */
export type OrganizationFacilitiesArgs = {
  after?: Maybe<Scalars['Cursor']>;
  before?: Maybe<Scalars['Cursor']>;
  condition?: Maybe<FacilityCondition>;
  first?: Maybe<Scalars['Int']>;
  last?: Maybe<Scalars['Int']>;
  offset?: Maybe<Scalars['Int']>;
  orderBy?: Maybe<Array<FacilitiesOrderBy>>;
};

/**
 * A condition to be used against `Organization` object types. All fields are
 * tested for equality and combined with a logical ‘and.’
 */
export type OrganizationCondition = {
  /** Checks for equality with the object’s `createdAt` field. */
  createdAt?: Maybe<Scalars['Datetime']>;
  /** Checks for equality with the object’s `id` field. */
  id?: Maybe<Scalars['Int']>;
  /** Checks for equality with the object’s `name` field. */
  name?: Maybe<Scalars['String']>;
  /** Checks for equality with the object’s `slug` field. */
  slug?: Maybe<Scalars['String']>;
  /** Checks for equality with the object’s `updatedAt` field. */
  updatedAt?: Maybe<Scalars['Datetime']>;
};

/** An input for mutations affecting `Organization` */
export type OrganizationInput = {
  /** The time this org was created. */
  createdAt?: Maybe<Scalars['Datetime']>;
  /** The primary unique identifier for the org. */
  id?: Maybe<Scalars['Int']>;
  /** The org’s name. */
  name: Scalars['String'];
  /** The org’s slug. */
  slug: Scalars['String'];
  /** The time this org was updated. */
  updatedAt?: Maybe<Scalars['Datetime']>;
};

/** Represents an update to a `Organization`. Fields that are set will be updated. */
export type OrganizationPatch = {
  /** The time this org was created. */
  createdAt?: Maybe<Scalars['Datetime']>;
  /** The primary unique identifier for the org. */
  id?: Maybe<Scalars['Int']>;
  /** The org’s name. */
  name?: Maybe<Scalars['String']>;
  /** The org’s slug. */
  slug?: Maybe<Scalars['String']>;
  /** The time this org was updated. */
  updatedAt?: Maybe<Scalars['Datetime']>;
};

/** A connection to a list of `Organization` values. */
export type OrganizationsConnection = {
  __typename?: 'OrganizationsConnection';
  /** A list of edges which contains the `Organization` and cursor to aid in pagination. */
  edges: Array<OrganizationsEdge>;
  /** A list of `Organization` objects. */
  nodes: Array<Organization>;
  /** Information to aid in pagination. */
  pageInfo: PageInfo;
  /** The count of *all* `Organization` you could get from the connection. */
  totalCount: Scalars['Int'];
};

/** A `Organization` edge in the connection. */
export type OrganizationsEdge = {
  __typename?: 'OrganizationsEdge';
  /** A cursor for use in pagination. */
  cursor?: Maybe<Scalars['Cursor']>;
  /** The `Organization` at the end of the edge. */
  node: Organization;
};

/** Methods to use when ordering `Organization`. */
export enum OrganizationsOrderBy {
  CREATED_AT_ASC = 'CREATED_AT_ASC',
  CREATED_AT_DESC = 'CREATED_AT_DESC',
  ID_ASC = 'ID_ASC',
  ID_DESC = 'ID_DESC',
  NAME_ASC = 'NAME_ASC',
  NAME_DESC = 'NAME_DESC',
  NATURAL = 'NATURAL',
  PRIMARY_KEY_ASC = 'PRIMARY_KEY_ASC',
  PRIMARY_KEY_DESC = 'PRIMARY_KEY_DESC',
  SLUG_ASC = 'SLUG_ASC',
  SLUG_DESC = 'SLUG_DESC',
  UPDATED_AT_ASC = 'UPDATED_AT_ASC',
  UPDATED_AT_DESC = 'UPDATED_AT_DESC'
}

/** Information about pagination in a connection. */
export type PageInfo = {
  __typename?: 'PageInfo';
  /** When paginating forwards, the cursor to continue. */
  endCursor?: Maybe<Scalars['Cursor']>;
  /** When paginating forwards, are there more items? */
  hasNextPage: Scalars['Boolean'];
  /** When paginating backwards, are there more items? */
  hasPreviousPage: Scalars['Boolean'];
  /** When paginating backwards, the cursor to continue. */
  startCursor?: Maybe<Scalars['Cursor']>;
};

/** The root query type which gives access points into the data universe. */
export type Query = Node & {
  __typename?: 'Query';
  /** Reads and enables pagination through a set of `Facility`. */
  facilities?: Maybe<FacilitiesConnection>;
  facility?: Maybe<Facility>;
  /** Reads a single `Facility` using its globally unique `ID`. */
  facilityByNodeId?: Maybe<Facility>;
  facilityBySlug?: Maybe<Facility>;
  /** Fetches an object given its globally unique `ID`. */
  node?: Maybe<Node>;
  /** The root query type must be a `Node` to work well with Relay 1 mutations. This just resolves to `query`. */
  nodeId: Scalars['ID'];
  organization?: Maybe<Organization>;
  /** Reads a single `Organization` using its globally unique `ID`. */
  organizationByNodeId?: Maybe<Organization>;
  organizationBySlug?: Maybe<Organization>;
  /** Reads and enables pagination through a set of `Organization`. */
  organizations?: Maybe<OrganizationsConnection>;
  /**
   * Exposes the root query type nested one level down. This is helpful for Relay 1
   * which can only query top level fields if they are in a particular form.
   */
  query: Query;
};


/** The root query type which gives access points into the data universe. */
export type QueryFacilitiesArgs = {
  after?: Maybe<Scalars['Cursor']>;
  before?: Maybe<Scalars['Cursor']>;
  condition?: Maybe<FacilityCondition>;
  first?: Maybe<Scalars['Int']>;
  last?: Maybe<Scalars['Int']>;
  offset?: Maybe<Scalars['Int']>;
  orderBy?: Maybe<Array<FacilitiesOrderBy>>;
};


/** The root query type which gives access points into the data universe. */
export type QueryFacilityArgs = {
  id: Scalars['Int'];
};


/** The root query type which gives access points into the data universe. */
export type QueryFacilityByNodeIdArgs = {
  nodeId: Scalars['ID'];
};


/** The root query type which gives access points into the data universe. */
export type QueryFacilityBySlugArgs = {
  slug: Scalars['String'];
};


/** The root query type which gives access points into the data universe. */
export type QueryNodeArgs = {
  nodeId: Scalars['ID'];
};


/** The root query type which gives access points into the data universe. */
export type QueryOrganizationArgs = {
  id: Scalars['Int'];
};


/** The root query type which gives access points into the data universe. */
export type QueryOrganizationByNodeIdArgs = {
  nodeId: Scalars['ID'];
};


/** The root query type which gives access points into the data universe. */
export type QueryOrganizationBySlugArgs = {
  slug: Scalars['String'];
};


/** The root query type which gives access points into the data universe. */
export type QueryOrganizationsArgs = {
  after?: Maybe<Scalars['Cursor']>;
  before?: Maybe<Scalars['Cursor']>;
  condition?: Maybe<OrganizationCondition>;
  first?: Maybe<Scalars['Int']>;
  last?: Maybe<Scalars['Int']>;
  offset?: Maybe<Scalars['Int']>;
  orderBy?: Maybe<Array<OrganizationsOrderBy>>;
};

/** All input for the `updateFacilityByNodeId` mutation. */
export type UpdateFacilityByNodeIdInput = {
  /**
   * An arbitrary string value with no semantic meaning. Will be included in the
   * payload verbatim. May be used to track mutations by the client.
   */
  clientMutationId?: Maybe<Scalars['String']>;
  /** The globally unique `ID` which will identify a single `Facility` to be updated. */
  nodeId: Scalars['ID'];
  /** An object where the defined keys will be set on the `Facility` being updated. */
  patch: FacilityPatch;
};

/** All input for the `updateFacilityBySlug` mutation. */
export type UpdateFacilityBySlugInput = {
  /**
   * An arbitrary string value with no semantic meaning. Will be included in the
   * payload verbatim. May be used to track mutations by the client.
   */
  clientMutationId?: Maybe<Scalars['String']>;
  /** An object where the defined keys will be set on the `Facility` being updated. */
  patch: FacilityPatch;
  /** The facility’s slug. */
  slug: Scalars['String'];
};

/** All input for the `updateFacility` mutation. */
export type UpdateFacilityInput = {
  /**
   * An arbitrary string value with no semantic meaning. Will be included in the
   * payload verbatim. May be used to track mutations by the client.
   */
  clientMutationId?: Maybe<Scalars['String']>;
  /** The primary unique identifier for the facility. */
  id: Scalars['Int'];
  /** An object where the defined keys will be set on the `Facility` being updated. */
  patch: FacilityPatch;
};

/** The output of our update `Facility` mutation. */
export type UpdateFacilityPayload = {
  __typename?: 'UpdateFacilityPayload';
  /**
   * The exact same `clientMutationId` that was provided in the mutation input,
   * unchanged and unused. May be used by a client to track mutations.
   */
  clientMutationId?: Maybe<Scalars['String']>;
  /** The `Facility` that was updated by this mutation. */
  facility?: Maybe<Facility>;
  /** An edge for our `Facility`. May be used by Relay 1. */
  facilityEdge?: Maybe<FacilitiesEdge>;
  /** Reads a single `Organization` that is related to this `Facility`. */
  organization?: Maybe<Organization>;
  /** Our root query field type. Allows us to run any query from our mutation payload. */
  query?: Maybe<Query>;
};


/** The output of our update `Facility` mutation. */
export type UpdateFacilityPayloadFacilityEdgeArgs = {
  orderBy?: Maybe<Array<FacilitiesOrderBy>>;
};

/** All input for the `updateOrganizationByNodeId` mutation. */
export type UpdateOrganizationByNodeIdInput = {
  /**
   * An arbitrary string value with no semantic meaning. Will be included in the
   * payload verbatim. May be used to track mutations by the client.
   */
  clientMutationId?: Maybe<Scalars['String']>;
  /** The globally unique `ID` which will identify a single `Organization` to be updated. */
  nodeId: Scalars['ID'];
  /** An object where the defined keys will be set on the `Organization` being updated. */
  patch: OrganizationPatch;
};

/** All input for the `updateOrganizationBySlug` mutation. */
export type UpdateOrganizationBySlugInput = {
  /**
   * An arbitrary string value with no semantic meaning. Will be included in the
   * payload verbatim. May be used to track mutations by the client.
   */
  clientMutationId?: Maybe<Scalars['String']>;
  /** An object where the defined keys will be set on the `Organization` being updated. */
  patch: OrganizationPatch;
  /** The org’s slug. */
  slug: Scalars['String'];
};

/** All input for the `updateOrganization` mutation. */
export type UpdateOrganizationInput = {
  /**
   * An arbitrary string value with no semantic meaning. Will be included in the
   * payload verbatim. May be used to track mutations by the client.
   */
  clientMutationId?: Maybe<Scalars['String']>;
  /** The primary unique identifier for the org. */
  id: Scalars['Int'];
  /** An object where the defined keys will be set on the `Organization` being updated. */
  patch: OrganizationPatch;
};

/** The output of our update `Organization` mutation. */
export type UpdateOrganizationPayload = {
  __typename?: 'UpdateOrganizationPayload';
  /**
   * The exact same `clientMutationId` that was provided in the mutation input,
   * unchanged and unused. May be used by a client to track mutations.
   */
  clientMutationId?: Maybe<Scalars['String']>;
  /** The `Organization` that was updated by this mutation. */
  organization?: Maybe<Organization>;
  /** An edge for our `Organization`. May be used by Relay 1. */
  organizationEdge?: Maybe<OrganizationsEdge>;
  /** Our root query field type. Allows us to run any query from our mutation payload. */
  query?: Maybe<Query>;
};


/** The output of our update `Organization` mutation. */
export type UpdateOrganizationPayloadOrganizationEdgeArgs = {
  orderBy?: Maybe<Array<OrganizationsOrderBy>>;
};
