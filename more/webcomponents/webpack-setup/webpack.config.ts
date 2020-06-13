const path = require("path");

const HtmlWebpackPlugin = require("html-webpack-plugin");
const webpack = require("webpack");

module.exports = {
    mode: "production",
    entry: "./src/index.ts",
    output: {
        filename: "[name].[hash].js",
        path: path.resolve(__dirname, "dist"),
    },
    module: {
        rules: [
            {
                test: /\.elm$/,
                loader: "elm-webpack-loader",
            },
        ]
    },
    plugins: [
        new HtmlWebpackPlugin(),
    ],
};
