import { DataType as SequelizeDataTypeInterface, DataTypes as SequelizeDataTypes } from 'sequelize';

export const DataTypes = SequelizeDataTypes;

export type IDataType = SequelizeDataTypeInterface;

export type IEntitySchemaOptions = Record<string, unknown>;
