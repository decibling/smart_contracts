<template>
  <CCard class="col-md-4">
    <CCardHeader>
      {{ nft.name }}
      <CBadge v-bind:color="nft_color[nft.status]">{{
        nft_status[nft.status]
      }}</CBadge></CCardHeader
    >
    <CCardBody>
      <audio controls style="width: 100%">
        <source
          v-bind:src="'https://ipfs.datgital.top/ipfs/' + nft.url"
          type="audio/mpeg"
        />
        Your browser does not support the audio element.
      </audio>
    </CCardBody>
    <CCardFooter>
      <a v-bind:href="'/nft/' + nft.tokenId"
        ><CButton color="danger" variant="outline">Detail</CButton></a
      >
      <a
        v-bind:href="
          'https://rinkeby.etherscan.io/token/' +
          contractAddress +
          '?a=' +
          nft.tokenId
        "
        target="_blank"
        class="left-margin"
        ><CButton color="success" variant="outline">ETH Scanner</CButton></a
      >
    </CCardFooter>
  </CCard>
</template>

<script>
export default {
  data() {
    return {
      nft: this.value,
      contractAddress: "0xaA773D0Ebf777F8311c813C0763A1e3e4Fd077c2",
      nft_status: ["NEW", "BIDING", "SELLING", "OWNED"],
      nft_color: ["success", "danger", "primary", "secondary"],
    };
  },
  props: {
    value: {
      type: Object,
      default: {},
    },
  },
};
</script>

<style scoped>
.left-margin {
  margin-left: 5px;
}
</style>