module.exports = {
  printWidth: 80,
  tabWidth: 2,
  useTabs: false,
  semi: true,
  singleQuote: true,
  trailingComma: "es5",
  bracketSpacing: true,
  jsxBracketSameLine: false,
  arrowParens: "always",
  overrides: [
    {
      files: "*.cls",
      options: { parser: "apex" }
    },
    {
      files: "*.xml",
      options: { parser: "xml" }
    }
  ],
  plugins: [
    require.resolve("prettier-plugin-apex"),
    require.resolve("prettier-plugin-xml")
  ]
};
