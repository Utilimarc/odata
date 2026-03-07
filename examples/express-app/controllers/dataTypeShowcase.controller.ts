import { ODataControler, QueryParser } from '../../../src';
import { DataTypeShowcase } from '../models/dataTypeShowcase';

export class DataTypeShowcaseController extends ODataControler {
  constructor() {
    super({
      model: DataTypeShowcase,
      allowedMethod: ['get'],
    });
  }

  public async get(query: QueryParser) {
    const result = await this.queryable<DataTypeShowcase>(query);
    return result;
  }
}
