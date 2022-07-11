<template>
  <div class="grid grid-cols-3 top-0 gap-4 adjust-tab">
    <a
      v-bind:class="
        'btn margin-right ' +
        (currentTab() == '/' ? 'btn-primary' : 'btn-outline-primary')
      "
      href="/"
      >Home</a
    >
    <a
      v-bind:class="
        'btn margin-right ' +
        (currentTab() == '/account' ? 'btn-primary' : 'btn-outline-primary')
      "
      href="/account"
      >My Account</a
    >
    <a
      v-bind:class="
        'btn margin-right ' +
        (currentTab() == '/token_farm' ? 'btn-primary' : 'btn-outline-primary')
      "
      href="/token_farm"
      >Token Farm</a
    >

    <!-- <a class="btn btn-outline-primary margin-right" href="/nft">NFT Detail</a> -->
  </div>
</template>
<script>
export default {
  methods: {
    currentTab() {
      return location.pathname;
    },
  },
};
</script>
<style>
.margin-right {
  margin-right: 5px;
}
.adjust-tab {
  margin-top: 5px;
  margin-bottom: 5px;
}
</style>
