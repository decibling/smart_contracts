export default{
    devServer: {
        proxy: {
          "http://127.0.0.1:8080": {
            ws: true,
            changeOrigin: true,
          }
        }
      }
}