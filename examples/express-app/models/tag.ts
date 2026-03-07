import { Column, DataTypes, HasMany, Model, Table } from '../../../src';
import type { NoteTag } from './noteTag';

@Table({ underscored: true, tableName: 'tags' })
export class Tag extends Model<Tag> {
  @Column({
    dataType: DataTypes.INTEGER,
    isPrimaryKey: true,
    isAutoIncrement: true,
  })
  public tagId!: number;

  @Column({
    dataType: DataTypes.STRING({ length: 50 }),
    isNullable: false,
  })
  public tagName!: string;

  @HasMany(() => require('./noteTag').NoteTag, {
    relation: [{ foreignKey: 'tagId', sourceKey: 'tagId' }],
  })
  public noteTags!: NoteTag[];
}
