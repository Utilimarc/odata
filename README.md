# Node OData Framework (TypeScript)

A powerful Node.js framework for building REST APIs with full OData v4 query capabilities. This framework provides a decorator-based approach to define models and automatically generates OData-compliant endpoints with advanced querying features.

> This is a hardened fork of [@phrasecode/odata](https://github.com/Phrasecode/odata) with security fixes, PostgreSQL testing, Excel/Power Query compatibility, and a containerized development workflow.

## What's Changed in This Fork

- **SQL injection prevention** in the Sequelize adapter (identifier validation, string escaping, cast type allowlist, LIKE wildcard escaping)
- **OData v4 client compatibility** (Excel, Power Query) — XML CSDL metadata, service document, proper content-type headers, IEEE754Compatible for BIGINT, JSON/BLOB serialization
- **PostgreSQL-first testing** via containerized Podman workflow
- **Demo mode** — one command to spin up a PostgreSQL database with sample data and an OData server that Excel can connect to
- **405 Method Not Allowed** for unsupported HTTP methods
- **Node.js 18+** minimum (14 and 16 are EOL)
- **Fixed `Edm.Date` vs `Edm.DateTimeOffset`** type mapping for Sequelize `DataTypes.DATE`
- **Fixed SSL connection** — `dialectOptions.ssl` is no longer set when SSL is disabled

## Quick Start

### Demo Mode (Excel / Power Query)

```bash
# Start PostgreSQL + OData server on http://localhost:3000
./dev.sh demo

# In Excel: Data -> Get Data -> From OData Feed -> http://localhost:3000
# Select Anonymous authentication, then pick your tables.

# Stop everything
./dev.sh demo:stop
```

### Development

```bash
# Run unit tests
./dev.sh test

# Run e2e tests (PostgreSQL)
./dev.sh test:e2e

# Run security tests (PostgreSQL)
./dev.sh test:security

# Lint + typecheck + unit tests
./dev.sh check

# Open psql shell to demo database
./dev.sh db:psql

# See all commands
./dev.sh help
```

All commands run in Podman containers — no local Node.js installation required.

## Key Features

- **Decorator-Based Model Definition**: Use TypeScript decorators to define your data models
- **Full OData v4 Query Support**: `$select`, `$filter`, `$expand`, `$orderby`, `$top`, `$skip`, `$count`
- **Advanced Filter Capabilities**: Comparison, logical, arithmetic operators, string/date/math functions
- **Powerful Expansion Features**: Nested expansions (5+ levels), filters on relations
- **Relationship Support**: One-to-many, one-to-one, and many-to-one relationships
- **Multiple Integration Options**: Express.js Router and OpenRouter for Next.js/serverless
- **OData Metadata**: XML CSDL (`$metadata`) and JSON service document for client discovery
- **Excel / Power Query Compatible**: Service document, XML metadata, IEEE754Compatible headers, JSON/BLOB serialization, and spec-compliant responses
- **Database Agnostic**: PostgreSQL, MySQL, SQLite, MariaDB, MSSQL, Oracle

## Installation

```bash
npm install @phrasecode/odata
```

You'll also need a database driver (e.g., `pg` for PostgreSQL).

## Usage

```typescript
import {
  Model,
  Table,
  Column,
  DataTypes,
  DataSource,
  ExpressRouter,
  ODataControler,
} from '@phrasecode/odata';
import express from 'express';

// Define a model
@Table({ tableName: 'users' })
class User extends Model<User> {
  @Column({
    dataType: DataTypes.INTEGER,
    isPrimaryKey: true,
    isAutoIncrement: true,
  })
  id: number;

  @Column({ dataType: DataTypes.STRING })
  name: string;

  @Column({ dataType: DataTypes.STRING })
  email: string;
}

// Create data source
const dataSource = new DataSource({
  dialect: 'postgres',
  database: 'mydb',
  username: 'user',
  password: 'password',
  host: 'localhost',
  port: 5432,
  models: [User],
});

// Set up Express router
const app = express();
const userController = new ODataControler({
  model: User,
  allowedMethod: ['get'],
});
new ExpressRouter(app, { controllers: [userController], dataSource });

app.listen(3000);
// Service document:  GET http://localhost:3000/
// Metadata (XML):    GET http://localhost:3000/$metadata
// Query:             GET http://localhost:3000/User?$select=name,email&$filter=name eq 'John'
```

## OData Query Examples

```
# Select specific fields
GET /User?$select=name,email

# Filter results
GET /User?$filter=age gt 18 and status eq 'active'

# Expand relations
GET /User?$expand=department,orders

# Combine multiple options
GET /User?$filter=age gt 18&$expand=department&$select=name,email&$orderby=name asc&$top=20

# String functions
GET /User?$filter=contains(name, 'john') or startswith(email, 'admin')

# Arithmetic expressions
GET /Order?$filter=((price mul quantity) sub discount) gt 1000
```

## Connection Pooling

Critical for production — improves query performance by 10-15x:

```typescript
const dataSource = new DataSource({
  // ... other config
  pool: {
    max: 10,
    min: 2,
    idle: 10000,
  },
});
```

## Security

This fork addresses several SQL injection vectors in the Sequelize adapter:

- **Identifier validation**: All table/column names interpolated into `literal()` are validated against a strict regex
- **String escaping**: Proper single-quote doubling and null byte rejection for string literals
- **Cast type allowlist**: `cast()` function arguments are restricted to known SQL types
- **Has operator restriction**: Limited to simple field-to-integer comparisons
- **LIKE wildcard escaping**: `%`, `_`, `\` characters escaped in `contains`/`startswith`/`endswith`
- **Numeric validation**: `NaN`/`Infinity` rejected in SQL literal positions

## License

MIT - see [LICENSE](./LICENSE).

## Upstream

This is a fork of [Phrasecode/odata](https://github.com/Phrasecode/odata). Security fixes have been submitted as upstream PRs.
