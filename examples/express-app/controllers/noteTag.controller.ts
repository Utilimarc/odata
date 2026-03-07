import { ODataControler, QueryParser } from '../../../src';
import { NoteTag } from '../models/noteTag';

export class NoteTagController extends ODataControler {
  constructor() {
    super({
      model: NoteTag,
      allowedMethod: ['get'],
    });
  }

  public async get(query: QueryParser) {
    const result = await this.queryable<NoteTag>(query);
    return result;
  }
}
