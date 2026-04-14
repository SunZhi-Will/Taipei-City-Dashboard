// vite.config.js
import { defineConfig } from "file:///opt/Taipei-City-Dashboard-FE/node_modules/vite/dist/node/index.js";
import vue from "file:///opt/Taipei-City-Dashboard-FE/node_modules/@vitejs/plugin-vue/dist/index.mjs";
import viteCompression from "file:///opt/Taipei-City-Dashboard-FE/node_modules/vite-plugin-compression/dist/index.mjs";
var isDockerCompose = process?.env.DOCKER_COMPOSE === "true";
var serverConfig = isDockerCompose ? {
  // Docker Compose override config
  host: "0.0.0.0",
  port: 80,
  // 如有需要可變更 port
  proxy: {
    "/api/dev": {
      target: "http://dashboard-be:8080",
      changeOrigin: true,
      rewrite: (path) => path.replace("/dev", "/v1")
    }
  }
} : {
  host: "0.0.0.0",
  port: 80,
  proxy: {
    "/api": {
      target: "https://citydashboard.taipei/api/v1",
      changeOrigin: true,
      rewrite: (path) => path.replace(/^\/api/, "")
    },
    "/geo_server": {
      target: "https://citydashboard.taipei/geo_server/",
      changeOrigin: true,
      rewrite: (path) => path.replace(/^\/geo_server/, "")
    }
  }
};
var vite_config_default = defineConfig({
  plugins: [vue(), viteCompression()],
  build: {
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (id.includes("node_modules")) {
            return id.toString().split("node_modules/")[1].split("/")[0].toString();
          }
        }
      }
    },
    chunkSizeWarningLimit: 1600
  },
  base: "/",
  server: serverConfig
});
export {
  vite_config_default as default
};
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsidml0ZS5jb25maWcuanMiXSwKICAic291cmNlc0NvbnRlbnQiOiBbImNvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9kaXJuYW1lID0gXCIvb3B0L1RhaXBlaS1DaXR5LURhc2hib2FyZC1GRVwiO2NvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9maWxlbmFtZSA9IFwiL29wdC9UYWlwZWktQ2l0eS1EYXNoYm9hcmQtRkUvdml0ZS5jb25maWcuanNcIjtjb25zdCBfX3ZpdGVfaW5qZWN0ZWRfb3JpZ2luYWxfaW1wb3J0X21ldGFfdXJsID0gXCJmaWxlOi8vL29wdC9UYWlwZWktQ2l0eS1EYXNoYm9hcmQtRkUvdml0ZS5jb25maWcuanNcIjtpbXBvcnQgeyBkZWZpbmVDb25maWcgfSBmcm9tIFwidml0ZVwiO1xyXG5pbXBvcnQgdnVlIGZyb20gXCJAdml0ZWpzL3BsdWdpbi12dWVcIjtcclxuaW1wb3J0IHZpdGVDb21wcmVzc2lvbiBmcm9tIFwidml0ZS1wbHVnaW4tY29tcHJlc3Npb25cIjtcclxuXHJcbi8vIFx1NTYxN1x1OEE2Nlx1OEI4MFx1NTNENlx1NzRCMFx1NTg4M1x1OEI4QVx1NjU3OFx1RkYwQ1x1ODJFNVx1NEUwRFx1NUI1OFx1NTcyOFx1NTI0N1x1NTZERVx1NTBCMyBmYWxzZVxyXG5sZXQgaXNEb2NrZXJDb21wb3NlID0gcHJvY2Vzcz8uZW52LkRPQ0tFUl9DT01QT1NFID09PSBcInRydWVcIjsgLy8gZXNsaW50LWRpc2FibGUtbGluZSBuby11bmRlZlxyXG5cclxuY29uc3Qgc2VydmVyQ29uZmlnID0gaXNEb2NrZXJDb21wb3NlXHJcblx0PyB7XHJcblx0XHQvLyBEb2NrZXIgQ29tcG9zZSBvdmVycmlkZSBjb25maWdcclxuXHRcdGhvc3Q6IFwiMC4wLjAuMFwiLFxyXG5cdFx0cG9ydDogODAsIC8vIFx1NTk4Mlx1NjcwOVx1OTcwMFx1ODk4MVx1NTNFRlx1OEI4QVx1NjZGNCBwb3J0XHJcblx0XHRwcm94eToge1xyXG5cdFx0XHRcIi9hcGkvZGV2XCI6IHtcclxuXHRcdFx0XHR0YXJnZXQ6IFwiaHR0cDovL2Rhc2hib2FyZC1iZTo4MDgwXCIsXHJcblx0XHRcdFx0Y2hhbmdlT3JpZ2luOiB0cnVlLFxyXG5cdFx0XHRcdHJld3JpdGU6IChwYXRoKSA9PiBwYXRoLnJlcGxhY2UoXCIvZGV2XCIsIFwiL3YxXCIpXHJcblx0XHRcdH1cclxuXHRcdH1cclxuXHR9XHJcblx0OiB7XHJcblx0XHRob3N0OiBcIjAuMC4wLjBcIixcclxuXHRcdHBvcnQ6IDgwLFxyXG5cdFx0cHJveHk6IHtcclxuXHRcdFx0XCIvYXBpXCI6IHtcclxuXHRcdFx0XHR0YXJnZXQ6IFwiaHR0cHM6Ly9jaXR5ZGFzaGJvYXJkLnRhaXBlaS9hcGkvdjFcIixcclxuXHRcdFx0XHRjaGFuZ2VPcmlnaW46IHRydWUsXHJcblx0XHRcdFx0cmV3cml0ZTogKHBhdGgpID0+IHBhdGgucmVwbGFjZSgvXlxcL2FwaS8sIFwiXCIpXHJcblx0XHRcdH0sXHJcblx0XHRcdFwiL2dlb19zZXJ2ZXJcIjoge1xyXG5cdFx0XHRcdHRhcmdldDogXCJodHRwczovL2NpdHlkYXNoYm9hcmQudGFpcGVpL2dlb19zZXJ2ZXIvXCIsXHJcblx0XHRcdFx0Y2hhbmdlT3JpZ2luOiB0cnVlLFxyXG5cdFx0XHRcdHJld3JpdGU6IChwYXRoKSA9PiBwYXRoLnJlcGxhY2UoL15cXC9nZW9fc2VydmVyLywgXCJcIilcclxuXHRcdFx0fVxyXG5cdFx0fVxyXG5cdH07XHJcblxyXG5leHBvcnQgZGVmYXVsdCBkZWZpbmVDb25maWcoe1xyXG5cdHBsdWdpbnM6IFt2dWUoKSwgdml0ZUNvbXByZXNzaW9uKCldLFxyXG5cdGJ1aWxkOiB7XHJcblx0XHRyb2xsdXBPcHRpb25zOiB7XHJcblx0XHRcdG91dHB1dDoge1xyXG5cdFx0XHRcdG1hbnVhbENodW5rcyhpZCkge1xyXG5cdFx0XHRcdFx0aWYgKGlkLmluY2x1ZGVzKFwibm9kZV9tb2R1bGVzXCIpKSB7XHJcblx0XHRcdFx0XHRcdHJldHVybiBpZFxyXG5cdFx0XHRcdFx0XHRcdC50b1N0cmluZygpXHJcblx0XHRcdFx0XHRcdFx0LnNwbGl0KFwibm9kZV9tb2R1bGVzL1wiKVsxXVxyXG5cdFx0XHRcdFx0XHRcdC5zcGxpdChcIi9cIilbMF1cclxuXHRcdFx0XHRcdFx0XHQudG9TdHJpbmcoKTtcclxuXHRcdFx0XHRcdH1cclxuXHRcdFx0XHR9LFxyXG5cdFx0XHR9LFxyXG5cdFx0fSxcclxuXHRcdGNodW5rU2l6ZVdhcm5pbmdMaW1pdDogMTYwMCxcclxuXHR9LFxyXG5cdGJhc2U6IFwiL1wiLFxyXG5cdHNlcnZlcjogc2VydmVyQ29uZmlnLFxyXG59KTsiXSwKICAibWFwcGluZ3MiOiAiO0FBQXlRLFNBQVMsb0JBQW9CO0FBQ3RTLE9BQU8sU0FBUztBQUNoQixPQUFPLHFCQUFxQjtBQUc1QixJQUFJLGtCQUFrQixTQUFTLElBQUksbUJBQW1CO0FBRXRELElBQU0sZUFBZSxrQkFDbEI7QUFBQTtBQUFBLEVBRUQsTUFBTTtBQUFBLEVBQ04sTUFBTTtBQUFBO0FBQUEsRUFDTixPQUFPO0FBQUEsSUFDTixZQUFZO0FBQUEsTUFDWCxRQUFRO0FBQUEsTUFDUixjQUFjO0FBQUEsTUFDZCxTQUFTLENBQUMsU0FBUyxLQUFLLFFBQVEsUUFBUSxLQUFLO0FBQUEsSUFDOUM7QUFBQSxFQUNEO0FBQ0QsSUFDRTtBQUFBLEVBQ0QsTUFBTTtBQUFBLEVBQ04sTUFBTTtBQUFBLEVBQ04sT0FBTztBQUFBLElBQ04sUUFBUTtBQUFBLE1BQ1AsUUFBUTtBQUFBLE1BQ1IsY0FBYztBQUFBLE1BQ2QsU0FBUyxDQUFDLFNBQVMsS0FBSyxRQUFRLFVBQVUsRUFBRTtBQUFBLElBQzdDO0FBQUEsSUFDQSxlQUFlO0FBQUEsTUFDZCxRQUFRO0FBQUEsTUFDUixjQUFjO0FBQUEsTUFDZCxTQUFTLENBQUMsU0FBUyxLQUFLLFFBQVEsaUJBQWlCLEVBQUU7QUFBQSxJQUNwRDtBQUFBLEVBQ0Q7QUFDRDtBQUVELElBQU8sc0JBQVEsYUFBYTtBQUFBLEVBQzNCLFNBQVMsQ0FBQyxJQUFJLEdBQUcsZ0JBQWdCLENBQUM7QUFBQSxFQUNsQyxPQUFPO0FBQUEsSUFDTixlQUFlO0FBQUEsTUFDZCxRQUFRO0FBQUEsUUFDUCxhQUFhLElBQUk7QUFDaEIsY0FBSSxHQUFHLFNBQVMsY0FBYyxHQUFHO0FBQ2hDLG1CQUFPLEdBQ0wsU0FBUyxFQUNULE1BQU0sZUFBZSxFQUFFLENBQUMsRUFDeEIsTUFBTSxHQUFHLEVBQUUsQ0FBQyxFQUNaLFNBQVM7QUFBQSxVQUNaO0FBQUEsUUFDRDtBQUFBLE1BQ0Q7QUFBQSxJQUNEO0FBQUEsSUFDQSx1QkFBdUI7QUFBQSxFQUN4QjtBQUFBLEVBQ0EsTUFBTTtBQUFBLEVBQ04sUUFBUTtBQUNULENBQUM7IiwKICAibmFtZXMiOiBbXQp9Cg==
