<script setup>
import TopNavbar from "../../components/TopNavbar.vue";
import { ethers } from "ethers";
import DbAudio from "../../../artifacts/contracts/DbAudio.sol/DbAudio.json";
import wallet from "../../lib/wallet";
import common from "../../lib/common";

import {
  CRow,
  CCol,
  CCard,
  CCardHeader,
  CButton,
  CForm,
  CFormLabel,
  CInputGroup,
  CFormInput,
} from "@coreui/vue";
import NFTMusic from "../../components/NFTMusic.vue";
</script>

<template>
  <TopNavbar />
  <div class="container">
    <template v-if="!is_connected">
      <div
        class="btn btn-primary"
        v-on:click="loadInformation()"
        v-if="checkEth()"
      >
        Connect To My Wallet
      </div>
      <div v-else>
        <h5>Please install metamask</h5>
      </div>
    </template>
    <template v-else>
      <div class="container">
        <div class="row">
          <h3>Welcome : {{ accountAddress }}</h3>
        </div>
        <div class="row">
          <div class="center" style="color: red; font-weight: bold">
            Your balance is : {{ balance }} ETH
          </div>
        </div>
        <div class="row">
          <div class="col-md-3"></div>
          <CCard class="col-md-6">
            <CCardHeader> Upload NFT </CCardHeader>
            <CCardBody>
              <div class="row" style="margin-bottom: 10px">
                <CInputGroup class="flex-nowrap">
                  <CInputGroupText id="addon-wrapping">Name</CInputGroupText>
                  <CFormInput
                    v-model="model.name"
                    placeholder="Name of NFT"
                    aria-label="Name of NFT"
                    aria-describedby="addon-wrapping"
                  />
                </CInputGroup>
              </div>
              <div class="row">
                <CInputGroup class="mb-3">
                  <input
                    class="form-control"
                    type="file"
                    ref="file_mp3"
                    accept=".mp3,audio/*"
                  />
                </CInputGroup>
              </div>
            </CCardBody>
            <CCardFooter>
              <CButton
                color="success"
                v-on:click="uploadNFT()"
                :disable="accountAddress != ''"
              >
                <CSpinner
                  component="span"
                  size="sm"
                  aria-hidden="true"
                  v-if="loading"
                />
                Upload NFT</CButton
              >
              <CButton color="secondary" variant="outline" class="left-margin"
                >Clear</CButton
              >
              <CButton
                color="secondary"
                variant="outline"
                v-on:click="loadMyNFT()"
                class="left-margin"
                >Reload</CButton
              >
            </CCardFooter>
          </CCard>
        </div>
        <div class="row">
          <hr style="margin-top: 10px" />
          <h3>My NFT</h3>
        </div>
        <div class="row">
          <div class="center">
            <CSpinner
              component="span"
              size="lg"
              aria-hidden="true"
              v-if="loadingNFT"
            />
          </div>

          <template v-for="item in myNFT" v-bind:key="item.url">
            <NFTMusic :value="item" />
          </template>
        </div>
      </div>
    </template>
  </div>
</template>
<style></style>

<script>
export default {
  components: {
    TopNavbar,
    NFTMusic,
  },
  data() {
    return {
      is_connected: false,
      balance: 0,
      accountAddress: "",
      loading: false,
      loadingNFT: false,
      model: {
        name: "",
        file: undefined,
      },
      signer: undefined,
      contract: undefined,
      myNFT: [],
    };
  },

  methods: {
    async uploadNFT() {
      try {
        if (!this.loading) {
          this.loading = true;
          if (this.model.name) {
            // call smart contract
            if (window.IpfsHttpClient) {
              let uploadedFile = await wallet.uploadIpfs(
                this.$refs.file_mp3.files[0]
              );
              let uploadedURL =
                "https://ipfs.datgital.top/ipfs/" + uploadedFile.path;
              console.log(uploadedURL);
              const [contract, signer] = wallet.getContract();
              const connection = contract.connect(signer);
              const addr = connection.address;
              const result = await contract.createNFT(
                uploadedFile.path,
                this.model.name,
                0
              );
              console.log(result);
              alert("https://rinkeby.etherscan.io/tx/" + result.hash);
              await result.wait();
              this.loading = false;
              this.loadMyNFT();
              // call smart contract to initialize
            } else {
              alert("IPFS service not found");
              this.loading = false;
            }
          } else {
            // alert("");
            $.alert({
              title: "Alert!",
              content: "You need input more information!",
            });

            this.loading = false;
          }
        }
      } catch (e) {
        if (e) {
          if (e.code == "UNPREDICTABLE_GAS_LIMIT") {
            let errorIndex = parseInt(e.error.message.match(/\d/g).join());
            alert("Error : " + common.errorCode[errorIndex]);
          } else {
            alert(e.message);
          }
          location.reload();
        }
      }
    },
    async clearAll() {},
    checkEth() {
      return !!window.ethereum;
    },
    async loadMyNFT() {
      try {
        this.myNFT = [];
        this.loadingNFT = true;
        const [contract, signer] = wallet.getContract();
        let userToken = await this.getListToken(contract);
        userToken.forEach(async (index) => {
          let uri = await contract.tokenURI(index.toNumber());
          let nft = await contract.listNFT(uri);
          this.myNFT.push({ tokenId: index, ...nft });
        });
        this.loadingNFT = false;
      } catch (e) {
        if (e) {
          if (e.code == "UNPREDICTABLE_GAS_LIMIT") {
            let errorIndex = parseInt(e.error.message.match(/\d/g).join());
            alert("Error : " + common.errorCode[errorIndex]);
          } else {
            alert(e.message);
          }
          location.reload();
        }
      }
    },
    async getListToken(contract) {
      let index = 0;
      let listToken = [];
      while (true) {
        try {
          let currentValue = await contract.listOwnToken(
            this.accountAddress,
            index
          );
          listToken.push(currentValue);
          index++;
        } catch (err) {
          console.log(err);
          return listToken;
        }
      }
    },
    async isConnected() {
      this.is_connected = await window.ethereum.isConnected();
      if (this.is_connected) {
        this.loadInformation();
      }
    },
    async loadInformation() {
      [this.accountAddress, this.balance] = await wallet.connectWallet();
      this.is_connected = true;
      this.loadMyNFT();
    },
  },
  computed: {},
  mounted() {
    this.isConnected();
    wallet.initEvent();
    common.loadIPFSModule();
  },
};
</script>

<style scoped>
.left-margin {
  margin-left: 5px;
}
</style>