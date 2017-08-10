const path = require('path');
const babili = require('babili-webpack-plugin');
const htmlWebpackPlugin = require('html-webpack-plugin');
const scriptExtHtmlWebpackPlugin = require('script-ext-html-webpack-plugin');
const webpack = require('webpack');

module.exports = {
  entry: './src/index.js',
  output: {
    filename: './bundle.js',
    path: path.resolve(__dirname, 'public'),
  },
  plugins: [
    new webpack.optimize.ModuleConcatenationPlugin(),
    new htmlWebpackPlugin({ template: './src/index.pug' }),
    new scriptExtHtmlWebpackPlugin({ inline: ['bundle.js'] }),
  ],
  module: {
    rules: [
      { test: /\.pug$/, use: 'pug-loader' },
      { test: /\.js$/, use: ['eslint-loader'], enforce: 'pre' },
      { test: /\.js$/, use: ['babel-loader'], exclude: /node_modules/ },
      { test: /\.css$/, use: [ 'style-loader', 'css-loader?minimize' ] },
    ]
  },
  resolve: {
    alias: {
      'vue$': 'vue/dist/vue.esm.js'
    }
  },
  node: {
    Buffer: false
  },
  devServer: {
    disableHostCheck: true,
    host: '0.0.0.0',
    proxy: {
      '*': 'http://127.0.0.1:21877/'
    }
  },
};

if (process.env.NODE_ENV === 'production') {
  module.exports.plugins = module.exports.plugins.concat([
    new babili({}),
    new webpack.DefinePlugin({
      'process.env': {
        NODE_ENV: '"production"'
      }
    }),
  ]);
};
