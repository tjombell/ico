import ICO from './ICO.json';

const options = {
  contracts: [ICO],
  web3: {
    fallback :{
        type: "ws",
        url: "ws://127.0.0.1:9545",
    },
  }
};

export default options;
