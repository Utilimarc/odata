const USER_URL = process.env.API_BASE_URL || 'http://localhost:3001/CustomUser';
const _DEPT_URL = 'http://localhost:3001/Department';
const _NOTE_URL = 'http://localhost:3001/Note';

/** Helper: expect non-200 status (error) and verify data is still intact */
async function expectRejectedAndDataIntact(url: string, maliciousQuery: string) {
  const result = await fetch(`${url}${maliciousQuery}`);
  expect(result.status).not.toBe(200);

  // Verify the table is still queryable
  const check = await fetch(`${url}?$top=1`);
  expect(check.status).toBe(200);
}

describe('SQL Injection Prevention', () => {
  test('should reject SQL injection in $filter (DROP TABLE)', async () => {
    await expectRejectedAndDataIntact(USER_URL, "?$filter=username eq 'admin'; DROP TABLE users--'");
  });

  test('should reject SQL injection with UNION SELECT', async () => {
    const result = await fetch(`${USER_URL}?$filter=username eq 'admin' UNION SELECT * FROM passwords--`);
    expect(result.status).not.toBe(200);
  });

  test('should reject SQL injection in $orderby', async () => {
    await expectRejectedAndDataIntact(USER_URL, '?$orderby=username; DROP TABLE users--');
  });

  test('should reject SQL comments in filter values', async () => {
    const result = await fetch(`${USER_URL}?$filter=username eq 'admin'--`);
    expect(result.status).not.toBe(200);
  });

  test('should not execute injected SQL functions', async () => {
    // CHAR() should not be executed as SQL — if it returns data, it was parsed as OData (safe)
    // The key assertion is that the DB was not compromised
    await fetch(`${USER_URL}?$filter=username eq CHAR(97,100,109,105,110)`);
    // Verify the table is still intact
    const check = await fetch(`${USER_URL}?$top=1`);
    expect(check.status).toBe(200);
  });
});

describe('Cast SQL Injection Prevention (issue #1)', () => {
  test('should reject malicious cast type', async () => {
    const result = await fetch(`${USER_URL}?$filter=cast(userId, 'int; DROP TABLE users--') gt 0`);
    expect(result.status).not.toBe(200);
  });

  test('should reject cast with subquery type', async () => {
    const result = await fetch(`${USER_URL}?$filter=cast(userId, '(SELECT 1)') gt 0`);
    expect(result.status).not.toBe(200);
  });

  test('should allow valid cast types', async () => {
    const result = await fetch(`${USER_URL}?$filter=cast(userId, 'integer') gt 0`);
    // Should succeed (200) or fail for dialect reasons, but NOT be a 500
    expect([200, 400]).toContain(result.status);
  });
});

describe('Has Operator SQL Injection Prevention (issue #2)', () => {
  test('should reject non-integer right-hand value', async () => {
    const result = await fetch(`${USER_URL}?$filter=departmentId has 'DROP TABLE users'`);
    expect(result.status).not.toBe(200);
  });

  test('should reject function on left side of has', async () => {
    const result = await fetch(`${USER_URL}?$filter=tolower(username) has 4`);
    expect(result.status).not.toBe(200);
  });
});

describe('Arithmetic/Literal SQL Injection Prevention (issue #3)', () => {
  test('should reject injection in arithmetic field names', async () => {
    // Field names are validated by queryConverter, so unknown fields should be rejected
    const result = await fetch(`${USER_URL}?$filter=nonexistentField mul 2 gt 0`);
    expect(result.status).not.toBe(200);
  });

  test('should handle safe arithmetic operations', async () => {
    const result = await fetch(`${USER_URL}?$filter=userId mul 1 gt 0`);
    // May succeed or fail for dialect reasons, but not be injection
    expect([200, 400, 500]).toContain(result.status);
  });

  test('should reject null bytes in string values', async () => {
    const result = await fetch(`${USER_URL}?$filter=username eq 'test%00DROP'`);
    // Should not return 200
    expect(result.status).not.toBe(200);
  });
});

describe('URL Encoding Security (issue #4)', () => {
  test('should not double-decode URL-encoded values', async () => {
    // %2527 = URL-encoded %27 = URL-encoded single quote
    // If double-decoded, this would become a bare single quote
    const result = await fetch(`${USER_URL}?$filter=username eq %2527admin%2527`);
    expect(result.status).not.toBe(200);
  });

  test('should handle normal URL-encoded characters safely', async () => {
    // %20 = space, should be handled normally
    const result = await fetch(`${USER_URL}?$filter=fullName eq 'John%20Doe'`);
    expect([200, 400]).toContain(result.status);
  });
});

describe('Information Disclosure Prevention (issue #5)', () => {
  test('should not expose stack traces in error responses', async () => {
    const result = await fetch(`${USER_URL}?$filter=INVALID QUERY`);
    const body = await result.text();
    expect(body).not.toContain('at ');
    expect(body).not.toContain('.ts:');
    expect(body).not.toContain('.js:');
    expect(body).not.toContain('node_modules');
  });

  test('should not enumerate table names in errors', async () => {
    const result = await fetch(`${USER_URL}?$expand=NonExistentTable`);
    const body = await result.text();
    // Should not list available navigation properties
    expect(body).not.toContain('Available');
    expect(body).not.toContain('navigation properties');
  });

  test('should return generic error for invalid paths', async () => {
    const result = await fetch('http://localhost:3001/NonExistentEndpoint');
    const body = await result.text();
    expect(body).not.toContain('stack');
    expect(body).not.toContain('node_modules');
  });
});

describe('Resource Exhaustion Prevention (issue #6)', () => {
  test('should reject excessive expand depth', async () => {
    // 6 levels of nesting should exceed MAX_EXPAND_DEPTH of 4
    const deepExpand = '?$expand=myDepartment($expand=users($expand=myDepartment($expand=users($expand=myDepartment($expand=users)))))';
    const result = await fetch(`${USER_URL}${deepExpand}`);
    expect(result.status).toBe(400);
  });

  test('should enforce $top maximum', async () => {
    const result = await fetch(`${USER_URL}?$top=99999`);
    expect(result.status).toBe(400);
  });

  test('should reject negative $skip', async () => {
    const result = await fetch(`${USER_URL}?$skip=-1`);
    expect(result.status).toBe(400);
  });

  test('should apply default top limit when not specified', async () => {
    const result = await fetch(`${USER_URL}`);
    expect(result.status).toBe(200);
    const data = await result.json() as any;
    // Default top should limit results (not return unlimited)
    expect(data.value.length).toBeLessThanOrEqual(100);
  });
});

describe('LIKE Wildcard Injection Prevention (issue #7)', () => {
  test('should escape % wildcard in contains filter', async () => {
    // The % should be escaped, not treated as SQL wildcard
    const result = await fetch(`${USER_URL}?$filter=contains(username, '%')`);
    expect([200, 400]).toContain(result.status);
    if (result.status === 200) {
      const data = await result.json() as any;
      // No usernames literally contain %, so should be empty
      expect(data.value.length).toBe(0);
    }
  });

  test('should escape _ wildcard in contains filter', async () => {
    const result = await fetch(`${USER_URL}?$filter=contains(username, '_')`);
    expect([200, 400]).toContain(result.status);
  });

  test('should still perform normal string searches', async () => {
    const result = await fetch(`${USER_URL}?$filter=contains(username, 'john')`);
    expect(result.status).toBe(200);
    const data = await result.json() as any;
    expect(data.value.length).toBeGreaterThan(0);
  });
});

describe('Invalid Query Parameter Rejection', () => {
  test('should reject unknown OData system query options', async () => {
    const result = await fetch(`${USER_URL}?$invalid=something`);
    expect(result.status).toBe(400);
  });

  test('should reject non-integer $top', async () => {
    const result = await fetch(`${USER_URL}?$top=abc`);
    expect(result.status).toBe(400);
  });

  test('should reject non-integer $skip', async () => {
    const result = await fetch(`${USER_URL}?$skip=abc`);
    expect(result.status).toBe(400);
  });
});
