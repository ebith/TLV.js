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
      { test: /\.js$/, use: ['eslint-loader'], enforce: 'pre'},
      { test: /\.js$/, use: ['babel-loader']},
      { test: /\.css$/, use: [ 'style-loader', 'css-loader?minimize' ] },
    ]
  },
  resolve: {
    alias: {}
  },
  node: {
    buffer: false
  },
  devServer: {
    disableHostCheck: true,
    host: '0.0.0.0',
    contentBase: path.join(__dirname, "public"),
    proxy: {
      '*': 'http://127.0.0.1:21877/'
    }
  }
};
module.exports.resolve.alias.vue = process.env.NODE_ENV === 'production' ? 'vue/dist/vue.min.js' : 'vue/dist/vue.js'
if (process.env.NODE_ENV === 'production') {
  module.exports.plugins.push(new babili({}));
}
