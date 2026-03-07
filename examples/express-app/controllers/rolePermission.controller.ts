import { ODataControler, QueryParser } from '../../../src';
import { RolePermission } from '../models/rolePermission';

export class RolePermissionController extends ODataControler {
  constructor() {
    super({
      model: RolePermission,
      allowedMethod: ['get'],
    });
  }

  public async get(query: QueryParser) {
    const result = await this.queryable<RolePermission>(query);
    return result;
  }
}
