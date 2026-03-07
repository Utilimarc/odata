// Set environment variable for security tests
process.env.TEST_TYPE = 'e2e';

module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  displayName: 'Security Tests',
  roots: ['<rootDir>/__tests__/e2e/security'],
  testMatch: ['**/__tests__/e2e/security/**/*.test.ts'],
  transform: {
    '^.+\\.ts$': 'ts-jest',
  },
  testTimeout: 60000,
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  setupFilesAfterEnv: ['<rootDir>/__tests__/e2e/setup.ts'],
  globalSetup: '<rootDir>/__tests__/e2e/globalSetup.ts',
  globalTeardown: '<rootDir>/__tests__/e2e/globalTeardown.ts',
  maxWorkers: 1,
  forceExit: true,
};
