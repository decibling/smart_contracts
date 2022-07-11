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
          <div class="container">
            <div class="row">
              <p>Account : {{ accountAddress }}</p>
            </div>
            <div class="row">
              <h4 class="center" style="color: red; font-weight: bold">
                Your balance: {{ balanceDB }} DB
              </h4>
              <h4 class="center" style="color: green; font-weight: bold">
                Staked: {{ stakeInfo.amount }} DB
              </h4>
              <h4 class="center" style="color: blue; font-weight: bold">
                Your reward:
                {{ unClaimAmountShow }} DB ({{ growPerMin }} DB per min)
              </h4>
            </div>
            <div class="container">
              <div class="row" style="margin-bottom: 10px">
                <CInputGroup class="flex-nowrap">
                  <CInputGroupText id="addon-wrapping"
                    >Stake Amount</CInputGroupText
                  >
                  <CFormInput
                    v-model="model.currentStake"
                    aria-describedby="addon-wrapping"
                  />
                </CInputGroup>
              </div>
              <div class="row">
                <v-btn color="primary" @click="stakeNow()">
                  <CSpinner
                    color="white"
                    v-if="stakeLoading"
                    size=""
                    style="margin-right: 5px"
                  />Stake</v-btn
                >
                <v-btn
                  class="mt-2 text-white"
                  color="danger"
                  @click="unStakeNow()"
                >
                  <CSpinner
                    color="white"
                    v-if="stakeLoading"
                    style="margin-right: 5px"
                  />UnStake All</v-btn
                ><v-btn
                  class="mt-2 text-white"
                  color="success"
                  @click="issueAll()"
                  v-if="allowToIssue"
                >
                  <CSpinner
                    color="white"
                    v-if="stakeLoading"
                    style="margin-right: 5px"
                  />Issue All Token</v-btn
                >
              </div>
            </div>
          </div>
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
      stakeLoading: false,
      balanceDB: 0,
      stakeInfo: {},
      allowToIssue: false,
      unClaimAmountShow: 0,
      lastUpdateStake: 0,
      rewardConfig: {},
      growPerMin: 0,
      model: { currentStake: "" },
      currentUnStake: "",
      tab: null,
      accountAddress: "",
      loading: false,
      loadingNFT: false,
      tab: null,
    };
  },

  methods: {
    async clearAll() {},
    checkEth() {
      return !!window.ethereum;
    },
    async isConnected() {
      this.is_connected = await window.ethereum.isConnected();
      if (this.is_connected) {
        this.loadInformation();
      }
    },
    initSetInterval() {
      setInterval(
        function () {
          try {
            if (
              this.stakeInfo.stakeTime &&
              this.rewardConfig.rewardPercent &&
              this.rewardConfig.perSeconds
            ) {
              let timeRange =
                new Date().getTime() / 1000 - this.stakeInfo.stakeTime;
              let moneyAdded =
                ((this.stakeInfo.amount * timeRange) /
                  this.rewardConfig.perSeconds) *
                (this.rewardConfig.rewardPercent / 1e4);
              this.unClaimAmountShow = (
                this.stakeInfo.unClaimAmount + moneyAdded
              ).toFixed(2);
              this.growPerMin =
                ((60 * this.rewardConfig.rewardPercent) /
                  this.rewardConfig.perSeconds /
                  1e4) *
                this.stakeInfo.amount;
            } else {
              this.unClaimAmountShow = 0;
              this.growPerMin = 0;
            }
          } catch (e) {
            if (e) {
              alert(e.message);
              location.reload();
            }
          }
        }.bind(this),
        200
      );
    },
    async stakeNow() {
      if (!this.stakeLoading)
        if (this.model.currentStake) {
          this.stakeLoading = true;
          const [contractTokenFarm, {}] = await wallet.getTokenFarmContract();
          const [contractToken, {}] = await wallet.getTokenContract();
          try {
            let tx1 = await contractToken.approve(
              contractTokenFarm.address,
              ethers.utils.parseEther(this.model.currentStake.toString())
            );
            await tx1.wait();
            let tx2 = await contractTokenFarm.stake(
              ethers.utils.parseEther(this.model.currentStake.toString())
            );
            await tx2.wait();
            this.stakeLoading = false;

            this.loadInformation();
            alert("Stake successfully!");
          } catch (e) {
            this.stakeLoading = false;

            if (e) {
              alert(e.message);
              location.reload();
            }
          }
        }
    },
    async unStakeNow() {
      if (!this.stakeLoading)
        if (confirm("Your reward will be lost, continues?")) {
          this.stakeLoading = true;
          const [contractTokenFarm, {}] = await wallet.getTokenFarmContract();
          try {
            let tx1 = await contractTokenFarm.unstake();
            await tx1.wait();
            this.stakeLoading = false;
            this.loadInformation();
            alert("Unstake successfully!");
          } catch (e) {
            this.stakeLoading = false;

            if (e) {
              alert(e.message);
              location.reload();
            }
          }
        }
    },
    async issueAll() {
      if (!this.stakeLoading);
      if (confirm("Issue all reward for all users?")) {
        this.stakeLoading = true;
        const [contractTokenFarm, {}] = await wallet.getTokenFarmContract();
        try {
          let tx1 = await contractTokenFarm.issueToken();
          await tx1.wait();
          this.stakeLoading = false;
          this.loadInformation();
          alert("Issue all token successfully!");
        } catch (e) {
          this.stakeLoading = false;
          if (e) {
            alert(e.message);
            location.reload();
          }
        }
      }
    },
    async updateBalanceDB() {
      const [contractToken, {}] = wallet.getTokenContract();
      this.balanceDB = (
        (await contractToken.balanceOf(this.accountAddress)) / 1e18
      ).toFixed(2);
      [window.contractTokenFarm, {}] = wallet.getTokenFarmContract();
      [window.contractToken, {}] = wallet.getTokenContract();
    },
    async updateRewardConfig() {
      const [contractTokenFarm, {}] = wallet.getTokenFarmContract();
      const [contractToken, {}] = wallet.getTokenContract();

      this.rewardConfig = {
        rewardPercent: (await contractTokenFarm.rewardPercent()).toNumber(),
        perSeconds: (await contractTokenFarm.perSeconds()).toNumber(),
      };
    },
    async updateStakeInfo() {
      const [contractTokenFarm, {}] = await wallet.getTokenFarmContract();
      if (
        (await contractTokenFarm.owner()).toUpperCase() ==
        this.accountAddress.toUpperCase()
      ) {
        this.allowToIssue = true;
      }
      let stakeInfo = await contractTokenFarm.listStake(this.accountAddress);
      this.stakeInfo = {
        amount: stakeInfo.amount / 1e18,
        stakeTime: stakeInfo.stakeTime.toNumber(),
        unClaimAmount: stakeInfo.unClaimAmount / 1e18,
      };
    },
    async loadInformation() {
      [this.accountAddress, this.balance] = await wallet.connectWallet();
      await this.updateBalanceDB();
      await this.updateStakeInfo();
      await this.updateRewardConfig();
      this.is_connected = true;
    },
  },
  computed: {},
  mounted() {
    this.isConnected();
    wallet.initEvent();
    this.initSetInterval();
  },
};
</script>

<style scoped>
.left-margin {
  margin-left: 5px;
}
/* Helper classes */
.basil {
  background-color: #fffbe6 !important;
}
.basil--text {
  color: #356859 !important;
}
</style>