import { Express } from 'express';
import { DataSource, EndpointNamingConvention, ExpressRouter, ODataControler } from '../../src';
import {
  CategoryController,
  DataTypeShowcaseController,
  DepartmentController,
  NoteController,
  NoteTagController,
  PermissionController,
  RoleController,
  RolePermissionController,
  TagController,
  UserRoleController,
} from './controllers';

import {
  Category,
  CustomUser,
  DataTypeShowcase,
  Department,
  Note,
  NoteTag,
  Permission,
  Role,
  RolePermission,
  Tag,
  UserRole,
} from './models';

const createSchema = (app: Express) => {
  const dataSource = new DataSource({
    dialect: (process.env.DB_DIALECT as any) || 'postgres',
    database: process.env.DB_NAME || 'neondb',
    username: process.env.DB_USER || '',
    password: process.env.DB_PASSWORD || '',
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    pool: {
      max: parseInt(process.env.DB_POOL_MAX || '5'),
      min: parseInt(process.env.DB_POOL_MIN || '0'),
      idle: parseInt(process.env.DB_POOL_IDLE || '10000'),
    },
    schema: process.env.DB_SCHEMA !== undefined ? process.env.DB_SCHEMA : 'public',
    ssl: process.env.DB_SSL === 'true',
    models: [Department, CustomUser, Note, Category, UserRole, Tag, Role, Permission, DataTypeShowcase, NoteTag, RolePermission],
  });

  // Initialize controllers
  const userController = new ODataControler({
    model: CustomUser,
    allowedMethod: ['get'],
  });
  const departmentController = new DepartmentController();
  const noteController = new NoteController();
  const categoryController = new CategoryController();
  const tagController = new TagController();
  const roleController = new RoleController();
  const permissionController = new PermissionController();
  const userRoleController = new UserRoleController();
  const dataTypeShowcaseController = new DataTypeShowcaseController();
  const noteTagController = new NoteTagController();
  const rolePermissionController = new RolePermissionController();

  new ExpressRouter(app, {
    controllers: [
      userController,
      departmentController,
      noteController,
      categoryController,
      tagController,
      roleController,
      permissionController,
      userRoleController,
      dataTypeShowcaseController,
      noteTagController,
      rolePermissionController,
    ],
    dataSource,
    logger: {
      enabled: false,
      logLevel: 'INFO',
      format: 'JSON',
      advancedOptions: {
        logSqlQuery: false,
        logDbExecutionTime: false,
        logDbQueryParameters: false,
      },
    },
    endpointNamingConvention: EndpointNamingConvention.AS_MODEL_NAME,
  });
};

export { createSchema };
