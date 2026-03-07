import { BelongsTo, Column, DataTypes, Model, Table } from '../../../src';
import type { Note } from './note';
import type { Tag } from './tag';

@Table({ underscored: true, tableName: 'note_tags' })
export class NoteTag extends Model<NoteTag> {
  @Column({
    dataType: DataTypes.INTEGER,
    isPrimaryKey: true,
    isNullable: false,
  })
  public noteId!: number;

  @Column({
    dataType: DataTypes.INTEGER,
    isPrimaryKey: true,
    isNullable: false,
  })
  public tagId!: number;

  @BelongsTo(() => require('./note').Note, {
    relation: [{ foreignKey: 'noteId', sourceKey: 'noteId' }],
  })
  public note!: Note;

  @BelongsTo(() => require('./tag').Tag, {
    relation: [{ foreignKey: 'tagId', sourceKey: 'tagId' }],
  })
  public tag!: Tag;
}
