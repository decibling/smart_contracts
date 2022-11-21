<script setup>
import TopNavbar from "../../components/TopNavbar.vue";
import wallet from "../../lib/wallet";
import { ethers } from "ethers";
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
  CModal,
  CCallout,
  CModalHeader,
  CModalFooter,
  CModalBody,
} from "@coreui/vue";
</script>
<template>
  <TopNavbar />
  <div class="container">
    <h3 v-if="!available">
      {{ [" Please install Metamas k", "Loading..."][getError()] }}
    </h3>
    <template v-else>
      <template v-if="!loading">
        <div class="row">
          <div class="col-md-6">
            <div class="row">
              <audio controls style="width: 100%">
                <source v-bind:src="'https://cloudflare-ipfs.com/ipfs/' + nft.url" type="audio/mpeg" />
                Your browser does not support the audio element.
              </audio>
            </div>
            <div class="row">
              <CButton v-on:click="showModal = true" color="primary" style="width: 150px; margin: 20px"
                v-if="nft.status != 1 && nft.owner.toUpperCase() == account?.toUpperCase()">
                Create Bidding
              </CButton>
            </div>
          </div>
          <div class="col-md-6">
            <div class="row">
              <CCallout color="info">
                <small class="text-mute font-bold">Name</small><br />
                <strong class="h4">{{ nft.name }}</strong>
              </CCallout>
            </div>
            <div class="row">
              <CCallout color="danger" style="overflow: hidden">
                <small class="text-muted">Owner</small><br />
                <strong class="h4" style="text-overflow: ellipsis">{{
                  nft.owner
                }}</strong>
              </CCallout>
            </div>
            <div class="row">
              <CCallout color="sucesss">
                <small class="text-muted">Status</small><br />
                <CBadge v-bind:color="nft_color[nft.status]">{{
                  nft_status[nft.status]
                }}</CBadge>
              </CCallout>
            </div>
          </div>
        </div>
        <div class="row">
          <hr class="m-2" />
        </div>
        <div class="row" v-if="biddingInfo">
          <CCard class="col-md-12">
            <CCardHeader>
              <v-progress-linear :color="countDownBid[0] < 1 ? 'red' : 'blue'" height="5" indeterminate>
              </v-progress-linear>
              <h3>
                <template v-if="countDownBid[0] >= 0 && countDownBid[1] >= 0">
                  [{{ countDownBid[0] }}:{{ countDownBid[1] }}]
                </template>
                Top bid:
                {{ biddingInfo.winner }}
              </h3>
            </CCardHeader>
            <CCardBody style="overflow-x: scroll">
              <div class="container">
                <div class="row">
                  Status: {{ bid_status[biddingInfo.status] }}
                </div>
                <div class="row">
                  Time:
                  {{
                  moment(biddingInfo.startTime).format("YYYY-MM-DD HH:mm:ss")
                  }}
                  -
                  {{
                  moment(biddingInfo.endTime).format("YYYY-MM-DD HH:mm:ss")
                  }}
                </div>
                <div class="row">
                  Top Price: {{ (biddingInfo.price / 1e9).toFixed(9) }} ETH (
                  {{ ((biddingInfo.price / 1e9) * usdtPerEth).toFixed(2) }}
                  USD)
                </div>
              </div>
              <div v-show="showDetailBidding">
                <CTable striped>
                  <CTableHead>
                    <CTableRow>
                      <CTableHeaderCell scope="col">#</CTableHeaderCell>
                      <CTableHeaderCell scope="col">User's Wallet address</CTableHeaderCell>
                      <CTableHeaderCell scope="col">Price (ETH)</CTableHeaderCell>
                      <CTableHeaderCell scope="col">Price (USD)</CTableHeaderCell>
                      <CTableHeaderCell scope="col">Time</CTableHeaderCell>
                    </CTableRow>
                  </CTableHead>
                  <CTableBody>
                    <CTableRow v-for="bid in bidTable.data" v-bind:key="bid.i">
                      <CTableHeaderCell scope="row">{{
                      bid.i + 1
                      }}</CTableHeaderCell>
                      <CTableDataCell><a :href="
                        'https://goerli.arbiscan.io/address/' + bid.user
                      " target="_blank">{{ bid.user.slice(0, 10) }}...</a></CTableDataCell>
                      <CTableDataCell>{{ bid.price / 1e9 }}</CTableDataCell>
                      <CTableDataCell>{{
                      ((bid.price / 1e9) * usdtPerEth).toFixed(2)
                      }}</CTableDataCell>
                      <CTableDataCell>{{
                      moment(bid.timestamp).format("YYYY-MM-DD HH:mm:ss")
                      }}</CTableDataCell>
                    </CTableRow>
                  </CTableBody>
                </CTable>
              </div>
            </CCardBody>
            <CCardFooter>
              <CButton variant="outline" color="danger" @click="showBidModal = true">
                Bid
              </CButton>
              <CButton variant="outline" color="primary" @click="settleBidding()" v-if="showSettleBidding">
                <CSpinner color="info" v-if="settleBiddingLoad" size="sm" style="margin-right: 5px" />Receive money
              </CButton>
            </CCardFooter>
          </CCard>
        </div>
      </template>
      <template v-else>
        <CSpinner color="success" style="width: 4rem; height: 4rem" />
      </template>
    </template>
  </div>
  <CModal title="Create biding" :visible="showModal" @close="showModal = false">
    <CModalHeader>
      <CModalTitle>Create Biding</CModalTitle>
    </CModalHeader>
    <CModalBody>
      <div class="row">
        <strong class="inline-row">Name :</strong>
        <p class="inline-row">{{ nft.name }}</p>
      </div>
      <div class="row">
        <strong class="inline-row col-md-4">Bid's start time :</strong>
        <Datepicker class="mb-1 inline-row col-md-8" v-model="model.startTime" v-if="!model.startNow"></Datepicker>
        <p class="inline-row" v-else>Right the way</p>
        <CButton color="danger" @click="model.startNow = !model.startNow" style="width: auto">{{ model.startNow ?
        "Select date" : "Now"
        }}</CButton>
      </div>
      <div class="row">
        <strong class="inline-row col-md-4">Bid's end time :</strong>
        <Datepicker class="mb-1 inline-row col-md-8" v-model="model.endTime"></Datepicker>
      </div>
      <div class="row">
        <strong class="inline-row col-md-4">Start price (ETH):</strong>
        <input class="form-control inline-row" placeholder="Start Price(ETH)" v-model="model.startPrice" type="number"
          @keyup="model.startPriceUsd = model.startPrice * usdtPerEth" />
      </div>
      <div class="row">
        <div style="
            height: 20px !important;
            width: 20px !important;
            background-image: url('/exchange.png');
            background-size: cover;
            position: relative;
            margin: 10px 0 10px 0;
            left: 40%;
          "></div>
      </div>
      <div class="row">
        <strong class="inline-row col-md-4">Start price (USD):</strong>
        <input class="form-control inline-row" placeholder="Start Price($)" v-model="model.startPriceUsd" type="number"
          @keyup="model.startPrice = model.startPriceUsd / usdtPerEth" />
      </div>
    </CModalBody>
    <CModalFooter>
      <CButton color="secondary" @click="
  showModal = false;
createBidingLoad = false;
      ">
        Cancel
      </CButton>
      <CButton color="primary" @click="createBiding()">
        <CSpinner color="info" v-if="createBidingLoad" size="sm" style="margin-right: 5px" />Create
      </CButton>
    </CModalFooter>
  </CModal>
  <CModal title="Bid" :visible="showBidModal" @close="showBidModal = false">
    <CModalHeader>
      <CModalTitle>Bid</CModalTitle>
    </CModalHeader>
    <CModalBody>
      <div class="container">
        <div class="row">
          <strong class="inline-row col-md-4">Bid's Price (ETH):</strong>
          <input class="form-control inline-row" placeholder="Start Price(ETH)" v-model="model.startPrice" type="number"
            @keyup="model.startPriceUsd = model.startPrice * usdtPerEth" />
        </div>
        <div class="row">
          <div style="
              height: 20px !important;
              width: 20px !important;
              background-image: url('/exchange.png');
              background-size: cover;
              position: relative;
              margin: 10px 0 10px 0;
              left: 40%;
            "></div>
        </div>
        <div class="row">
          <strong class="inline-row col-md-4">Bid's Price (USD):</strong>
          <input class="form-control inline-row" placeholder="Start Price($)" v-model="model.startPriceUsd"
            type="number" @keyup="model.startPrice = model.startPriceUsd / usdtPerEth" />
        </div>
      </div>
    </CModalBody>
    <CModalFooter>
      <CButton color="secondary" @click="
  showBidModal = false;
createBidLoad = false;
      ">
        Cancel
      </CButton>
      <CButton color="danger" @click="bidNFT()">
        <CSpinner color="info" v-if="createBidLoad" size="sm" style="margin-right: 5px" />Bid
      </CButton>
    </CModalFooter>
  </CModal>
  <v-overlay v-if="loading">
    <v-progress-circular indeterminate size="64"></v-progress-circular>
  </v-overlay>
</template>
<style>
.inline-row {
  display: inline-block;
  float: left;
  position: relative;
  width: auto;
}
</style>

<script>
import Datepicker from "vue3-date-time-picker";
import "vue3-date-time-picker/dist/main.css";
import moment from "moment";

export default {
  components: {
    TopNavbar,
    Datepicker,
  },
  data() {
    return {
      tokenId: 0,
      account: "",
      available: false,
      loading: false,
      showDetailBidding: true,
      showSettleBidding: false,
      settleBiddingLoad: false,
      countDownBid: [],
      showModal: false,
      showBidModal: false,
      createBidingLoad: false,
      createBidLoad: false,
      loadBidingData: false,
      biddingInfo: undefined,
      nft: {},
      nft_status: ["NEW", "BIDING", "SELLING", "OWNED"],
      nft_color: ["success", "danger", "primary", "secondary"],
      bid_status: ["NOTREADY", "START", "BIDING", "END"],
      usdtPerEth: 1113.40,
      model: {
        startNow: false,
        startTime: "",
        endTime: "",
        startPrice: 0,
        startPriceUsd: 0,
      },
      bidTable: {
        headers: [
          { text: "Address", align: "left", sortable: false, value: "user" },
          { text: "Price", align: "left", sortable: false, value: "price" },
          {
            text: "Timestamp",
            align: "left",
            sortable: false,
            value: "timestamp",
          },
        ],
        data: [],
      },
    };
  },

  computed: {},
  methods: {
    name() { },
    moment() {
      return moment();
    },
    async bidNFT() {
      try {
        this.createBidLoad = true;
        if (this.biddingInfo.price > this.model.startPrice * 1e9) {
          alert("Your bidding money must be larger current winner's bid");
          this.createBidLoad = false;
          return;
        }
        const [contract, signer] = wallet.getContract();
        const connection = contract.connect(signer);
        let result = await contract.bid(this.nft.url, {
          value: ethers.utils.parseEther(this.model.startPrice.toString()),
        });
        if (confirm("Open ethernet scanner for bidding process?")) {
          window.open(
            "https://goerli.arbiscan.io/tx/" + result.hash,
            "_blank"
          );
        }
        await result.wait();
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
      this.createBidLoad = false;
      this.showBidModal = false;
      alert("Bid successfully");
      location.reload();
    },
    async settleBidding() {
      if (this.settleBiddingLoad) return;
      this.settleBiddingLoad = true;
      const [contract, signer] = wallet.getContract();
      const connection = contract.connect(signer);
      let result = await contract.settleBiddingSession(this.nft.url);
      await result.wait();
      location.reload();
    },
    async timeLoading() {
      window.timecountInterval = setInterval(
        function () {
          this.countDownBid = this.getBiddingSecond();
          if (
            parseInt(this.countDownBid[0]) < 0 ||
            parseInt(this.countDownBid[1]) < 0
          ) {
            if (this.account.toUpperCase() == this.nft.owner.toUpperCase()) {
              // show settle biding button
              this.showSettleBidding = true;
              clearInterval(window.timecountInterval);
            }
          }
        }.bind(this),
        1000
      );
    },
    async loadData() {
      if (this.account) {
        // loading wallet
        const [contract, { }] = await wallet.getContract();
        let nftInfo = await contract.listNFT(
          await contract.tokenURI(this.tokenId)
        );
        this.nft = {
          ...nftInfo,
          price: nftInfo.price.toNumber(),
          currentBidding: nftInfo.currentBidding.toNumber(),
        };
        console.log({          ...nftInfo,
          price: nftInfo.price.toNumber(),
          currentBidding: nftInfo.currentBidding.toNumber(),
})
        window.contract = contract;
        // contract.
      }
    },
    getBiddingSecond() {
      let seconds = this.biddingInfo.endTime.getTime() - new Date().getTime();
      seconds = parseInt(seconds / 1000);
      let timeFormat = [
        String(parseInt(seconds / 60)).padStart(2, "0"),
        String(seconds % 60).padStart(2, "0"),
      ];
      return timeFormat;
    },
    async createBiding() {
      if (this.createBidingLoad) {
        // return;
      }
      if (!this.model.startNow && !this.model.startTime) {
        // start time must be select
        alert("Start time must be select");
        return;
      }
      if (this.model.startNow) {
        this.model.startTime = new Date();
      }
      if (!this.model.endTime) {
        // start time must be select
        alert("End time must be select");
        return;
      }
      if (new Date(this.model.endTime) <= new Date(this.model.startTime)) {
        alert("End time must be after start time");
        return;
      }
      if (this.model.startPrice == 0 || this.model.startPriceUsd == 0) {
        alert("You must enter start price");
        return;
      }
      this.createBidingLoad = true;
      try {
        if (this.nft.url) {
          //
          const [contract, signer] = wallet.getContract();
          const connection = contract.connect(signer);
          console.log("connection", connection);
          let result = await contract.createBidding(
            this.nft.url,
            ethers.BigNumber.from(
              parseInt(this.model.startPrice * 1e9).toString()
            ),
            ethers.BigNumber.from(
              parseInt(
                new Date(this.model.startTime).getTime() / 1000
              ).toString()
            ),
            ethers.BigNumber.from(
              parseInt(new Date(this.model.endTime).getTime() / 1000).toString()
            ),
            {
              value: ethers.utils.parseEther(
                ((await contract.biddingFee()).toNumber() / 1e9).toString()
              ),
            }
          );
          if (confirm("Open ethernet scanner for create biding process?")) {
            window.open(
              "https://goerli.arbiscan.io/tx/" + result.hash,
              "_blank"
            );
          }
          await result.wait();
          this.createBidingLoad = false;
          this.showModal = false;
          alert("Create biding successfully");
          location.reload();
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
    async loadBiding() {
      this.loadBidingData = true;
      let listMapping = [
        "winner",
        "price",
        "status",
        "startTime",
        "endTime",
        "currentSession",
      ];
      console.log('getBidding', this.nft.url, this.nft.currentBidding);
      let biddingResult = await contract.getBidding(this.nft.url, this.nft.currentBidding);
      let contractBiding = common.mappingWithKey(
        listMapping,
        biddingResult
      );
      console.log(biddingResult);
      if (contractBiding.status != 3) {
        //
        this.biddingInfo = {
          ...contractBiding,
          startTime: new Date(contractBiding.startTime * 1000),
          endTime: new Date(contractBiding.endTime * 1000),
          currentSession: contractBiding.currentSession,
          price: contractBiding.price / 1e9,
        };
        console.log(contractBiding);
      }
      // load
      await this.loadBiddingList();
      this.loadBidingData = false;
    },
    async loadBiddingList() {
      const [contract, signer] = wallet.getContract();
      let bidList = [];
      for (var i = 0; i < this.biddingInfo.currentSession; i++) {
        bidList.push(
          common.mappingWithKey(
            ["user", "price", "timestamp"],
            await contract.getBidSession(
              this.nft.url,
              this.nft.currentBidding,
              i + 1
            )
          )
        );
      }
      bidList = bidList.map((e, i) => ({
        ...e,
        i,
        price: e.price / 1e9,
        timestamp: new Date(e.timestamp.toNumber() * 1000),
      }));
      bidList.sort((a, b) => b.timestamp - a.timestamp);
      this.bidTable.data = bidList;
    },
    getError() {
      if (!window.ethereum) {
        return 0;
      }
      return 1;
    },
  },
  async mounted() {
    wallet.initEvent();
    try {
      if (!window.ethereum) {
        this.available = false;
        return;
      }
      this.available = true;

      this.tokenId = this.$route.params.tokenId;
      [this.account, {}] = await wallet.connectWallet();
      await this.loadData();
      this.loading = false;
      if (this.nft.status == 1) {
        await this.loadBiding();
        this.timeLoading();
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
};
</script>