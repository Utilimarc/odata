import { BelongsTo, Column, DataTypes, Model, Table } from '../../../src';
import type { Permission } from './permission';
import type { Role } from './role';

@Table({ underscored: true, tableName: 'role_permissions' })
export class RolePermission extends Model<RolePermission> {
  @Column({
    dataType: DataTypes.INTEGER,
    isPrimaryKey: true,
    isNullable: false,
  })
  public roleId!: number;

  @Column({
    dataType: DataTypes.INTEGER,
    isPrimaryKey: true,
    isNullable: false,
  })
  public permissionId!: number;

  @BelongsTo(() => require('./role').Role, {
    relation: [{ foreignKey: 'roleId', sourceKey: 'roleId' }],
  })
  public role!: Role;

  @BelongsTo(() => require('./permission').Permission, {
    relation: [{ foreignKey: 'permissionId', sourceKey: 'permissionId' }],
  })
  public permission!: Permission;
}
