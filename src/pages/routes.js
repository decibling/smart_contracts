import {createRouter} from 'vue-router'
import Homepage from './home/Home.vue';
import Account from './account/Account.vue';
import NFT from './nft/NFT.vue';
import TokenFarm from './TokenFarm/TokenFarm.vue';

const routes = [
  {
    path: '/',
    component: Homepage
  },

  {
    path: '/account',
    component: Account
  },

  {
    path: '/NFT/:tokenId',
    component: NFT
  },
  {
    path :'/token_farm',
    component: TokenFarm
  }
]

export default function (history) {
  return createRouter({
    history,
    routes
  })
}