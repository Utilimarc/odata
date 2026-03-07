import { BelongsTo, Column, DataTypes, Model, Table } from '../../../src';
import { Department } from './department';

@Table({ underscored: true, tableName: 'data_type_showcase' })
export class DataTypeShowcase extends Model<DataTypeShowcase> {
  @Column({
    dataType: DataTypes.INTEGER,
    isPrimaryKey: true,
    isAutoIncrement: true,
  })
  public id!: number;

  @Column({ dataType: DataTypes.STRING({ length: 100 }), isNullable: false })
  public label!: string;

  // Edm.Int64
  @Column({ dataType: DataTypes.BIGINT, isNullable: true })
  public bigIntVal!: number;

  // Edm.Int32 (SMALLINT hits the INT check first — known mapping quirk)
  @Column({ dataType: DataTypes.SMALLINT, isNullable: true })
  public smallIntVal!: number;

  // Edm.Decimal
  @Column({ dataType: DataTypes.DECIMAL(10, 2), isNullable: true })
  public decimalVal!: number;

  // Edm.Double (via FLOAT)
  @Column({ dataType: DataTypes.FLOAT, isNullable: true })
  public floatVal!: number;

  // Edm.Double (via DOUBLE PRECISION)
  @Column({ dataType: DataTypes.DOUBLE, isNullable: true })
  public doubleVal!: number;

  // Edm.Boolean
  @Column({ dataType: DataTypes.BOOLEAN, isNullable: true, defaultValue: false })
  public boolVal!: boolean;

  // Edm.String (VARCHAR)
  @Column({ dataType: DataTypes.STRING({ length: 200 }), isNullable: true })
  public stringVal!: string;

  // Edm.String (TEXT)
  @Column({ dataType: DataTypes.TEXT, isNullable: true })
  public textVal!: string;

  // Edm.Date (date only, no time)
  @Column({ dataType: DataTypes.DATEONLY, isNullable: true })
  public dateOnlyVal!: string;

  // Edm.DateTimeOffset (full timestamp)
  @Column({ dataType: DataTypes.DATE, isNullable: true })
  public datetimeVal!: Date;

  // Edm.Guid
  @Column({ dataType: DataTypes.UUID, isNullable: true })
  public uuidVal!: string;

  // Edm.String (JSON — serialized to string by the router)
  @Column({ dataType: DataTypes.JSON, isNullable: true })
  public jsonVal!: object;

  // Edm.Binary (BLOB — serialized to base64 by the router)
  @Column({ dataType: DataTypes.BLOB, isNullable: true })
  public blobVal!: Buffer;

  // FK → Department (interrelation)
  @Column({ dataType: DataTypes.INTEGER, isNullable: true })
  public departmentId!: number;

  @BelongsTo(() => Department, {
    relation: [{ foreignKey: 'id', sourceKey: 'departmentId' }],
  })
  public department!: Department;
}
