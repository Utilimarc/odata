import { Column, DataTypes, HasMany, Model, Table } from '../../../src';
import type { RolePermission } from './rolePermission';

@Table({ underscored: true, tableName: 'permissions' })
export class Permission extends Model<Permission> {
  @Column({
    dataType: DataTypes.INTEGER,
    isPrimaryKey: true,
    isAutoIncrement: true,
  })
  public permissionId!: number;

  @Column({
    dataType: DataTypes.STRING({ length: 100 }),
    isNullable: false,
  })
  public permissionName!: string;

  @Column({
    dataType: DataTypes.TEXT,
    isNullable: true,
  })
  public description!: string;

  @HasMany(() => require('./rolePermission').RolePermission, {
    relation: [{ foreignKey: 'permissionId', sourceKey: 'permissionId' }],
  })
  public rolePermissions!: RolePermission[];
}
