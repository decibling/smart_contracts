import { createVuetify } from "vuetify";
import "vuetify/styles"; // Global CSS has to be imported
import * as components from "vuetify/components";
import * as directives from "vuetify/directives";

import { loadFonts } from "./plugins/webfontloader";
import { createApp } from "vue";
import { createWebHistory } from "vue-router";
import { createPinia } from "pinia";
import "@coreui/coreui/dist/css/coreui.min.css";
import "bootstrap/dist/css/bootstrap.min.css";
import CoreuiVue from "@coreui/vue";
import "./index.css";
import createRouter from "./pages/routes.js";
import App from "./App.vue";
import moment from "moment";
const store = createPinia();
const router = createRouter(createWebHistory());
const app = createApp(App);
loadFonts();
const vuetify = createVuetify({
  components,
  directives,
});

app.use(vuetify);
app.use(CoreuiVue);
app.use(router).use(store).mount("#app");
