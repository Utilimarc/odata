import { Column, DataTypes, HasMany, Model, Table } from '../../../src';
import type { RolePermission } from './rolePermission';

@Table({ underscored: true, tableName: 'roles' })
export class Role extends Model<Role> {
  @Column({
    dataType: DataTypes.INTEGER,
    isPrimaryKey: true,
    isAutoIncrement: true,
  })
  public roleId!: number;

  @Column({
    dataType: DataTypes.STRING({ length: 50 }),
    isNullable: false,
  })
  public roleName!: string;

  @Column({
    dataType: DataTypes.TEXT,
    isNullable: true,
  })
  public description!: string;

  @HasMany(() => require('./rolePermission').RolePermission, {
    relation: [{ foreignKey: 'roleId', sourceKey: 'roleId' }],
  })
  public rolePermissions!: RolePermission[];
}
