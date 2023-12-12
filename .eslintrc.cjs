/* eslint-env node */
module.exports = {
  extends: ['eslint:recommended', 'plugin:@typescript-eslint/recommended'],
  parser: '@typescript-eslint/parser',
  plugins: ['@typescript-eslint', 'prettier'],
  rules: {
    'prettier/prettier': 'error',
    'comma-dangle': 'off',
    'arrow-parens': 'off',
    'import/prefer-default-export': 'off',
    'no-plusplus': 'off',
    'no-bitwise': 'off',
    'consistent-return': 'off',
    'no-await-in-loop': 'off',
    'keyword-spacing': 'off',
    'no-restricted-syntax': 'off',
    '@typescript-eslint/no-explicit-any': 'off',
    'max-len': 'off'
  },
  root: true
};
