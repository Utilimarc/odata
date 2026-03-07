import { ODataMetadata } from '../types';

/**
 * Escape special XML characters
 */
function escapeXml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/**
 * Convert OData JSON metadata to OData v4 EDMX XML (CSDL).
 * This format is required by Excel, Power Query, and other OData v4 clients.
 */
export function generateMetadataXml(metadata: ODataMetadata): string {
  const namespace = 'OData';
  const lines: string[] = [];

  lines.push('<?xml version="1.0" encoding="utf-8"?>');
  lines.push(
    '<edmx:Edmx Version="4.0" xmlns:edmx="http://docs.oasis-open.org/odata/ns/edmx">',
  );
  lines.push('  <edmx:DataServices>');
  lines.push(`    <Schema Namespace="${namespace}" xmlns="http://docs.oasis-open.org/odata/ns/edm">`);

  // Entity types
  const entities = metadata.entities || {};
  for (const [entityName, entityType] of Object.entries(entities)) {
    lines.push(`      <EntityType Name="${escapeXml(entityName)}">`);

    // Key
    if (entityType.$Key && entityType.$Key.length > 0) {
      lines.push('        <Key>');
      for (const key of entityType.$Key) {
        lines.push(`          <PropertyRef Name="${escapeXml(key)}"/>`);
      }
      lines.push('        </Key>');
    }

    // Properties and NavigationProperties
    for (const [propName, propDef] of Object.entries(entityType)) {
      if (propName.startsWith('$')) continue; // skip $Kind, $Key, $Endpoint

      const prop = propDef as any;
      if (prop.$Kind === 'Property') {
        const nullable = prop.$Nullable !== false ? 'true' : 'false';
        lines.push(
          `        <Property Name="${escapeXml(propName)}" Type="${escapeXml(prop.$Type)}" Nullable="${nullable}"/>`,
        );
      } else if (prop.$Kind === 'NavigationProperty') {
        // Qualify the type with namespace
        const qualifiedType = qualifyType(prop.$Type, namespace);
        let navLine = `        <NavigationProperty Name="${escapeXml(propName)}" Type="${escapeXml(qualifiedType)}"`;

        // Check if it's a collection - if not, add Partner later if needed
        navLine += '/>';
        lines.push(navLine);
      }
    }

    lines.push('      </EntityType>');
  }

  // EntityContainer
  lines.push('      <EntityContainer Name="Container">');
  for (const entityName of Object.keys(entities)) {
    lines.push(
      `        <EntitySet Name="${escapeXml(entityName)}" EntityType="${namespace}.${escapeXml(entityName)}">`,
    );

    // Add NavigationPropertyBinding for each navigation property
    const entityType = entities[entityName];
    for (const [propName, propDef] of Object.entries(entityType)) {
      if (propName.startsWith('$')) continue;
      const prop = propDef as any;
      if (prop.$Kind === 'NavigationProperty') {
        const targetEntity = extractEntityName(prop.$Type);
        if (entities[targetEntity]) {
          lines.push(
            `          <NavigationPropertyBinding Path="${escapeXml(propName)}" Target="${escapeXml(targetEntity)}"/>`,
          );
        }
      }
    }

    lines.push('        </EntitySet>');
  }
  lines.push('      </EntityContainer>');

  lines.push('    </Schema>');
  lines.push('  </edmx:DataServices>');
  lines.push('</edmx:Edmx>');

  return lines.join('\n');
}

/**
 * Qualify a type name with namespace, handling Collection() wrapper
 */
function qualifyType(type: string, namespace: string): string {
  const collectionMatch = type.match(/^Collection\((.+)\)$/);
  if (collectionMatch) {
    return `Collection(${namespace}.${collectionMatch[1]})`;
  }
  return `${namespace}.${type}`;
}

/**
 * Extract the entity name from a type string (handles Collection wrapper)
 */
function extractEntityName(type: string): string {
  const collectionMatch = type.match(/^Collection\((.+)\)$/);
  if (collectionMatch) {
    return collectionMatch[1];
  }
  return type;
}
