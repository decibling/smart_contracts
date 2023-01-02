export default {
  loadIPFSModule() {
    let recaptchaScript = document.createElement("script");
    recaptchaScript.setAttribute(
      "src",
      "https://cdn.jsdelivr.net/npm/ipfs-http-client/dist/index.min.js"
    );
    document.head.appendChild(recaptchaScript);
  },
  mappingWithKey(keys, values) {
    let data = {};
    keys.forEach((v, i) => {
      data[v] = values[i] ?? values[v] ?? "";
    });
    return data;
  },
  errorCode: {
    0: "ERROR",
    1: "Share percent format is not correct",
    2: "This NFT is existed",
    3: "You must be own this NFT for setPriceNFT",
    4: "This NFT is not existed",
    5: "You must be own this NFT for transferNFT",
    6: "You must be own this NFT for createBidding",
    7: "End time of biding must be in future",
    8: "Audio is not ready status",
    9: "You must pay fee in order to initialize biding session",
    10: "This NFT is not available for biding due to : STATUS_INCORRECT",
    11: "NFT is not available for biding due to : BIDING_NOT_FOUND",
    12: "Bidding is over",
    13: "Bidding price must be larger than current",
    14: "This NFT is not available for settle",
    15: "Bidding is not over yet",
    16: "Bidding is not available for settle",
    17: "Burn functionality is removed",
    18: "Start time must be before end time",
    19: "fee address",
    20: "pay value",
    21: "zero address",
    22: "positive integer only",
    23: "invalid amount",
    24: "error on transfer",
    25: "cannot bid on your own item",
    26: "invalid item id",
    27: "invalid uri",
    28: "invalid name",
    29: "no winner, please cancel it",
    30: "auction already ended",
    31: "no auction exists",
    32: "end time must be greater than start",
    33: "auction should end after 5 minutes",
    34: "DeciblingAuction: Constructor wallets cannot be zero"
  },
};
